import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Hash "mo:base/Hash";

actor ECommerceAPI {
    type ProductId = Nat;
    type UserId = Text;
    type OrderId = Nat;

    type Product = {
        id: ProductId;
        name: Text;
        price: Nat;
        inventory: Nat;
    };

    type User = {
        id: UserId;
        name: Text;
        balance: Nat;
    };

    type Order = {
        id: OrderId;
        userId: UserId;
        productId: ProductId;
        quantity: Nat;
        status: Text;
    };

    type Error = {
        #NotFound;
        #InsufficientFunds;
        #InsufficientInventory;
    };

    private var nextProductId : Nat = 0;
    private var nextOrderId : Nat = 0;
    private let products = HashMap.HashMap<ProductId, Product>(0, Nat.equal, Hash.hash);
    private let users = HashMap.HashMap<UserId, User>(0, Text.equal, Text.hash);
    private let orders = HashMap.HashMap<OrderId, Order>(0, Nat.equal, Hash.hash);

    public func addProduct(name: Text, price: Nat, inventory: Nat) : async ProductId {
        let id = nextProductId;
        nextProductId += 1;
        let product : Product = {
            id = id;
            name = name;
            price = price;
            inventory = inventory;
        };
        products.put(id, product);
        id
    };

    public query func getProduct(id: ProductId) : async ?Product {
        products.get(id)
    };

    public func createUser(id: UserId, name: Text) : async () {
        let user : User = {
            id = id;
            name = name;
            balance = 0;
        };
        users.put(id, user);
    };

    public func addUserBalance(userId: UserId, amount: Nat) : async Result.Result<(), Error> {
        switch (users.get(userId)) {
            case (null) { #err(#NotFound) };
            case (?user) {
                let updatedUser : User = {
                    id = user.id;
                    name = user.name;
                    balance = user.balance + amount;
                };
                users.put(userId, updatedUser);
                #ok(())
            };
        }
    };

    public func createOrder(userId: UserId, productId: ProductId, quantity: Nat) : async Result.Result<OrderId, Error> {
        switch (users.get(userId), products.get(productId)) {
            case (?user, ?product) {
                if (product.inventory < quantity) {
                    return #err(#InsufficientInventory);
                };
                if (user.balance < product.price * quantity) {
                    return #err(#InsufficientFunds);
                };
                let orderId = nextOrderId;
                nextOrderId += 1;
                let order : Order = {
                    id = orderId;
                    userId = userId;
                    productId = productId;
                    quantity = quantity;
                    status = "Pending";
                };
                orders.put(orderId, order);

                // Update product inventory
                let updatedProduct : Product = {
                    id = product.id;
                    name = product.name;
                    price = product.price;
                    inventory = product.inventory - quantity;
                };
                products.put(productId, updatedProduct);

                // Update user balance
                let updatedUser : User = {
                    id = user.id;
                    name = user.name;
                    balance = user.balance - (product.price * quantity);
                };
                users.put(userId, updatedUser);

                #ok(orderId)
            };
            case _ { #err(#NotFound) };
        }
    };

    public query func getOrder(id: OrderId) : async ?Order {
        orders.get(id)
    };

    public query func listProducts(start: Nat, limit: Nat) : async [Product] {
        let productArray = Iter.toArray(products.vals());
        let size = productArray.size();
        let end = if (start + limit > size) { size } else { start + limit };
        Array.subArray(productArray, start, end - start)
    };
}
