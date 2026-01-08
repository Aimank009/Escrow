// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow public escrow;
    address buyer = address(1);
    address seller = address(2);
    address arbitrator = address(3);

    uint256 escrowAmount = 1 ether;
    function setUp() public {
        escrow = new Escrow(
            buyer,
            seller,
            arbitrator,
            escrowAmount
        );
    }

    function testEscrowCreated() public view {
        assertEq(escrow.buyer(), buyer);
        assertEq(escrow.seller(), seller);
        assertEq(escrow.arbitrator(), arbitrator);
        assertEq(uint256(escrow.escrowState()), uint256(Escrow.EscrowState.Initialized));
    }

    function testBuyerDepositsFunds() public {
        vm.deal(buyer, 2 ether);

        vm.prank(buyer);
        escrow.depositFunds{value: escrowAmount}();

        assertEq(uint256(escrow.escrowState()), uint256(Escrow.EscrowState.Funded));
    }

    function testSellerCannotDeposit() public {
        vm.deal(seller, 2 ether);

        vm.prank(seller);
        vm.expectRevert();
        escrow.depositFunds{value: escrowAmount}();
    }
    function testSellerConfirmsDelivery() public {
        vm.deal(buyer, 1 ether);

        vm.prank(buyer);
        escrow.depositFunds{value: escrowAmount}();

        vm.prank(seller);
        escrow.confirmDelivery();

        assertEq(uint256(escrow.escrowState()), uint256(Escrow.EscrowState.Delivered));
    }

    function testBuyerApprovesDelivery() public {
        vm.deal(buyer, 1 ether);

        vm.prank(buyer);
        escrow.depositFunds{value: escrowAmount}();

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.approveDelivery();

        assertEq(uint256(escrow.escrowState()), uint256(Escrow.EscrowState.Completed));
        assertEq(seller.balance, sellerBalanceBefore + escrowAmount);
    }

    function testDisputeBuyerWins() public {
        vm.deal(buyer, 1 ether);

        vm.prank(buyer);
        escrow.depositFunds{value: escrowAmount}();

        vm.prank(buyer);
        escrow.raiseDispute();

        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(arbitrator);
        escrow.resolveDispute(false); // buyer wins

        assertEq(uint256(escrow.escrowState()), uint256(Escrow.EscrowState.Refunded));
        assertEq(buyer.balance, buyerBalanceBefore + escrowAmount);
    }

    function testCancelEscrow() public {
        vm.prank(buyer);
        escrow.cancelEscrow();

        assertEq(uint256(escrow.escrowState()), uint256(Escrow.EscrowState.Cancelled));
    }

}
