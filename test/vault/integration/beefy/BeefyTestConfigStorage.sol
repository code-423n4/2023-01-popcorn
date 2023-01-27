// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { ITestConfigStorage } from "../abstract/ITestConfigStorage.sol";

struct BeefyTestConfig {
  address beefyVault;
  address beefyBooster;
}

contract BeefyTestConfigStorage is ITestConfigStorage {
  BeefyTestConfig[] internal testConfigs;

  constructor() {
    // Polygon - stMATIC-MATIC vault
    testConfigs.push(
      BeefyTestConfig(0xF79BF908d0e6d8E7054375CD80dD33424B1980bf, 0x69C28193185CFcd42D62690Db3767915872bC5EA)
    );

    // Polygon - MAI-FRAX sLP vault
    //testConfigs.push(BeefyTestConfig(0xbC94bDb5393CBABF9B319E892abC95B93B5949A8, address(0)));

    //testConfigs.push(BeefyTestConfig(0xc10C75247f503cc7B7496D72a6F3C443adDB7110, address(0)));
  }

  function getTestConfig(uint256 i) public view returns (bytes memory) {
    return abi.encode(testConfigs[i].beefyVault, testConfigs[i].beefyBooster);
  }

  function getTestConfigLength() public view returns (uint256) {
    return testConfigs.length;
  }
}
