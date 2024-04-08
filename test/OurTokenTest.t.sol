// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {Test} from "forge-std/Test.sol";
import {OurToken} from "../src/OurToken.sol";

error TransferToZeroAddressNotAllowed();

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 10000;

        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testTransferToSelf() public {
        uint256 bobBalanceBefore = ourToken.balanceOf(bob);
        vm.prank(bob);
        ourToken.transfer(bob, STARTING_BALANCE / 2);
        uint256 bobBalanceAfter = ourToken.balanceOf(bob);

        // Balance should remain the same after transferring to self
        assertEq(
            bobBalanceBefore,
            bobBalanceAfter,
            "Bob's balance should remain unchanged after transferring to self"
        );
    }

    function testAllowanceResetAfterTransferFrom() public {
        uint256 initialAllowance = 500;
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 200;
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(
            ourToken.allowance(bob, alice),
            initialAllowance - transferAmount,
            "Allowance should be decreased by the transferred amount"
        );
    }

    function testCannotTransferFromWithoutAllowance() public {
        uint256 transferAmount = 100;
        vm.prank(alice);
        vm.expectRevert(); // Expect any revert
        ourToken.transferFrom(bob, alice, transferAmount);
    }
}
