// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

/// @title Metadex Bonding Curve Interface
/// @author Linum Labs on behalf of Mainston

interface ICurve {
    // =================== OWNER FUNCTIONS =================== //

    function setNFTStage(string memory _nftStage) external;

    // function getNFTStage() external view returns (string memory stage);

    function pauseCurve() external;

    function activateCurve() external;

    // function getCurveStatus() external view returns (bool);

    function withdrawCollateral(uint256 _amount) external;

    function getMarketTransitionContractAddress()
        external
        view
        returns (address);

    // function getCurveParams()
    //     external
    //     view
    //     returns (
    //         int256 _maxThreshold,
    //         uint256 _timeOutPeriod,
    //         int256 _minThreshold,
    //         address _collateralAddress,
    //         address _tokenAddress,
    //         address _nftAddress,
    //         address _interactionContractAddress,
    //         address _curveFactoryAddress,
    //         int256 _tokensSold,
    //         bool _curveActive,
    //         bool _transitionConditionsMet,
    //         bool _transitioned
    //     );

    // =================== GETTER FUNCTIONS =================== //

    function getCollateralInstance()
        external
        view
        returns (address collateralInstance);

    function getTokensSold() external view returns (int256 sold);

    // function getPrice(int256 _amountTokens)
    //     external
    //     view
    //     returns (int256 price);

    // =================== GENERAL FUNCTIONS =================== //

    function buyMetadex(int256 _amountTokens)
        external
        returns (int256 amountUSDC, int256 amountMetadex);

    function sellMetadex(int256 _amountMetadex)
        external
        returns (int256, int256);
}
