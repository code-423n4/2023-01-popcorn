// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import { IERC20Upgradeable as IERC20 } from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC4626 is IERC20 {
  event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

  event Withdraw(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  // ASSET

  function asset() external view returns (address assetTokenAddress);

  function totalAssets() external view returns (uint256 totalManagedAssets);

  // CONVERSION

  function convertToShares(uint256 assets) external view returns (uint256 shares);

  function convertToAssets(uint256 shares) external view returns (uint256 assets);

  // DEPOSIT

  function maxDeposit(address receiver) external view returns (uint256 maxAssets);

  function previewDeposit(uint256 assets) external view returns (uint256 shares);

  function deposit(uint256 assets, address receiver) external returns (uint256 shares);

  // MINT

  function maxMint(address receiver) external view returns (uint256 maxShares);

  function previewMint(uint256 shares) external view returns (uint256 assets);

  function mint(uint256 shares, address receiver) external returns (uint256 assets);

  // WITHDRAW

  function maxWithdraw(address owner) external view returns (uint256 maxAssets);

  function previewWithdraw(uint256 assets) external view returns (uint256 shares);

  function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

  // REDEEM

  function maxRedeem(address owner) external view returns (uint256 maxShares);

  function previewRedeem(uint256 shares) external view returns (uint256 assets);

  function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}
