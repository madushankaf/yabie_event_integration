import ballerina/io;
import ballerina/http;


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



service / on new http:Listener(9090) {


    resource function post orders(OrderObject orderObj) returns OrderObject {
        io:println("Order Received: ", orderObj);
        return orderObj;
    }
}
