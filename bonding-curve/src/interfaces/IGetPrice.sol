// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12;

interface IGetPrice {
    function setCurveAddress(address _curveAddress) external;

    function getPrice(int256 _amountTokens)
        external
        view
        returns (int256 price);
}
