// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StartupDepositContract {
    using SafeERC20 for IERC20;

    address public immutable manager;
    address public immutable AYG;
    mapping(address => bool) public whitelistedTokens;
    mapping(address => uint256) public tokensReceived;
    // @dev mapping to check if a token has been withdrawn by an investor
    mapping(address => mapping(address => bool)) public tokenToWithdrawer;

    event StartupDepositContract_TokenWhitelisted(address indexed token);
    event StartupDepositContract_TokenDeposited(address indexed token, address indexed depositor, uint256 amount);
    event StartupDepositContract_TokenWithdrawn(address indexed token, address indexed withdrawer, uint256 amount);

    error StartupDepositContract_NotAllowed();
    error StartupDepositContract_NotWhitelistedToken();
    error StartupDepositContract_AllowanceTooLow();
    error StartupDepositContract_AlreadyWithdrawn();

    modifier onlyManager() {
        require(msg.sender == manager, StartupDepositContract_NotAllowed());
        _;
    }

    constructor(address _manager, address _AYG) {
        manager = _manager;
        AYG = _AYG;
    }

    /**
     * @dev Set a token as whitelisted or not
     * @param token The address of the token to set
     * @notice Only the manager can call this function
     */
    function setWhitelistedToken(address token) external onlyManager {
        whitelistedTokens[token] = true;
        emit StartupDepositContract_TokenWhitelisted(token);
    }

    /**
     * @dev Deposit tokens into the contract
     * @param token The address of the token to deposit
     * @param amount The amount of tokens to deposit
     * @param from The address of the sender
     * @notice Only the manager can call this function
     */
    function depositToken(address token, uint256 amount, address from) external onlyManager {
        require(whitelistedTokens[token], StartupDepositContract_NotWhitelistedToken());
        require(IERC20(token).allowance(from, address(this)) >= amount, StartupDepositContract_AllowanceTooLow());
        IERC20(token).safeTransferFrom(from, address(this), amount);
        tokensReceived[token] += amount;
        emit StartupDepositContract_TokenDeposited(token, from, amount);
    }

    /**
     * @dev Withdraw tokens from the contract
     * @param token The address of the token to withdraw
     * @notice Only the manager can call this function
     */
    function withdrawToken(address token) external {
        require(!tokenToWithdrawer[token][msg.sender], StartupDepositContract_AlreadyWithdrawn());
        uint256 numberOfAYGTokens = IERC20(AYG).balanceOf(msg.sender);
        uint256 totalAYGTokenSupply = IERC20(AYG).totalSupply();
        uint256 amountToWithdraw = (numberOfAYGTokens * tokensReceived[token]) / totalAYGTokenSupply;

        IERC20(token).safeTransfer(msg.sender, amountToWithdraw);
        tokenToWithdrawer[token][msg.sender] = true;
        emit StartupDepositContract_TokenWithdrawn(token, msg.sender, amountToWithdraw);
    }
}
