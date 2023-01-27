// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import {AdapterBase, IERC20} from "../../../src/vault/adapter/abstracts/AdapterBase.sol";

contract MockAdapter is AdapterBase {
    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;
    uint256 public initValue;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    function initialize(
        bytes memory adapterInitData,
        address,
        bytes memory mockInitData
    ) external initializer {
        __AdapterBase_init(adapterInitData);

        if (mockInitData.length > 0)
            initValue = abi.decode(mockInitData, (uint256));
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function _totalAssets() internal view override returns (uint256) {
        return underlyingBalance;
    }

    function _underlyingBalance() internal view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function _protocolDeposit(uint256, uint256) internal override {
        afterDepositHookCalledCounter++;
    }

    function _protocolWithdraw(uint256, uint256) internal override {
        beforeWithdrawHookCalledCounter++;
    }
}
