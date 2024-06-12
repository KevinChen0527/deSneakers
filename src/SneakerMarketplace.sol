// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SneakerMarketplace {

    struct Sneaker {
        uint256 id;
        string name;
        string brand;
        uint256 price;
        address seller;
        address buyer;
        bool isSold;
    }

    uint256 private nextSneakerId;
    address private admin;

    mapping(uint256 => Sneaker) private sneakers;
    mapping(address => uint256) private balances;

    event SneakerListed(uint256 indexed sneakerId, string name, string brand, uint256 price, address indexed seller);
    event SneakerPurchased(uint256 indexed sneakerId, address indexed buyer, uint256 price);
    event FundsWithdrawn(address indexed seller, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlySeller(uint256 sneakerId) {
        require(sneakers[sneakerId].seller == msg.sender, "Only the seller can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function listSneaker(string memory name, string memory brand, uint256 price) public returns (uint256) {
        require(price > 0, "Price must be greater than zero");
        
        sneakers[nextSneakerId] = Sneaker({
            id: nextSneakerId,
            name: name,
            brand: brand,
            price: price,
            seller: msg.sender,
            buyer: address(0),
            isSold: false
        });

        emit SneakerListed(nextSneakerId, name, brand, price, msg.sender);
        nextSneakerId++;
        return nextSneakerId - 1;
    }

    function buySneaker(uint256 sneakerId) public payable {
        Sneaker storage sneaker = sneakers[sneakerId];
        require(!sneaker.isSold, "Sneaker already sold");
        require(msg.value >= sneaker.price, "Insufficient funds to purchase the sneaker");

        sneaker.buyer = msg.sender;
        sneaker.isSold = true;
        balances[sneaker.seller] += msg.value;

        emit SneakerPurchased(sneakerId, msg.sender, sneaker.price);
    }

    function withdrawFunds() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit FundsWithdrawn(msg.sender, amount);
    }

    function getSneaker(uint256 sneakerId) public view returns (Sneaker memory) {
        return sneakers[sneakerId];
    }
}
