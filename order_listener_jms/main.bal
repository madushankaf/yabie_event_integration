import ballerina/http;
import ballerina/log;
import ballerinax/java.jms;

configurable string initialContextFactory = "";
configurable string providerUrl = "";
configurable string connectionFactoryName = "";
configurable string solaceUsername = "";
configurable string solacePassword = "";
configurable string solaceJmsVpn = "";
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

    string paymentObjectId = "";
    PaymentMethod PaymentMethod;
    decimal? amount = 0.0;
};

type OrderObject record {
    string orderId;
    Customer customer;
    decimal quantity;
    Product? product?;
    PayementObject? paymentObject;
    PriceObject? priceObject?;
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
        properties = {
            "Solace_JMS_VPN": solaceJmsVpn,
            "java.naming.security.principal": solaceUsername,
            "java.naming.security.credentials": solacePassword
        }
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
            check processEvent(response);
        }
    }
}

function processEvent(jms:TextMessage response) returns error? {
    json jsonOrder = check response.content.fromJsonString();
    OrderRequest orderReq = check jsonOrder.cloneWithType(OrderRequest);
    OrderObject orderObj = check enrichOrder(orderReq);
    log:printInfo("Order Object ", orderObj = orderObj);
    check executeOrder(orderObj);
}

function enrichOrder(OrderRequest orderRequest) returns OrderObject|error {
    OrderObject orderObj = transform(orderRequest);
    Product product = check getProductById(orderRequest.productId);
    PriceObject priceObj = check getPriceObjectById(product.priceObjId);
    orderObj.product = product;
    orderObj.priceObject = priceObj;
    return orderObj;
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

function transform(OrderRequest orderRequest) returns OrderObject => {
    orderId: orderRequest.orderId,
    customer: {
        customerId: orderRequest.customerId,
        customerName: orderRequest.customerName,
        customerAddress: orderRequest.customerAddress,
        customerEmail: orderRequest.customerEmail,
        customerPhone: orderRequest.customerPhone
    },
    quantity: orderRequest.quantity,
    paymentObject: {
        PaymentMethod: orderRequest.paymentMethod
    }
};

configurable string backendApiUrl = "";
http:Client backendApiClient = check new (backendApiUrl);

function executeOrder(OrderObject orderObj) returns error? {
    log:printInfo("Order Object ", orderObj = orderObj);
    OrderObject savedOrder = check backendApiClient->post("/orders", orderObj);
    log:printInfo("Order Response ", savedOrder = savedOrder);

}
