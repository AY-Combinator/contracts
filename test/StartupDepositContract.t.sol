// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/StartupDepositContract.sol";
import "../src/AYCombinatorGovernanceToken.sol";

contract MockStartupToken is ERC20 {
    constructor(address _mintTo, uint256 _amount, string memory _tokenName, string memory _ticker)
        ERC20(_tokenName, _ticker)
    {
        _mint(_mintTo, _amount);
    }
}

contract StartupDepositContractTest is Test {
    StartupDepositContract public startupDepositContract;
    AYCombinatorGovernanceToken public AYG;
    MockStartupToken public startupOneToken;
    MockStartupToken public startupTwoToken;
    address public manager = makeAddr("Manager");
    address public startup1 = makeAddr("Startup1");
    address public startup2 = makeAddr("Startup2");
    address public investor1 = makeAddr("Investor1");
    address public investor2 = makeAddr("Investor2");
    address public investor3 = makeAddr("Investor3");
    address public investor4 = makeAddr("Investor4");

    function setUp() public {
        AYG = new AYCombinatorGovernanceToken();
        AYG.setMinter(address(this));
        AYG.mint(investor1, 1 ether);
        AYG.mint(investor2, 8 ether);
        AYG.mint(investor3, 0.5345 ether);
        AYG.mint(investor4, 0.4655 ether);
        startupDepositContract = new StartupDepositContract(manager, address(AYG));
        startupOneToken = new MockStartupToken(startup1, 10 ether, "MockStartupToken1", "MST1");
        startupTwoToken = new MockStartupToken(startup2, 100 ether, "MockStartupToken2", "MST2");
    }

    function test_TokenWhitelisting() public {
        vm.startPrank(manager);
        startupDepositContract.setWhitelistedToken(address(startupOneToken));
        vm.stopPrank();
        assertTrue(startupDepositContract.whitelistedTokens(address(startupOneToken)));
        assertFalse(startupDepositContract.whitelistedTokens(address(startupTwoToken)));
    }

    function test_RevertIf_NonManagerTriesToSetWhitelistedToken() public {
        vm.expectRevert(StartupDepositContract.StartupDepositContract_NotAllowed.selector);
        startupDepositContract.setWhitelistedToken(address(startupOneToken));
    }

    function test_Deposit() public {
        uint256 startupOneAmount = 1 ether;
        uint256 startupTwoAmount = 10 ether;

        uint256 tokensReceivedBefore = startupDepositContract.tokensReceived(address(startupOneToken));
        uint256 tokensReceivedBefore2 = startupDepositContract.tokensReceived(address(startupTwoToken));
        uint256 tokenOneBalanceBefore = startupOneToken.balanceOf(address(startupDepositContract));
        uint256 tokenTwoBalanceBefore = startupTwoToken.balanceOf(address(startupDepositContract));

        vm.prank(startup1);
        startupOneToken.approve(address(startupDepositContract), startupOneAmount);
        vm.prank(startup2);
        startupTwoToken.approve(address(startupDepositContract), startupTwoAmount);

        vm.startPrank(manager);
        startupDepositContract.setWhitelistedToken(address(startupOneToken));
        startupDepositContract.setWhitelistedToken(address(startupTwoToken));
        startupDepositContract.depositToken(address(startupOneToken), startupOneAmount, startup1);
        startupDepositContract.depositToken(address(startupTwoToken), startupTwoAmount, startup2);
        vm.stopPrank();

        assertEq(tokensReceivedBefore, 0);
        assertEq(tokensReceivedBefore2, 0);
        assertEq(startupDepositContract.tokensReceived(address(startupOneToken)), startupOneAmount);
        assertEq(startupDepositContract.tokensReceived(address(startupTwoToken)), startupTwoAmount);
        assertEq(tokenOneBalanceBefore, 0);
        assertEq(tokenTwoBalanceBefore, 0);
        assertEq(startupOneToken.balanceOf(address(startupDepositContract)), startupOneAmount);
        assertEq(startupTwoToken.balanceOf(address(startupDepositContract)), startupTwoAmount);
    }

    function test_RevertIf_NonManagerTriesToDepositToken() public {
        vm.expectRevert(StartupDepositContract.StartupDepositContract_NotAllowed.selector);
        startupDepositContract.depositToken(address(startupOneToken), 1 ether, startup1);
    }

    function test_RevertIf_TokenNotWhitelisted() public {
        vm.startPrank(manager);
        vm.expectRevert(StartupDepositContract.StartupDepositContract_NotWhitelistedToken.selector);
        startupDepositContract.depositToken(address(startupOneToken), 1 ether, startup1);
    }

    function test_RevertIf_AllowanceTooLow() public {
        vm.startPrank(manager);
        startupDepositContract.setWhitelistedToken(address(startupOneToken));
        vm.expectRevert(StartupDepositContract.StartupDepositContract_AllowanceTooLow.selector);
        startupDepositContract.depositToken(address(startupOneToken), 1 ether, startup1);
    }

    function test_Withdraw() public {
        uint256 startupOneAmount = 1 ether;
        uint256 startupTwoAmount = 10 ether;

        uint256 tokenOneStartupDepositContractBalanceBefore = startupOneToken.balanceOf(address(startupDepositContract));
        uint256 tokenTwoStartupDepositContractBalanceBefore = startupTwoToken.balanceOf(address(startupDepositContract));

        uint256 tokenOneInvestor1BalanceBefore = startupOneToken.balanceOf(investor1);
        uint256 tokenOneInvestor2BalanceBefore = startupOneToken.balanceOf(investor2);
        uint256 tokenOneInvestor3BalanceBefore = startupOneToken.balanceOf(investor3);
        uint256 tokenOneInvestor4BalanceBefore = startupOneToken.balanceOf(investor4);

        uint256 tokenTwoInvestor1BalanceBefore = startupTwoToken.balanceOf(investor1);
        uint256 tokenTwoInvestor2BalanceBefore = startupTwoToken.balanceOf(investor2);
        uint256 tokenTwoInvestor3BalanceBefore = startupTwoToken.balanceOf(investor3);
        uint256 tokenTwoInvestor4BalanceBefore = startupTwoToken.balanceOf(investor4);

        // First we have to deposit the tokens
        vm.prank(startup1);
        startupOneToken.approve(address(startupDepositContract), startupOneAmount);
        vm.prank(startup2);
        startupTwoToken.approve(address(startupDepositContract), startupTwoAmount);

        vm.startPrank(manager);
        startupDepositContract.setWhitelistedToken(address(startupOneToken));
        startupDepositContract.setWhitelistedToken(address(startupTwoToken));
        startupDepositContract.depositToken(address(startupOneToken), startupOneAmount, startup1);
        startupDepositContract.depositToken(address(startupTwoToken), startupTwoAmount, startup2);
        vm.stopPrank();

        // Now we can withdraw the tokens
        vm.startPrank(investor1);
        startupDepositContract.withdrawToken(address(startupOneToken));
        startupDepositContract.withdrawToken(address(startupTwoToken));
        vm.startPrank(investor2);
        startupDepositContract.withdrawToken(address(startupOneToken));
        startupDepositContract.withdrawToken(address(startupTwoToken));
        vm.startPrank(investor3);
        startupDepositContract.withdrawToken(address(startupOneToken));
        startupDepositContract.withdrawToken(address(startupTwoToken));
        vm.startPrank(investor4);
        startupDepositContract.withdrawToken(address(startupOneToken));
        startupDepositContract.withdrawToken(address(startupTwoToken));
        vm.stopPrank();

        assertEq(tokenOneStartupDepositContractBalanceBefore, 0);
        assertEq(tokenTwoStartupDepositContractBalanceBefore, 0);
        assertEq(tokenOneInvestor1BalanceBefore, 0);
        assertEq(tokenOneInvestor2BalanceBefore, 0);
        assertEq(tokenOneInvestor3BalanceBefore, 0);
        assertEq(tokenOneInvestor4BalanceBefore, 0);
        assertEq(tokenTwoInvestor1BalanceBefore, 0);
        assertEq(tokenTwoInvestor2BalanceBefore, 0);
        assertEq(tokenTwoInvestor3BalanceBefore, 0);
        assertEq(tokenTwoInvestor4BalanceBefore, 0);

        assertEq(startupOneToken.balanceOf(investor1), 0.1 ether);
        assertEq(startupOneToken.balanceOf(investor2), 0.8 ether);
        assertEq(startupOneToken.balanceOf(investor3), 0.05345 ether);
        assertEq(startupOneToken.balanceOf(investor4), 0.04655 ether);
        assertEq(startupTwoToken.balanceOf(investor1), 1 ether);
        assertEq(startupTwoToken.balanceOf(investor2), 8 ether);
        assertEq(startupTwoToken.balanceOf(investor3), 0.5345 ether);
        assertEq(startupTwoToken.balanceOf(investor4), 0.4655 ether);
    }
}
