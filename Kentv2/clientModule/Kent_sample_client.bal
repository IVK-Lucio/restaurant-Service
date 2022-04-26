import ballerina/grpc;
import ballerina/io;

public function main(string... args) {
    KentClient ep = new("http://localhost:9090");

    KentBlockingClient blockingEp = new("http://localhost:9090");

    int | error dayOfBooking = int.convert(io:readln("On which day would you like to book?"));
    int | error monthOfBooking = int.convert(io:readln("On which month would you like to book?"));
    int | error yearOfBooking = int.convert(io:readln("On which year would you like to book?"));
    int | error guests = int.convert(io:readln("How many people are you?"));
    int | error timeHour = int.convert(io:readln("For which hour of the specified day would you like to book?"));
    int | error timeMinute = int.convert(io:readln("For which minute of the specified day would you like to book?"));
    string durationConf = io:readln("Would you like to stay for 2 hours?");
    if (durationConf.equalsIgnoreCase("yes")) {
        appointment.hoursDuration = 2;
    } else {
        float | error duration = float.convert(io:readln("How many hours would you like to stay for?"));
        if !(duration is error) {
            appointment.hoursDuration = duration;
        }
    }

    boolean inputError = true;
    if !(dayOfBooking is error) {
        if !(monthOfBooking is error) {
            if !(yearOfBooking is error) {
                if !(guests is error) {
                    if !(timeHour is error) {
                        if !(timeMinute is error) {
                            inputError = false;

                            date = {
                                int_day: dayOfBooking,
                                int_month: monthOfBooking,
                                int_year: yearOfBooking
                            };
                            time = {
                                int_hour: timeHour,
                                int_minute: timeMinute
                            };

                            appointment = {
                                dateOfBooking: date,
                                prefTime: time,
                                numberOfGuests: guests,
                                deposit: depositvar
                            };
                            me = {
                                booking: appointment,
                                reference: ""
                            };

                            var response = blockingEp->book(me);
                            if !(response is error) {
                                string responseString;
                                grpc:Headers resHeaders;
                                (responseString, resHeaders) = response;
                                json | error responseJson = json.convert(responseString);
                                if !(responseJson is error) {
                                    string | error message = string.convert(responseJson["Message"]);
                                    if !(message is error) {
                                        if (message.equalsIgnoreCase("Overbooked")) {
                                            float | error dep = float.convert(io:readln("Kent is currently overbooked, how much would you like to pay to help secure your spot?"));
                                            if !(dep is error) {
                                                Deposit d = {
                                                    deposit: dep,
                                                    reference: me.reference,
                                                    confirmation: ""
                                                };
                                                // Send deposit
                                                var depresponse = blockingEp->deposit(d);
                                                if !(depresponse is error) {
                                                    string confCodeJsonString;
                                                    (confCodeJsonString, resHeaders) = depresponse;
                                                    json | error confCodeJson = json.convert(confCodeJsonString);
                                                    if !(confCodeJson is error) {
                                                        io:println("Deposit received!");
                                                        string | error confCode = string.convert(confCodeJson["confirmationCode"]);
                                                        if !(confCode is error) {
                                                            me.booking.deposit.confirmation = confCode;
                                                            io:print("Confirmation code: " + confCode);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                            }




                        }
                    }
                }
            }
        }
    }
    if (inputError) {
        io:println("Invalid input, please check the info added.");
    }

}

Date date = {
    int_day: 0,
    int_month: 0,
    int_year: 0
};

Time time = {
    int_hour: 0,
    int_minute: 0
};

Deposit depositvar = {
    reference: "",
    confirmation: "",
    deposit: 0
};

Booking appointment = {
    dateOfBooking: date,
    prefTime: time,
    numberOfGuests: 0,
    deposit: depositvar
};

Client me = {
    booking: appointment,
    reference: ""
};

service KentMessageListener = service {    

    resource function onMessage(string message) {
        io:println("Response received from server: " + message);
    }

    resource function onError(error err) {
        io:println("Error from Connector: " + err.reason() + " - " + <string>err.detail().message);
    }

    resource function onComplete() {
        io:println("Server Complete Sending Responses.");
    }
};

