// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

interface IUniswapRouter2  {

  function setPoolFee(uint24 _fee) external;

  function pausePool() external;

  function activatePool() external;

  function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
  ) external returns (bytes4);

  function mintNewPosition()
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
  );

  function collectAllFees(uint256 tokenId) external returns (uint256 amount0, uint256 amount1);

  function increaseLiquidityCurrentRange(
        uint256 tokenId,
        uint256 amountAdd0,
        uint256 amountAdd1
    )
        external
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

  function decreaseLiquidity(uint256 tokenId, uint128 liquidity) external returns (uint amount0, uint amount1);

  function retrieveNFT(uint256 tokenId) external;

  function getQuoteForMETADEX(uint256 _amountIn) external returns(uint256 amountOut);

  function getQuoteForUSDC(uint256 _amountIn) external returns(uint256 amountOut);

  function createPool(address token0, address token1, uint256 amount0, uint256 amount1) external returns (address poolAddress);

  function swapUSDCForMETADEX(uint256 _amountIn) external returns (uint256 amountOut);

  function swapMETADEXforUSDC(uint256 _amountIn) external returns (uint256 amountOut);  

}