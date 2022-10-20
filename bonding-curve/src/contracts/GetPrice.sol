// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12;

import "@prb-math/PRBMathSD59x18.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IGetPrice.sol";

contract GetPrice is IGetPrice {
    using PRBMathSD59x18 for int256;

    address curve;

    function setCurveAddress(address _curveAddress) public {
        curve = _curveAddress;
    }

    function getPrice(int256 _amountTokens) public view returns (int256 price) {
        require(_amountTokens > 0, "Please enter an amount of tokens");

        int256 tokensSold = ICurve(curve).getTokensSold();

        int256 startPoint = tokensSold;
        startPoint *= 1e18;

        int256 endPoint = tokensSold + _amountTokens;
        endPoint *= 1e18;

        int256 top;
        int256 bottom;
        int256 topFirstCurve;
        int256 bottomFirstCurve;
        int256 topSecondCurve;
        int256 bottomSecondCurve;
        int256 secondCurvePrice;

        if (tokensSold < 2000000) {
            if (endPoint / 1e18 < 2000000) {
                price = 1e17 * _amountTokens;
            } else {
                price = (2000000 - tokensSold) * 1e17;

                topSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        (endPoint),
                        ((endPoint) + 26000000 * 1e18)
                    ),
                    300000000 * 1e18
                );

                bottomSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        2000000 * 1e18,
                        (2000000 * 1e18 + 26000000 * 1e18)
                    ),
                    300000000 * 1e18
                );

                secondCurvePrice = topSecondCurve - bottomSecondCurve;

                price += secondCurvePrice;
            }
        }

        if (tokensSold >= 2000000 && tokensSold < 3000000) {
            if (endPoint / 1e18 < 3000000) {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint + 26000000 * 1e18)),
                    300000000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint + 26000000 * 1e18)
                    ),
                    300000000 * 1e18
                );

                price = top - bottom;
            } else {
                topFirstCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        2999999 * 1e18,
                        (2999999 * 1e18 + 26000000 * 1e18)
                    ),
                    300000000 * 1e18
                );

                bottomFirstCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint + 26000000 * 1e18)
                    ),
                    300000000 * 1e18
                );

                price = topFirstCurve - bottomFirstCurve;

                topSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint - 5903700 * 1e18)),
                    900000 * 1e18
                );

                bottomSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        3000000 * 1e18,
                        (3000000 * 1e18 - 5903700 * 1e18)
                    ),
                    900000 * 1e18
                );

                secondCurvePrice = topSecondCurve - bottomSecondCurve;

                price += secondCurvePrice;
            }
        }

        if (tokensSold >= 3000000 && tokensSold < 3500000) {
            if (endPoint / 1e18 < 3500000) {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint - 5903700 * 1e18)),
                    900000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint - 5903700 * 1e18)
                    ),
                    900000 * 1e18
                );

                price = top - bottom;
            } else {
                topFirstCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        3499999 * 1e18,
                        (3499999 * 1e18 - 5903700 * 1e18)
                    ),
                    900000 * 1e18
                );

                bottomFirstCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint - 5903700 * 1e18)
                    ),
                    900000 * 1e18
                );

                price = topFirstCurve - bottomFirstCurve;

                topSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        endPoint,
                        (PRBMathSD59x18.mul(endPoint, 25 * 1e18) -
                            173020971 *
                            1e18)
                    ),
                    16195000 * 1e18
                );

                bottomSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        3500000 * 1e18,
                        (PRBMathSD59x18.mul(3500000 * 1e18, 25 * 1e18) -
                            173020971 *
                            1e18)
                    ),
                    16195000 * 1e18
                );

                secondCurvePrice = topSecondCurve - bottomSecondCurve;

                price += secondCurvePrice;
            }
        }

        if (tokensSold >= 3500000 && tokensSold < 4000000) {
            if (endPoint / 1e18 < 4000000) {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        endPoint,
                        (PRBMathSD59x18.mul(endPoint, 25 * 1e18) -
                            173020971 *
                            1e18)
                    ),
                    16195000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (PRBMathSD59x18.mul(startPoint, 25 * 1e18) -
                            173020971 *
                            1e18)
                    ),
                    16195000 * 1e18
                );

                price = top - bottom;
            } else {
                topFirstCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        3999999 * 1e18,
                        (PRBMathSD59x18.mul(3999999 * 1e18, 25 * 1e18) -
                            173020971 *
                            1e18)
                    ),
                    16195000 * 1e18
                );

                bottomFirstCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (PRBMathSD59x18.mul(startPoint, 25 * 1e18) -
                            173020971 *
                            1e18)
                    ),
                    16195000 * 1e18
                );

                price = topFirstCurve - bottomFirstCurve;

                topSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint - 6569714 * 1e18)),
                    8580000 * 1e18
                );

                bottomSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        4000000 * 1e18,
                        (4000000 * 1e18 - 6569714 * 1e18)
                    ),
                    8580000 * 1e18
                );

                secondCurvePrice = topSecondCurve - bottomSecondCurve;

                price += secondCurvePrice;
            }
        }

        if (tokensSold >= 4000000 && tokensSold < 4500000) {
            if (endPoint / 1e18 < 4500000) {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint - 6569714 * 1e18)),
                    8580000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint - 6569714 * 1e18)
                    ),
                    8580000 * 1e18
                );

                price = top - bottom;
            } else {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        4499999 * 1e18,
                        (4499999 * 1e18 - 6569714 * 1e18)
                    ),
                    8580000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint - 6569714 * 1e18)
                    ),
                    8580000 * 1e18
                );

                price = top - bottom;

                topSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint - 7889856 * 1e18)),
                    3920000 * 1e18
                );

                bottomSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        4500000 * 1e18,
                        (4500000 * 1e18 - 7889856 * 1e18)
                    ),
                    3920000 * 1e18
                );

                secondCurvePrice = topSecondCurve - bottomSecondCurve;

                price += secondCurvePrice;
            }
        }

        if (tokensSold >= 4500000 && tokensSold < 5500000) {
            if (endPoint / 1e18 < 5500000) {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint - 7889856 * 1e18)),
                    3920000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint - 7889856 * 1e18)
                    ),
                    3920000 * 1e18
                );

                price = top - bottom;
            } else {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        5499999 * 1e18,
                        (5499999 * 1e18 - 7889856 * 1e18)
                    ),
                    3920000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint - 7889856 * 1e18)
                    ),
                    3920000 * 1e18
                );

                price = top - bottom;

                topSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint - 6668036 * 1e18)),
                    5460000 * 1e18
                );

                bottomSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        5500000 * 1e18,
                        (5500000 * 1e18 - 6668036 * 1e18)
                    ),
                    5460000 * 1e18
                );

                secondCurvePrice = topSecondCurve - bottomSecondCurve;

                price += secondCurvePrice;
            }
        }

        if (tokensSold >= 5500000 && tokensSold < 6000000) {
            if (endPoint / 1e18 < 6000000) {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint - 6668036 * 1e18)),
                    5460000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint - 6668036 * 1e18)
                    ),
                    5460000 * 1e18
                );

                price = top - bottom;
            } else {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        5999999 * 1e18,
                        (5999999 * 1e18 - 6668036 * 1e18)
                    ),
                    5460000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint - 6668036 * 1e18)
                    ),
                    5460000 * 1e18
                );

                price = top - bottom;

                topSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint + 270135 * 1e18)),
                    12550000 * 1e18
                );

                bottomSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        6000000 * 1e18,
                        (6000000 * 1e18 + 270135 * 1e18)
                    ),
                    12550000 * 1e18
                );

                secondCurvePrice = topSecondCurve - bottomSecondCurve;

                price += secondCurvePrice;
            }
        }

        if (tokensSold >= 6000000 && tokensSold < 6500000) {
            if (endPoint / 1e18 < 6500000) {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint + 270135 * 1e18)),
                    12550000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint + 270135 * 1e18)
                    ),
                    12550000 * 1e18
                );

                price = top - bottom;
            } else {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        6499999 * 1e18,
                        (6499999 * 1e18 + 270135 * 1e18)
                    ),
                    12550000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint + 270135 * 1e18)
                    ),
                    12550000 * 1e18
                );

                price = top - bottom;

                topSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint + 23998500 * 1e18)),
                    35000000 * 1e18
                );

                bottomSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        6500000 * 1e18,
                        (6500000 * 1e18 + 23998500 * 1e18)
                    ),
                    35000000 * 1e18
                );

                secondCurvePrice = topSecondCurve - bottomSecondCurve;

                price += secondCurvePrice;
            }
        }

        if (tokensSold >= 6500000 && tokensSold < 7000000) {
            if (endPoint / 1e18 < 7000000) {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint + 23998500 * 1e18)),
                    35000000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint + 23998500 * 1e18)
                    ),
                    35000000 * 1e18
                );

                price = top - bottom;
            } else {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        6999999 * 1e18,
                        (6999999 * 1e18 + 23998500 * 1e18)
                    ),
                    35000000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint + 23998500 * 1e18)
                    ),
                    35000000 * 1e18
                );

                price = top - bottom;

                topSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint + 94600000 * 1e18)),
                    100000000 * 1e18
                );

                bottomSecondCurve = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        7000000 * 1e18,
                        (7000000 * 1e18 + 94600000 * 1e18)
                    ),
                    100000000 * 1e18
                );

                secondCurvePrice = topSecondCurve - bottomSecondCurve;

                price += secondCurvePrice;
            }
        }

        if (tokensSold >= 7000000 && tokensSold < 7500000) {
            if (endPoint / 1e18 < 7500000) {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(endPoint, (endPoint + 94600000 * 1e18)),
                    100000000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint + 94600000 * 1e18)
                    ),
                    100000000 * 1e18
                );

                price = top - bottom;
            } else {
                top = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        7499999 * 1e18,
                        (7499999 * 1e18 + 94600000 * 1e18)
                    ),
                    100000000 * 1e18
                );

                bottom = PRBMathSD59x18.div(
                    PRBMathSD59x18.mul(
                        startPoint,
                        (startPoint + 94600000 * 1e18)
                    ),
                    100000000 * 1e18
                );

                price = top - bottom;

                secondCurvePrice = 11 * 1e17 * (endPoint / 1e18 - 7500000);

                price += secondCurvePrice;
            }
        }

        if (tokensSold >= 7500000) {
            price = 11 * 1e17 * _amountTokens;
        }
    }
}
