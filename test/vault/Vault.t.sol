// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "../utils/mocks/MockERC20.sol";
import { MockERC4626 } from "../utils/mocks/MockERC4626.sol";
import { Vault } from "../../src/vault/Vault.sol";
import { IERC4626, IERC20 } from "../../src/interfaces/vault/IERC4626.sol";
import { VaultFees } from "../../src/interfaces/vault/IVault.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";

contract VaultTest is Test {
  using FixedPointMathLib for uint256;

  bytes32 constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  MockERC20 asset;
  MockERC4626 adapter;
  Vault vault;

  uint256 ONE = 1e18;

  address feeRecipient = address(0x4444);
  address alice = address(0xABCD);
  address bob = address(0xDCBA);

  event NewFeesProposed(VaultFees newFees, uint256 timestamp);
  event ChangedFees(VaultFees oldFees, VaultFees newFees);
  event FeeRecipientUpdated(address oldFeeRecipient, address newFeeRecipient);
  event NewAdapterProposed(IERC4626 newAdapter, uint256 timestamp);
  event ChangedAdapter(IERC4626 oldAdapter, IERC4626 newAdapter);
  event QuitPeriodSet(uint256 quitPeriod);
  event Paused(address account);
  event Unpaused(address account);

  function setUp() public {
    vm.label(feeRecipient, "feeRecipient");
    vm.label(alice, "alice");
    vm.label(bob, "bob");

    asset = new MockERC20("Mock Token", "TKN", 18);
    adapter = new MockERC4626(IERC20(address(asset)), "Mock Token Vault", "vwTKN");

    address vaultAddress = address(new Vault());
    vm.label(vaultAddress, "vault");

    vault = Vault(vaultAddress);
    vault.initialize(
      IERC20(address(asset)),
      IERC4626(address(adapter)),
      VaultFees({ deposit: 0, withdrawal: 0, management: 0, performance: 0 }),
      feeRecipient,
      address(this)
    );
  }

  /*//////////////////////////////////////////////////////////////
                              HELPER
    //////////////////////////////////////////////////////////////*/

  function _setFees(
    uint64 depositFee,
    uint64 withdrawalFee,
    uint64 managementFee,
    uint64 performanceFee
  ) internal {
    vault.proposeFees(
      VaultFees({
        deposit: depositFee,
        withdrawal: withdrawalFee,
        management: managementFee,
        performance: performanceFee
      })
    );

    vm.warp(block.timestamp + 3 days);
    vault.changeFees();
  }

  /*//////////////////////////////////////////////////////////////
                          INITIALIZATION
    //////////////////////////////////////////////////////////////*/
  function test__metadata() public {
    address vaultAddress = address(new Vault());
    Vault newVault = Vault(vaultAddress);

    uint256 callTime = block.timestamp;
    newVault.initialize(
      IERC20(address(asset)),
      IERC4626(address(adapter)),
      VaultFees({ deposit: 100, withdrawal: 100, management: 100, performance: 100 }),
      feeRecipient,
      bob
    );

    assertEq(newVault.name(), "Popcorn Mock Token Vault");
    assertEq(newVault.symbol(), "pop-TKN");
    assertEq(newVault.decimals(), 18);

    assertEq(address(newVault.asset()), address(asset));
    assertEq(address(newVault.adapter()), address(adapter));
    assertEq(newVault.owner(), bob);

    (uint256 deposit, uint256 withdrawal, uint256 management, uint256 performance) = newVault.fees();
    assertEq(deposit, 100);
    assertEq(withdrawal, 100);
    assertEq(management, 100);
    assertEq(performance, 100);
    assertEq(newVault.feeRecipient(), feeRecipient);
    assertEq(newVault.highWaterMark(), 1 ether);
    assertEq(newVault.feesUpdatedAt(), callTime);

    assertEq(newVault.quitPeriod(), 3 days);
    assertEq(asset.allowance(address(newVault), address(adapter)), type(uint256).max);
  }

  function testFail__initialize_asset_is_zero() public {
    address vaultAddress = address(new Vault());
    vm.label(vaultAddress, "vault");

    vault = Vault(vaultAddress);
    vault.initialize(
      IERC20(address(0)),
      IERC4626(address(adapter)),
      VaultFees({ deposit: 0, withdrawal: 0, management: 0, performance: 0 }),
      feeRecipient,
      address(this)
    );
  }

  function testFail__initialize_adapter_asset_is_not_matching() public {
    MockERC20 newAsset = new MockERC20("New Mock Token", "NTKN", 18);
    MockERC4626 newAdapter = new MockERC4626(IERC20(address(newAsset)), "Mock Token Vault", "vwTKN");

    address vaultAddress = address(new Vault());

    vault = Vault(vaultAddress);
    vault.initialize(
      IERC20(address(asset)),
      IERC4626(address(newAdapter)),
      VaultFees({ deposit: 0, withdrawal: 0, management: 0, performance: 0 }),
      feeRecipient,
      address(this)
    );
  }

  function testFail__initialize_adapter_addressZero() public {
    MockERC20 newAsset = new MockERC20("New Mock Token", "NTKN", 18);
    MockERC4626 newAdapter = new MockERC4626(IERC20(address(newAsset)), "Mock Token Vault", "vwTKN");

    address vaultAddress = address(new Vault());

    vault = Vault(vaultAddress);
    vault.initialize(
      IERC20(address(asset)),
      IERC4626(address(newAdapter)),
      VaultFees({ deposit: 0, withdrawal: 0, management: 0, performance: 0 }),
      feeRecipient,
      address(this)
    );
  }

  function testFail__initialize_feeRecipient_addressZero() public {
    address vaultAddress = address(new Vault());

    vault = Vault(vaultAddress);
    vault.initialize(
      IERC20(address(asset)),
      IERC4626(address(adapter)),
      VaultFees({ deposit: 0, withdrawal: 0, management: 0, performance: 0 }),
      address(0),
      address(this)
    );
  }

  /*//////////////////////////////////////////////////////////////
                        DEPOSIT / WITHDRAW
    //////////////////////////////////////////////////////////////*/

  function test__deposit_withdraw(uint128 amount) public {
    if (amount == 0) amount = 1;

    uint256 aliceassetAmount = amount;

    asset.mint(alice, aliceassetAmount);

    vm.prank(alice);
    asset.approve(address(vault), aliceassetAmount);
    assertEq(asset.allowance(alice, address(vault)), aliceassetAmount);

    uint256 alicePreDepositBal = asset.balanceOf(alice);

    vm.prank(alice);
    uint256 aliceShareAmount = vault.deposit(aliceassetAmount, alice);

    assertEq(adapter.afterDepositHookCalledCounter(), 1);

    // Expect exchange rate to be 1:1 on initial deposit.
    assertEq(aliceassetAmount, aliceShareAmount);
    assertEq(vault.previewWithdraw(aliceShareAmount), aliceassetAmount);
    assertEq(vault.previewDeposit(aliceassetAmount), aliceShareAmount);
    assertEq(vault.totalSupply(), aliceShareAmount);
    assertEq(vault.totalAssets(), aliceassetAmount);
    assertEq(vault.balanceOf(alice), aliceShareAmount);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceassetAmount);
    assertEq(asset.balanceOf(alice), alicePreDepositBal - aliceassetAmount);

    vm.prank(alice);
    vault.withdraw(aliceassetAmount, alice, alice);

    assertEq(adapter.beforeWithdrawHookCalledCounter(), 1);

    assertEq(vault.totalAssets(), 0);
    assertEq(vault.balanceOf(alice), 0);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
    assertEq(asset.balanceOf(alice), alicePreDepositBal);
  }

  function testFail__deposit_zero() public {
    vault.deposit(0, address(this));
  }

  function test__withdraw_zero() public {
    vault.withdraw(0, address(this), address(this));
  }

  function testFail__deposit_with_no_approval() public {
    vault.deposit(1e18, address(this));
  }

  function testFail__deposit_with_not_enough_approval() public {
    asset.mint(address(this), 1e18);
    asset.approve(address(vault), 0.5e18);
    assertEq(asset.allowance(address(this), address(vault)), 0.5e18);

    vault.deposit(1e18, address(this));
  }

  function testFail__withdraw_with_not_enough_assets() public {
    asset.mint(address(this), 0.5e18);
    asset.approve(address(vault), 0.5e18);

    vault.deposit(0.5e18, address(this));

    vault.withdraw(1e18, address(this), address(this));
  }

  function testFail__withdraw_with_no_assets() public {
    vault.withdraw(1e18, address(this), address(this));
  }

  /*//////////////////////////////////////////////////////////////
                          MINT / REDEEM
    //////////////////////////////////////////////////////////////*/

  function test__mint_redeem(uint128 amount) public {
    if (amount == 0) amount = 1;

    uint256 aliceShareAmount = amount;

    asset.mint(alice, aliceShareAmount);

    vm.prank(alice);
    asset.approve(address(vault), aliceShareAmount);
    assertEq(asset.allowance(alice, address(vault)), aliceShareAmount);

    uint256 alicePreDepositBal = asset.balanceOf(alice);

    vm.prank(alice);
    uint256 aliceassetAmount = vault.mint(aliceShareAmount, alice);

    assertEq(adapter.afterDepositHookCalledCounter(), 1);

    // Expect exchange rate to be 1:1 on initial mint.
    assertEq(aliceShareAmount, aliceassetAmount);
    assertEq(vault.previewWithdraw(aliceShareAmount), aliceassetAmount);
    assertEq(vault.previewDeposit(aliceassetAmount), aliceShareAmount);
    assertEq(vault.totalSupply(), aliceShareAmount);
    assertEq(vault.totalAssets(), aliceassetAmount);
    assertEq(vault.balanceOf(alice), aliceassetAmount);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceassetAmount);
    assertEq(asset.balanceOf(alice), alicePreDepositBal - aliceassetAmount);

    vm.prank(alice);
    vault.redeem(aliceShareAmount, alice, alice);

    assertEq(adapter.beforeWithdrawHookCalledCounter(), 1);

    assertEq(vault.totalAssets(), 0);
    assertEq(vault.balanceOf(alice), 0);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
    assertEq(asset.balanceOf(alice), alicePreDepositBal);
  }

  function testFail__mint_zero() public {
    vault.mint(0, address(this));
  }

  function test__redeem_zero() public {
    vault.redeem(0, address(this), address(this));
  }

  function testFail__mint_with_no_approval() public {
    vault.mint(1e18, address(this));
  }

  function testFail__mint_with_not_enough_approval() public {
    asset.mint(address(this), 1e18);
    asset.approve(address(vault), 0.5e18);
    assertEq(asset.allowance(address(this), address(vault)), 0.5e18);

    vault.mint(1e18, address(this));
  }

  function testFail__redeem_with_not_enough_shares() public {
    asset.mint(address(this), 0.5e18);
    asset.approve(address(vault), 0.5e18);

    vault.deposit(0.5e18, address(this));

    vault.redeem(1e18, address(this), address(this));
  }

  function testFail__redeem_with_no_shares() public {
    vault.redeem(1e18, address(this), address(this));
  }

  /*//////////////////////////////////////////////////////////////
                DEPOSIT / MINT / WITHDRAW / REDEEM
    //////////////////////////////////////////////////////////////*/

  function test__multiple_mint_deposit_redeem_withdraw() public {
    // Scenario:
    // A = Alice, B = Bob
    //  ________________________________________________________
    // | Vault shares | A share | A assets | B share | B assets |
    // |========================================================|
    // | 1. Alice mints 2000 shares (costs 2000 tokens)         |
    // |--------------|---------|----------|---------|----------|
    // |         2000 |    2000 |     2000 |       0 |        0 |
    // |--------------|---------|----------|---------|----------|
    // | 2. Bob deposits 4000 tokens (mints 4000 shares)        |
    // |--------------|---------|----------|---------|----------|
    // |         6000 |    2000 |     2000 |    4000 |     4000 |
    // |--------------|---------|----------|---------|----------|
    // | 3. Vault mutates by +3000 tokens...                    |
    // |    (simulated yield returned from adapter)...         |
    // |--------------|---------|----------|---------|----------|
    // |         6000 |    2000 |     3000 |    4000 |     6000 |
    // |--------------|---------|----------|---------|----------|
    // | 4. Alice deposits 2000 tokens (mints 1333 shares)      |
    // |--------------|---------|----------|---------|----------|
    // |         7333 |    3333 |     4999 |    4000 |     6000 |
    // |--------------|---------|----------|---------|----------|
    // | 5. Bob mints 2000 shares (costs 3000 assets)           |
    // |--------------|---------|----------|---------|----------|
    // |         9333 |    3333 |     4999 |    6000 |     9000 |
    // |--------------|---------|----------|---------|----------|
    // | 6. Vault mutates by +3000 tokens...                    |
    // |    (simulated yield returned from adapter)            |
    // |    NOTE: Vault holds 17001 tokens, but sum of          |
    // |          assetsOf() is 17000.                          |
    // |--------------|---------|----------|---------|----------|
    // |         9333 |    3333 |     6071 |    6000 |    10928 |
    // |--------------|---------|----------|---------|----------|
    // | 7. Alice redeem 1333 shares (2428 assets)              |
    // |--------------|---------|----------|---------|----------|
    // |         8000 |    2000 |     3643 |    6000 |    10929 |
    // |--------------|---------|----------|---------|----------|
    // | 8. Bob withdraws 2928 assets (1608 shares)             |
    // |--------------|---------|----------|---------|----------|
    // |         6392 |    2000 |     3642 |    4392 |     8000 |
    // |--------------|---------|----------|---------|----------|
    // | 9. Alice withdraws 3643 assets (2000 shares)           |
    // |--------------|---------|----------|---------|----------|
    // |         4392 |       0 |        0 |    4392 |     8000 |
    // |--------------|---------|----------|---------|----------|
    // | 10. Bob redeem 4392 shares (8000 tokens)               |
    // |--------------|---------|----------|---------|----------|
    // |            0 |       0 |        0 |       0 |        0 |
    // |______________|_________|__________|_________|__________|

    uint256 mutationassetAmount = 3000;

    asset.mint(alice, 4000);

    vm.prank(alice);
    asset.approve(address(vault), 4000);

    assertEq(asset.allowance(alice, address(vault)), 4000);

    asset.mint(bob, 7001);

    vm.prank(bob);
    asset.approve(address(vault), 7001);

    assertEq(asset.allowance(bob, address(vault)), 7001);

    // 1. Alice mints 2000 shares (costs 2000 tokens)
    vm.prank(alice);
    uint256 aliceassetAmount = vault.mint(2000, alice);

    uint256 aliceShareAmount = vault.previewDeposit(aliceassetAmount);
    assertEq(adapter.afterDepositHookCalledCounter(), 1);

    // Expect to have received the requested mint amount.
    assertEq(aliceShareAmount, 2000);
    assertEq(vault.balanceOf(alice), aliceShareAmount);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceassetAmount);
    assertEq(vault.convertToShares(aliceassetAmount), vault.balanceOf(alice));

    // Expect a 1:1 ratio before mutation.
    assertEq(aliceassetAmount, 2000);

    // Sanity check.
    assertEq(vault.totalSupply(), aliceShareAmount);
    assertEq(vault.totalAssets(), aliceassetAmount);

    // 2. Bob deposits 4000 tokens (mints 4000 shares)
    vm.prank(bob);
    uint256 bobShareAmount = vault.deposit(4000, bob);
    uint256 bobassetAmount = vault.previewWithdraw(bobShareAmount);
    assertEq(adapter.afterDepositHookCalledCounter(), 2);

    // Expect to have received the requested asset amount.
    assertEq(bobassetAmount, 4000);
    assertEq(vault.balanceOf(bob), bobShareAmount);
    assertEq(vault.convertToAssets(vault.balanceOf(bob)), bobassetAmount);
    assertEq(vault.convertToShares(bobassetAmount), vault.balanceOf(bob));

    // Expect a 1:1 ratio before mutation.
    assertEq(bobShareAmount, bobassetAmount);

    // Sanity check.
    uint256 preMutationShareBal = aliceShareAmount + bobShareAmount;
    uint256 preMutationBal = aliceassetAmount + bobassetAmount;
    assertEq(vault.totalSupply(), preMutationShareBal);
    assertEq(vault.totalAssets(), preMutationBal);
    assertEq(vault.totalSupply(), 6000);
    assertEq(vault.totalAssets(), 6000);

    // 3. Vault mutates by +3000 tokens...                    |
    //    (simulated yield returned from adapter)...
    // The Vault now contains more tokens than deposited which causes the exchange rate to change.
    // Alice share is 33.33% of the Vault, Bob 66.66% of the Vault.
    // Alice's share count stays the same but the asset amount changes from 2000 to 3000.
    // Bob's share count stays the same but the asset amount changes from 4000 to 6000.
    asset.mint(address(adapter), mutationassetAmount);
    assertEq(vault.totalSupply(), preMutationShareBal);
    assertEq(vault.totalAssets(), preMutationBal + mutationassetAmount);
    assertEq(vault.balanceOf(alice), aliceShareAmount);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceassetAmount + (mutationassetAmount / 3) * 1);
    assertEq(vault.balanceOf(bob), bobShareAmount);
    assertEq(vault.convertToAssets(vault.balanceOf(bob)), bobassetAmount + (mutationassetAmount / 3) * 2);

    // 4. Alice deposits 2000 tokens (mints 1333 shares)
    vm.prank(alice);
    vault.deposit(2000, alice);

    assertEq(vault.totalSupply(), 7333);
    assertEq(vault.balanceOf(alice), 3333);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), 4999);
    assertEq(vault.balanceOf(bob), 4000);
    assertEq(vault.convertToAssets(vault.balanceOf(bob)), 6000);

    // 5. Bob mints 2000 shares (costs 3000 assets)
    // NOTE: Bob's assets spent got rounded up
    // NOTE: Alices's vault assets got rounded up
    vm.prank(bob);
    vault.mint(2000, bob);

    assertEq(vault.totalSupply(), 9333);
    assertEq(vault.balanceOf(alice), 3333);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), 4999);
    assertEq(vault.balanceOf(bob), 6000);
    assertEq(vault.convertToAssets(vault.balanceOf(bob)), 9000);

    // Sanity checks:
    // Alice and bob should have spent all their tokens now
    // Bob still has 1 wei left
    assertEq(asset.balanceOf(alice), 0);
    assertEq(asset.balanceOf(bob), 1);
    // Assets in vault: 4k (alice) + 7k (bob) + 3k (yield)
    assertEq(vault.totalAssets(), 14000);

    // 6. Vault mutates by +3000 tokens
    asset.mint(address(adapter), mutationassetAmount);
    assertEq(vault.totalAssets(), 17000);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), 6071);
    assertEq(vault.convertToAssets(vault.balanceOf(bob)), 10928);

    // 7. Alice redeem 1333 shares (2428 assets)
    vm.prank(alice);
    vault.redeem(1333, alice, alice);

    assertEq(asset.balanceOf(alice), 2428);
    assertEq(vault.totalSupply(), 8000);
    assertEq(vault.totalAssets(), 14572);
    assertEq(vault.balanceOf(alice), 2000);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), 3643);
    assertEq(vault.balanceOf(bob), 6000);
    assertEq(vault.convertToAssets(vault.balanceOf(bob)), 10929);

    // 8. Bob withdraws 2929 assets (1608 shares)
    vm.prank(bob);
    vault.withdraw(2929, bob, bob);

    assertEq(asset.balanceOf(bob), 2930);
    assertEq(vault.totalSupply(), 6392);
    assertEq(vault.totalAssets(), 11643);
    assertEq(vault.balanceOf(alice), 2000);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), 3642);
    assertEq(vault.balanceOf(bob), 4392);
    assertEq(vault.convertToAssets(vault.balanceOf(bob)), 8000);

    // 9. Alice withdraws 3643 assets (2000 shares)
    vm.prank(alice);
    vault.withdraw(3643, alice, alice);

    assertEq(asset.balanceOf(alice), 6071);
    assertEq(vault.totalSupply(), 4392);
    assertEq(vault.totalAssets(), 8000);
    assertEq(vault.balanceOf(alice), 0);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
    assertEq(vault.balanceOf(bob), 4392);
    assertEq(vault.convertToAssets(vault.balanceOf(bob)), 8000);

    // 10. Bob redeem 4392 shares (8000 tokens)
    vm.prank(bob);
    vault.redeem(4392, bob, bob);
    assertEq(asset.balanceOf(bob), 10930);
    assertEq(vault.totalSupply(), 0);
    assertEq(vault.totalAssets(), 0);
    assertEq(vault.balanceOf(alice), 0);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
    assertEq(vault.balanceOf(bob), 0);
    assertEq(vault.convertToAssets(vault.balanceOf(bob)), 0);

    // Sanity check
    assertEq(asset.balanceOf(address(vault)), 0);
  }

  function test__interactions_for_someone_else() public {
    // init 2 users with a 1e18 balance
    asset.mint(alice, 1e18);
    asset.mint(bob, 1e18);

    vm.prank(alice);
    asset.approve(address(vault), 1e18);

    vm.prank(bob);
    asset.approve(address(vault), 1e18);

    // alice deposits 1e18 for bob
    vm.prank(alice);
    vault.deposit(1e18, bob);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(vault.balanceOf(bob), 1e18);
    assertEq(asset.balanceOf(alice), 0);

    // bob mint 1e18 for alice
    vm.prank(bob);
    vault.mint(1e18, alice);
    assertEq(vault.balanceOf(alice), 1e18);
    assertEq(vault.balanceOf(bob), 1e18);
    assertEq(asset.balanceOf(bob), 0);

    // alice redeem 1e18 for bob
    vm.prank(alice);
    vault.redeem(1e18, bob, alice);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(vault.balanceOf(bob), 1e18);
    assertEq(asset.balanceOf(bob), 1e18);

    // bob withdraw 1e18 for alice
    vm.prank(bob);
    vault.withdraw(1e18, alice, bob);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(vault.balanceOf(bob), 0);
    assertEq(asset.balanceOf(alice), 1e18);
  }

  /*//////////////////////////////////////////////////////////////
                          TAKING FEES
    //////////////////////////////////////////////////////////////*/

  function test__previewDeposit_previewMint_takes_fees_into_account(uint8 fuzzAmount) public {
    uint256 amount = bound(uint256(fuzzAmount), 1, 1 ether);

    _setFees(1e17, 0, 0, 0);

    asset.mint(alice, amount);

    vm.prank(alice);
    asset.approve(address(vault), amount);

    // Test PreviewDeposit and Deposit
    uint256 expectedShares = vault.previewDeposit(amount);

    vm.prank(alice);
    uint256 actualShares = vault.deposit(amount, alice);
    assertApproxEqAbs(expectedShares, actualShares, 2);
  }

  function test__previewWithdraw_previewRedeem_takes_fees_into_account(uint8 fuzzAmount) public {
    uint256 amount = bound(uint256(fuzzAmount), 1, 1 ether);

    _setFees(0, 1e17, 0, 0);

    asset.mint(alice, amount);
    asset.mint(bob, amount);

    vm.startPrank(alice);
    asset.approve(address(vault), amount);
    uint256 shares = vault.deposit(amount, alice);
    vm.stopPrank();

    vm.startPrank(bob);
    asset.approve(address(vault), amount);
    vault.deposit(amount, bob);
    vm.stopPrank();

    // Test PreviewWithdraw and Withdraw
    // NOTE: Reduce the amount of assets to withdraw to take withdrawalFee into account (otherwise we would withdraw more than we deposited)
    uint256 withdrawAmount = (amount / 10) * 9;
    uint256 expectedShares = vault.previewWithdraw(withdrawAmount);

    vm.prank(alice);
    uint256 actualShares = vault.withdraw(withdrawAmount, alice, alice);
    assertApproxEqAbs(expectedShares, actualShares, 1);

    // Test PreviewRedeem and Redeem
    uint256 expectedAssets = vault.previewRedeem(shares);

    vm.prank(bob);
    uint256 actualAssets = vault.redeem(shares, bob, bob);
    assertApproxEqAbs(expectedAssets, actualAssets, 1);
  }

  function test__managementFee(uint128 timeframe) public {
    // Test Timeframe less than 10 years
    vm.assume(timeframe <= 315576000);
    uint256 depositAmount = 1 ether;

    _setFees(0, 0, 1e17, 0);

    asset.mint(alice, depositAmount);
    vm.startPrank(alice);
    asset.approve(address(vault), depositAmount);
    vault.deposit(depositAmount, alice);
    vm.stopPrank();

    // Increase Block Time to trigger managementFee
    uint256 timestamp = block.timestamp + timeframe;
    vm.roll(timestamp);

    uint256 expectedFeeInAsset = vault.accruedManagementFee();

    uint256 expectedFeeInShares = vault.convertToShares(expectedFeeInAsset);

    vault.takeManagementAndPerformanceFees();

    assertEq(vault.totalSupply(), depositAmount + expectedFeeInShares);
    assertEq(vault.balanceOf(feeRecipient), expectedFeeInShares);

    // High Water Mark should remain unchanged
    assertEq(vault.highWaterMark(), 1 ether);
  }

  function test__performanceFee(uint128 amount) public {
    vm.assume(amount <= 315576000);
    uint256 depositAmount = 1 ether;

    _setFees(0, 0, 0, 1e17);

    asset.mint(alice, depositAmount);
    vm.startPrank(alice);
    asset.approve(address(vault), depositAmount);
    vault.deposit(depositAmount, alice);
    vm.stopPrank();

    // Increase asset assets to trigger performanceFee
    asset.mint(address(adapter), amount);

    uint256 expectedFeeInAsset = vault.accruedPerformanceFee();
    uint256 expectedFeeInShares = vault.convertToShares(expectedFeeInAsset);

    vault.takeManagementAndPerformanceFees();

    assertEq(vault.totalSupply(), depositAmount + expectedFeeInShares);
    assertEq(vault.balanceOf(feeRecipient), expectedFeeInShares);

    // There should be a new High Water Mark
    assertEq(vault.highWaterMark(), (depositAmount + amount).mulDivDown(depositAmount, depositAmount));
  }

  /*//////////////////////////////////////////////////////////////
                          CHANGE FEES
    //////////////////////////////////////////////////////////////*/

  // Propose Fees
  function test__proposeFees() public {
    VaultFees memory newVaultFees = VaultFees({ deposit: 1, withdrawal: 1, management: 1, performance: 1 });

    uint256 callTime = block.timestamp;
    vm.expectEmit(false, false, false, true, address(vault));
    emit NewFeesProposed(newVaultFees, callTime);

    vault.proposeFees(newVaultFees);

    assertEq(vault.proposedFeeTime(), callTime);
    (uint256 deposit, uint256 withdrawal, uint256 management, uint256 performance) = vault.proposedFees();
    assertEq(deposit, 1);
    assertEq(withdrawal, 1);
    assertEq(management, 1);
    assertEq(performance, 1);
  }

  function testFail__proposeFees_nonOwner() public {
    VaultFees memory newVaultFees = VaultFees({ deposit: 1, withdrawal: 1, management: 1, performance: 1 });

    vm.prank(alice);
    vault.proposeFees(newVaultFees);
  }

  function testFail__proposeFees_fees_too_high() public {
    VaultFees memory newVaultFees = VaultFees({ deposit: 1e18, withdrawal: 1, management: 1, performance: 1 });

    vault.proposeFees(newVaultFees);
  }

  // Change Fees
  function test__changeFees() public {
    VaultFees memory newVaultFees = VaultFees({ deposit: 1, withdrawal: 1, management: 1, performance: 1 });
    vault.proposeFees(newVaultFees);

    vm.warp(block.timestamp + 3 days);

    vm.expectEmit(false, false, false, true, address(vault));
    emit ChangedFees(VaultFees({ deposit: 0, withdrawal: 0, management: 0, performance: 0 }), newVaultFees);

    vault.changeFees();

    (uint256 deposit, uint256 withdrawal, uint256 management, uint256 performance) = vault.fees();
    assertEq(deposit, 1);
    assertEq(withdrawal, 1);
    assertEq(management, 1);
    assertEq(performance, 1);
  }

  function testFail__changeFees_NonOwner() public {
    vm.prank(alice);
    vault.changeFees();
  }

  function testFail__changeFees_respect_rageQuit() public {
    VaultFees memory newVaultFees = VaultFees({ deposit: 1, withdrawal: 1, management: 1, performance: 1 });
    vault.proposeFees(newVaultFees);

    // Didnt respect 3 days before propsal and change
    vault.changeFees();
  }

  /*//////////////////////////////////////////////////////////////
                          SET FEE_RECIPIENT
    //////////////////////////////////////////////////////////////*/

  function test__setFeeRecipient() public {
    vm.expectEmit(false, false, false, true, address(vault));
    emit FeeRecipientUpdated(feeRecipient, alice);

    vault.setFeeRecipient(alice);

    assertEq(vault.feeRecipient(), alice);
  }

  function testFail__setFeeRecipient_NonOwner() public {
    vm.prank(alice);
    vault.setFeeRecipient(alice);
  }

  function testFail__setFeeRecipient_addressZero() public {
    vault.setFeeRecipient(address(0));
  }

  /*//////////////////////////////////////////////////////////////
                          CHANGE ADAPTER
    //////////////////////////////////////////////////////////////*/

  // Propose Adapter
  function test__proposeAdapter() public {
    MockERC4626 newAdapter = new MockERC4626(IERC20(address(asset)), "Mock Token Vault", "vwTKN");

    uint256 callTime = block.timestamp;
    vm.expectEmit(false, false, false, true, address(vault));
    emit NewAdapterProposed(IERC4626(address(newAdapter)), callTime);

    vault.proposeAdapter(IERC4626(address(newAdapter)));

    assertEq(vault.proposedAdapterTime(), callTime);
    assertEq(address(vault.proposedAdapter()), address(newAdapter));
  }

  function testFail__proposeAdapter_nonOwner() public {
    MockERC4626 newAdapter = new MockERC4626(IERC20(address(asset)), "Mock Token Vault", "vwTKN");

    vm.prank(alice);
    vault.proposeAdapter(IERC4626(address(newAdapter)));
  }

  function testFail__proposeAdapter_asset_missmatch() public {
    MockERC20 newAsset = new MockERC20("New Mock Token", "NTKN", 18);
    MockERC4626 newAdapter = new MockERC4626(IERC20(address(newAsset)), "Mock Token Vault", "vwTKN");

    vm.prank(alice);
    vault.proposeAdapter(IERC4626(address(newAdapter)));
  }

  // Change Adapter
  function test__changeAdapter() public {
    MockERC4626 newAdapter = new MockERC4626(IERC20(address(asset)), "Mock Token Vault", "vwTKN");
    uint256 depositAmount = 1 ether;

    // Deposit funds for testing
    asset.mint(alice, depositAmount);
    vm.startPrank(alice);
    asset.approve(address(vault), depositAmount);
    vault.deposit(depositAmount, alice);
    vm.stopPrank();

    // Increase assets in asset Adapter to check hwm and assetCheckpoint later
    asset.mint(address(adapter), depositAmount);
    vault.takeManagementAndPerformanceFees();
    uint256 oldHWM = vault.highWaterMark();

    // Preparation to change the adapter
    vault.proposeAdapter(IERC4626(address(newAdapter)));

    vm.warp(block.timestamp + 3 days);

    vm.expectEmit(false, false, false, true, address(vault));
    emit ChangedAdapter(IERC4626(address(adapter)), IERC4626(address(newAdapter)));

    vault.changeAdapter();

    assertEq(asset.allowance(address(vault), address(adapter)), 0);
    assertEq(asset.balanceOf(address(adapter)), 0);
    assertEq(adapter.balanceOf(address(vault)), 0);

    assertEq(asset.balanceOf(address(newAdapter)), depositAmount * 2);
    assertEq(newAdapter.balanceOf(address(vault)), depositAmount * 2);
    assertEq(asset.allowance(address(vault), address(newAdapter)), type(uint256).max);

    assertEq(vault.highWaterMark(), oldHWM);
  }

  function testFail__changeAdapter_NonOwner() public {
    vm.prank(alice);
    vault.changeAdapter();
  }

  function testFail__changeAdapter_respect_rageQuit() public {
    MockERC4626 newAdapter = new MockERC4626(IERC20(address(asset)), "Mock Token Vault", "vwTKN");

    vault.proposeAdapter(IERC4626(address(newAdapter)));

    // Didnt respect 3 days before propsal and change
    vault.changeAdapter();
  }

  /*//////////////////////////////////////////////////////////////
                          SET RAGE QUIT
    //////////////////////////////////////////////////////////////*/

  function test__setQuitPeriod() public {
    uint256 newQuitPeriod = 1 days;
    vm.expectEmit(false, false, false, true, address(vault));
    emit QuitPeriodSet(newQuitPeriod);

    vault.setQuitPeriod(newQuitPeriod);

    assertEq(vault.quitPeriod(), newQuitPeriod);
  }

  function testFail__setQuitPeriod_NonOwner() public {
    vm.prank(alice);
    vault.setQuitPeriod(1 days);
  }

  function testFail__setQuitPeriod_too_low() public {
    vault.setQuitPeriod(23 hours);
  }

  function testFail__setQuitPeriod_too_high() public {
    vault.setQuitPeriod(8 days);
  }

  /*//////////////////////////////////////////////////////////////
                                PAUSE
    //////////////////////////////////////////////////////////////*/

  // Pause
  function test__pause() public {
    uint256 depositAmount = 1 ether;

    // Deposit funds for testing
    asset.mint(alice, depositAmount * 3);
    vm.startPrank(alice);
    asset.approve(address(vault), depositAmount * 3);
    vault.deposit(depositAmount * 2, alice);
    vm.stopPrank();

    vm.expectEmit(false, false, false, true, address(vault));
    emit Paused(address(this));

    vault.pause();

    assertTrue(vault.paused());

    vm.prank(alice);
    vm.expectRevert("Pausable: paused");
    vault.deposit(depositAmount, alice);

    vm.prank(alice);
    vm.expectRevert("Pausable: paused");
    vault.mint(depositAmount, alice);

    vm.prank(alice);
    vault.withdraw(depositAmount, alice, alice);

    vm.prank(alice);
    vault.redeem(depositAmount, alice, alice);
  }

  function testFail__pause_nonOwner() public {
    vm.prank(alice);
    vault.pause();
  }

  // Unpause
  function test__unpause() public {
    uint256 depositAmount = 1 ether;

    // Deposit funds for testing
    asset.mint(alice, depositAmount * 2);
    vm.prank(alice);
    asset.approve(address(vault), depositAmount * 2);

    vault.pause();

    vm.expectEmit(false, false, false, true, address(vault));
    emit Unpaused(address(this));

    vault.unpause();

    assertFalse(vault.paused());

    vm.prank(alice);
    vault.deposit(depositAmount, alice);

    vm.prank(alice);
    vault.mint(depositAmount, alice);

    vm.prank(alice);
    vault.withdraw(depositAmount, alice, alice);

    vm.prank(alice);
    vault.redeem(depositAmount, alice, alice);
  }

  function testFail__unpause_nonOwner() public {
    vault.pause();

    vm.prank(alice);
    vault.unpause();
  }

  /*//////////////////////////////////////////////////////////////
                              PERMIT
    //////////////////////////////////////////////////////////////*/

  function test_permit() public {
    uint256 privateKey = 0xBEEF;
    address owner = vm.addr(privateKey);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      privateKey,
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          vault.DOMAIN_SEPARATOR(),
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp))
        )
      )
    );

    vault.permit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);

    assertEq(vault.allowance(owner, address(0xCAFE)), 1e18);
    assertEq(vault.nonces(owner), 1);
  }
}
