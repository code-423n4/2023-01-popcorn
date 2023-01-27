# Popcorn DAO contest details
- Total Prize Pool: $90,500 USDC
  - HM awards: $63,750 USDC 
  - QA report awards: $7,500 USDC 
  - Gas report awards: $3,750 USDC 
  - Judge + presort awards: $15,000 USDC 
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-01-popcorn-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts January 31, 2023 20:00 UTC
- Ends February 07, 2023 20:00 UTC


# Overview

This protocols goal is to make vault creation easy, safe and all without compromising on flexibility. It allows anyone to spin up their own Yearn in minutes.

**Vaults** can be created permissionlessly based on any underlying protocol and execute arbitrary strategies. 
The factory uses only endorsed **Adapters** and **Strategies** with minimal user input to reduce complexity for a creator and ensure safety of the created clones. It gives vault creators a quick and easy way to spin up any **Vault** they need and end users the guarantee that the created **Vault** will be safe. For some more context checkout the [whitepaper](https://github.com/code-423n4/2023-01-popcorn//blob/main/WhitePaper.pdf)

The protocol consists of 2 parts. The Vault Factory and the actual Vaults and Adapters.

## Vault Factory
The Vault Factory part consists of a mix of Registry and Execution contracts. All contracts are immutable but execution contracts can be swapped out if requirements change or additional functionality should be added.

-   **CloneFactory:** A simple factory that clones and initializes new contracts based on a **Template**.
-   **CloneRegistry:** A minimal registry which saves the address of each newly created clone.
-   **TemplateRegistry:** A registry for **Templates**. Each Template contains an implementation and some metadata to ensure proper initialization of the clone. **Templates** need to be endorsed before they can be used to create new clones. Anyone can add a new **Template** but only the contract owner can endorse them if they are deemed correct and safe.
-   **DeploymentController:** This contract bundles **CloneFactory**, **CloneRegistry** and **TemplateRegistry** to simplify the creation of new clones and ensure their safety.
-   **PermissionRegistry:** A simple registry to endorse or reject certain addresses from beeing used. Currently this is only used to reject potentially unsafe assets and in the creation of beefy adapters.
-   **VaulRegistry:** This registry safes new **Vaults** with additional metadata. The metadata can be used by any frontend and supply it with additional informations about the vault.
-   **VaultController:** This contract bundles all previously mentioned contracts. It adds additional ux and safety measures to the creation of **Vaults**, **Adapters** and **Staking** contracts. Any management function in the protocol must be executed via the **VaultController**.
-   **AdminProxy:** This contract owns any clone and most infrastructure contracts. Its used to make ownership transfers easy in case the **VaultController** should get updated. This contracts forwards almost all calls from the **VaultController**.

**Note:** This system ensures that minimal user input is needed and executions are handled with valid inputs and in the correct order. The goal is to minimize human error and the attack surface. A lot of configurations for **Adapters** and **Strategies** is very protocol specific. These are therefore mainly handled in the implementations itself. **Adapters** should receive all there critical data from an on-chain registry of the underlying protocol. As its nearly impossible to tell otherwise if the passed in configuration is malicious. There is still a need for some kind of governance to ensure that only correct and safe **Templates** are added and dangerous assets get rejected. 
![vaultInfraFlow](https://github.com/code-423n4/2023-01-popcorn/blob/main/vaultInfraFlow.PNG)
## Vault, Adapter & Strategy
-   **Vault:** A simple ERC-4626 implementation which allows the creator to add various types of fees and interact with other protocols via any ERC-4626 compliant **Adapter**. Fees and **Adapter** can be changed by the creator after a ragequit period.
-   **Adapter:** An immutable wrapper for existing contract to allow for ERC-4626 compatability. Optionally adapters can utilize a **Strategy** to perform various additional tasks besides simply depositing and withdrawing token from the wrapped protocol. PopcornDAO will collect management fees via these **Adapter**.
-   **Strategy:** An arbitrary module to perform various tasks from compouding, leverage or simply forwarding rewards. Strategies can be attached to an **Adapter** to give it additionaly utility.

![vaultFlow](https://github.com/code-423n4/2023-01-popcorn/blob/main/vaultFlow.PNG)

## Utility Contracts
Additionally we included 2 utility contracts that are used alongside the vault system.
-   **MultiRewardStaking:** A simple ERC-4626 implementation of a staking contract. A user can provide an asset and receive rewards in multiple tokens. Adding these rewards is done by the contract owner. They can be either paid out over time or instantly. Rewards can optionally also be vested on claim.
-   **MultiRewardEscrow:** Allows anyone to lock up and vest arbitrary tokens over a given time. Will be used mainly in conjuction with **MultiRewardStaking**.


## Scope
### Files in scope
|File|[SLOC](#nowhere "(nSLOC, SLOC, Lines)")|Description and [Coverage](#nowhere "(Lines hit / Total)")|Libraries|
|:-|:-:|:-|:-|
|_Contracts (16)_|
|[src/utils/EIP165.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/EIP165.sol)|[4](#nowhere "(nSLOC:4, SLOC:4, Lines:8)")|Exposes the contract interface., &nbsp;&nbsp;-||
|[src/vault/adapter/abstracts/OnlyStrategy.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/abstracts/OnlyStrategy.sol)|[8](#nowhere "(nSLOC:8, SLOC:8, Lines:14)")|Abstract modifier for delegatecall., &nbsp;&nbsp;-||
|[src/vault/AdminProxy.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/AdminProxy.sol)|[12](#nowhere "(nSLOC:8, SLOC:12, Lines:26)")|Proxy contract that owns a majority of contracts. Allows VaultController to call management functions., &nbsp;&nbsp;[100.00%](#nowhere "(Hit:1 / Total:1)")||
|[src/vault/adapter/abstracts/WithRewards.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/abstracts/WithRewards.sol)|[12](#nowhere "(nSLOC:12, SLOC:12, Lines:24)")|Abstract for adapters with additional rewardTokens., &nbsp;&nbsp;[0.00%](#nowhere "(Hit:0 / Total:1)")||
|[src/vault/CloneFactory.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/CloneFactory.sol)|[17](#nowhere "(nSLOC:17, SLOC:17, Lines:49)")|Creates arbitrary clones based on Templates., &nbsp;&nbsp;[100.00%](#nowhere "(Hit:5 / Total:5)")| `openzeppelin-contracts/*`|
|[src/vault/PermissionRegistry.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/PermissionRegistry.sol)|[24](#nowhere "(nSLOC:24, SLOC:24, Lines:58)")|Endorsement/Rejection registry for arbitrary addresses., &nbsp;&nbsp;[100.00%](#nowhere "(Hit:8 / Total:8)")||
|[src/vault/CloneRegistry.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/CloneRegistry.sol)|[29](#nowhere "(nSLOC:21, SLOC:29, Lines:68)")|Registers each newly created clone., &nbsp;&nbsp;[66.67%](#nowhere "(Hit:4 / Total:6)")||
|[src/vault/VaultRegistry.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/VaultRegistry.sol)|[34](#nowhere "(nSLOC:34, SLOC:34, Lines:78)")|Registers all created Vaults and provides aditional metadata., &nbsp;&nbsp;[60.00%](#nowhere "(Hit:6 / Total:10)")||
|[src/vault/DeploymentController.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/DeploymentController.sol)|[55](#nowhere "(nSLOC:47, SLOC:55, Lines:136)")|Bundles auxiliary contracts for easy interaction., &nbsp;&nbsp;[100.00%](#nowhere "(Hit:13 / Total:13)")||
|[src/vault/TemplateRegistry.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/TemplateRegistry.sol)|[57](#nowhere "(nSLOC:53, SLOC:57, Lines:126)")|Registry for clone Templates with additional metadata. Templates are used by the CloneFactory, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:18 / Total:18)")||
|[src/vault/adapter/yearn/YearnAdapter.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/yearn/YearnAdapter.sol)|[110](#nowhere "(nSLOC:83, SLOC:110, Lines:173)")|Wraps any Yearn Vault in a 4626-compliant interface. Uses AdapterBase., &nbsp;&nbsp;[96.43%](#nowhere "(Hit:27 / Total:28)")||
|[src/utils/MultiRewardEscrow.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/MultiRewardEscrow.sol) [🧮](#nowhere "Uses Hash-Functions")|[118](#nowhere "(nSLOC:112, SLOC:118, Lines:217)")|Allows vesting of arbitrary token over any time frame., &nbsp;&nbsp;[100.00%](#nowhere "(Hit:42 / Total:42)")| `openzeppelin-contracts-upgradeable/*` `openzeppelin-contracts/*` `solmate/*`|
|[src/vault/adapter/beefy/BeefyAdapter.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/beefy/BeefyAdapter.sol)|[163](#nowhere "(nSLOC:121, SLOC:163, Lines:240)")|Wraps any BeefyV6 Vault in a 4626-compliant interface. Uses AdapterBase., &nbsp;&nbsp;[80.85%](#nowhere "(Hit:38 / Total:47)")||
|[src/utils/MultiRewardStaking.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/MultiRewardStaking.sol) [📤](#nowhere "Initiates ETH Value Transfer") [🧮](#nowhere "Uses Hash-Functions") [🔖](#nowhere "Handles Signatures: ecrecover") [Σ](#nowhere "Unchecked Blocks")|[311](#nowhere "(nSLOC:267, SLOC:311, Lines:503)")|Staking contract with one stakingToken and multiple rewardsToken. Rewards can be paid out instantly or over time., &nbsp;&nbsp;[100.00%](#nowhere "(Hit:110 / Total:110)")| `openzeppelin-contracts-upgradeable/*` `solmate/*`|
|[src/vault/Vault.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/Vault.sol) [🧮](#nowhere "Uses Hash-Functions") [🔖](#nowhere "Handles Signatures: ecrecover") [Σ](#nowhere "Unchecked Blocks")|[426](#nowhere "(nSLOC:376, SLOC:426, Lines:730)")|4626-compliant Vault implementation. Uses Adapter for actual deposits and withdrawals. Allows creator to set fees., &nbsp;&nbsp;[90.00%](#nowhere "(Hit:108 / Total:120)")| `openzeppelin-contracts-upgradeable/*` `openzeppelin-contracts/*`|
|[src/vault/VaultController.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/VaultController.sol) [🧮](#nowhere "Uses Hash-Functions")|[520](#nowhere "(nSLOC:467, SLOC:520, Lines:872)")|ManagementContract to create new clones, register and endorse Templates or call management functions., &nbsp;&nbsp;[98.87%](#nowhere "(Hit:175 / Total:177)")| `openzeppelin-contracts-upgradeable/*`|
|_Abstracts (1)_|
|[src/vault/adapter/abstracts/AdapterBase.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/abstracts/AdapterBase.sol) [👥](#nowhere "DelegateCall") [🧮](#nowhere "Uses Hash-Functions") [🔖](#nowhere "Handles Signatures: ecrecover") [Σ](#nowhere "Unchecked Blocks")|[405](#nowhere "(nSLOC:284, SLOC:405, Lines:696)")|4626-compliant abstract for all adapter implementations. Holds a majority of the business logic of each adapter., &nbsp;&nbsp;[95.65%](#nowhere "(Hit:88 / Total:92)")| `openzeppelin-contracts-upgradeable/*`|
|_Interfaces (18)_|
|[src/interfaces/IEIP165.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/IEIP165.sol)|[4](#nowhere "(nSLOC:4, SLOC:4, Lines:6)")|-||
|[src/interfaces/vault/IAdminProxy.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IAdminProxy.sol)|[5](#nowhere "(nSLOC:5, SLOC:5, Lines:10)")|-||
|[src/interfaces/vault/IWithRewards.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IWithRewards.sol)|[5](#nowhere "(nSLOC:5, SLOC:5, Lines:10)")|-||
|[src/interfaces/vault/ICloneFactory.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/ICloneFactory.sol)|[6](#nowhere "(nSLOC:6, SLOC:6, Lines:11)")|-||
|[src/interfaces/vault/IStrategy.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IStrategy.sol)|[7](#nowhere "(nSLOC:7, SLOC:7, Lines:14)")|-||
|[src/interfaces/vault/ICloneRegistry.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/ICloneRegistry.sol)|[10](#nowhere "(nSLOC:6, SLOC:10, Lines:16)")|-||
|[src/interfaces/vault/IPermissionRegistry.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IPermissionRegistry.sol)|[11](#nowhere "(nSLOC:11, SLOC:11, Lines:19)")|-||
|[src/interfaces/vault/IVaultRegistry.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IVaultRegistry.sol)|[16](#nowhere "(nSLOC:16, SLOC:16, Lines:30)")|-||
|[src/vault/adapter/yearn/IYearn.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/yearn/IYearn.sol)|[18](#nowhere "(nSLOC:18, SLOC:18, Lines:34)")|Yearn Interfaces, &nbsp;&nbsp;-| `openzeppelin-contracts-upgradeable/*`|
|[src/interfaces/vault/IAdapter.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IAdapter.sol)|[23](#nowhere "(nSLOC:19, SLOC:23, Lines:39)")|-||
|[src/interfaces/vault/IDeploymentController.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IDeploymentController.sol)|[24](#nowhere "(nSLOC:20, SLOC:24, Lines:41)")|-||
|[src/interfaces/vault/ITemplateRegistry.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/ITemplateRegistry.sol)|[25](#nowhere "(nSLOC:21, SLOC:25, Lines:45)")|-||
|[src/interfaces/IMultiRewardEscrow.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/IMultiRewardEscrow.sol)|[26](#nowhere "(nSLOC:20, SLOC:26, Lines:43)")|-| `openzeppelin-contracts-upgradeable/*`|
|[src/interfaces/vault/IERC4626.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IERC4626.sol)|[28](#nowhere "(nSLOC:28, SLOC:28, Lines:61)")|-| `openzeppelin-contracts-upgradeable/*`|
|[src/vault/adapter/beefy/IBeefy.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/beefy/IBeefy.sol)|[31](#nowhere "(nSLOC:31, SLOC:31, Lines:57)")|Beefy Interfaces, &nbsp;&nbsp;-||
|[src/interfaces/IMultiRewardStaking.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/IMultiRewardStaking.sol)|[38](#nowhere "(nSLOC:26, SLOC:38, Lines:61)")|-||
|[src/interfaces/vault/IVault.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IVault.sol)|[48](#nowhere "(nSLOC:42, SLOC:48, Lines:97)")|-||
|[src/interfaces/vault/IVaultController.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IVaultController.sol)|[64](#nowhere "(nSLOC:43, SLOC:64, Lines:104)")|-||
|Total (over 35 files):| [2694](#nowhere "(nSLOC:2266, SLOC:2694, Lines:4716)") |[94.84%](#nowhere "Hit:643 / Total:678")|


### All other source contracts (not in scope)
|File|[SLOC](#nowhere "(nSLOC, SLOC, Lines)")|Description and [Coverage](#nowhere "(Lines hit / Total)")|Libraries|
|:-|:-:|:-|:-|
|_Contracts (5)_|
|[src/vault/strategy/StrategyBase.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/strategy/StrategyBase.sol)|[16](#nowhere "(nSLOC:16, SLOC:16, Lines:25)")|[0.00%](#nowhere "(Hit:0 / Total:4)")||
|[src/vault/strategy/RewardsClaimer.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/strategy/RewardsClaimer.sol)|[22](#nowhere "(nSLOC:22, SLOC:22, Lines:34)")|[0.00%](#nowhere "(Hit:0 / Total:9)")| `openzeppelin-contracts-upgradeable/*`|
|[src/utils/Owned.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/Owned.sol)|[29](#nowhere "(nSLOC:29, SLOC:29, Lines:40)")|[100.00%](#nowhere "(Hit:7 / Total:7)")||
|[src/utils/OwnedUpgradeable.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/OwnedUpgradeable.sol)|[30](#nowhere "(nSLOC:30, SLOC:30, Lines:42)")|[40.00%](#nowhere "(Hit:4 / Total:10)")| `openzeppelin-contracts-upgradeable/*`|
|[src/vault/strategy/Pool2SingleAssetCompounder.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/strategy/Pool2SingleAssetCompounder.sol)|[47](#nowhere "(nSLOC:47, SLOC:47, Lines:67)")|[0.00%](#nowhere "(Hit:0 / Total:28)")| `openzeppelin-contracts-upgradeable/*`|
|_Interfaces (5)_|
|[src/interfaces/external/IWETH.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/external/IWETH.sol) [💰](#nowhere "Payable Functions")|[5](#nowhere "(nSLOC:5, SLOC:5, Lines:10)")|-||
|[src/interfaces/IPausable.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/IPausable.sol)|[6](#nowhere "(nSLOC:6, SLOC:6, Lines:12)")|-||
|[src/interfaces/IOwned.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/IOwned.sol)|[7](#nowhere "(nSLOC:7, SLOC:7, Lines:14)")|-||
|[src/interfaces/IPermit.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/IPermit.sol)|[14](#nowhere "(nSLOC:6, SLOC:14, Lines:20)")|-||
|[src/interfaces/external/uni/IUniswapRouterV2.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/external/uni/IUniswapRouterV2.sol) [💰](#nowhere "Payable Functions")|[158](#nowhere "(nSLOC:27, SLOC:158, Lines:184)")|-||
|Total (over 10 files):| [334](#nowhere "(nSLOC:195, SLOC:334, Lines:448)") |[18.97%](#nowhere "Hit:11 / Total:58")|


## External imports
* **openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol**
  * ~~[src/utils/OwnedUpgradeable.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/OwnedUpgradeable.sol)~~
* **openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol**
  * [src/vault/Vault.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/Vault.sol)
  * [src/vault/adapter/abstracts/AdapterBase.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/abstracts/AdapterBase.sol)
* **openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol**
  * [src/vault/Vault.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/Vault.sol)
  * [src/vault/adapter/abstracts/AdapterBase.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/abstracts/AdapterBase.sol)
* **openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol**
  * [src/vault/Vault.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/Vault.sol)
  * ~~[src/vault/strategy/RewardsClaimer.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/strategy/RewardsClaimer.sol)~~
* **openzeppelin-contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol**
  * [src/utils/MultiRewardStaking.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/MultiRewardStaking.sol)
  * [src/vault/adapter/abstracts/AdapterBase.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/abstracts/AdapterBase.sol)
  * ~~[src/vault/strategy/Pool2SingleAssetCompounder.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/strategy/Pool2SingleAssetCompounder.sol)~~
* **openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol**
  * [src/interfaces/IMultiRewardEscrow.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/IMultiRewardEscrow.sol)
  * [src/interfaces/vault/IERC4626.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/interfaces/vault/IERC4626.sol)
  * [src/utils/MultiRewardEscrow.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/MultiRewardEscrow.sol)
  * [src/vault/adapter/yearn/IYearn.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/yearn/IYearn.sol)
* **openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol**
  * [src/utils/MultiRewardEscrow.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/MultiRewardEscrow.sol)
  * [src/utils/MultiRewardStaking.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/MultiRewardStaking.sol)
  * [src/vault/Vault.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/Vault.sol)
  * [src/vault/VaultController.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/VaultController.sol)
  * [src/vault/adapter/abstracts/AdapterBase.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/abstracts/AdapterBase.sol)
  * ~~[src/vault/strategy/RewardsClaimer.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/strategy/RewardsClaimer.sol)~~
* **openzeppelin-contracts-upgradeable/utils/math/MathUpgradeable.sol**
  * [src/utils/MultiRewardStaking.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/MultiRewardStaking.sol)
  * [src/vault/Vault.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/Vault.sol)
  * [src/vault/adapter/abstracts/AdapterBase.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/adapter/abstracts/AdapterBase.sol)
* **openzeppelin-contracts/proxy/Clones.sol**
  * [src/vault/CloneFactory.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/CloneFactory.sol)
* **openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol**
  * [src/vault/Vault.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/vault/Vault.sol)
* **openzeppelin-contracts/utils/math/Math.sol**
  * [src/utils/MultiRewardEscrow.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/MultiRewardEscrow.sol)
* **solmate/utils/SafeCastLib.sol**
  * [src/utils/MultiRewardEscrow.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/MultiRewardEscrow.sol)
  * [src/utils/MultiRewardStaking.sol](https://github.com/code-423n4/2023-01-popcorn//blob/main/src/utils/MultiRewardStaking.sol)

Some of these contracts depend on older utility contracts which is why this repo contains more than just these contracts. These dependencies have been audited previously.
Additionally there are some wip sample strategies which might help to illustrate how strategies can be used in conjuction with adapters.

# Additional Context

**Note:** The `AdapterBase.sol` still has a TODO to use a deterministic address for `feeRecipient`. As we didnt deploy this proxy yet on our target chains it remains a placeholder value for the moment. Once the proxy exists we will simply switch out the palceholder address.


# Security
There are multiple possible targets for attacks.
1. Draining user funds of endorsed vaults
2. Draining user funds with malicious vaults/adapter/strategies or staking contracts
3. Draining user funds with malicious assets
4. Grieving of management functions

### Dangerous Attacks
- Attack infrastructure to insert malicious assets / adapters / strategies
  - Set malicious `deploymentController`
  - Get malicious `Template` endorsed
  - Get malicious `asset` endorsed
- Initial Deposit exploit (See the test in `YearnAdapter.t.sol`)
- Change `fees` of a vault to the max amount and change the `feeRecipient` to the attacker
- Exchange the adapter of a vault for a malicious adapter
- Nominate new `owner` of the `adminProxy` to change configurations or endorse malicious `templates`
## Grieving Attacks
- Set `harvestCooldown` too low and waste tokens and gas on harvests
- Add a multitude of templates to make identifing the legit template harder in the endorsement process
- `Reject` legit vaults / assets
- `Pause` vaults / adapters of other `creators`
- Predeploy deterministic proxies on other chains

Most of these attacks are only possible when the `VaultController` is misconfigured on deployment or its `owner` is compromised. The `owner` of `VaultController` should be a MultiSig which should make this process harder but nonetheless not impossible.

## Inflation Attack
EIP-4626 is vulnerable to the so-called [inflation attacks](https://ethereum-magicians.org/t/address-eip-4626-inflation-attacks-with-virtual-shares-and-assets/12677). This attack results from the possibility to manipulate the exchange rate and front run a victim’s deposit when the vault has low liquidity volume.  A similiar issue that affects yearn is already known. See Finding 3, "Division rounding may affect issuance of shares" in [Yearn's ToB audit](https://github.com/yearn/yearn-security/blob/master/audits/20210719_ToB_yearn_vaultsv2/ToB_-_Yearn_Vault_v_2_Smart_Contracts_Audit_Report.pdf) for the details. In order to combat this `AdapterBase.sol` ignores gifted assets when calculating `totalAssets`. (To ensure correct functionality of rebasing tokens is the responsibility of the concrete `adapter`-implementations).
Additionally `creators` can send an initial deposit on vault/adapter creation to create some inital volume.

## Scoping Details 
```
- If you have a public code repo, please share it here:  
- How many contracts are in scope?: 36
- Total SLoC for these contracts?: 2728
- How many external imports are there?: 8
- How many separate interfaces and struct definitions are there for the contracts within scope?: 18 interfaces, 10 structs
- Does most of your code generally use composition or inheritance?: inheritance  
- How many external calls?: 21   
- What is the overall line coverage percentage provided by your tests?: 94.52%
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?: no
- Please describe required context: -
- Does it use an oracle?: no  
- Does the token conform to the ERC20 standard?: yes  
- Are there any novel or unique curve logic or mathematical models?: no 
- Does it use a timelock function?: yes  
- Is it an NFT?: no 
- Does it have an AMM?: no   
- Is it a fork of a popular project?: no   
- Does it use rollups?: no   
- Is it multi-chain?:  no
- Does it use a side-chain?: no
```

# Tests
## Quickstart command
`export ETH_RPC_URL="<your-eth-rpc-url>" && export POLYGON_RPC_URL="<your-polygon-rpc-url>" && rm -Rf 2023-01-popcorn || true && gc https://github.com/code-423n4/2023-01-popcorn.git -j8 --recurse-submodules && cd 2023-01-popcorn && echo -e "ETH_RPC_URL=$ETH_RPC_URL\nPOLYGON_RPC_URL=$POLYGON_RPC_URL" > .env && foundryup && forge install && yarn install && forge test --no-match-contract 'Abstract' --gas-report`
## Prerequisites

-   [Node.js](https://nodejs.org/en/) v16.16.0 (you may wish to use [nvm][1])
-   [yarn](https://yarnpkg.com/)
-   [foundry](https://github.com/foundry-rs/foundry)


## Installing Dependencies

```
foundryup

forge install

yarn install
```

## Testing

```
Add RPC urls to .env

forge build

forge test --no-match-contract 'Abstract'
```
