// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "src/contracts/CurveFactory.sol";
import "src/contracts/MarketTransition.sol";
import "../src/contracts/UniswapRouter2.sol";
import "../src/contracts/MockUSDC.sol";
import "../src/contracts/MockMETADEX.sol";
import "../src/contracts/MockERC1155.sol";
import "../src/contracts/Tick.sol";

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/UniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungibleTokenPositionDescriptor.sol';
import 'openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol';

contract UniswapRouterTests is Test {
    
    UniswapRouter2 router;

    address owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address alice = vm.addr(3);

    MockMETADEX METADEX = new MockMETADEX();
    MockUSDC USDC = new MockUSDC();

    INonfungiblePositionManager public manager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);  

    ISwapRouter public swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IUniswapV3Factory public factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    INonfungibleTokenPositionDescriptor nftDescriptor = INonfungibleTokenPositionDescriptor(0x91ae842A5Ffd8d12023116943e72A606179294f3);

    function setUp() public {

        router = new UniswapRouter2(
            manager,
            address(USDC),
            address(METADEX)
        );
        
        METADEX.mint(address(this), 10000 * 1e18);
        METADEX.mint(address(router), 10000 * 1e18);
        METADEX.mint(address(alice), 10000 * 1e18);
        METADEX.approve(address(this), 1000 * 1e18);

        USDC.mint(address(this), 10000 * 1e18);
        USDC.mint(address(router), 10000 * 1e18);
        USDC.mint(address(alice), 10000 * 1e18);
        USDC.approve(address(this), 1000 * 1e18);
    }

    function testPause() public {
        vm.prank(owner);
        router.activatePool();
        bool active = router.poolActive();
        assertTrue(active);

        vm.prank(owner);
        router.pausePool();

        active = router.poolActive();
        assertFalse(active);
    }

    function testPauseOnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert("Caller is not the owner");
        router.pausePool();
    }

    function testActivate() public {
        bool active = router.poolActive();
        assertFalse(active);

        vm.prank(owner);
        router.activatePool();

        active = router.poolActive();
        assertTrue(active);
    }

    function testActivateOnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert("Caller is not the owner");
        router.activatePool();
    }

    function testCreatePool() public {
        vm.prank(owner);
        router.activatePool();
        (address pool,) = router.createPool(address(USDC), address(METADEX), 5, 5);
        assertEq(USDC.balanceOf(address(pool)), 5);
        assertEq(METADEX.balanceOf(address(pool)), 5);
        vm.stopPrank();
    }

    function testCreatePoolUnequalAmounts() public {
        vm.prank(owner);
        router.activatePool();
        (address pool,) = router.createPool(address(USDC), address(METADEX), 2000, 1000);
        assertEq(USDC.balanceOf(address(pool)), 2000);
        assertEq(METADEX.balanceOf(address(pool)), 1000);
        vm.stopPrank();
    }

    function testTransferOwnership() public {
        assertEq(router.owner(), owner);

        router.transferOwner(alice);
        assertEq(router.owner(), alice);
    }

    function testSwapFail() public {
        vm.prank(owner);
        router.activatePool();
        vm.startPrank(alice);
        vm.expectRevert("Amount must be larger than zero");
        router.swapMETADEXforUSDC(0);
        vm.stopPrank();
    }

    function testSwapUSDCForMetadexEqualAmountsAnd100Tokens() public {
        vm.startPrank(owner);
        router.activatePool();
        (address pool,) = router.createPool(address(USDC), address(METADEX), 1000, 1000);
        console.logUint(USDC.balanceOf(address(pool)));
        console.logUint(METADEX.balanceOf(address(pool)));
        vm.stopPrank();

        vm.startPrank(alice);
        uint256 balanceBefore = METADEX.balanceOf(alice);

        uint256 quoteAmount = router.getQuoteForUSDC(100);
        console.logUint(quoteAmount);
        
        USDC.approve(address(router), 1000);
        METADEX.approve(address(router), 1000);
        USDC.approve(address(alice), 1000);
        METADEX.approve(address(alice), 1000);
        USDC.approve(address(pool), 1000);
        METADEX.approve(address(pool), 1000);
        METADEX.approve(address(swapRouter), 1000);
        USDC.approve(address(swapRouter), 1000);
        USDC.approve(address(this), 1000);
        METADEX.approve(address(this), 1000);
        
        uint256 amountOut = router.swapUSDCForMETADEX(100);
        uint256 balanceAfter = METADEX.balanceOf(alice);

        assertEq(amountOut, quoteAmount);
        assertEq(balanceAfter, balanceBefore + amountOut);

        vm.stopPrank();
    }

    function testSwapUSDCForMetadexUnEqualAmountsAnd100Tokens() public {
        vm.startPrank(owner);
        router.activatePool();
        USDC.approve(address(router), 20000);
        (address pool,) = router.createPool(address(USDC), address(METADEX), 4000, 1000);
        console.logUint(USDC.balanceOf(address(pool)));
        console.logUint(METADEX.balanceOf(address(pool)));
        vm.stopPrank();

        vm.startPrank(alice);
        uint256 balanceBefore = METADEX.balanceOf(alice);

        uint256 quoteAmount = router.getQuoteForUSDC(100);
        console.logUint(quoteAmount);
        
        USDC.approve(address(router), 1000);
        METADEX.approve(address(router), 1000);
        USDC.approve(address(alice), 1000);
        METADEX.approve(address(alice), 1000);
        USDC.approve(address(pool), 1000);
        METADEX.approve(address(pool), 1000);
        METADEX.approve(address(swapRouter), 1000);
        USDC.approve(address(swapRouter), 1000);
        USDC.approve(address(this), 1000);
        METADEX.approve(address(this), 1000);
        
        uint256 amountOut = router.swapUSDCForMETADEX(100);
        uint256 balanceAfter = METADEX.balanceOf(alice);

        assertEq(amountOut, quoteAmount);
        assertEq(balanceAfter, balanceBefore + amountOut);

        vm.stopPrank();
    }

    function testSwapMETADEXForUSDCEqualAmountsAnd100Tokens() public {
        vm.startPrank(owner);
        router.activatePool();
        (address pool,) = router.createPool(address(USDC), address(METADEX), 1000, 1000);
        console.logUint(USDC.balanceOf(address(pool)));
        console.logUint(METADEX.balanceOf(address(pool)));
        vm.stopPrank();

        vm.startPrank(alice);
        uint256 balanceBefore = USDC.balanceOf(alice);

        uint256 quoteAmount = router.getQuoteForMETADEX(100);
        console.logUint(quoteAmount);
        
        USDC.approve(address(router), 1000);
        METADEX.approve(address(router), 1000);
        USDC.approve(address(alice), 1000);
        METADEX.approve(address(alice), 1000);
        USDC.approve(address(pool), 1000);
        METADEX.approve(address(pool), 1000);
        METADEX.approve(address(swapRouter), 1000);
        USDC.approve(address(swapRouter), 1000);
        USDC.approve(address(this), 1000);
        METADEX.approve(address(this), 1000);
        
        uint256 amountOut = router.swapMETADEXforUSDC(100);
        uint256 balanceAfter = USDC.balanceOf(alice);

        assertEq(amountOut, quoteAmount);
        assertEq(balanceAfter, balanceBefore + amountOut);

        vm.stopPrank();
    }

    function testSwapMETADEXForUSDCUnEqualAmountsAnd100Tokens() public {
        vm.startPrank(owner);
        router.activatePool();
        (address pool,) = router.createPool(address(USDC), address(METADEX), 4000, 1000);
        console.logUint(USDC.balanceOf(address(pool)));
        console.logUint(METADEX.balanceOf(address(pool)));
        vm.stopPrank();

        vm.startPrank(alice);
        uint256 balanceBefore = USDC.balanceOf(alice);

        uint256 quoteAmount = router.getQuoteForMETADEX(100);
        console.logUint(quoteAmount);
        
        USDC.approve(address(router), 1000);
        METADEX.approve(address(router), 1000);
        USDC.approve(address(alice), 1000);
        METADEX.approve(address(alice), 1000);
        USDC.approve(address(pool), 1000);
        METADEX.approve(address(pool), 1000);
        METADEX.approve(address(swapRouter), 1000);
        USDC.approve(address(swapRouter), 1000);
        USDC.approve(address(this), 1000);
        METADEX.approve(address(this), 1000);
        
        uint256 amountOut = router.swapMETADEXforUSDC(100);
        uint256 balanceAfter = USDC.balanceOf(alice);

        assertEq(amountOut, quoteAmount);
        assertEq(balanceAfter, balanceBefore + amountOut);

        vm.stopPrank();
    }

    function testIncreaseLiquidity() public {

        (address pool, uint256 tokenId) = router.createPool(address(USDC), address(METADEX), 2200, 2000);

        vm.startPrank(alice);
    
        TransferHelper.safeApprove(address(USDC), address(router), 100000);
        TransferHelper.safeApprove(address(METADEX), address(router), 100000);

        console.log("-----balance before increase-----");
        console.logUint(USDC.balanceOf(address(pool)));
        console.logUint(METADEX.balanceOf(address(pool)));

        console.log("-----alice balance before increase-----");
        console.logUint(USDC.balanceOf(alice));
        console.logUint(METADEX.balanceOf(alice));

        assertEq(USDC.balanceOf(address(pool)), 2200);
        assertEq(METADEX.balanceOf(address(pool)), 2000);

        router.increaseLiquidityCurrentRange(tokenId, 500, 500);

        console.log("-----balance after increase-----");
        console.logUint(USDC.balanceOf(address(pool)));
        console.logUint(METADEX.balanceOf(address(pool)));

        assertEq(USDC.balanceOf(address(pool)), 2700);
        assertEq(METADEX.balanceOf(address(pool)), 2454);

        console.log("-----alice balance after increase-----");
        console.logUint(USDC.balanceOf(alice));
        console.logUint(METADEX.balanceOf(alice));
        
    }

    function testDecreaseLiquidity() public {
        
        (address pool, uint256 tokenId) = router.createPool(address(USDC), address(METADEX), 2000, 1000);
        
         vm.startPrank(alice);

        TransferHelper.safeApprove(address(USDC), address(router), 100000);
        TransferHelper.safeApprove(address(METADEX), address(router), 100000);

        console.log("-----pool balance before decrease-----");
        console.logUint(USDC.balanceOf(address(pool)));
        console.logUint(METADEX.balanceOf(address(pool)));

        assertEq(USDC.balanceOf(address(pool)), 2000);
        assertEq(METADEX.balanceOf(address(pool)), 1000);

        console.log("-----alice balance before decrease-----");
        console.logUint(USDC.balanceOf(alice));
        console.logUint(METADEX.balanceOf(alice));

        router.decreaseLiquidity(tokenId, 500);

        console.log("-----pool balance after decrease-----");
        console.logUint(USDC.balanceOf(address(pool)));
        console.logUint(METADEX.balanceOf(address(pool)));

        assertEq(USDC.balanceOf(address(pool)), 1292);
        assertEq(METADEX.balanceOf(address(pool)), 646);

        console.log("-----alice balance after decrease-----");
        console.logUint(USDC.balanceOf(alice));
        console.logUint(METADEX.balanceOf(alice));
        
    }
}