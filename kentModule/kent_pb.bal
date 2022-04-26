import ballerina/grpc;
import ballerina/io;

public type KentBlockingClient client object {
    private grpc:Client grpcClient;

    function __init(string url, grpc:ClientEndpointConfig? config = ()) {
        // initialize client endpoint.
        grpc:Client c = new(url, config = config);
        error? result = c.initStub("blocking", ROOT_DESCRIPTOR, getDescriptorMap());
        if (result is error) {
            panic result;
        } else {
            self.grpcClient = c;
        }
    }


    remote function book(Client req, grpc:Headers? headers = ()) returns ((string, grpc:Headers)|error) {
        
        var payload = check self.grpcClient->blockingExecute("grpc_service.Kent/book", req, headers = headers);
        grpc:Headers resHeaders = new;
        any result = ();
        (result, resHeaders) = payload;
        return (string.convert(result), resHeaders);
    }

    remote function deposit(Deposit req, grpc:Headers? headers = ()) returns ((string, grpc:Headers)|error) {
        
        var payload = check self.grpcClient->blockingExecute("grpc_service.Kent/deposit", req, headers = headers);
        grpc:Headers resHeaders = new;
        any result = ();
        (result, resHeaders) = payload;
        return (string.convert(result), resHeaders);
    }

};

public type KentClient client object {
    private grpc:Client grpcClient;

    function __init(string url, grpc:ClientEndpointConfig? config = ()) {
        // initialize client endpoint.
        grpc:Client c = new(url, config = config);
        error? result = c.initStub("non-blocking", ROOT_DESCRIPTOR, getDescriptorMap());
        if (result is error) {
            panic result;
        } else {
            self.grpcClient = c;
        }
    }


    remote function book(Client req, service msgListener, grpc:Headers? headers = ()) returns (error?) {
        
        return self.grpcClient->nonBlockingExecute("grpc_service.Kent/book", req, msgListener, headers = headers);
    }

    remote function deposit(Deposit req, service msgListener, grpc:Headers? headers = ()) returns (error?) {
        
        return self.grpcClient->nonBlockingExecute("grpc_service.Kent/deposit", req, msgListener, headers = headers);
    }

};

type Booking record {|
    Date dateOfBooking;
    Time prefTime;
    int numberOfGuests;
    float hoursDuration = 2;
    Deposit deposit;
    
|};


type Deposit record {|
    float deposit;
    string reference;
    string confirmation;
    
|};


type Client record {|
    Booking booking;
    string reference;
    
|};


type Date record {|
    int int_day;
    int int_month;
    int int_year;
    
|};


type Time record {|
    int int_hour;
    int int_minute;
    
|};



const string ROOT_DESCRIPTOR = "0A0A6B656E742E70726F746F120C677270635F736572766963651A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F22F5010A07426F6F6B696E6712380A0D646174654F66426F6F6B696E6718012002280B32122E677270635F736572766963652E44617465520D646174654F66426F6F6B696E67122E0A087072656654696D6518022002280B32122E677270635F736572766963652E54696D6552087072656654696D6512260A0E6E756D6265724F66477565737473180320022805520E6E756D6265724F6647756573747312270A0D686F7572734475726174696F6E1804200128013A0132520D686F7572734475726174696F6E122F0A076465706F73697418052001280B32152E677270635F736572766963652E4465706F73697452076465706F73697422650A074465706F73697412180A076465706F73697418012002280152076465706F736974121C0A097265666572656E636518022002280952097265666572656E636512220A0C636F6E6669726D6174696F6E180320022809520C636F6E6669726D6174696F6E22570A06436C69656E74122F0A07626F6F6B696E6718012002280B32152E677270635F736572766963652E426F6F6B696E675207626F6F6B696E67121C0A097265666572656E636518022002280952097265666572656E636522420A044461746512100A03646179180120022805520364617912140A056D6F6E746818022002280552056D6F6E746812120A047965617218032002280552047965617222320A0454696D6512120A04686F75721801200228055204686F757212160A066D696E75746518022002280552066D696E7574653282010A044B656E74123A0A04626F6F6B12142E677270635F736572766963652E436C69656E741A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C7565123E0A076465706F73697412152E677270635F736572766963652E4465706F7369741A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C7565";
function getDescriptorMap() returns map<string> {
    return {
        "kent.proto":"0A0A6B656E742E70726F746F120C677270635F736572766963651A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F22F5010A07426F6F6B696E6712380A0D646174654F66426F6F6B696E6718012002280B32122E677270635F736572766963652E44617465520D646174654F66426F6F6B696E67122E0A087072656654696D6518022002280B32122E677270635F736572766963652E54696D6552087072656654696D6512260A0E6E756D6265724F66477565737473180320022805520E6E756D6265724F6647756573747312270A0D686F7572734475726174696F6E1804200128013A0132520D686F7572734475726174696F6E122F0A076465706F73697418052001280B32152E677270635F736572766963652E4465706F73697452076465706F73697422650A074465706F73697412180A076465706F73697418012002280152076465706F736974121C0A097265666572656E636518022002280952097265666572656E636512220A0C636F6E6669726D6174696F6E180320022809520C636F6E6669726D6174696F6E22570A06436C69656E74122F0A07626F6F6B696E6718012002280B32152E677270635F736572766963652E426F6F6B696E675207626F6F6B696E67121C0A097265666572656E636518022002280952097265666572656E636522420A044461746512100A03646179180120022805520364617912140A056D6F6E746818022002280552056D6F6E746812120A047965617218032002280552047965617222320A0454696D6512120A04686F75721801200228055204686F757212160A066D696E75746518022002280552066D696E7574653282010A044B656E74123A0A04626F6F6B12142E677270635F736572766963652E436C69656E741A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C7565123E0A076465706F73697412152E677270635F736572766963652E4465706F7369741A1C2E676F6F676C652E70726F746F6275662E537472696E6756616C7565",
        "google/protobuf/wrappers.proto":"0A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F120F676F6F676C652E70726F746F62756622230A0B446F75626C6556616C756512140A0576616C7565180120012801520576616C756522220A0A466C6F617456616C756512140A0576616C7565180120012802520576616C756522220A0A496E74363456616C756512140A0576616C7565180120012803520576616C756522230A0B55496E74363456616C756512140A0576616C7565180120012804520576616C756522220A0A496E74333256616C756512140A0576616C7565180120012805520576616C756522230A0B55496E74333256616C756512140A0576616C756518012001280D520576616C756522210A09426F6F6C56616C756512140A0576616C7565180120012808520576616C756522230A0B537472696E6756616C756512140A0576616C7565180120012809520576616C756522220A0A427974657356616C756512140A0576616C756518012001280C520576616C756542570A13636F6D2E676F6F676C652E70726F746F627566420D577261707065727350726F746F50015A057479706573F80101A20203475042AA021E476F6F676C652E50726F746F6275662E57656C6C4B6E6F776E5479706573620670726F746F33"
        
    };
}

