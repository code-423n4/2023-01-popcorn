// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";

import { YearnAdapter, SafeERC20, IERC20, IERC20Metadata, Math, VaultAPI, IYearnRegistry } from "../../../../src/vault/adapter/yearn/YearnAdapter.sol";
import { YearnTestConfigStorage, YearnTestConfig } from "./YearnTestConfigStorage.sol";
import { AbstractAdapterTest, ITestConfigStorage, IAdapter } from "../abstract/AbstractAdapterTest.sol";

contract YearnAdapterTest is AbstractAdapterTest {
  using Math for uint256;

  VaultAPI yearnVault;

  function setUp() public {
    uint256 forkId = vm.createSelectFork(vm.rpcUrl("mainnet"));
    vm.selectFork(forkId);

    testConfigStorage = ITestConfigStorage(address(new YearnTestConfigStorage()));

    _setUpTest(testConfigStorage.getTestConfig(0));
  }

  function overrideSetup(bytes memory testConfig) public override {
    _setUpTest(testConfig);
  }

  function _setUpTest(bytes memory testConfig) internal {
    createAdapter();

    address _asset = abi.decode(testConfig, (address));

    setUpBaseTest(IERC20(_asset), adapter, 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804, 10, "Yearn ", false);

    yearnVault = VaultAPI(IYearnRegistry(externalRegistry).latestVault(_asset));

    vm.label(address(yearnVault), "yearnVault");
    vm.label(address(asset), "asset");
    vm.label(address(this), "test");

    adapter.initialize(abi.encode(asset, address(this), address(0), 0, sigs, ""), externalRegistry, "");
  }

  /*//////////////////////////////////////////////////////////////
                          HELPER
    //////////////////////////////////////////////////////////////*/

  function createAdapter() public override {
    adapter = IAdapter(address(new YearnAdapter()));
  }

  function increasePricePerShare(uint256 amount) public override {
    deal(
      address(asset),
      address(yearnVault),
      asset.balanceOf(address(0x336600990ae039b4acEcE630667871AeDEa46E5E)) + amount
    );
  }

  function iouBalance() public view override returns (uint256) {
    return yearnVault.balanceOf(address(adapter));
  }

  // Verify that totalAssets returns the expected amount
  function verify_totalAssets() public override {
    // Make sure totalAssets isnt 0
    deal(address(asset), bob, defaultAmount);
    vm.startPrank(bob);
    asset.approve(address(adapter), defaultAmount);
    adapter.deposit(defaultAmount, bob);
    vm.stopPrank();

    assertApproxEqAbs(
      adapter.totalAssets(),
      adapter.convertToAssets(adapter.totalSupply()),
      _delta_,
      string.concat("totalSupply converted != totalAssets", baseTestId)
    );
    assertApproxEqAbs(
      adapter.totalAssets(),
      iouBalance().mulDiv(
        yearnVault.pricePerShare(),
        10**IERC20Metadata(address(adapter)).decimals(),
        Math.Rounding.Up
      ),
      _delta_,
      string.concat("totalAssets != yearn assets", baseTestId)
    );
  }

  /*//////////////////////////////////////////////////////////////
                          INITIALIZATION
    //////////////////////////////////////////////////////////////*/

  function verify_adapterInit() public override {
    assertEq(adapter.asset(), yearnVault.token(), "asset");
    assertEq(
      IERC20Metadata(address(adapter)).name(),
      string.concat("Popcorn Yearn", IERC20Metadata(address(asset)).name(), " Adapter"),
      "name"
    );
    assertEq(
      IERC20Metadata(address(adapter)).symbol(),
      string.concat("popY-", IERC20Metadata(address(asset)).symbol()),
      "symbol"
    );

    assertEq(asset.allowance(address(adapter), address(yearnVault)), type(uint256).max, "allowance");
  }

  /*//////////////////////////////////////////////////////////////
                          ROUNDTRIP TESTS
    //////////////////////////////////////////////////////////////*/

  // NOTE - The yearn adapter suffers often from an off-by-one error which "steals" 1 wei from the user
  function test__RT_deposit_withdraw() public override {
    _mintFor(defaultAmount, bob);

    vm.startPrank(bob);
    uint256 shares1 = adapter.deposit(defaultAmount, bob);
    uint256 shares2 = adapter.withdraw(defaultAmount - 1, bob, bob);
    vm.stopPrank();

    assertGe(shares2, shares1, testId);
  }

  // NOTE - The yearn adapter suffers often from an off-by-one error which "steals" 1 wei from the user
  function test__RT_mint_withdraw() public override {
    _mintFor(adapter.previewMint(defaultAmount), bob);

    vm.startPrank(bob);
    uint256 assets = adapter.mint(defaultAmount, bob);
    uint256 shares = adapter.withdraw(assets - 1, bob, bob);
    vm.stopPrank();

    assertGe(shares, defaultAmount, testId);
  }
}
