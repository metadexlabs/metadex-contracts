// // SPDX-License-Identifier: MIT
// pragma solidity =0.8.15;
// pragma abicoder v2;

// import "../interfaces/IUniswapRouter.sol"; 
// import "./MarketTransition.sol";
// import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
// import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
// //import '@uniswap/v3-core/contracts/UniswapV3Factory.sol';
// import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
// import 'openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
// import '@uniswap/v3-periphery/contracts/SwapRouter.sol';
// import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
// import "@uniswap/v3-periphery/contracts/lens/Quoter.sol";
// import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
// import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol';

// import "openzeppelin/contracts/access/Ownable.sol";

// abstract contract UniswapRouter is IUniswapRouter, IUniswapV3Factory, SwapRouter, IERC721Receiver, Ownable {

//     //IUniswapV3Factory factory;

//     Quoter quoter = new Quoter(address(factory), 0x4c28f48448720e9000907BC2611F73022fdcE1fA);

//     INonfungiblePositionManager public immutable nonfungiblePositionManager;

//     SwapRouter public immutable swapRouter;

//     //IUniswapV3Factory factory; 
    
//     bool poolActive;

//     uint24 public poolFee;

//     address public USDC;

//     address public METADEX;

//     address marketTransitionContractAddress;

//     /// @notice Represents the deposit of an NFT
//     struct Deposit {
//         address owner;
//         uint128 liquidity;
//         address token0;
//         address token1;
//     }

//     /// @dev deposits[tokenId] => Deposit
//     mapping(uint256 => Deposit) public deposits;

//     modifier isActive() {
//         require(poolActive, "Liquidity Pool Paused");
//         _;
//     }
    
//     constructor(INonfungiblePositionManager _nonfungiblePositionManager,
//                 SwapRouter _swapRouter,
//                 address _USDC,
//                 address _METADEX,
//                 address _transitionContractAddress) {
//         swapRouter = _swapRouter;
//         poolActive = false;
//         nonfungiblePositionManager = _nonfungiblePositionManager;
//         poolFee = 3000;
//         USDC = _USDC;
//         METADEX = _METADEX;
//         marketTransitionContractAddress = _transitionContractAddress;
//     }

//     function setPoolFee(uint24 _fee) external onlyOwner {
//         poolFee = _fee;
//     }

//     function pausePool() external onlyOwner {
//         poolActive = false;
//     }

//     function activatePool() external onlyOwner {
//         poolActive = true;
//     }

//     // function getTokensToMint(address _transitionContractAddress) internal returns (int256) {
//     //     MarketTransition transition = MarketTransition(marketTransitionContractAddress);
//     //     transition.getTokenstoMint();
//     // }

//     function onERC721Received(
//         address operator,
//         address,
//         uint256 tokenId,
//         bytes calldata
//     ) external override returns (bytes4) {
//         // get position information
//         _createDeposit(operator, tokenId);
//         return this.onERC721Received.selector;
//     }

//     function _createDeposit(address owner, uint256 tokenId) internal {
//         (, , address token0, address token1, , , , uint128 liquidity, , , , ) =
//             nonfungiblePositionManager.positions(tokenId);

//         // set the owner and data for position
//         // operator is msg.sender
//         deposits[tokenId] = Deposit({owner: owner, liquidity: liquidity, token0: token0, token1: token1});
//     }

//     /// @notice Increases liquidity in the current range
//     /// @dev Pool must be initialized already to add liquidity
//     /// @param tokenId The id of the erc721 token
//     /// @param amount0 The amount to add of token0
//     /// @param amount1 The amount to add of token1
//     function increaseLiquidityCurrentRange(
//         uint256 tokenId,
//         uint256 amountAdd0,
//         uint256 amountAdd1
//     )
//         external
//         returns (
//             uint128 liquidity,
//             uint256 amount0,
//             uint256 amount1
//         )
//     {
//         INonfungiblePositionManager.IncreaseLiquidityParams memory params =
//             INonfungiblePositionManager.IncreaseLiquidityParams({
//                 tokenId: tokenId,
//                 amount0Desired: amountAdd0,
//                 amount1Desired: amountAdd1,
//                 amount0Min: 0,
//                 amount1Min: 0,
//                 deadline: block.timestamp
//             });

//         (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);
//     }

//     /// @notice A function that decreases the current liquidity by half. An example to show how to call the `decreaseLiquidity` function defined in periphery.
//     /// @param tokenId The id of the erc721 token
//     /// @return amount0 The amount received back in token0
//     /// @return amount1 The amount returned back in token1
//     function decreaseLiquidityInHalf(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
//         // caller must be the owner of the NFT
//         require(msg.sender == deposits[tokenId].owner, 'Not the owner');
//         // get liquidity data for tokenId
//         uint128 liquidity = deposits[tokenId].liquidity;
//         uint128 halfLiquidity = liquidity / 2;

//         // amount0Min and amount1Min are price slippage checks
//         // if the amount received after burning is not greater than these minimums, transaction will fail
//         INonfungiblePositionManager.DecreaseLiquidityParams memory params =
//             INonfungiblePositionManager.DecreaseLiquidityParams({
//                 tokenId: tokenId,
//                 liquidity: halfLiquidity,
//                 amount0Min: 0,
//                 amount1Min: 0,
//                 deadline: block.timestamp
//             });

//         (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);

//         //send liquidity back to owner
//         _sendToOwner(tokenId, amount0, amount1);
//     }

//     /// @notice Transfers funds to owner of NFT
//     /// @param tokenId The id of the erc721
//     /// @param amount0 The amount of token0
//     /// @param amount1 The amount of token1
//     function _sendToOwner(
//         uint256 tokenId,
//         uint256 amount0,
//         uint256 amount1
//     ) internal {
//         // get owner of contract
//         address owner = deposits[tokenId].owner;

//         address token0 = deposits[tokenId].token0;
//         address token1 = deposits[tokenId].token1;
//         // send collected fees to owner
//         TransferHelper.safeTransfer(token0, owner, amount0);
//         TransferHelper.safeTransfer(token1, owner, amount1);
//     }

//     /// @notice Transfers the NFT to the owner
//     /// @param tokenId The id of the erc721
//     function retrieveNFT(uint256 tokenId) external {
//         // must be the owner of the NFT
//         require(msg.sender == deposits[tokenId].owner, 'Not the owner');
//         // transfer ownership to original owner
//         nonfungiblePositionManager.safeTransferFrom(address(this), msg.sender, tokenId);
//         //remove information related to tokenId
//         delete deposits[tokenId];
//     }

//     /// @notice Collects the fees associated with provided liquidity
//     /// @dev The contract must hold the erc721 token before it can collect fees
//     /// @param tokenId The id of the erc721 token
//     /// @return amount0 The amount of fees collected in token0
//     /// @return amount1 The amount of fees collected in token1
//     function collectAllFees(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
//         // Caller must own the ERC721 position, meaning it must be a deposit

//         // set amount0Max and amount1Max to uint256.max to collect all fees
//         // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
//         INonfungiblePositionManager.CollectParams memory params =
//             INonfungiblePositionManager.CollectParams({
//                 tokenId: tokenId,
//                 recipient: address(this),
//                 amount0Max: type(uint128).max,
//                 amount1Max: type(uint128).max
//             });

//         (amount0, amount1) = nonfungiblePositionManager.collect(params);

//         // send collected feed back to owner
//         _sendToOwner(tokenId, amount0, amount1);
//     } 

//     // function mintNewPosition(address _tokenA, address _tokenB, uint256 _amountTokenA, uint256 _amountTokenB)
//     //     external
//     //     returns (
//     //         uint256 tokenId,
//     //         uint128 liquidity,
//     //         uint256 amount0,
//     //         uint256 amount1
//     //     )
//     // {

//     //     // Approve the position manager
//     //     TransferHelper.safeApprove(_tokenA, address(nonfungiblePositionManager), _amountTokenA);
//     //     TransferHelper.safeApprove(_tokenB, address(nonfungiblePositionManager), _amountTokenB);

//     //     INonfungiblePositionManager.MintParams memory params =
//     //         INonfungiblePositionManager.MintParams({
//     //             token0: _tokenA,
//     //             token1: _tokenB,
//     //             fee: 3000,
//     //             tickLower: TickMath.MIN_TICK,
//     //             tickUpper: TickMath.MAX_TICK,
//     //             amount0Desired: _amountTokenA,
//     //             amount1Desired: _amountTokenB,
//     //             amount0Min: 0,
//     //             amount1Min: 0,
//     //             recipient: address(this),
//     //             deadline: block.timestamp
//     //         });

//     //     // Note that the pool defined by DAI/USDC and fee tier 0.3% must already be created and initialized in order to mint
//     //     (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);

//     //     // Create a deposit
//     //     _createDeposit(msg.sender, tokenId);

//     //     // Remove allowance and refund in both assets.
//     //     if (amount0 < amount0ToMint) {
//     //         TransferHelper.safeApprove(_tokenA, address(nonfungiblePositionManager), 0);
//     //         uint256 refund0 = _amountTokenA - amount0;
//     //         TransferHelper.safeTransfer(_tokenA, msg.sender, refund0);
//     //     }

//     //     if (amount1 < amount1ToMint) {
//     //         TransferHelper.safeApprove(_tokenB, address(nonfungiblePositionManager), 0);
//     //         uint256 refund1 = _amountTokenB - amount1;
//     //         TransferHelper.safeTransfer(_tokenB, msg.sender, refund1);
//     //     }
//     // }

//     function createUniswapPool(address _tokenA, address _tokenB, uint24 _fee) public view onlyOwner returns(address) {
//         address poolAddress = factory.createPool(_tokenA, _tokenB, _fee);
//         return poolAddress;
//     }

//     function getQuoteForMETADEX(uint256 _amountIn) external isActive returns(uint256 amountOut) {
//         amountOut = quoter.quoteExactInputSingle(
//             address(METADEX),
//             address(USDC),
//             poolFee,
//             _amountIn,
//             0);
//     }

//     function getQuoteForUSDC(uint256 _amountIn) external isActive returns(uint256 amountOut) {
//         amountOut = quoter.quoteExactInputSingle(
//             address(USDC),
//             address(METADEX),
//             poolFee,
//             _amountIn,
//             0);
//     }

//     /// @notice Swaps a fixed amount of USDC for a maximum possible amount of METADEX
//     /// using the USDC/METADEX 0.3% pool by calling `exactInputSingle` in the swap router.
//     /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its USDC for this function to succeed.
//     /// @param amountIn The exact amount of USDC that will be swapped for METADEX.
//     /// @return amountOut The amount of METADEX received.
//     function swapUSDCForMETADEX(uint256 amountIn) external isActive returns (uint256 amountOut) {
//         // msg.sender must approve this contract

//         // Transfer the specified amount of USDC to this contract.
//         TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), amountIn);

//         // Approve the router to spend USDC.
//         TransferHelper.safeApprove(USDC, address(swapRouter), amountIn);

//         // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
//         // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
//         ISwapRouter.ExactInputSingleParams memory params =
//             ISwapRouter.ExactInputSingleParams({
//                 tokenIn: USDC,
//                 tokenOut: METADEX,
//                 fee: poolFee,
//                 recipient: msg.sender,
//                 deadline: block.timestamp,
//                 amountIn: amountIn,
//                 amountOutMinimum: 0,
//                 sqrtPriceLimitX96: 0
//             });

//         // The call to `exactInputSingle` executes the swap.
//         amountOut = swapRouter.exactInputSingle(params);
//     }

//     /// @notice Swaps a fixed amount of METADEX for a maximum possible amount of USDC
//     /// using the USDC/METADEX 0.3% pool by calling `exactInputSingle` in the swap router.
//     /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its METADEX for this function to succeed.
//     /// @param amountIn The exact amount of METADEX that will be swapped for USDC.
//     /// @return amountOut The amount of USDC received.
//     function swapMETADEXForUSDC(uint256 amountIn) external isActive returns (uint256 amountOut) {
//         // msg.sender must approve this contract

//         // Transfer the specified amount of METADEX to this contract.
//         TransferHelper.safeTransferFrom(METADEX, msg.sender, address(this), amountIn);

//         // Approve the router to spend METADEX.
//         TransferHelper.safeApprove(METADEX, address(swapRouter), amountIn);

//         // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
//         // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
//         ISwapRouter.ExactInputSingleParams memory params =
//             ISwapRouter.ExactInputSingleParams({
//                 tokenIn: METADEX,
//                 tokenOut: USDC,
//                 fee: poolFee,
//                 recipient: msg.sender,
//                 deadline: block.timestamp,
//                 amountIn: amountIn,
//                 amountOutMinimum: 0,
//                 sqrtPriceLimitX96: 0
//             });

//         // The call to `exactInputSingle` executes the swap.
//         amountOut = swapRouter.exactInputSingle(params);
//     }



//     // function createPool(address token0, address token1, uint256 amount0, uint256 amount1) public {
//     //     if (token0 > token1) {
//     //         address tmp = token0;
//     //         token0 = token1;
//     //         token1 = tmp;
//     //     }

//     //     address pool = nft.createAndInitializePoolIfNecessary(token0, token1, FEE_MEDIUM, encodePriceSqrt(1, 1));

//     //     weth.approve(pool, amount1);
//     //     INonfungiblePositionManager.MintParams memory params =
//     //         INonfungiblePositionManager.MintParams({
//     //                 token0: token0,
//     //                 token1: token1,
//     //                 fee: FEE_MEDIUM,
//     //                 tickLower: getMinTick(TICK_MEDIUM),
//     //                 tickUpper: getMaxTick(TICK_MEDIUM),
//     //                 amount0Desired: amount0,
//     //                 amount1Desired: amount1,
//     //                 amount0Min: 0,
//     //                 amount1Min: 0,
//     //                 recipient: address(account0),
//     //                 deadline: block.timestamp + 10
//     //             });

//     //     TransferHelper.safeApprove(token0, pool, 100000);
//     //     TransferHelper.safeApprove(token1, pool, 100000);

//     //     TransferHelper.safeApprove(token0, address(nft), 100000);
//     //     TransferHelper.safeApprove(token1, address(nft), 100000);
//     //     // Note Call this when the pool does exist and is initialized. 
//     //     // Note that if the pool is created but not initialized a method does not exist, i.e. the pool is assumed to be initialized.
//     //     // Note that the pool defined by token_A/token_B and fee tier 0.3% must already be created and initialized in order to mint
//     //     nft.mint(params);

//     // } 

// }
