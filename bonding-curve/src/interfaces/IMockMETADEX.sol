// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

/// @title Metadex Bonding Curve - MockMetadex Interface
/// @author Linum Labs, on behalf of Metadex

interface IMockMETADEX {
    // function pause() external;

    // function unpause() external;

    function approve(address _spender, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;

    // function getBuyCost(uint256 _tokens, address _curveInstance) external view returns (uint256);
}
