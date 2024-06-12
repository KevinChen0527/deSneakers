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

    uint256 public initSellerBalance = 0.1 ether;
    uint256 public initBuyerBalance = 0.5 ether;

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


    function test_listSneaker() public {
        vm.startPrank(seller);
        uint256 sneakerId = 123;
        marketplace.listSneaker(sneakerId);

        uint256 id = marketplace.getListing(seller);

        assertEq(id, sneakerId);

        vm.stopPrank();
    }

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

    // function test_buySneaker() public {
    //     vm.startPrank(seller);
    //     uint256 sneakerId = marketplace.listSneaker("Air Max", "Nike", 0.05 ether);
    //     vm.stopPrank();

    //     vm.startPrank(buyer);
    //     marketplace.buySneaker{value: 0.05 ether}(sneakerId);

    //     (, , , , , address listedBuyer, bool isSold) = marketplace.getSneaker(sneakerId);
    //     assertEq(listedBuyer, buyer);
    //     assertEq(isSold, true);
    //     vm.stopPrank();
    // }

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
