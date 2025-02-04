// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/InvestorDepositContract.sol";
import "../src/AYCombinatorGovernanceToken.sol";

contract MockUSDC is ERC20 {
    constructor(address _mintTo) ERC20("MockUSDC", "USDC") {
        _mint(_mintTo, 10000000000000000000000);
    }
}

contract InvestorDepositContractTest is Test {
    InvestorDepositContract public investorDepositContract;
    AYCombinatorGovernanceToken public AYG;
    MockUSDC public USDC;
    address public aygAdmin = makeAddr("AYGAdmin");
    address public investor = makeAddr("Investor");
    address public startup = makeAddr("Startup");
    address public depositManager = makeAddr("DepositManager");
    address public fundManager = makeAddr("FundManager");
    address public daoTeamTreasury = makeAddr("DaoTeamTreasury");

    function setUp() public {
        USDC = new MockUSDC(address(investor));

        vm.startPrank(aygAdmin);
        AYG = new AYCombinatorGovernanceToken();
        vm.stopPrank();

        investorDepositContract =
            new InvestorDepositContract(daoTeamTreasury, depositManager, fundManager, address(USDC), address(AYG));
        vm.startPrank(aygAdmin);
        AYG.setMinter(address(investorDepositContract));
        vm.stopPrank();
    }

    function test_Deposit() public {
        vm.startPrank(investor);
        USDC.approve(address(investorDepositContract), 1000000000000000000);
        vm.stopPrank();

        vm.startPrank(depositManager);
        investorDepositContract.deposit(investor, 1000000000000000000);
        vm.stopPrank();

        assertEq(USDC.balanceOf(address(investorDepositContract)), 1000000000000000000 * 95 / 100);
        assertEq(USDC.balanceOf(daoTeamTreasury), 1000000000000000000 * 5 / 100);
        assertEq(AYG.balanceOf(investor), 950000000000000000 * 90 / 100);
        assertEq(AYG.balanceOf(daoTeamTreasury), 950000000000000000 * 10 / 100);
    }

    function test_RevertIf_DepositNotCalledByDepositManager() public {
        vm.startPrank(investor);
        vm.expectRevert(InvestorDepositContract.InvestorDepositContract_NotAllowed.selector);
        investorDepositContract.deposit(investor, 1000000000000000000);
        vm.stopPrank();
    }

    function test_RevertIf_DepositAllowanceTooLow() public {
        vm.startPrank(investor);
        USDC.approve(address(investorDepositContract), 0);
        vm.stopPrank();

        vm.startPrank(depositManager);
        vm.expectRevert(InvestorDepositContract.InvestorDepositContract_AllowanceTooLow.selector);
        investorDepositContract.deposit(investor, 1000000000000000000);
        vm.stopPrank();
    }

    function test_Invest() public {
        vm.startPrank(investor);
        USDC.transfer(address(investorDepositContract), 1000000000000000000);
        vm.stopPrank();

        vm.startPrank(fundManager);
        investorDepositContract.invest(startup, 1000000000000000000);
        vm.stopPrank();

        assertEq(USDC.balanceOf(startup), 1000000000000000000);
    }

    function test_RevertIf_InvestNotCalledByFundManager() public {
        vm.startPrank(investor);
        vm.expectRevert(InvestorDepositContract.InvestorDepositContract_NotAllowed.selector);
        investorDepositContract.invest(investor, 1000000000000000000);
        vm.stopPrank();
    }
}
