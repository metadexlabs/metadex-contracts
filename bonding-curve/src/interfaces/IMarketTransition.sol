// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

interface IMarketTransition {
    function transition(address _curveAddress) external;

    function getTransitionInfo(address _token)
        external
        view
        returns (
            int256,
            int256,
            int256
        );

    function getTokenstoMint() external returns (int256);
}
