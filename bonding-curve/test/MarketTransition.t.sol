// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "src/contracts/CurveFactory.sol";
import "../src/contracts/GetPrice.sol";
import "src/contracts/MarketTransition.sol";
import "../src/contracts/UniswapRouter2.sol";
import "src/contracts/Curve.sol";
import "../src/contracts/MockERC1155.sol";
import "../src/contracts/MockUSDC.sol";
import "../src/contracts/MockMETADEX.sol";
import "../src/contracts/Interaction.sol";
import "../src/contracts/TokenVesting.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {console} from "forge-std/console.sol";

contract MarketTransitionTests is Test {
    CurveFactory curveFactory;
    UniswapRouter2 router;
    Curve curve;
    IMarketTransition marketTransition;
    Interaction interaction;
    MockUSDC USDC;
    MockMETADEX METADEX;
    GetPrice getPriceContract;
    TokenVesting vestingContract;
    NFT nft = new NFT();
    INonfungiblePositionManager manager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter public swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address daoAddress = vm.addr(1);
    address treasuryAddress = vm.addr(2);

    address owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        USDC = new MockUSDC();
        USDC.mint(address(owner), 100000 * 1e18);
        USDC.mint(address(this), 1000000 * 1e18);
        METADEX = new MockMETADEX();
        router = new UniswapRouter2(manager, address(USDC), address(METADEX));
        curveFactory = new CurveFactory(address(router));
        interaction = new Interaction();
        vestingContract = new TokenVesting(address(METADEX));
        getPriceContract = new GetPrice();
        vm.startPrank(owner);

        USDC.approve(address(manager), USDC.balanceOf(address(curve)) * 1e18);
        USDC.approve(address(router), USDC.balanceOf(address(curve)) * 1e18);
        USDC.approve(
            address(swapRouter),
            USDC.balanceOf(address(curve)) * 1e18
        );
        USDC.approve(
            0x3d183681a0a393e85824Eb614fc84615332BfF0B,
            USDC.balanceOf(address(curve)) * 1e18
        );
        USDC.approve(address(this), USDC.balanceOf(address(curve)) * 1e18);

        METADEX.grantRole(MINTER_ROLE, address(interaction));

        vestingContract.transferOwnership(address(interaction));
        vm.stopPrank();
    }

    function testTransition() public {
        address[2] memory criticalAddresses = curveFactory.createBondingCurve(
            address(USDC),
            address(METADEX),
            address(nft),
            address(interaction),
            address(curveFactory),
            daoAddress,
            treasuryAddress,
            address(router),
            address(getPriceContract)
        );

        getPriceContract.setCurveAddress(criticalAddresses[0]);

        assertEq(curveFactory.curveInstance() - 1, 1);
        assertEq(curveFactory.marketInstance() - 1, 1);
        assertEq(
            curveFactory.curveToMarketTransition(criticalAddresses[0]),
            criticalAddresses[1]
        );
        // assertEq(criticalAddresses[0], curveFactory.getCurveAddress(1));

        marketTransition = IMarketTransition(criticalAddresses[1]);
        curve = Curve(criticalAddresses[0]);

        USDC.mint(address(owner), 100000000 * 1e18);

        vm.startPrank(owner);
        interaction.setAddr(
            address(METADEX),
            address(vestingContract),
            address(curve)
        );
        curve.activateCurve();
        curve.setNFTStage("NONE");
        console.log("Manager");
        console.logAddress(address(manager));
        USDC.approve(address(curve), USDC.balanceOf(address(curve)) * 1e18);
        USDC.approve(address(manager), USDC.balanceOf(address(curve)) * 1e18);
        USDC.approve(address(router), USDC.balanceOf(address(curve)) * 1e18);
        USDC.approve(
            address(swapRouter),
            USDC.balanceOf(address(curve)) * 1e18
        );
        USDC.approve(
            address(marketTransition),
            USDC.balanceOf(address(curve)) * 1e18
        );
        USDC.approve(address(this), USDC.balanceOf(address(curve)) * 1e18);
        USDC.approve(
            0x3d183681a0a393e85824Eb614fc84615332BfF0B,
            USDC.balanceOf(address(curve)) * 1e18
        );
        USDC.approve(address(curve), 20000000 * 1e18);

        curve.buyMetadex(20000000);
        vm.stopPrank();

        vm.startPrank(address(router));
        USDC.approve(
            address(curve),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(manager),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(router),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(swapRouter),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(marketTransition),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            0x3d183681a0a393e85824Eb614fc84615332BfF0B,
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(this),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        METADEX.approve(address(curve), 200000000 * 1e18);
        METADEX.approve(address(manager), 200000000 * 1e18);
        METADEX.approve(address(router), 200000000 * 1e18);
        METADEX.approve(address(swapRouter), 200000000 * 1e18);
        METADEX.approve(address(marketTransition), 200000000 * 1e18);
        METADEX.approve(
            0x3d183681a0a393e85824Eb614fc84615332BfF0B,
            200000000 * 1e18
        );
        METADEX.approve(address(this), 200000000 * 1e18);
        vm.stopPrank();

        vm.startPrank(address(marketTransition));
        USDC.approve(
            address(curve),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(manager),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(router),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(swapRouter),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(marketTransition),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            0x3d183681a0a393e85824Eb614fc84615332BfF0B,
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(this),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        vm.stopPrank();

        vm.startPrank(address(manager));
        USDC.approve(
            address(curve),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(manager),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(router),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(swapRouter),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(marketTransition),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            0x3d183681a0a393e85824Eb614fc84615332BfF0B,
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(this),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        vm.stopPrank();

        vm.startPrank(address(curve));
        USDC.approve(
            address(curve),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(manager),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(router),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(swapRouter),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(marketTransition),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            0x3d183681a0a393e85824Eb614fc84615332BfF0B,
            USDC.balanceOf(address(marketTransition)) * 1e18
        );
        USDC.approve(
            address(this),
            USDC.balanceOf(address(marketTransition)) * 1e18
        );

        console.logAddress(address((manager))); //0xc36442b4a4522e871399cd717abdd847ab11fe88
        console.logAddress(address((curve))); //0xaff9558ae2565b98193ee625b95f330f10abe0b6
        console.logAddress(address((router))); //0xf5a2fe45f4f1308502b1c136b9ef8af136141382
        console.logAddress(address((swapRouter))); //0xe592427a0aece92de3edee1f18e0157c05861564
        console.logAddress(address((marketTransition))); //0x1da550bbd13d572d3658c5500ad00718c6ca99b1

        //marketTransition.transition(criticalAddresses[0]);

        assertEq(curve.curveActive(), false);

        vm.stopPrank();
    }

    function testGetTokensToMint() public {
        address[2] memory criticalAddresses = curveFactory.createBondingCurve(
            address(USDC),
            address(METADEX),
            address(nft),
            address(interaction),
            address(curveFactory),
            daoAddress,
            treasuryAddress,
            address(router),
            address(getPriceContract)
        );

        getPriceContract.setCurveAddress(criticalAddresses[0]);

        assertEq(curveFactory.curveInstance() - 1, 1);
        assertEq(curveFactory.marketInstance() - 1, 1);
        assertEq(
            curveFactory.curveToMarketTransition(criticalAddresses[0]),
            criticalAddresses[1]
        );
        // assertEq(criticalAddresses[0], curveFactory.getCurveAddress(1));

        marketTransition = IMarketTransition(criticalAddresses[1]);
        curve = Curve(criticalAddresses[0]);

        USDC.mint(address(owner), 100000000 * 1e18);
        vm.startPrank(owner);
        interaction.setAddr(
            address(METADEX),
            address(vestingContract),
            address(curve)
        );
        curve.activateCurve();
        curve.setNFTStage("NONE");
        USDC.approve(address(curve), 200000000 * 1e18);
        curve.buyMetadex(20000000);
        curve.activateCurve();
        vm.stopPrank();
        assertEq(marketTransition.getTokenstoMint(), 2659999999999999997340000);
    }
}
