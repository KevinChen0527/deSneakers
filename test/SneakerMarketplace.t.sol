// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import {SneakerMarketplace} from "../src/SneakerMarketplace.sol";

contract SneakerMarketplaceTest is Test {
    SneakerMarketplace public marketplace;

    // ===================== //
    // ==== local roles ==== //
    // ===================== //

    address public admin = address(0x01);
    address public seller = address(0x02);
    address public buyer = address(0x03);

    uint256 public initSellerBalance = 1 ether;
    uint256 public initBuyerBalance = 1 ether;

    function setUp() public {
        vm.deal(seller, initSellerBalance);
        vm.deal(buyer, initBuyerBalance);
        vm.startPrank(admin);
        marketplace = new SneakerMarketplace();
        vm.stopPrank();

        vm.startPrank(seller);
        marketplace.registerSeller();
        vm.stopPrank();

        vm.startPrank(buyer);
        marketplace.registerBuyer();
        vm.stopPrank();
    }

    // testing the register functions

    function test_registerBuyer() public {
        address temp = address(0x05);
        vm.startPrank(temp);
        bool registered = marketplace.registerBuyer();
        assertEq(registered, true, "User should be registered");
        vm.stopPrank();
    }

    function test_registerSeller() public {
        address temp = address(0x05);
        vm.startPrank(temp);
        bool registered = marketplace.registerSeller();
        assertEq(registered, true, "User should be registered");
        vm.stopPrank();
    }

    // list a sneaker
    function test_listSneaker() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);

        uint256 id = marketplace.getListing(seller);

        assertEq(id, sneakerId);

        vm.stopPrank();
    }

    // list sneaker when already have a listing
    function test_listSneaker_listingAlreadyExisted() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);

        uint256 id = marketplace.getListing(seller);

        assertEq(id, sneakerId);

        sneakerId = 456;
        vm.expectRevert("Already have a listing");
        marketplace.listSneaker(sneakerId);

        id = marketplace.getListing(seller);
        assertEq(id, 123, "Listing should remain sneaker ID 123 as duplicate listing is not allowed");

        vm.stopPrank();

    }

    function test_buySneaker() public {
        // list the sneaker first
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        vm.stopPrank();

        // try buying it
        vm.startPrank(buyer);
        marketplace.buySneaker{value: 0.05 ether}(sneakerId);

        // check it the balance change are correct
        // buyer should have 0.95 eth

        uint256 buyerBalance = buyer.balance;
        assertEq(buyerBalance, 0.95 ether, "Balance is wrong, Buyer should have paid 0.05 eth");
        vm.stopPrank();

    }

    // test confrim delivery
    function test_confirmDelivery_delivered() public {
        // list the sneaker first
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        vm.stopPrank();

        // try buying it
        vm.startPrank(buyer);
        marketplace.buySneaker{value: 0.05 ether}(sneakerId);

        // check it the balance change are correct
        // buyer should have 0.95 eth

        uint256 buyerBalance = buyer.balance;
        assertEq(buyerBalance, 0.95 ether, "Balance is wrong, Buyer should have paid 0.05 eth");

        marketplace.confirmDelivery(sneakerId);

        // seller should receive 0.05 eth

        uint256 sellerBalance = seller.balance;
        assertEq(sellerBalance, 1.05 ether, "Balance is wrong, Seller should have received 0.05 eth");
        vm.stopPrank();
    }

// test confrim delivery
    function test_noDelivery() public {
        // list the sneaker first
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        vm.stopPrank();

        // try buying it
        vm.startPrank(buyer);
        marketplace.buySneaker{value: 0.05 ether}(sneakerId);

        // check it the balance change are correct
        // buyer should have 0.95 eth

        uint256 buyerBalance = buyer.balance;
        assertEq(buyerBalance, 0.95 ether, "Balance is wrong, Buyer should have paid 0.05 eth");

        marketplace.noDelivery(sneakerId);

        // buyer should receive 0.05 eth
        buyerBalance = buyer.balance;

        assertEq(buyerBalance, 1 ether, "Balance is wrong, Buyer should have received 0.05 eth");
        vm.stopPrank();
    }

    // function test_withdrawFunds() public {
    //     vm.startPrank(seller);
    //     uint256 sneakerId = marketplace.listSneaker("Air Max", "Nike", 0.05 ether);
    //     vm.stopPrank();

    //     vm.startPrank(buyer);
    //     marketplace.buySneaker{value: 0.05 ether}(sneakerId);
    //     vm.stopPrank();

    //     vm.startPrank(seller);
    //     uint256 sellerBalanceBefore = seller.balance;
    //     marketplace.withdrawFunds();
    //     uint256 sellerBalanceAfter = seller.balance;

    //     assertEq(sellerBalanceAfter, sellerBalanceBefore + 0.05 ether);
    //     vm.stopPrank();
    // }
}
