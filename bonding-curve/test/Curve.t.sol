// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "../src/interfaces/ICurve.sol";
import "../src/interfaces/IMarketTransition.sol";
import "../src/contracts/CurveFactory.sol";
import "../src/contracts/Curve.sol";
import "../src/contracts/MockUSDC.sol";
import "../src/contracts/MockMETADEX.sol";
import "../src/contracts/TokenVesting.sol";
import "../src/contracts/GetPrice.sol";
import "../src/contracts/UniswapRouter2.sol";
import "../src/contracts/Interaction.sol";
import "../src/contracts/TokenVesting.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

//import "@prb-math/PRBMathUD60x18.sol";
import "@prb-math/PRBMathSD59x18.sol";

import {console} from "forge-std/console.sol";

contract CurveTest is Test {
    Curve public curve;
    IMarketTransition public marketTransition;
    CurveFactory public curveFactory;
    MockUSDC USDC;
    GetPrice getPriceContract;
    Interaction interaction;
    TokenVesting vestingContract;
    INonfungiblePositionManager public manager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    MockMETADEX metadex;
    NFT nft;
    UniswapRouter2 router;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;

    address internal constant account1 = address(0xACC1);
    address internal constant account2 = address(0xACC2);

    address alice = vm.addr(3);
    address bob = vm.addr(4);
    address chad = vm.addr(5);

    address daoAddress = vm.addr(6);
    address treasuryAddress = vm.addr(7);

    uint256 private immutable BLACK_NFT_ID =
        17070672852597023074941515922167015879142834870116410379570272617131629609011;
    uint256 private immutable GOLD_NFT_ID =
        17070672852597023074941515922167015879142834870116410379570272618231141236936;
    uint256 private immutable SILVER_NFT_ID =
        17070672852597023074941515922167015879142834870116410379570272619330652874511;

    event CollateralWithdrawn(address, uint256);
    event CurvePaused(address pauser, uint256 time);
    event CurveActivated(address owner, uint256 timestamp);
    event MetadexBought(int256 amountBought, address Buyer, uint256 timestamp);
    event MetadexSold(int256 amountSold, address Seller, uint256 timestamp);

    function setUp() public {
        USDC = new MockUSDC();
        metadex = new MockMETADEX();
        nft = new NFT();
        router = new UniswapRouter2(manager, address(USDC), address(metadex));
        interaction = new Interaction();
        vestingContract = new TokenVesting(address(metadex));
        curveFactory = new CurveFactory(address(router));
        getPriceContract = new GetPrice();

        vm.prank(owner);

        address[2] memory curveAddresses = curveFactory.createBondingCurve(
            address(USDC),
            address(metadex),
            address(nft),
            address(interaction),
            address(curveFactory),
            daoAddress,
            treasuryAddress,
            address(router),
            address(getPriceContract)
        );

        curve = Curve(curveAddresses[0]);
        marketTransition = IMarketTransition(curveAddresses[1]);

        getPriceContract.setCurveAddress(curveAddresses[0]);

        vm.startPrank(owner);
        interaction.setAddr(
            address(metadex),
            address(vestingContract),
            address(curve)
        );

        metadex.grantRole(MINTER_ROLE, address(interaction));

        vestingContract.transferOwnership(address(interaction));

        USDC.mint(address(curve), 1000 * 1e18);

        USDC.approve(address(curve), 10000e18);
        USDC.mint(address(this), 1000000 * 1e18);
        USDC.mint(alice, 30000000 * 1e18);
        USDC.mint(bob, 1000e18);
        USDC.mint(chad, 1000e18);

        vm.stopPrank();
    }

    // =================== PAUSE CURVE TESTS ================= //

    function testCurveIsPausedOnDeployment() public {
        assertEq(curve.curveActive(), false);

        vm.prank(owner);
        curve.activateCurve();

        assertEq(curve.curveActive(), true);
    }

    function testOnlyOwnerCanActivateCurve() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        curve.activateCurve();
    }

    // =================== NFT STAGE TESTS =================== //

    function testSetNFTStage() public {
        vm.startPrank(owner);
        curve.activateCurve();
        curve.setNFTStage("BLACK");
        string memory stage = curve.currentNFTStage();
        assertEq(stage, "Black");
        curve.setNFTStage("GOLD");
        stage = curve.currentNFTStage();
        assertEq(stage, "Gold");
        vm.stopPrank();
    }

    function testSetNFTStageFailNotOwner() public {
        vm.prank(account1);
        vm.expectRevert("Ownable: caller is not the owner");
        curve.setNFTStage("NONE");
        vm.stopPrank();
    }

    function testSetNFTStageFailInvalidInput() public {
        vm.prank(owner);
        vm.expectRevert(Curve.IncorrectInput.selector);

        curve.setNFTStage("White");
    }

    function testSetNFTStageFailFuzz(string memory _string) public {
        vm.assume(
            keccak256(bytes(_string)) != keccak256(bytes("BLACK")) &&
                keccak256(bytes(_string)) != keccak256(bytes("GOLD")) &&
                keccak256(bytes(_string)) != keccak256(bytes("SILVER")) &&
                keccak256(bytes(_string)) != keccak256(bytes("NONE"))
        );
        vm.startPrank(owner);
        vm.expectRevert(Curve.IncorrectInput.selector);
        curve.setNFTStage(_string);
    }

    // =================== WITHDRAW TESTS =================== //

    function testWithdrawCollateral() public {
        uint256 ownerBal = USDC.balanceOf(owner);
        uint256 curveBal = USDC.balanceOf(address(curve));

        assertEq(ownerBal, 1000000e18);
        assertEq(curveBal, 1000e18);

        curve.withdrawCollateral(500e18);

        ownerBal = USDC.balanceOf(owner);
        curveBal = USDC.balanceOf(address(curve));

        assertEq(ownerBal, 1000500e18);
        assertEq(curveBal, 500e18);
    }

    function testWithdrawCollateralGreaterThanBalance() public {
        vm.expectRevert(Curve.InsufficientFunds.selector);
        curve.withdrawCollateral(2000e18);
    }

    function testWithdrawZeroCollateral() public {
        vm.expectRevert(Curve.NoZeroWithdrawals.selector);
        curve.withdrawCollateral(0);
    }

    function testEmitCollateralWithdrawn() public {
        vm.expectEmit(false, false, false, true);
        emit CollateralWithdrawn(owner, 500e18);
        curve.withdrawCollateral(500e18);
    }

    function testFuzzWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0 && _amount <= 1000e18);

        uint256 ownerBalBefore = USDC.balanceOf(owner);
        uint256 curveBalBefore = USDC.balanceOf(address(curve));

        assertEq(ownerBalBefore, 1000000e18);
        assertEq(curveBalBefore, 1000e18);

        curve.withdrawCollateral(_amount);

        uint256 ownerBalAfter = USDC.balanceOf(owner);
        uint256 curveBalAfter = USDC.balanceOf(address(curve));

        assertEq(ownerBalAfter, ownerBalBefore + _amount);
        assertEq(curveBalAfter, curveBalBefore - _amount);
    }

    // =================== ELIGABILITY TESTS =================== //

    function testIsEligibleNoNFT() public {
        curve.setNFTStage("BLACK");
        curve.activateCurve();
        vm.startPrank(alice);
        int256 price = getPriceContract.getPrice(1);
        USDC.approve(address(curve), uint256(price));

        vm.expectRevert("NFTRequired");
        curve.buyMetadex(1);

        vm.stopPrank();
    }

    function testIsEligibleBlackNft() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("BLACK");
        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(1);
        USDC.approve(address(curve), uint256(price));

        vm.expectRevert("NFTRequired");
        curve.buyMetadex(1);

        nft.mint(alice, BLACK_NFT_ID, 1, "0x");

        curve.buyMetadex(1);
        vm.stopPrank();
    }

    function testIsEligibleBlackAndGoldNft() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("GOLD");
        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(1);
        USDC.approve(address(curve), uint256(price));

        vm.expectRevert("NFTRequired");
        curve.buyMetadex(1);

        nft.mint(alice, BLACK_NFT_ID, 1, "0x");
        curve.buyMetadex(1);
        vm.stopPrank();

        vm.startPrank(bob);

        price = getPriceContract.getPrice(1);

        USDC.approve(address(curve), uint256(price));

        vm.expectRevert("NFTRequired");
        curve.buyMetadex(1);

        nft.mint(bob, GOLD_NFT_ID, 1, "0x");

        curve.buyMetadex(1);

        vm.stopPrank();
    }

    function testIsEligibleBlackGoldAndSilverNft() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("SILVER");
        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(1);
        USDC.approve(address(curve), uint256(price));

        vm.expectRevert("NFTRequired");
        curve.buyMetadex(1);

        nft.mint(alice, BLACK_NFT_ID, 1, "0x");
        curve.buyMetadex(1);

        vm.stopPrank();
        vm.startPrank(bob);

        price = getPriceContract.getPrice(1);

        USDC.approve(address(curve), uint256(price));

        vm.expectRevert("NFTRequired");
        curve.buyMetadex(1);

        nft.mint(bob, GOLD_NFT_ID, 1, "0x");
        curve.buyMetadex(1);

        vm.stopPrank();
        vm.startPrank(chad);

        price = getPriceContract.getPrice(1);

        USDC.approve(address(curve), uint256(price));

        vm.expectRevert("NFTRequired");
        curve.buyMetadex(1);

        nft.mint(chad, SILVER_NFT_ID, 1, "0x");
        curve.buyMetadex(1);

        vm.stopPrank();
    }

    function testIsEligibleAll() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");

        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(1);
        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(1);
        vm.stopPrank();

        vm.startPrank(bob);
        price = getPriceContract.getPrice(1);

        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(1);
        vm.stopPrank();
    }

    // =================== GET PARAMS TESTS =================== //

    // function testGetCurveParams() public {
    //     vm.startPrank(owner);

    //     (
    //         int256 max,
    //         uint256 period,
    //         int256 min,
    //         address collateral,
    //         address token,
    //         address nftAddress,
    //         address interactionAddress,
    //         address factory,
    //         int256 sold,
    //         bool active,
    //         bool conditions,
    //         bool transitioned
    //     ) = curve.getCurveParams();

    //     assertEq(max, 20000000);
    //     assertEq(period, 150 days);
    //     assertEq(min, 5000000);
    //     assertEq(collateral, address(USDC));
    //     assertEq(token, address(metadex));
    //     assertEq(nftAddress, address(nft));
    //     assertEq(interactionAddress, address(interaction));
    //     assertEq(factory, address(curveFactory));
    //     assertEq(sold, 0);
    //     assertEq(active, false);
    //     assertEq(conditions, false);
    //     assertEq(transitioned, false);

    //     vm.stopPrank();
    // }

    // =================== GET PRICE TESTS =================== //

    function testGetPriceFirstToken() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();
        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1), 100000000000000000);
        vm.stopPrank();
    }

    function testGetPriceFirst2000Tokens() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(2000), 200000000000000000000);
        vm.stopPrank();
    }

    function testGetPriceBetweenFirstSet() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 1999999 * 1e18);
        curve.buyMetadex(1999999);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(500), 50000830003333333334);
        vm.stopPrank();
    }

    function testGetPriceAbove2Million() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 2000000 * 1e18);
        curve.buyMetadex(2000000);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(499), 49900830003333333334);
        vm.stopPrank();
    }

    function testGetPriceAbove2MillionOneToken() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 999998 * 1e18);
        curve.buyMetadex(2999998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1), 106666656666666666);
        vm.stopPrank();
    }

    function testGetPriceBetweenSecondSet() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 2999998 * 1e18);
        curve.buyMetadex(2999998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(302), 32306666656666666666);
        vm.stopPrank();
    }

    function testGetPriceAbove3Million() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 3000000 * 1e18);
        curve.buyMetadex(3000000);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(300), 32200000000000000000);
        vm.stopPrank();
    }

    function testGetPriceAbove3MillionLast2Tokens() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 3499998 * 1e18);
        curve.buyMetadex(3499998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(2), 1218107777777777778);
        vm.stopPrank();
    }

    function testGetPriceBetweenThirdSet() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 3499998 * 1e18);
        curve.buyMetadex(3499998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1002), 124961794100716956537);
        vm.stopPrank();
    }

    function testGetPriceBelow4Million() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 3500000 * 1e18);
        curve.buyMetadex(3500000);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1000), 123743686322939178759);
        vm.stopPrank();
    }

    function testGetPriceBelow4MillionLast2Tokens() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 3999998 * 1e18);
        curve.buyMetadex(3999998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(2), 1665881691880209942);
        vm.stopPrank();
    }

    function testGetPriceBetweenFourthSet() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 3999998 * 1e18);
        curve.buyMetadex(3999998);

        vm.startPrank(alice);
        console.logInt(getPriceContract.getPrice(1002));
        assertEq(getPriceContract.getPrice(1002), 168482431808430326492);
        vm.stopPrank();
    }

    function testGetPriceAbove4Million() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 4000000 * 1e18);
        curve.buyMetadex(4000000);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1000), 166816550116550116550);
        vm.stopPrank();
    }

    function testGetPriceAbove4MillionLast2Tokens() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 4499998 * 1e18);
        curve.buyMetadex(4499998);

        vm.startPrank(alice);
        console.logInt(getPriceContract.getPrice(2));
        assertEq(getPriceContract.getPrice(2), 283249766899766900);
        vm.stopPrank();
    }

    function testGetPriceBetweenFifthSet() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 4500000 * 1e18);
        curve.buyMetadex(4499998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1002), 283738351807716093431);
        vm.stopPrank();
    }

    function testGetPriceABetween4And5Million() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 4500000 * 1e18);
        curve.buyMetadex(4500000);

        vm.startPrank(alice);
        console.logInt(getPriceContract.getPrice(1000));
        assertEq(getPriceContract.getPrice(1000), 283455102040816326531);
        vm.stopPrank();
    }

    function testGetPriceAbove4And5MillionLast2Tokens() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 5499998 * 1e18);
        curve.buyMetadex(5499998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(2), 793403316326530612);
        vm.stopPrank();
    }

    function testGetPriceBetweenSixthSet() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 5499998 * 1e18);
        curve.buyMetadex(5499998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1002), 794376553499476713763);
        vm.stopPrank();
    }

    function testGetPriceBelow6Million() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 5500000 * 1e18);
        curve.buyMetadex(5500000);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1000), 793583150183150183151);
        vm.stopPrank();
    }

    function testGetPriceBelow6MillionLast2Tokens() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 5999998 * 1e18);
        curve.buyMetadex(5999998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(2), 976549633699633700);
        vm.stopPrank();
    }

    function testGetPriceBetweenSeventhSet() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 5999998 * 1e18);
        curve.buyMetadex(5999998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1002), 978756230908600032106);
        vm.stopPrank();
    }

    function testGetPriceAbove6Million() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 6000000 * 1e18);
        curve.buyMetadex(6000000);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1000), 977779681274900398406);
        vm.stopPrank();
    }

    function testGetPriceAbove6MillionLastToken() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 6499998 * 1e18);
        curve.buyMetadex(6499998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1), 1057381035856573705);
        vm.stopPrank();
    }

    function testGetPriceBetweenEightSet() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 6499998 * 1e18);
        curve.buyMetadex(6499998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1002), 1058185952464428002276);
        vm.stopPrank();
    }

    function testGetPriceBelow7Million() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 6500000 * 1e18);
        curve.buyMetadex(6500000);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1000), 1057128571428571428571);
        vm.stopPrank();
    }

    function testGetPriceBelow7MillionLastTokens() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 6999998 * 1e18);
        curve.buyMetadex(6999998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(2), 1085671342857142858);
        vm.stopPrank();
    }

    function testGetPriceBetweenNinthSet() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 6999998 * 1e18);
        curve.buyMetadex(6999998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1002), 1087095671342857142858);
        vm.stopPrank();
    }

    function testGetPriceAbove7Million() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 7000000 * 1e18);
        curve.buyMetadex(7000000);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1000), 1086010000000000000000);
        vm.stopPrank();
    }

    function testGetPriceAbove7MillionLastTokens() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 7499998 * 1e18);
        curve.buyMetadex(7499998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(2), 1095999970000000000);
        vm.stopPrank();
    }

    function testGetPriceBetweenTenthSet() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 7499998 * 1e18);
        curve.buyMetadex(7499998);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1002), 1101095999970000000000);
        vm.stopPrank();
    }

    function testGetPriceRestOfCurve() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 7500000 * 1e18);
        curve.buyMetadex(7500000);

        vm.startPrank(alice);
        console.logInt(getPriceContract.getPrice(1000));
        assertEq(getPriceContract.getPrice(1000), 1100000000000000000000);
        vm.stopPrank();
    }

    function testGetPriceRestOfCurve2000Tokens() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 7500000 * 1e18);
        curve.buyMetadex(7500000);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(2000), 2200000000000000000000);
        vm.stopPrank();
    }

    function testGetPriceRestOfCurve1Token() public {
        USDC.mint(address(owner), 20000000 * 1e18);
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        USDC.approve(address(curve), 19999999 * 1e18);
        curve.buyMetadex(19999999);

        vm.startPrank(alice);
        assertEq(getPriceContract.getPrice(1), 1100000000000000000);
        vm.stopPrank();
    }

    function testGetPriceNone() public {
        vm.prank(owner);
        curve.activateCurve();
        vm.startPrank(alice);
        vm.expectRevert("Please enter an amount of tokens");
        getPriceContract.getPrice(0);
        vm.stopPrank();
    }

    // ============ Sell Metadex Tests ============== //

    function testSellMetadexTakesCorrectFee() public {
        vm.startPrank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        vm.startPrank(alice);
        int256 price = getPriceContract.getPrice(10);
        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(10);

        uint256 aliceMetadexBal = metadex.balanceOf(alice);
        uint256 vestingMetadexBal = metadex.balanceOf(address(vestingContract));

        assertEq(aliceMetadexBal, 0);
        assertEq(vestingMetadexBal, 10e18);

        skip(52 weeks);

        bytes32 AliceVestingId = vestingContract.getVestingIdAtIndex(0);
        vestingContract.release(AliceVestingId, 1e18);

        aliceMetadexBal = metadex.balanceOf(alice);
        vestingMetadexBal = metadex.balanceOf(address(vestingContract));

        assertEq(aliceMetadexBal, 1e18);
        assertEq(vestingMetadexBal, 9e18);

        uint256 treasuryBalBefore = USDC.balanceOf(treasuryAddress);
        uint256 daoBalBefore = USDC.balanceOf(daoAddress);

        metadex.approve(address(curve), 1e18);
        curve.sellMetadex(1);

        price = getPriceContract.getPrice(1);

        int256 amountDAO = PRBMathSD59x18.mul(
            PRBMathSD59x18.div(2 * 1e18, 100e18),
            price
        );

        int256 amountTreasury = PRBMathSD59x18.mul(
            PRBMathSD59x18.div(3 * 1e18, 100e18),
            price
        );

        uint256 treasuryBalAfter = USDC.balanceOf(treasuryAddress);
        uint256 daoBalAfter = USDC.balanceOf(daoAddress);

        assertEq(treasuryBalAfter, treasuryBalBefore + uint256(amountTreasury));
        assertEq(daoBalAfter, daoBalBefore + uint256(amountDAO));

        vm.stopPrank();
    }

    function testSellMetadexBurnsMETADEX() public {
        vm.startPrank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        vm.startPrank(alice);
        int256 price = getPriceContract.getPrice(10);
        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(10);

        assertEq(metadex.totalSupply(), 10e18);

        skip(52 weeks);

        bytes32 AliceVestingId = vestingContract.getVestingIdAtIndex(0);
        vestingContract.release(AliceVestingId, 1e18);

        metadex.approve(address(curve), 1e18);
        curve.sellMetadex(1);

        assertEq(metadex.balanceOf(alice), 0);
        assertEq(metadex.totalSupply(), 9e18);
    }

    function testSellMetadexDecreasesTokensSold() public {
        vm.startPrank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        vm.startPrank(alice);
        int256 price = getPriceContract.getPrice(10);
        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(10);

        assertEq(curve.getTokensSold(), 10);

        skip(52 weeks);

        bytes32 AliceVestingId = vestingContract.getVestingIdAtIndex(0);
        vestingContract.release(AliceVestingId, 1e18);

        metadex.approve(address(curve), 1e18);
        curve.sellMetadex(1);

        assertEq(curve.getTokensSold(), 9);
    }

    function testSellMetadexTransfersUSDC() public {
        vm.startPrank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(1);
        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(1);

        uint256 aliceUSDCBefore = USDC.balanceOf(alice);

        skip(55 weeks);

        bytes32 AliceVestingId = vestingContract.getVestingIdAtIndex(0);
        bytes32 AliceVestingId2 = vestingContract.getVestingIdAtIndex(1);
        bytes32 AliceVestingId3 = vestingContract.getVestingIdAtIndex(2);

        uint256 releaseableAmount1 = vestingContract.computeReleasableAmount(
            AliceVestingId
        );
        uint256 releaseableAmount2 = vestingContract.computeReleasableAmount(
            AliceVestingId2
        );
        uint256 releaseableAmount3 = vestingContract.computeReleasableAmount(
            AliceVestingId3
        );

        vestingContract.release(AliceVestingId, releaseableAmount1);
        vestingContract.release(AliceVestingId2, releaseableAmount2);
        vestingContract.release(AliceVestingId3, releaseableAmount3);

        uint256 totalMetadexReleased = releaseableAmount1 +
            releaseableAmount2 +
            releaseableAmount3;

        metadex.approve(address(curve), totalMetadexReleased);

        totalMetadexReleased /= 1e18;

        (, int256 sellerPrice) = curve.sellMetadex(
            int256(totalMetadexReleased)
        );

        uint256 aliceUSDCAfter = USDC.balanceOf(alice);

        assertEq(aliceUSDCAfter, aliceUSDCBefore + uint256(sellerPrice));

        vm.stopPrank();
    }

    function testSellMetadexEmitsEvent() public {
        vm.startPrank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(10);
        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(10);

        skip(52 weeks);

        bytes32 AliceVestingId = vestingContract.getVestingIdAtIndex(0);
        vestingContract.release(AliceVestingId, 1e18);

        metadex.approve(address(curve), 1e18);

        vm.expectEmit(false, false, false, true);
        emit MetadexSold(1, alice, block.timestamp);
        curve.sellMetadex(1);
        vm.stopPrank();
    }

    function testSellMetadexRequireAmountMoreThanZero() public {
        vm.startPrank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(10);
        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(10);

        metadex.approve(address(curve), 1);

        skip(52 weeks);

        bytes32 AliceVestingId = vestingContract.getVestingIdAtIndex(0);
        vestingContract.release(AliceVestingId, 1e18);

        metadex.approve(address(curve), 1e18);

        vm.expectRevert(Curve.CannotSellZero.selector);
        curve.sellMetadex(0);
    }

    function testSellMetadexRequireMetadexInWallet() public {
        vm.startPrank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(10);
        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(10);

        vm.stopPrank();
        vm.startPrank(bob);

        vm.expectRevert(Curve.NoMetadex.selector);
        curve.sellMetadex(5);

        vm.stopPrank();
    }

    function testSellMetadexRequireTokensSold() public {
        vm.startPrank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
        vm.stopPrank();

        vm.prank(alice);
        vm.expectRevert(Curve.TokensNotAvailable.selector);
        curve.sellMetadex(5);
    }

    function testFuzzSellMetadexTransfersUSDC(int256 _amount) public {
        vm.assume(_amount > 0 && uint256(_amount) <= 19999999);
        vm.startPrank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");

        USDC.mint(address(curve), 50000000000000000000 * 1e18);

        vm.stopPrank();

        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(_amount);
        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(_amount);

        uint256 aliceUSDCBefore = USDC.balanceOf(alice);

        skip(55 weeks);

        bytes32 AliceVestingId = vestingContract.getVestingIdAtIndex(0);
        bytes32 AliceVestingId2 = vestingContract.getVestingIdAtIndex(1);
        bytes32 AliceVestingId3 = vestingContract.getVestingIdAtIndex(2);

        uint256 releaseableAmount1 = vestingContract.computeReleasableAmount(
            AliceVestingId
        );
        uint256 releaseableAmount2 = vestingContract.computeReleasableAmount(
            AliceVestingId2
        );
        uint256 releaseableAmount3 = vestingContract.computeReleasableAmount(
            AliceVestingId3
        );

        vestingContract.release(AliceVestingId, uint256(releaseableAmount1));
        vestingContract.release(AliceVestingId2, uint256(releaseableAmount2));
        vestingContract.release(AliceVestingId3, uint256(releaseableAmount3));

        uint256 totalMetadexReleased = releaseableAmount1 +
            releaseableAmount2 +
            releaseableAmount3;

        metadex.approve(address(curve), totalMetadexReleased);

        totalMetadexReleased /= 1e18;

        (, int256 sellerPrice) = curve.sellMetadex(
            int256(totalMetadexReleased)
        );

        uint256 aliceUSDCAfter = USDC.balanceOf(alice);

        assertEq(aliceUSDCAfter, aliceUSDCBefore + uint256(sellerPrice));

        vm.stopPrank();
    }

    // =================== BUY TESTS =================== //

    function testBuyMetadexTransfersUSDC() public {
        vm.prank(owner);
        curve.activateCurve();
        uint256 AliceBefore = USDC.balanceOf(alice);
        uint256 CurveBefore = USDC.balanceOf(address(curve));
        uint256 DaoBefore = USDC.balanceOf(address(daoAddress));
        uint256 TreasuryBefore = USDC.balanceOf(address(treasuryAddress));

        vm.prank(owner);
        curve.setNFTStage("NONE");
        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(1);

        int256 amountDAO = PRBMathSD59x18.mul(
            PRBMathSD59x18.div(2 * 1e18, 100e18),
            price
        );

        int256 amountTreasury = PRBMathSD59x18.mul(
            PRBMathSD59x18.div(3 * 1e18, 100e18),
            price
        );

        int256 totalFee = amountDAO + amountTreasury;

        USDC.approve(address(curve), uint256(price));

        curve.buyMetadex(1);

        uint256 AliceAfter = USDC.balanceOf(alice);
        uint256 CurveAfter = USDC.balanceOf(address(curve));
        uint256 daoAfter = USDC.balanceOf(address(daoAddress));
        uint256 treasuryAfter = USDC.balanceOf(address(treasuryAddress));

        assertEq(AliceAfter, AliceBefore - uint256(price));
        assertEq(CurveAfter, CurveBefore + uint256(price - totalFee));
        assertEq(daoAfter, DaoBefore + uint256(amountDAO));
        assertEq(treasuryAfter, TreasuryBefore + uint256(amountTreasury));
    }

    function testBuyMetadexMintsAndVests() public {
        vm.prank(owner);
        curve.activateCurve();

        vm.prank(owner);
        curve.setNFTStage("NONE");

        uint256 tokenVestingMetadexBalBefore = metadex.balanceOf(
            address(vestingContract)
        );

        assertEq(tokenVestingMetadexBalBefore, 0);

        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(10);

        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(10);

        uint256 tokenVestingMetadexBalAfter = metadex.balanceOf(
            address(vestingContract)
        );

        vm.stopPrank();

        assertEq(tokenVestingMetadexBalAfter, 10e18);
    }

    function testBuyMetadexIncreasesTokensSold() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");

        int256 tokensSold = curve.getTokensSold();

        assertEq(tokensSold, 0);

        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(10);

        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(10);

        tokensSold = curve.getTokensSold();

        assertEq(tokensSold, 10);

        vm.stopPrank();
        vm.startPrank(bob);

        price = getPriceContract.getPrice(5);

        USDC.approve(address(curve), uint256(price));
        curve.buyMetadex(5);

        tokensSold = curve.getTokensSold();

        assertEq(tokensSold, 15);

        vm.stopPrank();
    }

    function testBuyMetadexRequireAmountGreaterThanZero() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");

        vm.prank(alice);
        vm.expectRevert(Curve.CannotBuyZero.selector);
        curve.buyMetadex(0);
    }

    function testBuyMetadexTransitionsOnMaxThreshold() public {
        vm.prank(owner);
        curve.activateCurve();
        curve.setNFTStage("NONE");
    }

    function testBuyMetadexFuzzTransferUSDC(int256 _amount) public {
        vm.assume(_amount > 0 && _amount <= 19999999);
        vm.prank(owner);
        curve.activateCurve();
        uint256 AliceBefore = USDC.balanceOf(alice);
        uint256 CurveBefore = USDC.balanceOf(address(curve));
        uint256 DaoBefore = USDC.balanceOf(address(daoAddress));
        uint256 TreasuryBefore = USDC.balanceOf(address(treasuryAddress));

        vm.prank(owner);
        curve.setNFTStage("NONE");
        vm.startPrank(alice);

        int256 price = getPriceContract.getPrice(_amount);

        int256 amountDAO = PRBMathSD59x18.mul(
            PRBMathSD59x18.div(2 * 1e18, 100e18),
            price
        );

        int256 amountTreasury = PRBMathSD59x18.mul(
            PRBMathSD59x18.div(3 * 1e18, 100e18),
            price
        );

        int256 totalFee = amountDAO + amountTreasury;

        USDC.approve(address(curve), uint256(price));

        curve.buyMetadex(_amount);

        uint256 AliceAfter = USDC.balanceOf(alice);
        uint256 CurveAfter = USDC.balanceOf(address(curve));
        uint256 daoAfter = USDC.balanceOf(address(daoAddress));
        uint256 treasuryAfter = USDC.balanceOf(address(treasuryAddress));

        assertEq(AliceAfter, AliceBefore - uint256(price));
        assertEq(CurveAfter, CurveBefore + uint256(price - totalFee));
        assertEq(daoAfter, DaoBefore + uint256(amountDAO));
        assertEq(treasuryAfter, TreasuryBefore + uint256(amountTreasury));
    }

    // =================== ACTIVATE CURVE TESTS =================== //

    function testActiveCurve() public {
        bool active = curve.curveActive();
        assertEq(active, false);

        vm.prank(owner);
        curve.activateCurve();

        active = curve.curveActive();
        assertEq(active, true);
    }

    function testAcivateCurveOnlyOwner() public {
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        curve.activateCurve();
    }

    function testActivateCurveEmitCurveActivated() public {
        vm.prank(owner);
        curve.pauseCurve();

        vm.expectEmit(false, false, false, true);
        emit CurveActivated(owner, block.timestamp);
        curve.activateCurve();
    }
}
