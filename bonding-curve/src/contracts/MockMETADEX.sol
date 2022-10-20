// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import "../interfaces/IMockMETADEX.sol";

import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "openzeppelin/contracts/security/Pausable.sol";
import "openzeppelin/contracts/access/AccessControl.sol";

import {console} from "forge-std/console.sol";


/// @title Metadex Bonding Curve - MockMETADEX Contract
/// @author Mainston

contract MockMETADEX is
    ERC20,
    ERC20Burnable,
    ERC20Capped,
    Pausable,
    AccessControl
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IERC20 public collateralInstance;

    constructor()
        //address _mockUSDC
        ERC20("METADEX", "METADEX")
        ERC20Capped(1000000000 * (10**uint256(18)))
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        require(
            ERC20.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}