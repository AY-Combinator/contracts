// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AYCombinatorGovernanceToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    error AYCombinatorGovernanceToken_TransfersAreDisabled();

    /**
     * @dev Constructor for the AYCombinatorGovernanceToken contract
     */
    constructor() ERC20("AYCombinatorGovernanceToken", "AYG") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Sets the minter role for the InvestorDepositContract
     * @param minterAddress The address to grant minter role to
     */
    function setMinter(address minterAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, minterAddress);
    }

    /**
     * @dev Mints tokens to the given address
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     * @notice Only the MINTER_ROLE can mint tokens, in this case the InvestorDepositContract
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Transfers are disabled, easy fix for hackathin urposes so we don't have to deal with snapshotting or adding more complex Governance Contracts from OpenZeppelin
     */
    function transfer(address, uint256) public pure override returns (bool) {
        revert AYCombinatorGovernanceToken_TransfersAreDisabled();
    }

    /**
     * @dev Transfers are disabled, easy fix for hackathin urposes so we don't have to deal with snapshotting or adding more complex Governance Contracts from OpenZeppelin
     */
    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert AYCombinatorGovernanceToken_TransfersAreDisabled();
    }
}
