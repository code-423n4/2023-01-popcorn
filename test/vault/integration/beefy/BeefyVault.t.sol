// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { AbstractVaultIntegrationTest } from "../abstract/AbstractVaultIntegrationTest.sol";
import { BeefyAdapter, SafeERC20, IERC20, IERC20Metadata, Math, IBeefyVault, IBeefyBooster, IAdapter, IStrategy } from "../../../../src/vault/adapter/beefy/BeefyAdapter.sol";
import { BeefyTestConfigStorage, BeefyTestConfig, ITestConfigStorage } from "./BeefyTestConfigStorage.sol";
import { MockStrategy } from "../../../utils/mocks/MockStrategy.sol";
import { IPermissionRegistry, Permission } from "../../../../src/interfaces/vault/IPermissionRegistry.sol";
import { PermissionRegistry } from "../../../../src/vault/PermissionRegistry.sol";

contract BeefyVaultTest is AbstractVaultIntegrationTest {
  using Math for uint256;

  IBeefyBooster beefyBooster;
  IBeefyVault beefyVault;
  IStrategy strategy;
  IPermissionRegistry permissionRegistry;

  function setUp() public {
    uint256 forkId = vm.createSelectFork(vm.rpcUrl("polygon"));
    vm.selectFork(forkId);

    testConfigStorage = ITestConfigStorage(address(new BeefyTestConfigStorage()));

    _setUpTest(testConfigStorage.getTestConfig(0));
  }

  function overrideSetup(bytes memory testConfig) public override {
    _setUpTest(testConfig);
  }

  function _setUpTest(bytes memory testConfig) internal {
    createAdapter();

    (address _beefyVault, address _beefyBooster) = abi.decode(testConfig, (address, address));
    beefyVault = IBeefyVault(_beefyVault);
    beefyBooster = IBeefyBooster(_beefyBooster);
    address _asset = IBeefyVault(beefyVault).want();
    strategy = IStrategy(address(new MockStrategy()));

    // Endorse Beefy Vault
    permissionRegistry = IPermissionRegistry(address(new PermissionRegistry(address(this))));
    Permission[] memory newPermissions = new Permission[](1);
    newPermissions[0] = Permission(true, false);
    address[] memory targets = new address[](1);
    targets[0] = _beefyVault;
    permissionRegistry.setPermissions(targets, newPermissions);

    adapter.initialize(
      abi.encode(IERC20(_asset), address(this), strategy, 0, sigs, ""),
      address(permissionRegistry),
      testConfig
    );

    setUpBaseTest(IERC20(_asset), adapter, "Beefy ", 1);

    vm.label(_beefyVault, "beefyVault");
    vm.label(_beefyBooster, "beefyBooster");
    vm.label(address(strategy), "strategy");
    vm.label(address(this), "test");
  }

  /*//////////////////////////////////////////////////////////////
                          HELPER
    //////////////////////////////////////////////////////////////*/

  function createAdapter() public override {
    adapter = IAdapter(address(new BeefyAdapter()));
  }

  function increasePricePerShare(uint256 amount) public override {
    deal(address(asset), address(beefyVault), asset.balanceOf(address(beefyVault)) + amount);
    beefyVault.earn();
  }
}
