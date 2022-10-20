// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import "../interfaces/ICurveFactory.sol";
import "../interfaces/IUniswapRouter.sol";
import "./MockERC1155.sol";

import "./Curve.sol";
import "./MarketTransition.sol";

import "openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Metadex Bonding Curve - Curve Factory
/// @author Linum Labs, on behalf of Metadex

contract CurveFactory is ICurveFactory {
    IUniswapRouter router;
    uint256 public curveInstance = 1;
    uint256 public marketInstance = 1;

    NFT nft = new NFT();

    mapping(uint256 => address) public curveIdToAddress;
    mapping(address => address) public curveToMarketTransition;

    event CurveInstanceCreated(uint256 curveId, address curveAddress);
    event MarketInstanceCreated(
        uint256 marketInstance,
        address newMarketAddress
    );

    error ZeroAddress();

    constructor(address _routerAddress) {
        router = IUniswapRouter(_routerAddress);
    }

    function createBondingCurve(
        address _collateralAddress,
        address _tokenAddress,
        address _nftAddress,
        address _interactionContractAddress,
        address _curveFactoryAddress,
        address _daoAddress,
        address _treasuryAddress,
        address _uniswapRouter,
        address _getPrice
    ) external returns (address[2] memory) {
        if (_collateralAddress == address(0)) revert ZeroAddress();

        if (_tokenAddress == address(0)) revert ZeroAddress();

        if (_interactionContractAddress == address(0)) revert ZeroAddress();

        Curve newCurve = new Curve(
            _collateralAddress,
            _tokenAddress,
            _nftAddress,
            _interactionContractAddress,
            _curveFactoryAddress,
            _daoAddress,
            _treasuryAddress,
            _uniswapRouter,
            _getPrice
        );

        newCurve.transferOwnership(msg.sender);

        curveIdToAddress[curveInstance] = address(newCurve);

        emit CurveInstanceCreated(curveInstance, address(newCurve));

        curveInstance++;

        // address marketAddress = createMarketTransitionContract(
        //     _tokenAddress,
        //     _collateralAddress,
        //     address(newCurve),
        //     _getPrice
        // );

        MarketTransition newMarket = new MarketTransition(
            address(newCurve),
            address(router),
            _collateralAddress,
            _tokenAddress,
            _getPrice
        );

        emit MarketInstanceCreated(marketInstance, address(newMarket));

        marketInstance++;
        curveToMarketTransition[address(newCurve)] = address(newMarket);

        return [address(newCurve), address(newMarket)];
    }

    // function createMarketTransitionContract(
    //     address _tokenAddress,
    //     address _usdc,
    //     address _curveAddress,
    //     address _getPrice
    // ) internal returns (address) {
    //     MarketTransition newMarket = new MarketTransition(
    //         _curveAddress,
    //         address(router),
    //         _usdc,
    //         _tokenAddress,
    //         _getPrice
    //     );

    //     emit MarketInstanceCreated(marketInstance, address(newMarket));

    //     marketInstance++;

    //     return address(newMarket);
    // }

    function getCurveAddress(uint256 _curveId) external view returns (address) {
        return curveIdToAddress[_curveId];
    }

    function getMarketAddress(address _curveAddress)
        external
        view
        returns (address)
    {
        return curveToMarketTransition[_curveAddress];
    }
}
