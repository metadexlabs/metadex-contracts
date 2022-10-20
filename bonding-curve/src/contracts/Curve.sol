// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import "../interfaces/ICurve.sol";
import "../interfaces/IGetPrice.sol";
import "../interfaces/ICurveFactory.sol";

import "../contracts/Interaction.sol";
import "../contracts/MockMETADEX.sol";
import "../contracts/MarketTransition.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@prb-math/PRBMathSD59x18.sol";

import {console} from "forge-std/console.sol";

/// @title Metadex Token Bonding Curve
/// @author Linum Labs, on behalf of Mainston

/// @dev Token Vesting Contract needs to transfer ownership to the
//  Implementation Contract in order to create the vestingScedule

contract Curve is ICurve, Ownable, ReentrancyGuard {
    using PRBMathSD59x18 for int256;

    // =================== VARIABLES =================== //

    ICurveFactory curveFactory;

    int256 maxThreshold;
    int256 minThreshold;
    uint256 timeoutPeriod;
    uint256 timeoutPeriodExpiry;

    int256 tokensSold;

    uint256 private immutable BLACK_NFT_ID =
        17070672852597023074941515922167015879142834870116410379570272617131629609011;
    uint256 private immutable GOLD_NFT_ID =
        17070672852597023074941515922167015879142834870116410379570272618231141236936;
    uint256 private immutable SILVER_NFT_ID =
        17070672852597023074941515922167015879142834870116410379570272619330652874511;

    bool public curveActive;

    bool public transitionConditionsMet;
    bool public transitioned;

    address marketTransitionContractAddress;
    address interactionContractAddress;
    address tokenVestingAddress;
    address curveFactoryAddress;
    address uniswapRouterAddress;

    address daoAddress;
    address treasuryAddress;

    IERC20 USDC;
    MockMETADEX metadex;
    IERC1155 NFT;

    IGetPrice getPriceContract;

    Interaction interaction;
    MarketTransition transition;

    struct NFTStage {
        bool black;
        bool gold;
        bool silver;
        bool none;
    }

    NFTStage public nftStage;
    string public currentNFTStage;

    // =================== EVENTS =================== //

    event NFTStageSet(string currentNFTStage, uint256 time);
    event CurvePaused(address pauser, uint256 time);
    event CurveActivated(address pauser, uint256 time);
    event CollateralWithdrawn(address drawer, uint256 time);
    event MetadexBought(int256 amountBought, address Buyer, uint256 timestamp);
    event MetadexSold(int256 amountSold, address Seller, uint256 timestamp);

    // =================== ERRORS ====================== //
    error Paused();
    error IncorrectInput();
    error NoZeroWithdrawals();
    error InsufficientFunds();
    error CannotBuyZero();
    error CannotSellZero();
    error TokensNotAvailable();
    error NoMetadex();

    // =================== MODIFIERS =================== //

    modifier isActive() {
        if (curveActive == false) revert Paused();
        _;
    }

    /// @notice Checks if a user is whitelisted for the current sale round
    /// @dev Gets the currentNFTStage and checks if the user has a balance of the correcponding NFT in their wallet
    modifier isEligible() {
        if (keccak256(bytes(currentNFTStage)) == keccak256(bytes("Black"))) {
            require(NFT.balanceOf(msg.sender, BLACK_NFT_ID) > 0, "NFTRequired");
            _;
        }
        if (keccak256(bytes(currentNFTStage)) == keccak256(bytes("Gold"))) {
            require(
                NFT.balanceOf(msg.sender, BLACK_NFT_ID) > 0 ||
                    NFT.balanceOf(msg.sender, GOLD_NFT_ID) > 0,
                "NFTRequired"
            );
            _;
        }
        if (keccak256(bytes(currentNFTStage)) == keccak256(bytes("Silver"))) {
            require(
                NFT.balanceOf(msg.sender, BLACK_NFT_ID) > 0 ||
                    NFT.balanceOf(msg.sender, GOLD_NFT_ID) > 0 ||
                    NFT.balanceOf(msg.sender, SILVER_NFT_ID) > 0,
                "NFTRequired"
            );
            _;
        }
        if (keccak256(bytes(currentNFTStage)) == keccak256(bytes("None"))) {
            _;
        }
    }

    // =================== CONSTRUCTOR =================== //

    constructor(
        address _collateralAddress,
        address _tokenAddress,
        address _nftAddress,
        address _interactionContractAddress,
        address _curveFactoryAddress,
        address _daoAddress,
        address _treasuryAddress,
        address _uniswapRouter,
        address _getPrice
    ) {
        curveFactory = ICurveFactory(_curveFactoryAddress);

        maxThreshold = 20000000;
        minThreshold = 5000000;
        timeoutPeriod = 150 days;

        tokensSold = 0;

        timeoutPeriodExpiry = block.timestamp + timeoutPeriod;

        daoAddress = _daoAddress;
        treasuryAddress = _treasuryAddress;
        uniswapRouterAddress = _uniswapRouter;

        USDC = IERC20(_collateralAddress);
        metadex = MockMETADEX(_tokenAddress);

        NFT = IERC1155(_nftAddress);

        getPriceContract = IGetPrice(_getPrice);

        interactionContractAddress = _interactionContractAddress;
        interaction = Interaction(interactionContractAddress);

        curveActive = false;
        transitionConditionsMet = false;
        transitioned = false;

        nftStage = NFTStage(true, false, false, false);

        currentNFTStage = "Black";
    }

    // =================== OWNER FUNCTIONS =================== //

    /// @notice sets the NFTStage - Users who have a balance of the NFT that is set are able to buy MetaDex
    /// @dev sets NFTStage struct to input string value by making the corresponding bool true
    function setNFTStage(string memory _nftStage) external onlyOwner {
        if (
            // keccak256(bytes(_nftStage)) == keccak256(bytes("Black")) ||
            keccak256(bytes(_nftStage)) == keccak256(bytes("BLACK"))
            // keccak256(bytes(_nftStage)) == keccak256(bytes("black"))
        ) {
            currentNFTStage = "Black";
            nftStage.black = true;
        } else if (
            // keccak256(bytes(_nftStage)) == keccak256(bytes("Gold")) ||
            keccak256(bytes(_nftStage)) == keccak256(bytes("GOLD"))
            // keccak256(bytes(_nftStage)) == keccak256(bytes("gold"))
        ) {
            currentNFTStage = "Gold";
            nftStage.black = true;
            nftStage.gold = true;
        } else if (
            // keccak256(bytes(_nftStage)) == keccak256(bytes("Silver")) ||
            keccak256(bytes(_nftStage)) == keccak256(bytes("SILVER"))
            // keccak256(bytes(_nftStage)) == keccak256(bytes("silver"))
        ) {
            currentNFTStage = "Silver";
            nftStage.black = true;
            nftStage.gold = true;
            nftStage.silver = true;
        } else if (
            // keccak256(bytes(_nftStage)) == keccak256(bytes("None")) ||
            keccak256(bytes(_nftStage)) == keccak256(bytes("NONE"))
            // keccak256(bytes(_nftStage)) == keccak256(bytes("none"))
        ) {
            currentNFTStage = "None";
            nftStage.black = true;
            nftStage.gold = true;
            nftStage.silver = true;
            nftStage.none = true;
        } else {
            revert IncorrectInput();
        }

        emit NFTStageSet(currentNFTStage, block.timestamp);
    }

    function pauseCurve() external {
        marketTransitionContractAddress = curveFactory.getMarketAddress(
            address(this)
        );
        require(
            msg.sender == marketTransitionContractAddress ||
                msg.sender == owner(),
            "Access Denied"
        );

        curveActive = false;

        emit CurvePaused(msg.sender, block.timestamp);
    }

    function activateCurve() external onlyOwner {
        curveActive = true;
        emit CurveActivated(msg.sender, block.timestamp);
    }

    function withdrawCollateral(uint256 _amount) public onlyOwner {
        if (_amount <= 0) revert NoZeroWithdrawals();
        if (_amount > USDC.balanceOf(address(this))) revert InsufficientFunds();
        address owner = owner();
        USDC.transfer(owner, _amount);

        emit CollateralWithdrawn(owner, _amount);
    }

    // =================== VIEW FUNCTIONS =================== //

    // function getCurveStatus() public view returns (bool) {
    //     return curveActive;
    // }

    // function getNFTStage() public view returns (string memory stage) {
    //     stage = currentNFTStage;
    // }

    function getMarketTransitionContractAddress()
        public
        view
        returns (address)
    {
        return curveFactory.getMarketAddress(address(this));
    }

    function getTokensSold() public view returns (int256 sold) {
        sold = tokensSold;
    }

    function getCollateralInstance() public view returns (address) {
        return address(USDC);
    }

    // function getCurveParams()
    //     public
    //     view
    //     returns (
    //         int256,
    //         uint256,
    //         int256,
    //         address,
    //         address,
    //         address,
    //         address,
    //         address,
    //         int256,
    //         bool,
    //         bool,
    //         bool
    //     )
    // {
    //     return (
    //         maxThreshold,
    //         timeoutPeriod,
    //         minThreshold,
    //         address(USDC),
    //         address(metadex),
    //         address(NFT),
    //         interactionContractAddress,
    //         address(curveFactory),
    //         tokensSold,
    //         curveActive,
    //         transitionConditionsMet,
    //         transitioned
    //     );
    // }

    // =================== GENERAL FUNCTIONS =================== //

    /// @notice 'Buys' Metadex on behalf of user, if the curve is active and the user is eligible (either has correct NFT or there is no NFT set)
    /// @dev Calculates the price in USDC by calling getPrice(), then:
    /// -> Transfers this amount from the user to the Curve contract.
    /// -> 3% of the USDC is sent to the Treasury address.
    /// -> 2% of the USDC is sent to the DAO address.
    /// -> Calls mintAndVestTokens() for msg.sender, minting the input amount.
    /// -> 10% of the tokens minted are available for the user to immediately redeem from the vesting contract.
    /// -> Checks if the transition conditions have been met.
    /// -> If they are met, approves the transition contract.
    /// -> Approves the UniswapRouter to transfer the Curves balance of collateral funds.
    /// -> Calls transition() in the transition contract.
    /// @param _amountTokens - The amount of Metadex the user would like to buy.
    /// @return amountUSDC - The amount of USDC spent by the user.
    /// @return amountMetadex - The amount of Metadex minted on behalf of user.
    function buyMetadex(int256 _amountTokens)
        public
        isEligible
        isActive
        returns (int256 amountUSDC, int256 amountMetadex)
    {
        if (_amountTokens <= 0) revert CannotBuyZero();

        address forTransition = curveFactory.getMarketAddress(address(this));
        transition = MarketTransition(forTransition);

        amountUSDC = getPriceContract.getPrice(_amountTokens);
        amountMetadex = _amountTokens * 1e18;

        int256 amountDAO = PRBMathSD59x18.mul(
            PRBMathSD59x18.div(2 * 1e18, 100e18),
            amountUSDC
        );

        int256 amountTreasury = PRBMathSD59x18.mul(
            PRBMathSD59x18.div(3 * 1e18, 100e18),
            amountUSDC
        );

        int256 curveAmount = amountUSDC - amountDAO - amountTreasury;

        USDC.transferFrom(msg.sender, address(this), uint256(curveAmount));
        USDC.transferFrom(msg.sender, daoAddress, uint256(amountDAO));
        USDC.transferFrom(msg.sender, treasuryAddress, uint256(amountTreasury));

        interaction.mintAndCreateVesting(msg.sender, uint256(amountMetadex));

        tokensSold += (amountMetadex / 1e18);

        if (tokensSold == maxThreshold) {
            transitionConditionsMet = true;

            USDC.approve(address(transition), USDC.balanceOf(address(this)));
            USDC.approve(
                uniswapRouterAddress,
                USDC.balanceOf(address(this))
            );

            USDC.transfer(uniswapRouterAddress, USDC.balanceOf(address(this)));

            transition.transition(address(this));
            transitioned = true;
            
        } else if (
            block.timestamp >= timeoutPeriodExpiry && tokensSold >= 5000000
        ) {
            transitionConditionsMet = true;

            USDC.approve(address(transition), USDC.balanceOf(address(this)));
            USDC.approve(
                uniswapRouterAddress,
                USDC.balanceOf(address(this))
            );

            USDC.transfer(uniswapRouterAddress, USDC.balanceOf(address(this)));

            transition.transition(address(this));
            transitioned = true;
        }

        emit MetadexBought(_amountTokens, msg.sender, block.timestamp);
       
    }

    function sellMetadex(int256 _amountMetadex)
        public
        isActive
        returns (int256, int256)
    {
        if (_amountMetadex <= 0) revert CannotSellZero();
        if (tokensSold == 0) revert TokensNotAvailable();
        if (metadex.balanceOf(msg.sender) == 0) revert NoMetadex();

        tokensSold -= _amountMetadex;

        int256 amountTokens = _amountMetadex * 1e18;

        int256 sellPrice = getPriceContract.getPrice(_amountMetadex);

        int256 amountDAO = PRBMathSD59x18.mul(
            PRBMathSD59x18.div(2 * 1e18, 100e18),
            sellPrice
        );

        int256 amountTreasury = PRBMathSD59x18.mul(
            PRBMathSD59x18.div(3 * 1e18, 100e18),
            sellPrice
        );

        int256 fee = amountDAO + amountTreasury;
        int256 userSalePrice = sellPrice - fee;

        USDC.transfer(msg.sender, uint256(userSalePrice));
        USDC.transfer(daoAddress, uint256(amountDAO));
        USDC.transfer(treasuryAddress, uint256(amountTreasury));

        metadex.burnFrom(msg.sender, uint256(amountTokens));

        emit MetadexSold(_amountMetadex, msg.sender, block.timestamp);

        return (sellPrice, userSalePrice);
    }
}
