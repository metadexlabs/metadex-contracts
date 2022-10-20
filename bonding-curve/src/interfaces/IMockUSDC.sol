// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

/// @title Metadex Bonding Curve - MockUSDC Interface
/// @author Linum Labs, on behalf of Metadex

interface IMockUSDC {
    function balanceOf(address _account) external view returns (uint256);

    function mint(address _to, uint256 _amount) external;

    function approve(address _spender, uint256 _amount) external;
}
