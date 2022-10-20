// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

struct VestingSchedule {
        bool initialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // cliff period in seconds
        uint256 cliff;
        // start time of the vesting period
        uint256 start;
        // duration of the vesting period in seconds
        uint256 duration;
        // duration of a slice period for the vesting in seconds
        uint256 slicePeriodSeconds;
        // whether or not the vesting is revocable
        bool revocable;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;
        // whether or not the vesting has been revoked
        bool revoked;
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

    function getVestingSchedulesCountByBeneficiary(address _beneficiary)
        external
        returns (uint256);
    
    function getVestingIdAtIndex(uint256 index)
        external
        returns (bytes32);

    function getVestingScheduleByAddressAndIndex(address holder, uint256 index)
        external
        returns (VestingSchedule memory);


    function getVestingSchedulesTotalAmount() external view returns (uint256);

    function getToken() external view returns (address);

    function revoke(bytes32 vestingScheduleId) external;

    function getVestingSchedulesCount() external view returns (uint256);

    function computeReleasableAmount(bytes32 vestingScheduleId)
        external
        view
        returns (uint256);

    function getVestingSchedule(bytes32 vestingScheduleId)
        external
        view
        returns (VestingSchedule memory);

    function computeNextVestingScheduleIdForHolder(address holder)
        external
        view
        returns (bytes32);

    function getLastVestingScheduleForHolder(address holder)
        external
        view
        returns (VestingSchedule memory);

    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) external pure returns (bytes32);
    
}