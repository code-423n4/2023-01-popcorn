// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";
import { ITestConfigStorage } from "./ITestConfigStorage.sol";
import { IAdapter, IERC4626 } from "../../../../src/interfaces/vault/IAdapter.sol";
import { IStrategy } from "../../../../src/interfaces/vault/IStrategy.sol";
import { Vault, VaultFees, IERC20Metadata, IERC20 } from "../../../../src/vault/Vault.sol";
import { MathUpgradeable as Math } from "openzeppelin-contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";

uint256 constant ETH_MAINNET = 1;
uint256 constant POLYGON_MAINNET = 137;
uint256 constant ARBITRUM_MAINNET = 42161;

contract AbstractVaultIntegrationTest is Test {
  using Math for uint256;

  ITestConfigStorage testConfigStorage;

  string baseTestId; // Depends on external Protocol (e.g. Beefy,Yearn...)
  string testId; // baseTestId + Asset

  uint256 maxConfigs;

  IERC20 asset;
  Vault vault;
  IAdapter adapter;

  address bob = address(1);
  address alice = address(2);
  address feeRecipient = address(0x1234);

  uint256 defaultAmount;
  uint256 maxDeposit;
  uint256 constant DEPOSIT_FEE = 50 * 1e14;
  uint256 constant WITHDRAWAL_FEE = 50 * 1e14;
  uint256 constant MANAGEMENT_FEE = 200 * 1e14;
  uint256 constant PERFORMANCE_FEE = 2000 * 1e14;

  address contractRegistry;
  address aclRegistry;
  address aclAdmin;

  bytes4[8] sigs;

  /*//////////////////////////////////////////////////////////////
                          TEST SETUP
    //////////////////////////////////////////////////////////////*/

  function setUpBaseTest(
    IERC20 asset_,
    IAdapter adapter_,
    string memory baseTestId_,
    uint256 maxConfigs_
  ) public {
    asset = asset_;
    adapter = adapter_;
    baseTestId = baseTestId_;
    maxConfigs = maxConfigs_;
    defaultAmount = 10**IERC20Metadata(address(asset_)).decimals();
    maxDeposit = defaultAmount * 10_000;

    address vaultAddress = address(new Vault());
    vault = Vault(vaultAddress);
    vault.initialize(
      asset_,
      adapter_,
      VaultFees({ deposit: 0, withdrawal: 0, management: 0, performance: 0 }),
      feeRecipient,
      address(this)
    );

    vm.label(alice, "alice");
    vm.label(bob, "bob");
    vm.label(feeRecipient, "feeRecipient");
    vm.label(address(asset_), "asset");
    vm.label(vaultAddress, "vault");
    vm.label(address(adapter_), "adapter");

    baseTestId = baseTestId_;
    testId = string.concat(baseTestId_, IERC20Metadata(address(asset)).symbol());
  }

  /*//////////////////////////////////////////////////////////////
                            HELPER
    //////////////////////////////////////////////////////////////*/

  // Increase the pricePerShare of the external protocol
  // sometimes its enough to simply add assets, othertimes one also needs to call some functions before the external protocol reflects the change
  function increasePricePerShare(uint256 amount) public virtual {}

  // Its should use exactly setup to override the previous setup
  function overrideSetup(bytes memory testConfig) public virtual {
    // setUpBasetest();
    // protocol specific setup();
  }

  // Construct a new Adapter and set it to `adapter`
  function createAdapter() public virtual {}

  function assertWithin(
    uint256 expected,
    uint256 actual,
    uint256 delta,
    string memory err
  ) internal {
    if (expected > actual) {
      assertLe(expected - actual, delta, err);
    } else if (actual > expected) {
      assertLe(actual - expected, delta, err);
    } else {
      assertEq(expected, actual, err);
    }
  }

  function deposit(uint256 amount) public returns (uint256 actualShares) {
    deal(address(asset), bob, asset.balanceOf(bob) + amount);
    vm.startPrank(bob);
    asset.approve(address(vault), amount);
    actualShares = vault.deposit(amount);
    vm.stopPrank();
  }

  function mint(uint256 amount) public returns (uint256 actualAssets) {
    uint256 reqAssets = vault.previewMint(amount);
    deal(address(asset), bob, asset.balanceOf(bob) + reqAssets);
    vm.startPrank(bob);
    asset.approve(address(vault), reqAssets);
    actualAssets = vault.mint(amount);
    vm.stopPrank();
  }

  /*//////////////////////////////////////////////////////////////
                          DEPOSIT / WITHDRAW
    //////////////////////////////////////////////////////////////*/

  // NOTE We struggle with off-by-one errors here
  // -  Limiting this to uint8 with lower bound of 10 unveils plenty of issues stemming from off-by-one errors.
  // -  For example depositing 10 assets will mint 10 shares on the first deposit and 11 shares later on but will only return 9 assets each time...
  //    ... 1. 9a/10s = 0.9pps | 2. 18a/21s = 0.8571pps | 3. 27a/32s = 0.84375pps
  // -  We can already see these issues here as i have to use `assertWithin` instead of `assertEq` with a delta of 1.
  // -  Its slightly worse for withdrawals as it fluctuates here between a delta of 1 and 2.
  // -> I am not happy with this but it also doesnt seem like an entire dealbreaker...
  //    ... Additionally this really depends on the underlying implementations of external protocols and adapters. Better protocols + adapter shouldnt run into these issues
  function test__deposit_withdrawl_pps_stays_constant(uint80 fuzzAmount) public {
    uint256 amount = bound(uint256(fuzzAmount), defaultAmount, maxDeposit);

    uint256 pps1;
    uint256 pps2;
    uint256 len = Math.min(uint256(testConfigStorage.getTestConfigLength()), maxConfigs);
    // solhint-disable
    for (uint256 i; i < len; i++) {
      if (i > 0) overrideSetup(testConfigStorage.getTestConfig(i));

      // solhint-disable-next-line
      for (uint256 i; i < 3; ++i) {
        pps1 = vault.convertToAssets(defaultAmount);
        deposit(amount);
        pps2 = vault.convertToAssets(defaultAmount);
        assertWithin(pps1, pps2, 2, string.concat(Strings.toString(i), "-deposit-", testId));
      }
      // solhint-disable-next-line
      for (uint256 i; i < 2; ++i) {
        pps1 = vault.convertToAssets(defaultAmount);
        vm.prank(bob);
        vault.withdraw(amount);
        pps2 = vault.convertToAssets(defaultAmount);
        assertWithin(pps1, pps2, 3, string.concat(Strings.toString(i), "-withdraw-", testId));
      }
    }
  }

  function test__deposit_withdrawl_preview_resembles_actual(uint80 fuzzAmount) public {
    uint256 amount = bound(uint256(fuzzAmount), defaultAmount, maxDeposit);

    uint256 len = Math.min(uint256(testConfigStorage.getTestConfigLength()), maxConfigs);
    // solhint-disable
    for (uint256 i; i < len; i++) {
      if (i > 0) overrideSetup(testConfigStorage.getTestConfig(i));

      deposit(defaultAmount);

      increasePricePerShare(amount * 1000);

      uint256 expectedShares = vault.previewDeposit(amount);
      uint256 actualShares = deposit(amount);
      assertWithin(actualShares, expectedShares, 1, string.concat("deposit-", testId));

      expectedShares = vault.previewWithdraw(amount);
      vm.prank(bob);
      actualShares = vault.withdraw(amount);
      assertWithin(actualShares, expectedShares, 1, string.concat("withdraw-", testId));
    }
  }

  /*//////////////////////////////////////////////////////////////
                          MINT / REDEEM
    //////////////////////////////////////////////////////////////*/

  function test__mint_redeem_pps_stays_constant(uint80 fuzzAmount) public {
    uint256 amount = bound(uint256(fuzzAmount), defaultAmount, maxDeposit);

    uint256 pps1;
    uint256 pps2;
    uint256 len = Math.min(uint256(testConfigStorage.getTestConfigLength()), maxConfigs);
    // solhint-disable
    for (uint256 i; i < len; i++) {
      if (i > 0) overrideSetup(testConfigStorage.getTestConfig(i));

      // solhint-disable-next-line
      for (uint256 i; i < 3; ++i) {
        pps1 = vault.convertToAssets(defaultAmount);
        mint(amount);
        pps2 = vault.convertToAssets(defaultAmount);
        assertWithin(pps1, pps2, 2, string.concat(Strings.toString(i), "-mint-", testId));
      }
      // solhint-disable-next-line
      for (uint256 i; i < 2; ++i) {
        pps1 = vault.convertToAssets(defaultAmount);
        vm.prank(bob);
        vault.redeem(amount);
        pps2 = vault.convertToAssets(defaultAmount);
        assertWithin(pps1, pps2, 2, string.concat(Strings.toString(i), "-redeem-", testId));
      }
    }
  }

  function test__mint_redeem_preview_resembles_actual(uint80 fuzzAmount) public {
    uint256 amount = bound(uint256(fuzzAmount), defaultAmount, maxDeposit);

    uint256 len = Math.min(uint256(testConfigStorage.getTestConfigLength()), maxConfigs);
    // solhint-disable
    for (uint256 i; i < len; i++) {
      if (i > 0) overrideSetup(testConfigStorage.getTestConfig(i));

      mint(defaultAmount);

      increasePricePerShare(amount * 1000);

      uint256 expectedShares = vault.previewMint(amount);
      uint256 actualShares = mint(amount);
      assertWithin(actualShares, expectedShares, 1, string.concat("mint-", testId));

      expectedShares = vault.previewRedeem(amount);
      vm.prank(bob);
      actualShares = vault.redeem(amount);
      assertWithin(actualShares, expectedShares, 1, string.concat("redeem-", testId));
    }
  }
}
