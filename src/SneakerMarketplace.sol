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
    
    // mapp address to the sneaker id
    // track the exisiting listings
    mapping(address => uint256) private listings;


    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlySeller(uint256 sneakerId) {
        require(roles[msg.sender] == 2, "Only the seller can perform this action");
        _;
    }

    modifier onlyBuyer(uint256 sneakerId) {
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
            // make user a guest
            roles[msg.sender] = 2;
            return true;
        } else {
            return false;
        }
    }

    // function for buyers

    // when buyer buys a sneaker
    // should transfer money to DeSneaker
    function buySneaker(uint256 sneakerId) public payable onlyBuyer(sneakerId) {
    }

    // after buying, buyer will be able to confirm delivery
    // this wil then ask the vault (smart contract) to withdraw the funds to the seller
    function confirmDelivery(uint256 sneakerId) public onlyBuyer(sneakerId) {
    }



    // functions for the seller

    // list a sneaker
    function listSneaker(uint256 sneakerId) public payable onlySeller(sneakerId) {
        // make sure seller doesn't already have a listing
        require(listings[msg.sender] == 0, "Already have a listing");
        listings[msg.sender] = sneakerId;
    }

    // take the listing down
    function withdrawListing() public onlySeller(listings[msg.sender]) {
        listings[msg.sender] = 0;
    }

    // getters
    function getListing(address seller) public view returns (uint256 sneakerId) {
        sneakerId = listings[seller];
        return sneakerId;
    }

    function withdrawFunds() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

    }


}
