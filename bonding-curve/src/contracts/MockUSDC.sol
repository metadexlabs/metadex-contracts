// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import "../interfaces/IMockUSDC.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console} from "forge-std/console.sol";


/// @title Metadex Bonding Curve - MockUSDC Contract
/// @author Linum Labs, on behalf of Mainston

contract MockUSDC is ERC20 {
    constructor() ERC20("mUSDC", "MockUSDC") {}

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function getBalanceOf(address _account) public view returns (uint256){
        return balanceOf(_account);
    }

}
