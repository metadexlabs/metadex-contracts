// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IInteraction {
  function renounceOwnership() external;

  function setAddr(
        address _tokenContractAddr,
        address _vestingContractAddr,
        address _bondingCurveContractAddr
    ) external;

  function addGenesisInvestor(address _genesisInvestorWalletAddr)
        external;

  function transferVestingOwnership(address newOwner) external;

  function mintAndCreateVesting(address userAddress, uint256 amount) external;
  
  function withdraw(uint256 amount) external;

  function release(bytes32 vestingScheduleId, uint256 amount) external;

  function getWithdrawableAmount() external view returns (uint256);

  
}


