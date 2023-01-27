// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

interface IWithRewards {
  function claim() external;

  function rewardTokens() external view returns (address[] memory);
}
