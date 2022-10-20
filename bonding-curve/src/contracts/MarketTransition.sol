// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import "../interfaces/IMarketTransition.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IGetPrice.sol";
import "../interfaces/IUniswapRouter2.sol";
import "../interfaces/IMockMETADEX.sol";
import "../interfaces/IMockUSDC.sol";
import "../contracts/MockMETADEX.sol";
import "../contracts/MockUSDC.sol";

import "./CurveFactory.sol";

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import {console} from "forge-std/console.sol";

/// @title Metadex Bonding Curve - Market Transition Contract
/// @author Linum Labs, on behalf of Mainston

contract MarketTransition is IMarketTransition {
    ICurve curveInstance;
    IERC20 USDC;
    //IERC20 METADEX;
    MockMETADEX METADEX;
    //MockUSDC USDC;
    CurveFactory curveFactory;
    IUniswapRouter2 router;
    IGetPrice getPriceContract;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    INonfungiblePositionManager public manager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);  

    ISwapRouter public swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    mapping(address => int256[3]) public transitionInfo;

    // =============== ERRORS =============== //
    error IncorrectContractCalling();

    constructor(
        address _curveAddress,
        address _routerAddress,
        address _USDC,
        address _METADEX,
        address _getPrice
    ) {
        curveInstance = ICurve(_curveAddress);
        router = IUniswapRouter2(_routerAddress);

        METADEX = new MockMETADEX();
        USDC = IERC20(_USDC);

        getPriceContract = IGetPrice(_getPrice);
        METADEX.grantRole(MINTER_ROLE, address(this));
    }

    // function transition(address _curveAddress) public onlyCurve(_curveAddress) {

    //     //Check the token ratios to see if we need to mint more tokens
    //     int256 tokenToMint = getTokenstoMint();

    //     //Create pool in the uniswap router
    //     USDC.approve(address(manager), 1000 * 1e18);
    //     USDC.approve(address(router), 1000 * 1e18);
    //     USDC.approve(address(swapRouter), 1000 * 1e18);

    //     METADEX.approve(address(manager), 1000 * 1e18);
    //     METADEX.approve(address(router), 1000 * 1e18);
    //     METADEX.approve(address(swapRouter), 1000 * 1e18);

    //     console.logUint(USDC.balanceOf(_curveAddress));
    //     console.logUint(uint256(tokenToMint));

    //     router.createPool(address(METADEX), address(USDC), uint256(tokenToMint), USDC.balanceOf(_curveAddress));

    //     //Pause the curve
    //     curveInstance.pauseCurve();
    // }

    function transition(address _curveAddress) public onlyCurve(_curveAddress) {
        //Check the token ratios to see if we need to mint more tokens
        int256 tokenToMint = getTokenstoMint();

        //Create pool in the uniswap router
        USDC.approve(address(manager), 200000000 * 1e18);
        USDC.approve(address(router), 200000000 * 1e18);
        USDC.approve(address(swapRouter), 200000000 * 1e18);
        //USDC.approve(address(this), 200000000 * 1e18);
        USDC.approve(address(curveInstance), 200000000 * 1e18);
        USDC.approve(
            0x3d183681a0a393e85824Eb614fc84615332BfF0B,
            2000000000 * 1e18
        );

        TransferHelper.safeApprove(
            address(USDC),
            address(manager),
            200000000 * 1e18
        );
        TransferHelper.safeApprove(
            address(USDC),
            address(router),
            200000000 * 1e18
        );
        TransferHelper.safeApprove(
            address(METADEX),
            address(manager),
            200000000 * 1e18
        );
        TransferHelper.safeApprove(
            address(METADEX),
            address(router),
            200000000 * 1e18
        );
        TransferHelper.safeApprove(
            address(USDC),
            address(this),
            200000000 * 1e18
        );
        TransferHelper.safeApprove(
            address(METADEX),
            address(this),
            200000000 * 1e18
        );
        TransferHelper.safeApprove(
            address(USDC),
            address(swapRouter),
            200000000 * 1e18
        );
        TransferHelper.safeApprove(
            address(METADEX),
            address(swapRouter),
            200000000 * 1e18
        );
        TransferHelper.safeApprove(
            address(USDC),
            address(this),
            200000000 * 1e18
        );
        TransferHelper.safeApprove(
            address(USDC),
            0x3d183681a0a393e85824Eb614fc84615332BfF0B,
            200000000 * 1e18
        );

        //Pause the curve
        curveInstance.pauseCurve();

        METADEX.mint(address(router), uint256(tokenToMint));

        router.createPool(
            address(USDC),
            address(METADEX),
            (USDC.balanceOf(address(router)) / 1e18),
            (uint256(tokenToMint) / 1e18)
        );
    }

    function getTokenstoMint() public returns (int256) {
        int256 currentPrice = getPriceContract.getPrice(1);


        uint256 collateralInToken = USDC.balanceOf(address(router));
        int256 collateralInTokenInt = int256(collateralInToken);
        int256 tokensToMint = (collateralInTokenInt * 1e18) / currentPrice;

        transitionInfo[msg.sender][0] = currentPrice;
        transitionInfo[msg.sender][1] = tokensToMint;
        transitionInfo[msg.sender][2] = collateralInTokenInt;

        return tokensToMint;
    }

    function getTransitionInfo(address _token)
        public
        view
        returns (
            int256,
            int256,
            int256
        )
    {
        return (
            transitionInfo[_token][0],
            transitionInfo[_token][1],
            transitionInfo[_token][2]
        );
    }

    modifier onlyCurve(address _curveAddress) {
        if (msg.sender != _curveAddress) revert IncorrectContractCalling();
        _;
    }
}
