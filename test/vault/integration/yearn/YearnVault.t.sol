// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { AbstractVaultIntegrationTest } from "../abstract/AbstractVaultIntegrationTest.sol";
import { YearnAdapter, SafeERC20, IERC20, IERC20Metadata, Math, VaultAPI, IYearnRegistry, IAdapter } from "../../../../src/vault/adapter/yearn/YearnAdapter.sol";
import { YearnTestConfigStorage, YearnTestConfig, ITestConfigStorage } from "./YearnTestConfigStorage.sol";

contract YearnVaultTest is AbstractVaultIntegrationTest {
  using Math for uint256;

  VaultAPI yearnVault;
  address yearnRegistry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

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

    yearnVault = VaultAPI(IYearnRegistry(yearnRegistry).latestVault(_asset));

    adapter.initialize(abi.encode(_asset, address(this), address(0), 0, sigs, ""), yearnRegistry, "");

    setUpBaseTest(IERC20(_asset), adapter, "Yearn ", 1);

    vm.label(address(yearnVault), "yearnVault");
    vm.label(address(this), "test");
  }

  /*//////////////////////////////////////////////////////////////
                          HELPER
    //////////////////////////////////////////////////////////////*/

  function createAdapter() public override {
    adapter = IAdapter(address(new YearnAdapter()));
  }

  function increasePricePerShare(uint256 amount) public override {
    deal(address(asset), address(yearnVault), asset.balanceOf(address(yearnVault)) + amount);
  }
}
