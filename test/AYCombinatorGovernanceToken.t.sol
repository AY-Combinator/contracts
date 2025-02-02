// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/AYCombinatorGovernanceToken.sol";

contract AYCombinatorGovernanceTokenTest is Test {
    AYCombinatorGovernanceToken public token;
    address public admin = makeAddr("admin");
    address public minter = makeAddr("minter");

    function setUp() public {
        vm.startPrank(admin);
        token = new AYCombinatorGovernanceToken(minter);
        vm.stopPrank();
    }

    function test_mint() public {
        vm.startPrank(minter);
        token.mint(admin, 1000000000 * 10 ** token.decimals());
        vm.stopPrank();
        assertEq(token.balanceOf(admin), 1000000000 * 10 ** token.decimals());
    }

    function test_RevertWhen_Transfer() public {
        vm.startPrank(minter);
        token.mint(admin, 1000000000 * 10 ** token.decimals());
        vm.stopPrank();

        vm.expectRevert(AYCombinatorGovernanceToken.AYCombinatorGovernanceToken_TransfersAreDisabled.selector);
        vm.prank(admin);
        token.transfer(minter, 1000000);
    }

    function test_RevertWhen_TransferFrom() public {
        vm.startPrank(minter);
        token.mint(admin, 1000000000 * 10 ** token.decimals());
        vm.stopPrank();

        vm.expectRevert(AYCombinatorGovernanceToken.AYCombinatorGovernanceToken_TransfersAreDisabled.selector);
        vm.prank(admin);
        token.transferFrom(admin, minter, 1000000);
    }
}
