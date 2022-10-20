// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "../src/contracts/CurveFactory.sol";
import "../src/contracts/GetPrice.sol";
import "../src/contracts/UniswapRouter2.sol";
import "../src/contracts/MarketTransition.sol";
import "../src/contracts/UniswapRouter2.sol";
import "../src/contracts/MockUSDC.sol";
import "../src/contracts/MockMETADEX.sol";
import "../src/contracts/MockERC1155.sol";

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

contract CurveFactoryTests is Test {
    CurveFactory curveFactory;
    MockUSDC USDC;
    MockMETADEX metadex;
    NFT nft;
    GetPrice getPriceContract;

    UniswapRouter2 router;

    INonfungiblePositionManager manager;

    address daoAddress = vm.addr(1);
    address treasuryAddress = vm.addr(2);

    function setUp() public {
        manager = INonfungiblePositionManager(
            0xC36442b4a4522E871399CD717aBDD847Ab11FE88
        );
        USDC = new MockUSDC();
        metadex = new MockMETADEX();
        router = new UniswapRouter2(manager, address(USDC), address(metadex));
        curveFactory = new CurveFactory(address(router));
        nft = new NFT();
        getPriceContract = new GetPrice();
    }

    function testCurveCreation() public {
        address[2] memory criticalAddresses = curveFactory.createBondingCurve(
            address(USDC),
            0x2953399124F0cBB46d2CbACD8A89cF0599974963,
            address(nft),
            0x11Ac5d7BE1B826198a57A8Fd953E1d0EbD9eC17C,
            address(this),
            daoAddress,
            treasuryAddress,
            address(router),
            address(getPriceContract)
        );

        assertEq(curveFactory.curveInstance() - 1, 1);
        assertEq(curveFactory.marketInstance() - 1, 1);
        assertEq(
            curveFactory.curveToMarketTransition(criticalAddresses[0]),
            criticalAddresses[1]
        );
        assertEq(criticalAddresses[0], curveFactory.getCurveAddress(1));

        console.logAddress(criticalAddresses[0]);
        console.logAddress(criticalAddresses[1]);
    }

    // function testCurvecreationMaxBelowMinThreshold() public {
    //     vm.expectRevert("Max threshold lower than min");

    //     curveFactory.createBondingCurve(
    //         100,
    //         20,
    //         300,
    //         0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747,
    //         address(USDC),
    //         address(nft),
    //         //address(marketTransition),
    //         0x11Ac5d7BE1B826198a57A8Fd953E1d0EbD9eC17C,
    //         address(this),
    //         daoAddress,
    //         treasuryAddress,
    //         address(router)
    //     );
    // }

    function testCurveCreationCollateralAddressZero() public {
        vm.expectRevert(CurveFactory.ZeroAddress.selector);

        curveFactory.createBondingCurve(
            0x0000000000000000000000000000000000000000,
            address(USDC),
            address(nft),
            //address(marketTransition),
            0x11Ac5d7BE1B826198a57A8Fd953E1d0EbD9eC17C,
            address(this),
            daoAddress,
            treasuryAddress,
            address(router),
            address(getPriceContract)
        );
    }

    function testCurveCreationTokenAddressZero() public {
        vm.expectRevert(CurveFactory.ZeroAddress.selector);

        curveFactory.createBondingCurve(
            0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747,
            0x0000000000000000000000000000000000000000,
            address(nft),
            //address(marketTransition),
            0x11Ac5d7BE1B826198a57A8Fd953E1d0EbD9eC17C,
            address(this),
            daoAddress,
            treasuryAddress,
            address(router),
            address(getPriceContract)
        );
    }

    // function testCurveCreationMarketAddressZero() public {
    //     vm.expectRevert("Address cannot be zero-address");

    //     curveFactory.createBondingCurve(
    //         300,
    //         20,
    //         100,
    //         //0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747,
    //         address(USDC),
    //         address(nft),
    //         // 0x0000000000000000000000000000000000000000,
    //         address(this),
    //         0x11Ac5d7BE1B826198a57A8Fd953E1d0EbD9eC17C,
    //         address(this)
    //     );
    // }

    function testCurveCreationInteractionAddressZero() public {
        vm.expectRevert(CurveFactory.ZeroAddress.selector);

        curveFactory.createBondingCurve(
            0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747,
            address(USDC),
            address(nft),
            //address(marketTransition),
            0x0000000000000000000000000000000000000000,
            address(this),
            daoAddress,
            treasuryAddress,
            address(router),
            address(getPriceContract)
        );
    }

    // function testCurveCreationTimeOutEquals0() public {
    //     vm.expectRevert("Time out period cannot be zero");

    //     curveFactory.createBondingCurve(
    //         300,
    //         0,
    //         100,
    //         0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747,
    //         address(metadex),
    //         address(nft),
    //         //address(marketTransition),
    //         0x11Ac5d7BE1B826198a57A8Fd953E1d0EbD9eC17C,
    //         address(this),
    //         daoAddress,
    //         treasuryAddress,
    //         address(router)
    //     );
    // }
}
