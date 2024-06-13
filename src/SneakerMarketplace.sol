// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SneakerMarketplace {

    address private admin;

    // maps an address to one of the following roles:
    //   - 0: unregistered users
    //   - 1: admin, the one that deploy the contract; do not use
    //   - 2: seller
    //   - 3: buyer
    //   - others: invalid; do not use
    mapping(address => uint8) private roles;
    mapping(address => uint256) private balances;
    
    // map address to the sneaker id
    // track the existing listings
    mapping(address => uint256) private listings;

    mapping(uint256 => address) private sneakerToSeller;
    mapping(uint256 => uint256) private sneakerPrices;

    // mapping from sneaker ID to the address of the buyer
    mapping(uint256 => address) private sneakerBuyers;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlySeller() {
        require(roles[msg.sender] == 2, "Only the seller can perform this action");
        _;
    }

    modifier onlyBuyer() {
        require(roles[msg.sender] == 3, "Only the buyer can perform this action");
        _;
    }

    constructor() {
        // setting the admin as the deployer of the contract
        admin = msg.sender;
    }

    // register a new user
    function registerBuyer() public returns (bool) {
        // check if user is unregistered
        if (roles[msg.sender] == 0) {
            // make user a buyer
            roles[msg.sender] = 3;
            return true;
        } else {
            return false;
        }
    }

    // Register the caller as seller
    function registerSeller() public returns (bool) {
        if (roles[msg.sender] == 0) {
            // make user a seller
            roles[msg.sender] = 2;
            return true;
        } else {
            return false;
        }
    }

    // function for buyers
    // when buyer buys a sneaker
    // should transfer money to the contract
    function buySneaker(uint256 sneakerId) public payable onlyBuyer {
        address seller = getSellerBySneakerId(sneakerId);
        require(seller != address(0), "Sneaker not listed for sale");
        require(msg.value > 0, "Value must be greater than zero");
        //require(msg.value == sneakerPrices[sneakerId], "Incorrect price");

        // Record the buyer
        sneakerBuyers[sneakerId] = msg.sender;

        // Transfer money to the contract
        balances[address(this)] += msg.value;
    }

    // after buying, buyer will be able to confirm delivery
    // this will then transfer the funds to the seller
    function confirmDelivery(uint256 sneakerId) public onlyBuyer {
        require(sneakerBuyers[sneakerId] == msg.sender, "You are not the buyer of this sneaker");

        address seller = getSellerBySneakerId(sneakerId);
        require(seller != address(0), "Seller not found");

        // Transfer the funds to the seller
        uint256 amount = balances[address(this)];
        require(amount > 0, "No funds to transfer");

        balances[seller] = 0;
        payable(seller).transfer(amount);
    }

    // If the buyer doesn't receive the item, this function refunds the money
    function noDelivery(uint256 sneakerId) public onlyBuyer {
        require(sneakerBuyers[sneakerId] == msg.sender, "You are not the buyer of this sneaker");

        uint256 amount = balances[address(this)];
        //require(amount > 0, "No funds to refund");

        balances[address(this)] -= amount;

        payable(msg.sender).transfer(amount);
    }

    // functions for the seller
    // list a sneaker
    function listSneaker(uint256 sneakerId) public onlySeller {
        // make sure seller doesn't already have a listing
        require(listings[msg.sender] == 0, "Already have a listing");
        listings[msg.sender] = sneakerId;
        sneakerToSeller[sneakerId] = msg.sender;
        //sneakerPrices[sneakerId] = price;
    }

    // take the listing down
    function withdrawListing() public onlySeller {
        uint256 sneakerId = listings[msg.sender];
        require(sneakerId != 0, "No listing to withdraw");

        listings[msg.sender] = 0;
        sneakerToSeller[sneakerId] = address(0);
    }

    // getters
    function getListing(address seller) public view returns (uint256 sneakerId) {
        sneakerId = listings[seller];
        return sneakerId;
    }


    // helper function to find the seller by sneaker ID
    function getSellerBySneakerId(uint256 sneakerId) private view returns (address seller) {
        return sneakerToSeller[sneakerId];
    }
}
