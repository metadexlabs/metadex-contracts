// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

interface ICurveFactory  {

    function getMarketAddress(address _curveAddress) external view returns (address);

}