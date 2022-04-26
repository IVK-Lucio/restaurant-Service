import ballerina/grpc;
import ballerina/system;
import wso2/kafka;
import ballerina/http;
import ballerina/io;
import ballerina/encoding;

listener grpc:Listener ep = new (9000);

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

public function main(string... args) {
// Poll for open tables
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
        //if (overbooked) {
        //    response["Message"] = "Overbooked";
        //}
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
        string confirmationCode = system:uuid();
        json r = {
            "Result": "Success",
            "confirmationCode": confirmationCode
        };
        // return conf code
        var response = caller->send(r);
        var respconf = caller->complete();
    }
}



// Kafka consumer listener configurations
kafka:ConsumerConfig consumerConfig = {
    bootstrapServers: "localhost:9092, localhost:9093",
    // Consumer group ID
    groupId: "bookingHandlers",
    // Listen from topic 'product-price'
    topics: ["bookings", "clientStatus"],
    // Poll every 0.3 seconds
    pollingInterval: 300
};

// Create kafka listener
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
                //if (status["clientLeft"])
                }
            }
        }
    }
}

service WelcomeService on new http:Listener(8080) {
    resource function checkAvailTable(http:Caller caller, http:Request request) {
    //if (tableAvail) {

    //}

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

    }

    resource function orderBeverage(http:Caller caller, http:Request request) {

    }

    resource function generateBill(http:Caller caller, http:Request request) {

    }

    resource function pay(http:Caller caller, http:Request request) {

    }

    resource function generateReceipt(http:Caller caller, http:Request request) {

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
            foodo[x] = array[x];
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
            drinko[x] = array[x];
            x = x + 1;
        }
        var response = waiter->post("/WaiterService/deliverDrink", (untaint(drinko)));
    }
}
service WaiterService on new http:Listener(8080) {
    resource function deliverFood(http:Caller caller, http:Request request) {

    }
    resource function deliverDrink(http:Caller caller, http:Request request) {

    }
}


































































































































































































































































































































































































