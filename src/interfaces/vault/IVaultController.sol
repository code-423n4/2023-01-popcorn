// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { VaultInitParams, VaultFees } from "./IVault.sol";
import { VaultMetadata } from "./IVaultRegistry.sol";
import { IDeploymentController } from "./IDeploymentController.sol";

import { IERC4626, IERC20 } from "./IERC4626.sol";

struct DeploymentArgs {
  /// @Notice templateId
  bytes32 id;
  /// @Notice encoded init params
  bytes data;
}

interface IVaultController {
  function deployVault(
    VaultInitParams memory vaultData,
    DeploymentArgs memory adapterData,
    DeploymentArgs memory strategyData,
    address staking,
    bytes memory rewardsData,
    VaultMetadata memory metadata,
    uint256 initialDeposit
  ) external returns (address);

  function deployAdapter(
    IERC20 asset,
    DeploymentArgs memory adapterData,
    DeploymentArgs memory strategyData,
    uint256 initialDeposit
  ) external returns (address);

  function deployStaking(IERC20 asset) external returns (address);

  function proposeVaultAdapters(address[] memory vaults, IERC4626[] memory newAdapter) external;

  function changeVaultAdapters(address[] memory vaults) external;

  function proposeVaultFees(address[] memory vaults, VaultFees[] memory newFees) external;

  function changeVaultFees(address[] memory vaults) external;

  function registerVaults(address[] memory vaults, VaultMetadata[] memory metadata) external;

  function addClones(address[] memory clones) external;

  function toggleEndorsements(address[] memory targets) external;

  function toggleRejections(address[] memory targets) external;

  function addStakingRewardsTokens(address[] memory vaults, bytes[] memory rewardsTokenData) external;

  function changeStakingRewardsSpeeds(
    address[] memory vaults,
    IERC20[] memory rewardTokens,
    uint160[] memory rewardsSpeeds
  ) external;

  function fundStakingRewards(
    address[] memory vaults,
    IERC20[] memory rewardTokens,
    uint256[] memory amounts
  ) external;

  function setEscrowTokenFees(IERC20[] memory tokens, uint256[] memory fees) external;

  function addTemplateCategories(bytes32[] memory templateCategories) external;

  function toggleTemplateEndorsements(bytes32[] memory templateCategories, bytes32[] memory templateIds) external;

  function pauseAdapters(address[] calldata vaults) external;

  function pauseVaults(address[] calldata vaults) external;

  function unpauseAdapters(address[] calldata vaults) external;

  function unpauseVaults(address[] calldata vaults) external;

  function nominateNewAdminProxyOwner(address newOwner) external;

  function acceptAdminProxyOwnership() external;

  function setPerformanceFee(uint256 newFee) external;

  function setAdapterPerformanceFees(address[] calldata adapters) external;

  function performanceFee() external view returns (uint256);

  function setHarvestCooldown(uint256 newCooldown) external;

  function setAdapterHarvestCooldowns(address[] calldata adapters) external;

  function harvestCooldown() external view returns (uint256);

  function setDeploymentController(IDeploymentController _deploymentController) external;

  function setActiveTemplateId(bytes32 templateCategory, bytes32 templateId) external;

  function activeTemplateId(bytes32 templateCategory) external view returns (bytes32);
}
