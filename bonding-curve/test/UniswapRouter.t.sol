// // SPDX-License-Identifier: UNLICENSED
// pragma solidity =0.8.15;

// import "forge-std/Test.sol";
// import "src/contracts/CurveFactory.sol";
// import "src/contracts/MarketTransition.sol";
// import "../src/contracts/UniswapRouter2.sol";
// import "../src/contracts/MockUSDC.sol";
// import "../src/contracts/MockMetadex.sol";
// import "../src/contracts/MockERC1155.sol";

// contract UniswapRouterTests is Test {
//     UniswapRouter2 router;

//     address owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
//     address alice = vm.addr(3);

//     MockMETADEX METADEX = new MockMETADEX();

//     INonfungiblePositionManager nonfungiblePositionManager = new INonfungiblePositionManager();  

//     SwapRouter swapRouter = new SwapRouter();

//     function setUp() public {
//         router = new UniswapRouter2(
//             nonfungiblePositionManager,
//             swapRouter,
//             0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,
//             address(METADEX)
//             // address _transitionContractAddress
//         );
//     }

//     function testPause() public {
//         bool active = router.poolActive();
//         assertTrue(active);

//         vm.prank(owner);
//         router.pausePool();

//         active = router.poolActive();
//         assertFalse(active);
//     }

//     function testPauseOnlyOwner() public {
//         vm.prank(alice);
//         vm.expectRevert("Ownable: caller is not the owner");

//         router.pausePool();
//     }

//     function testActivate() public {
//         bool active = router.poolActive();
//         assertFalse(active);

//         vm.prank(owner);
//         router.activatePool();

//         active = router.poolActive();
//         assertTrue(active);
//     }
// }
