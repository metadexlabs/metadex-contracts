// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

//Interface for MetadexBaseToken
interface IMetadexBaseToken {
    function mint(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
}

//Interface for TokenVesting
interface ITokenVesting {
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount
    ) external;
    function transferOwnership(address newOwner) external;
    function revoke(bytes32 vestingScheduleId) external;
}

/** @title Interaction. */
contract Interaction is Ownable {
    address public vestingContractAddr;
    address public tokenContractAddr;
    address public bondingCurveContractAddr;
    address[] public genesisInvestor;

    event NewSetAddr(address vestingContractAddr, address tokenContractAddr, address bondingCurveContractAddr);
    event AddGenesisInvestor(address genesisInvestorWalletAddr);

    modifier onlyBondingCurve() {
        require(msg.sender == bondingCurveContractAddr, "Not bonding curve");
        _;
    }

    function renounceOwnership() public override onlyOwner {
        revert("Can't renounceOwnership");
    }

    /**
     * @notice Set operator, treasury, and injector addresses
     * @dev Only callable by owner
     * @param _vestingContractAddr: address of the vesting contract
     * @param _tokenContractAddr: address of the token contract
     * @param _bondingCurveContractAddr: address of the bonding curve contract
     */
    function setAddr(address _tokenContractAddr, address _vestingContractAddr, address _bondingCurveContractAddr) external onlyOwner {
        require(_vestingContractAddr != address(0), "Cannot be zero address");
        require(_tokenContractAddr != address(0), "Cannot be zero address");
        require(_bondingCurveContractAddr != address(0), "Cannot be zero address");

       
        vestingContractAddr = _vestingContractAddr;
        tokenContractAddr = _tokenContractAddr;
        bondingCurveContractAddr = _bondingCurveContractAddr;

        emit NewSetAddr(_vestingContractAddr, _tokenContractAddr, _bondingCurveContractAddr);
    }

    function addGenesisInvestor(address _genesisInvestorWalletAddr) external onlyOwner {
        require(_genesisInvestorWalletAddr != address(0), "Cannot be zero address");
       
        genesisInvestor.push(_genesisInvestorWalletAddr);

        emit AddGenesisInvestor(_genesisInvestorWalletAddr);
    }

    function _isGenesisInvestors(address _genesisInvestorWalletAddr) internal view returns (bool) {
        for (uint i = 0; i < genesisInvestor.length; i++) {
            if (genesisInvestor[i] == _genesisInvestorWalletAddr) {
                return true;
            }
        }

        return false;
    }

    function transferVestingOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        ITokenVesting(vestingContractAddr).transferOwnership(newOwner);
    } 

    /**
    * @notice Mint tokens for TokenVesting contract & create a new vesting schedule for a beneficiary.
    * @param userAddress The beneficiary address.
    * @param amount The number of token to mint and vest.
    */

    function mintAndCreateVesting(address userAddress, uint256 amount) public onlyBondingCurve {

        /**
        * @notice Mint tokens for a recipient.
        * @param to The recipient address.
        * @param amount The number of token to mint.
        */

        IMetadexBaseToken(tokenContractAddr).mint(vestingContractAddr, amount);

        /**
        * @notice Creates a new vesting schedule for a beneficiary.
        * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
        * @param _start start time of the vesting period
        * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
        * @param _duration duration in seconds of the period in which the tokens will vest
        * @param _slicePeriodSeconds duration of a slice period for the vesting in seconds
        * @param _revocable whether the vesting is revocable or not
        * @param _amount total amount of tokens to be released at the end of the vesting
        */

        if (_isGenesisInvestors(userAddress)) {
            //50% liquid
            ITokenVesting(vestingContractAddr).createVestingSchedule(
                userAddress,
                block.timestamp,
                1 seconds,
                1 seconds,
                1,
                true,
                amount * 50 / 100
            );

            //50% liquid after 180 days
            ITokenVesting(vestingContractAddr).createVestingSchedule(
                userAddress,
                block.timestamp,
                180 days,
                180 days,
                1,
                true,
                amount * 50 / 100
            );
        } else {
            //10% liquid
            ITokenVesting(vestingContractAddr).createVestingSchedule(
                userAddress,
                block.timestamp,
                1 seconds,
                1 seconds,
                1,
                true,
                amount * 10 / 100
            );

            //25% liquid after 180 days
            ITokenVesting(vestingContractAddr).createVestingSchedule(
                userAddress,
                block.timestamp,
                180 days,
                180 days,
                1,
                true,
                amount * 25 / 100
            );

            //65% liquid after 365 days
            ITokenVesting(vestingContractAddr).createVestingSchedule(
                userAddress,
                block.timestamp,
                365 days,
                365 days,
                1,
                true,
                amount * 65 / 100
            );
        }
    }
}