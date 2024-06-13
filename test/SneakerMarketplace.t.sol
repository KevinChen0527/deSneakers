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

    // test getSellerbyListing

    function test_getSellerByListing() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        address _seller = marketplace.getSellerBySneakerId(sneakerId);
        assertEq(_seller, seller, "Seller should be seller");
        vm.stopPrank();
    }

    // test getSellerbyListing after removing the listing

    function test_getSellerByListing_afterRemovingListing() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        marketplace.withdrawListing();
        address _seller = marketplace.getSellerBySneakerId(sneakerId);
        assertEq(_seller, address(0), "Seller should be 0");
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

    // test the withdrawListing function
    function test_withdrawListing() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        marketplace.withdrawListing();
        uint256 id = marketplace.getListing(seller);
        assertEq(id, 0, "Listing should be withdrawn");
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

    // test no delivery
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


    function test_overflowUnderflow() public {
        // Simulate very high values to check overflow
        vm.startPrank(seller);
        uint256 maxUint = type(uint256).max;
        marketplace.listSneaker(maxUint);
        address _seller = marketplace.getSellerBySneakerId(maxUint);
        assertEq(_seller, seller, "Should handle maximum uint256 values correctly");
        vm.stopPrank();
    }

    function test_unauthorizedWithdrawalOfListing() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        vm.stopPrank();

        vm.startPrank(buyer);
        vm.expectRevert("Only the seller can perform this action");
        marketplace.withdrawListing();
        vm.stopPrank();
    }

    function test_unauthorizedConfirmDelivery() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        vm.stopPrank();

        vm.startPrank(buyer);
        marketplace.buySneaker{value: 0.05 ether}(sneakerId);
        vm.stopPrank();

        address unauthorizedUser = address(0x04);
        vm.startPrank(unauthorizedUser);
        vm.expectRevert("Only the buyer can perform this action");
        marketplace.confirmDelivery(sneakerId);
        vm.stopPrank();
    }

    function test_confirmDeliveryWithoutPurchase() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        vm.stopPrank();

        vm.startPrank(buyer);
        vm.expectRevert("You are not the buyer of this sneaker");
        marketplace.confirmDelivery(sneakerId);
        vm.stopPrank();
    }

    function test_unauthorizedNoDeliveryClaim() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        vm.stopPrank();

        vm.startPrank(buyer);
        marketplace.buySneaker{value: 0.05 ether}(sneakerId);
        vm.stopPrank();

        address unauthorizedUser = address(0x04);
        vm.startPrank(unauthorizedUser);
        vm.expectRevert("Only the buyer can perform this action");
        marketplace.noDelivery(sneakerId);
        vm.stopPrank();
    }

    function test_reRegisterAsBuyer() public {
        vm.startPrank(buyer);
        bool registered = marketplace.registerBuyer();
        assertEq(registered, false, "User should not be able to re-register as buyer");
        vm.stopPrank();
    }

    function test_reRegisterAsSeller() public {
        vm.startPrank(seller);
        bool registered = marketplace.registerSeller();
        assertEq(registered, false, "User should not be able to re-register as seller");
        vm.stopPrank();
    }

    function test_registerAsBothBuyerAndSeller() public {
        address user = address(0x04);
        vm.deal(user, 1 ether);

        vm.startPrank(user);
        bool registered = marketplace.registerBuyer();
        assertEq(registered, true, "User should be registered as buyer");

        registered = marketplace.registerSeller();
        assertEq(registered, false, "User should not be able to register as seller");
        vm.stopPrank();
    }

    function test_withdrawListingNotOwned() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        vm.stopPrank();

        address otherSeller = address(0x04);
        vm.deal(otherSeller, 1 ether);

        vm.startPrank(otherSeller);
        vm.expectRevert("Only the seller can perform this action");
        marketplace.withdrawListing();
        vm.stopPrank();
    }

    function test_buyNonexistentSneaker() public {
        vm.startPrank(buyer);
        vm.expectRevert("Sneaker not listed for sale");
        marketplace.buySneaker{value: 0.05 ether}(999);
        vm.stopPrank();
    }

    function test_confirmDeliveryByUnauthorizedUser() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        vm.stopPrank();

        vm.startPrank(buyer);
        marketplace.buySneaker{value: 0.05 ether}(sneakerId);
        vm.stopPrank();

        address unauthorizedUser = address(0x04);
        vm.startPrank(unauthorizedUser);
        vm.expectRevert("Only the buyer can perform this action");
        marketplace.confirmDelivery(sneakerId);
        vm.stopPrank();
    }

    function test_noDeliveryClaimByUnauthorizedUser() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);
        vm.stopPrank();

        vm.startPrank(buyer);
        marketplace.buySneaker{value: 0.05 ether}(sneakerId);
        vm.stopPrank();

        address unauthorizedUser = address(0x04);
        vm.startPrank(unauthorizedUser);
        vm.expectRevert("Only the buyer can perform this action");
        marketplace.noDelivery(sneakerId);
        vm.stopPrank();
    }

    function test_doubleListingBySeller() public {
        vm.startPrank(seller);
        uint256 sneakerId1 = 123;
        marketplace.listSneaker(sneakerId1);
        
        uint256 sneakerId2 = 456;
        vm.expectRevert("Already have a listing");
        marketplace.listSneaker(sneakerId2);
        vm.stopPrank();
    }

}

