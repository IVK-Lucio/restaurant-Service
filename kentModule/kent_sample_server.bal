import ballerina/grpc;
import ballerina/system;
import wso2/kafka;
import ballerina/http;
import ballerina/io;
import ballerina/encoding;
import ballerina/math;

listener grpc:Listener ep = new (9000);

boolean overbooked = false;

map<Client> clients = {

};
map<json> bills = {

};
map<float> food = {
    //Default foods
    "Chips": 1.0,
    "Soup": 0.3
};
map<float> beverages = {
    // Default drinks
    "Coke": 0.3,
    "Tafel": 9.0
};
map<json> foodOrders = {

};
map<json> drinkOrders = {

};

string[] waitingList = [];

function reOrderWaitingList {
        // Get smallest
        int j = 0;
        int i = 0;
        while (j<waitingList.length()) {
            while (i<waitingList.length()) {
                float deposit1 = clients[waitingList[i]].booking.deposit;
                float deposit2 = clients[waitingList[j]].booking.deposit;
                if(deposit2>deposit1) {
                    // Swap
                    string temp = waitingList[j];
                    waitingList[j] = waitingList[i];
                    waitingList[i] = temp;
                }
                i = i+1;
            }
           i = 0; 
           j = j+1;
        }
    }

string[] bookingList = [];

kafka:ProducerConfig producerConfigs = {
    bootstrapServers: "localhost:9092",
    clientID: "basic-producer",
    acks: "all",
    noRetries: 3
};
kafka:SimpleProducer BookingProducer = new kafka:SimpleProducer(producerConfigs);



service Kent on ep {

    resource function book(grpc:Caller caller, Client value) {
        // Implementation goes here.

        // You should return a string

        // Reference number generated using UUID
        string referenceNumber = system:uuid();
        // Response JSON file generated with reference number
        json response = {
            "referenceNumber": referenceNumber
        };
        // If overbooked, tell the client so they can pay a deposit
        if (overbooked) {
            response["Message"] = "Overbooked";
        }
        // Give the client a reference number
        value.reference = referenceNumber;
        // Add the client to the map of clients
        clients[referenceNumber] = value;
        // Add the client's reference number to the array for ordering
        bookingList[bookingList.length()] = referenceNumber;

        // Publish customer info to Kafka


        json timeInfo = {

        };
        Booking booking = value.booking;
        Time time = booking.prefTime;

        timeInfo["hour"] = value.booking.prefTime.int_hour;
        timeInfo["minute"] = value.booking.prefTime.int_minute;
        json dateInfo = {

        };
        dateInfo["day"] = value.booking.dateOfBooking.int_day;
        dateInfo["month"] = value.booking.dateOfBooking.int_month;
        dateInfo["year"] = value.booking.dateOfBooking.int_year;
        json bookingInfo = {

        };
        bookingInfo["numberOfGuests"] = value.booking.numberOfGuests;
        bookingInfo["duration"] = value.booking.hoursDuration;
        bookingInfo["date"] = dateInfo;
        bookingInfo["time"] = timeInfo;
        json clientInfo = {
            "Client": {
                "bookingInfo": bookingInfo,
                "referenceNumber": value.reference
            }
        };

        // Push json to kafka
        byte[] serializedMsg = clientInfo.toString().toByteArray("UTF-8");
        var sendResult = BookingProducer->send(serializedMsg, "bookings", partition = 0);


        var resp = caller->send(referenceNumber);
        var respconf = caller->complete();

    }
    resource function deposit(grpc:Caller caller, Deposit value) {
        // Implementation goes here.

        // You should return a float
        string referenceNum = value.reference;
        clients[referenceNum].booking.deposit.deposit = value.deposit;
        //generate random conf code
        string confirmationCode = system:uuid();
        json r = {
            "Result": "Success",
            "confirmationCode": confirmationCode
        };
        // return conf code
        var response = caller->send(r);
        var respconf = caller->complete();
    }
    resource function arrive(grpc:Caller caller, string value) {
        // Implementation goes here.
        var respconf = caller->complete();
        // You should return a string
    }
}



// Kafka consumer listener configurations
kafka:ConsumerConfig consumerConfig = {
    bootstrapServers: "localhost:9092, localhost:9093",
    // Consumer group ID
    groupId: "bookingHandlers",
    // Listen from topics 'Bookings' and 'clientstatus'
    topics: ["bookings", "clientStatus"],
    // Poll every 0.3 seconds
    pollingInterval: 300
};

// Create kafka consumer listener
listener kafka:SimpleConsumer consumer = new(consumerConfig);



service TableMonitor on consumer {
    resource function onMessage(kafka:SimpleConsumer simpleConsumer, kafka:ConsumerRecord[] records) {
        foreach var item in records {
            byte[] serializedMsg = item.value;
            // Convert the serialized message to string message
            string msg = encoding:byteArrayToString(serializedMsg);
            //io:println("New message received from the product admin");
            // log the retrieved Kafka record
            //io:println("Topic: " + item.topic + "; Received Message: " + msg);

            // Check topic here to make sure it's the right one being listened to
            // If clientStatus add/remove from busy list
            //
            if (item.topic.equalsIgnoreCase("clientStatus")) {
                json | error status =  json.convert(msg);
                if !(status is error) {
                    string|error state = string.convert(status["state"]);
                    if !(state is error) {
                        if (state.equalsIgnoreCase("arrived")) {
                            // If a client has arrived, add to waiting list
                            string|error refNum = string.convert(status["referenceNumber"]);
                            if !(refNum is error) {
                                waitingList[waitingList.length()] = refNum;
                                reOrderWaitingList();
                            }

                        } else if (state.equalsIgnoreCase("left")) {
                            // If client left, get top candidate into restaurantv
                            reOrderWaitingList();
                            http:Client welcomingService = new("http://localhost:8080");
                            var response = welcomingService->get("/WelcomeService/greetAndTakeToTable");
                        }
                    }
                }
            } else if (item.topic.equalsIgnoreCase("bookings")) {
                // Don't do anything, table monitoring service shouldn't care.
            }
        }
    }
}

service WelcomeService on new http:Listener(8080) {
    resource function greetAndTakeToTable(http:Caller caller, http:Request request) {
        string clientRefNo = waitingList[0];
        clients[waitingList[0]].booking.deposit = -1;
        reOrderWaitingList();
    }
}
service tableService on new http:Listener(8080) {

    resource function greet(http:Caller caller, http:Request request) {
        var response = caller->respond("Hi, what would you like to order?");
    }

    resource function getFoodMenu(http:Caller caller, http:Request request) {
        string[] keys = food.keys();
        json menu = {

        };
        int j = 0;
        while (j < keys.length()) {
            menu[keys[j]] = food[keys[j]];
            j = j + 1;
        }
        var response = caller->respond(menu);
    }

    resource function getDrinkMenu(http:Caller caller, http:Request request) {
        string[] keys = beverages.keys();
        json menu = {

        };
        int j = 0;
        while (j < keys.length()) {
            menu[keys[j]] = beverages[keys[j]];
            j = j + 1;
        }
        var response = caller->respond(menu);
    }

    resource function orderFood(http:Caller caller, http:Request request) {
        json[] orderJson;
        string choice = io:readln("Would you like to order a meal?")
        while(choice.equalsIgnoreCase("yes")){
            // Adds new items to the order as long as the loop is running
            string option = io:readln("Please enter the name of the item you would like to order:");
            // Appends the option to the Json array
            json[orderJson.length()] = option;
             choice = io:readln("Would you like to order another meal?")
        }
        if (choice.equalsIgnoreCase("no")){
            // Uses 'whatever' to store 'orderJson' as a json instead of a json[]
            json whatever = {"orders":orderJson};
            foodOrders[clientRefNum] = whatever;
            //Sends the order with the reference to the kitchen
            var response = kitchenAndBarService->post("/kitchenAndBarService/makeFood", (untaint(whatever)));
        }
        // Error handling in case of any other input except yes or no
        else {
            io:println("Invalid option, oopsie");
        }
    }

    resource function orderBeverage(http:Caller caller, http:Request request) {
        json[] orderJson;
        string choice = io:readln("Would you like to order a drink?")
        while(choice.equalsIgnoreCase("yes")){
            // Adds new items to the order as long as the loop is running
            string option = io:readln("Please enter the name of the item you would like to order:");
            // Appends the option to the Json array
            json[orderJson.length()] = option;
            choice = io:readln("Would you like to order another drink?")
        }
        if (choice.equalsIgnoreCase("no")){
            // Uses 'whatever' to store 'orderJson' as a json instead of a json[]
            json whatever = {"orders":orderJson};
            drinkOrders[clientRefNum] = whatever;
            //Sends the order with the reference to the kitchen
            var response = kitchenAndBarService->post("/kitchenAndBarService/pourDrink", (untaint(drinkOrders[clientRefNum])));
        }
        // Error handling in case of any other input except yes or no
        else {
            io:println("Invalid option, oopsie");
        }
    }

    resource function receiveFood(http:Caller caller, http:Request request, json food) {
        io:println(untaint(food));
        var response = tableService->post("/tableService/generateBill", (untaint(food));
    }

        resource function receiveDrink(http:Caller caller, http:Request request, json drink) {
        io:println(untaint(drink));
        var response = tableService->post("/tableService/generateBill", (untaint(drink));
    }

     resource function generateBill(http:Caller caller, http:Request request, json ordr) {
        //recieve order from foodOrder & drinkOrder. combine keys and floats, use maths to calulate total.
        json billJson;
        json granularBills;
        string[] keys = ordr.getKeys();
        float[] prices;
        int i=0;
        while(i<keys.length()){
            float|error tempPrice = food[keys[i]];
            if !(tempPrice is error) {
                prices[prices.length()] = tempPrice;
                granularBills[keys[i]] = tempPrice;
            } else {
                prices[prices.length()] = beverages[keys[i]];
                granularBills[keys[i]] = beverages[keys[i]];
            }
            i= i+1;
        }    
        int j = 0;
        float total = 0;
        while (j<keys.length()) {
            total = total+prices[j];
            j = j+1;
        }
        billJson["Total"] = total;
        billJson["GranularBills"] = granularBills;
        int k  = 0;
        while (k<keys.length()) {
            billJson[keys[k]] = prices[k];
            k = k+1;
     
        }
        http:Client tableService = new http:Client("http://localhost:8080");
       var response = tableService->post("/tableService/pay", (untaint(billJson));
    //json needs to be printed, and this might not make sense yet
       io:println(billJson); 
    }

    resource function pay(http:Caller caller, http:Request request, json bill) {
        //recieve client payment, use math to check if enough has been payed. Once the boolean is true, generate recipt and let the client know they can leave
        //this code makes no sense
        float cash = io:readln("Give us your moolah: ");
        float|error total = float.convert(billJson["Total"]);
        float remainder = -1;
        boolean paidEnough = false;
        while (paidEnough) {
            if !(total is error) {
            float remainder = total - cash;
        }
        if (remainder>0) {
            string enough = io:println("Thank you for paying, here's your reciept, feel free to leave");
            paidEnough = true;
        } else if (remainder=0) {
            string enough = io:println("Thank you for paying, here's your reciept, feel free to leave");
            paidEnough = true;
        } else {
            //ntenough doesn't make sense yet
            float owed = remainder*-1;
            string|error sowed = string.convert(owed);
            if !(sowed is error) {
                io:println("Please pay §"+owed+" more");
                paidEnough = false;
            }
        }
        }
        
    http:Client receiptService = new http:Client("http://localhost:8080");
       var response = receiptService->post("/tableService/generateReceipt", (untaint(bill));
    
    }

    resource function generateReceipt(http:Caller caller, http:Request request, json bill) {
        //recieve json from pay function, format and generate reciept
        string receiptNumber = system:uuid();
        string refrenceNum;
        io:println(receiptNumber+"/n"+referenceNum+"Thank you come again 😳");
        //Add reference number that comes from the table to recipt
        io:println("Food/Beverage-----Cost");
        //unpack the order from the bill, convert it to a string to be presented
    string[] FoodBev;
    string[] c0st;
    string[] keys = bill["GranularBills"].getKeys();
    int i = 0;
    while(i<keys.length()){
        string itemName = keys[i];
        float|error itemPrice = float.convert(bill["GranularBills"][keys[i]]);
        if !(itemPrice is error) {
            FoodBev[FoodBev.length()] = itemName;
            c0st[c0st.length()] = itemPrice;
        }
        i = i+1;
    };
    i = 0;
    while (i<keys.length()) {
        io:println(FoodBev[i]+"       "+c0st[i]);
    }
    float|error total = float.convert(bill["Total"]);
    if !(total is error) {
        io:println("Total:       "+total);
    }
    
    }

}
service kitchenAndBarService on new http:Listener(8080) {
    resource function makeFood(http:Caller caller, http:Request request, json ordr) {
        // Get bill from
        http:Client waiter = new("http://localhost:8080");
        int x = 0;
        string[] array = ordr.getKeys();
        json foodo = {

        };
        while (x < ordr.length()) {
            foodo[array[x]] = ordr[array[x]];
            x = x + 1;
        }
        var response = waiter->post("/WaiterService/deliverFood", (untaint(foodo)));
    }
    resource function pourDrink(http:Caller caller, http:Request request, json ordr) {
        http:Client waiter = new("http://localhost:8080");
        int x = 0;
        string[] array = ordr.getKeys();
        json drinko = {

        };
        while (x < ordr.length()) {
            drinko[array[x]] = ordr[array[x]];
            x = x + 1;
        }
        var response = waiter->post("/WaiterService/deliverDrink", (untaint(drinko)));
    }
}
service WaiterService on new http:Listener(8080) {
    resource function deliverFood(http:Caller caller, http:Request request, json Food) {
        http:Client mytable = new http:Client("http://localhost:8080");
        var response = mytable->post("/tableService/receiveFood", (untaint(Food)));
    }
    resource function deliverDrink(http:Caller caller, http:Request request, json Drink) {
        http:Client mytable = new http:Client("http://localhost:8080");
        var response = mytable->post("/tableService/receiveDrink", (untaint(Drink)));
    }
}


































































































































































































































































































































































































