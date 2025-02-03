// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";
import "./AYCombinatorGovernanceToken.sol";

contract InvestorDepositContract {
    using SafeERC20 for IERC20;

    address public owner;
    address public daoTeamTreasury;
    address public depositManager;
    address public fundManager;
    address public USDCAddress;
    AYCombinatorGovernanceToken public AYG;

    error InvestorDepositContract_NotAllowed();
    error InvestorDepositContract_AllowanceTooLow();

    constructor(
        address _daoTeamTreasury,
        address _depositManager,
        address _fundManager,
        address _USDCAddress,
        address _AYGAddress
    ) {
        owner = msg.sender;
        daoTeamTreasury = _daoTeamTreasury;
        depositManager = _depositManager;
        fundManager = _fundManager;
        USDCAddress = _USDCAddress;
        AYG = AYCombinatorGovernanceToken(_AYGAddress);
    }

    /**
     * @dev Deposit USDC tokens into the contract
     * @param initialDepositor The address of the initial depositor, that is investor
     * @param amount The amount of USDC tokens to deposit
     * @notice Only the depositManager can call this function (should be called by InvestorDepositContract)
     */
    function deposit(address initialDepositor, uint256 amount) external {
        require(msg.sender == depositManager, InvestorDepositContract_NotAllowed());
        require(
            IERC20(USDCAddress).allowance(initialDepositor, address(this)) >= amount,
            InvestorDepositContract_AllowanceTooLow()
        );
        // Calculate 5% fee for DAO treasury
        uint256 daoFee = (amount * 5) / 100;
        uint256 remainingAmount = amount - daoFee;

        // Transfer 5% to DAO treasury and 95% to this contract
        IERC20(USDCAddress).safeTransferFrom(initialDepositor, daoTeamTreasury, daoFee);
        IERC20(USDCAddress).safeTransferFrom(initialDepositor, address(this), remainingAmount);

        // Mint AYG tokens to the initial depositor
        uint256 daoPortionOfAYG = (remainingAmount * 10) / 100;
        uint256 investorPortionOfAYG = remainingAmount - daoPortionOfAYG;
        AYG.mint(initialDepositor, investorPortionOfAYG);
        AYG.mint(daoTeamTreasury, daoPortionOfAYG);
    }

    /**
     * @dev Invest AYG tokens into the contract
     * @param beneficiary The address of the beneficiary, that is startup
     * @param amount The amount of AYG tokens to invest
     * @notice Only the fundManager can call this function (should be called by StartupDepositContract)
     */
    function invest(address beneficiary, uint256 amount) external {
        require(msg.sender == fundManager, InvestorDepositContract_NotAllowed());

        IERC20(USDCAddress).safeTransfer(beneficiary, amount);
    }
}
