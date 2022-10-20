// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
pragma abicoder v2;

import "forge-std/Script.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import "../src/contracts/Curve.sol";
import "../src/contracts/GetPrice.sol";
import "../src/contracts/CurveFactory.sol";
import "../src/contracts/Interaction.sol";
import "../src/contracts/MarketTransition.sol";
import "../src/contracts/MockERC1155.sol";
import "../src/contracts/MockMETADEX.sol";
import "../src/contracts/MockUSDC.sol";
import "../src/contracts/TokenVesting.sol";
import "../src/contracts/UniswapRouter2.sol";

import "../src/interfaces/ICurve.sol";
import "../src/interfaces/ICurveFactory.sol";
import "../src/interfaces/IInteraction.sol";
import "../src/interfaces/IMarketTransition.sol";
import "../src/interfaces/IMockERC1155.sol";
import "../src/interfaces/IMockMETADEX.sol";
import "../src/interfaces/IMockUSDC.sol";
import "../src/interfaces/ITokenVesting.sol";
import "../src/interfaces/IUniswapRouter2.sol";

contract DeployToMumbaiScript is Script {
    INonfungiblePositionManager public manager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        UniswapRouter2 router = new UniswapRouter2(
            manager,
            0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747,
            0x6470A27E83F23aaB95bD9cD7f7e9DfA1a307c173
        );
        address routerAddress = address(router);
        CurveFactory curveFactory = new CurveFactory(routerAddress);
        GetPrice getPriceContract = new GetPrice();
        NFT nft = new NFT();
        MockUSDC usdc = new MockUSDC();
        MockMETADEX metadex = new MockMETADEX();
        Interaction interaction = new Interaction();
        TokenVesting vesting = new TokenVesting(
            0x2953399124F0cBB46d2CbACD8A89cF0599974963
        );
        Curve curve = new Curve(
            0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747,
            0x6470A27E83F23aaB95bD9cD7f7e9DfA1a307c173,
            0x2953399124F0cBB46d2CbACD8A89cF0599974963,
            0x11Ac5d7BE1B826198a57A8Fd953E1d0EbD9eC17C,
            address(curveFactory),
            0xa25ac4331F0ffCd7886Ae91b46d05f91F1002BF3,
            0x5B7c4D17024a19DFdA9401Fc7592752114fABb28,
            address(router),
            address(getPriceContract)
        );
        MarketTransition transition = new MarketTransition(
            address(curve),
            address(router),
            address(usdc),
            address(metadex),
            address(getPriceContract)
        );
        vm.stopBroadcast();
    }
}
