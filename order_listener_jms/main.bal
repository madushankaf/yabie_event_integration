import ballerina/http;
import ballerina/log;
import ballerinax/java.jms;

configurable string initialContextFactory = "";
configurable string providerUrl = "";
configurable string connectionFactoryName = "";
configurable map<string> initialContextProperties = {
 
};
configurable string queueName = "";
configurable string topicName = "";

type Customer record {
    string customerId;
    string customerName;
    string customerAddress;
    string customerEmail;
    string customerPhone;
};

type PriceObject record {
    string priceObjId;
    string price;
};

type Product record {
    string productId;
    string productName;
    string productCategory;
    string priceObjId;
};

enum PaymentMethod {
    Cash,
    Card
}

type PayementObject record {
    string paymentObjectId;
    PaymentMethod PaymentMethod;
    decimal amount;
};

type OrderObject record {
    string orderId;
    Customer customer;
    int quantity;
    Product product;
    PayementObject paymentObject;
};

type OrderRequest record {
    string orderId;
    string customerId;
    string customerName;
    string customerAddress;
    string customerEmail;
    string customerPhone;
    decimal quantity;
    string productId;
    string currency;
    PaymentMethod paymentMethod;
};

public function main() returns error? {

    jms:Connection solaceBrokerConnection = check new (
        initialContextFactory = initialContextFactory,
        providerUrl = providerUrl,
        connectionFactoryName = connectionFactoryName,
        properties = initialContextProperties
    );
    jms:Session session = check solaceBrokerConnection->createSession();
    jms:MessageConsumer orderConsumer = check session.createConsumer(
        destination = {
        'type: jms:TOPIC,
        name: topicName
    });
    while true {
        jms:Message? response = check orderConsumer->receive();
        if response is jms:TextMessage {
            json jsonOrder = check response.content.fromJsonString();
            OrderRequest orderReq = check jsonOrder.cloneWithType(OrderRequest);
            Product product = check getProductById(orderReq.productId);
            PriceObject priceObj = check getPriceObjectById(product.priceObjId);

            log:printInfo("Message received: ", content = orderReq, product = product, priceObj = priceObj);
        }
    }
}

configurable string partnetApiUrl = "";
http:Client partnerApiClient = check new (partnetApiUrl);

function getProductById(string productId) returns Product|error {

    Product[] products = check partnerApiClient->/Products(id = productId);
    if (products.length() == 0) {
        return error("Product not found");
    }
    return products[0];
}

function getPriceObjectById(string priceObjId) returns PriceObject|error {

    PriceObject[] priceObjects = check partnerApiClient->/Prices(id = priceObjId);
    if (priceObjects.length() == 0) {
        return error("Price object not found");
    }
    return priceObjects[0];
}
