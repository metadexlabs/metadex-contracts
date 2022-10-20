// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

/// @title Metadex Bonding Curve - MockERC1155 Interface
/// @author Linum Labs, on behalf of Metadex

interface IMockERC1155 {
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;
}
