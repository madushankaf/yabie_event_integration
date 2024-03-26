import ballerina/http;
import ballerina/io;
import ballerina/sql;
import ballerinax/mysql;

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

configurable string dbHost = "";
configurable string dbUser = "";
configurable string dbPass = "";
configurable string dbName = "";
configurable int dbPort = 24276;

final mysql:Client dbClient = check new (dbHost, dbUser, dbPass, dbName, dbPort);

service / on new http:Listener(9090) {

    resource function post orders(OrderObject orderObj) returns OrderObject|error {

        io:println("Order Received: ", orderObj);
        sql:ParameterizedQuery query = `INSERT INTO orders (orderId, customerId, quantity, productId, price)
                      VALUES (${orderObj.orderId}, ${orderObj.customer.customerId}, ${orderObj.quantity}, ${orderObj?.product?.productId}, ${orderObj?.priceObject?.price})`;
        sql:ExecutionResult result = check dbClient->execute(query);
        
        return orderObj;

    }
}
