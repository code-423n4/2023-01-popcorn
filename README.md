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

This protocols goal is to make vault creation easy, safe and all without compromising on flexibility. It allows anyone to spin up their own Yearn in minutes. <br/>
**Vaults** can be created permissionlessly based on any underlying protocol and execute arbitrary strategies. 
The factory uses only endorsed **Adapters** and **Strategies** with minimal user input to reduce complexity for a creator and ensure safety of the created clones. It gives vault creators a quick and easy way to spin up any **Vault** they need and end users the guarantee that the created **Vault** will be safe. For some more context checkout the [whitepaper](./WhitePaper.pdf)

The protocol consists of 2 parts. The Vault Factory and the actual Vaults and Adapters.
<br/>
<br/>
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
<br/>

![vaultInfraFlow](./vaultInfraFlow.PNG)

<br/>
<br/>

## Vault, Adapter & Strategy
-   **Vault:** A simple ERC-4626 implementation which allows the creator to add various types of fees and interact with other protocols via any ERC-4626 compliant **Adapter**. Fees and **Adapter** can be changed by the creator after a ragequit period.
-   **Adapter:** An immutable wrapper for existing contract to allow for ERC-4626 compatability. Optionally adapters can utilize a **Strategy** to perform various additional tasks besides simply depositing and withdrawing token from the wrapped protocol. PopcornDAO will collect management fees via these **Adapter**.
-   **Strategy:** An arbitrary module to perform various tasks from compouding, leverage or simply forwarding rewards. Strategies can be attached to an **Adapter** to give it additionaly utility.

![vaultFlow](./vaultFlow.PNG)

<br/>
<br/>

## Utility Contracts
Additionally we included 2 utility contracts that are used alongside the vault system.
-   **MultiRewardStaking:** A simple ERC-4626 implementation of a staking contract. A user can provide an asset and receive rewards in multiple tokens. Adding these rewards is done by the contract owner. They can be either paid out over time or instantly. Rewards can optionally also be vested on claim.
-   **MultiRewardEscrow:** Allows anyone to lock up and vest arbitrary tokens over a given time. Will be used mainly in conjuction with **MultiRewardStaking**.

<br/>
<br/>

# Scope


| Contract | SLOC | Purpose | Libraries used |  
| ----------- | ----------- | ----------- | ----------- |
| [src/interfaces/vault/IAdapter.sol](src/interfaces/vault/IAdapter.sol) | 23 |  |  |
| [src/interfaces/vault/IAdminProxy.sol](src/interfaces/vault/IAdminProxy.sol) | 5 |  |  |
| [src/interfaces/vault/ICloneFactory.sol](src/interfaces/vault/ICloneFactory.sol) | 6 |  |  |
| [src/interfaces/vault/ICloneRegistry.sol](src/interfaces/vault/ICloneRegistry.sol) | 10 |  |  |
| [src/interfaces/vault/IDeploymentController.sol](src/interfaces/vault/IDeploymentController.sol) | 24 |  |  |
| [src/interfaces/vault/IERC4626.sol](src/interfaces/vault/IERC4626.sol) | 28 |  | [oz-upgradable/tokens/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/IERC20Upgradeable.sol) |
| [src/interfaces/vault/IPermissionRegistry.sol](src/interfaces/vault/IPermissionRegistry.sol) | 11 |  |  |
| [src/interfaces/vault/IStrategy.sol](src/interfaces/vault/IStrategy.sol) | 7 | |  |
| [src/interfaces/vault/ITemplateRegistry.sol](src/interfaces/vault/ITemplateRegistry.sol) | 25 |  |  |
| [src/interfaces/vault/IVault.sol](src/interfaces/vault/IVault.sol) | 48 |  |  |
| [src/interfaces/vault/IVaultController.sol](src/interfaces/vault/IVaultController.sol) | 64 |  | [oz-upgradable/tokens/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/IERC20Upgradeable.sol) |
| [src/interfaces/vault/IVaultRegistry.sol](src/interfaces/vault/IVaultRegistry.sol) | 16 |  |  |
| [src/interfaces/vault/IWithRewards.sol](src/interfaces/vault/IWithRewards.sol) | 5 |  |  |
| [src/interfaces/IEIP165.sol](src/interfaces/IEIP165.sol) | 4 |  |  |
| [src/interfaces/IMultiRewardEscrow.sol](src/interfaces/IMultiRewardEscrow.sol) | 26 || [oz-upgradable/tokens/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/IERC20Upgradeable.sol) |
| [src/interfaces/IMultiRewardStaking.sol](src/interfaces/IMultiRewardStaking.sol) | 38 |  | [oz-upgradable/tokens/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/IERC20Upgradeable.sol) |
| [src/utils/EIP165](src/utils/EIP165.sol) | 4 | Exposes the contract interface. |  |
| [src/utils/MultiRewardEscrow.sol](src/utils/MultiRewardEscrow.sol) | 118 | Allows vesting of arbitrary token over any time frame. |  |
| [src/utils/MultiRewardStaking.sol](src/utils/MultiRewardStaking.sol) | 311 | Staking contract with one stakingToken and multiple rewardsToken. Rewards can be paid out instantly or over time. |  |
| [src/vault/adapter/abstracts/AdapterBase](src/vault/adapter/abstracts/AdapterBase.sol) | 403 | 4626-compliant abstract for all adapter implementations. Holds a majority of the business logic of each adapter.  | [oz-upgradable/tokens/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/IERC20Upgradeable.sol) [oz-upgradable/tokens/ERC4626.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol) [oz-upgradable/tokens/IERC20Metadata.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/SafeERC20.sol) [oz-upgradable/tokens/SafeERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/token/ERC20/utils/SafeERC20Upgradeable.sol) [oz-upgradable/math/MathUpgradeable.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/math/MathUpgradeable.sol) [oz-upgradable/security/PausableUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/security/PausableUpgradeable) [oz-upgradable/security/ReentrancyGuardUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/security/ReentrancyGuardUpgradeable)|
| [src/vault/adapter/abstracts/OnlyStrategy.sol](src/vault/adapter/abstracts/OnlyStrategy.sol) | 12 | Abstract modifier for delegatecall. |  |
| [src/vault/adapter/abstracts/WithRewards.sol](src/vault/adapter/abstracts/WithRewards.sol) | 8 | Abstract for adapters with additional rewardTokens. |  |
| [src/vault/adapter/beefy/BeefyAdapter.sol](src/vault/adapter/beefy/BeefyAdapter.sol) | 163 | Wraps any BeefyV6 Vault in a 4626-compliant interface. Uses AdapterBase. | [oz-upgradable/tokens/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/IERC20Upgradeable.sol) [oz-upgradable/tokens/ERC4626.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol) [oz-upgradable/tokens/IERC20Metadata.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/SafeERC20.sol) [oz-upgradable/tokens/SafeERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/token/ERC20/utils/SafeERC20Upgradeable.sol) [oz-upgradable/math/MathUpgradeable.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/math/MathUpgradeable.sol) [oz-upgradable/security/PausableUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/security/PausableUpgradeable) |
| [src/vault/adapter/beefy/IBeefy.sol](src/vault/adapter/beefy/IBeefy.sol) | 31 | Beefy Interfaces |  |
| [src/vault/adapter/yearn/IYearn.sol](src/vault/adapter/yearn/IYearn.sol) | 18 | Yearn Interfaces |  |
| [src/vault/adapter/yearn/YearnAdapter.sol](src/vault/adapter/yearn/YearnAdapter.sol) | 110 | Wraps any Yearn Vault in a 4626-compliant interface. Uses AdapterBase. | [oz-upgradable/tokens/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/IERC20Upgradeable.sol) [oz-upgradable/tokens/ERC4626.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol) [oz-upgradable/tokens/IERC20Metadata.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/SafeERC20.sol) [oz-upgradable/tokens/SafeERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/token/ERC20/utils/SafeERC20Upgradeable.sol) [oz-upgradable/math/MathUpgradeable.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/math/MathUpgradeable.sol) [oz-upgradable/security/PausableUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/security/PausableUpgradeable) |
| [src/vault/AdminProxy.sol](src/vault/AdminProxy.sol) | 12 | Proxy contract that owns a majority of contracts. Allows `VaultController` to call management functions. |  |
| [src/vault/CloneFactory.sol](src/vault/CloneFactory.sol) | 17 | Creates arbitrary clones based on `Templates`. | [oz/proxy/Clones.sol]([openzeppelin-contracts/proxy/Clones.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol)) |
| [src/vault/CloneRegistry.sol](src/vault/CloneRegistry.sol) | 29 | Registers each newly created clone. |  |
| [src/vault/DeploymentController.sol](src/vault/DeploymentController.sol) | 55 | Bundles auxiliary contracts for easy interaction. |  |
| [src/vault/PermissionRegistry.sol](src/vault/PermissionRegistry.sol) | 24 | Endorsement/Rejection registry for arbitrary addresses. |  |
| [src/vault/TemplateRegistry.sol](src/vault/TemplateRegistry.sol) | 57 | Registry for clone `Templates` with additional metadata. `Templates` are used by the `CloneFactory` |  |
| [src/vault/Vault.sol](src/vault/Vault.sol) | 426 | 4626-compliant Vault implementation. Uses Adapter for actual deposits and withdrawals. Allows creator to set fees. | [oz-upgradable/tokens/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/IERC20Upgradeable.sol) [oz-upgradable/tokens/ERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/ERC20Upgradeable.sol) [oz-upgradable/tokens/IERC20Metadata.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/SafeERC20.sol) [oz-upgradable/tokens/SafeERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/token/ERC20/utils/SafeERC20Upgradeable.sol) [oz-upgradable/math/MathUpgradeable.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/math/MathUpgradeable.sol) [oz-upgradable/security/PausableUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/security/PausableUpgradeable) [oz-upgradable/security/ReentrancyGuardUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/security/ReentrancyGuardUpgradeable) |
| [src/vault/VaultController.sol](src/vault/v.sol) | 520 | ManagementContract to create new clones, register and endorse `Templates` or call management functions. |  |
| [src/vault/VaultRegistry.sol](src/vault/VaultRegistry.sol) | 34 | Registers all created `Vaults` and provides aditional metadata. |  |


## Out of scope

- IPermit.sol
- IOwned.sol
- IPausable.sol
- IUniswapRouterV2.sol
- IWETH.sol
- Owned.sol
- OwnedUpgradeable.sol
- Pool2SingleAssetCompounder.sol
- RewardsClaimer.sol
- StrategyBase.sol

Some of these contracts depend on older utility contracts which is why this repo contains more than just these contracts. These dependencies have been audited previously.
Additionally there are some wip sample strategies which might help to illustrate how strategies can be used in conjuction with adapters.

# Additional Context

**Note:** The `AdapterBase.sol` still has a TODO to use a deterministic address for `feeRecipient`. As we didnt deploy this proxy yet on our target chains it remains a placeholder value for the moment. Once the proxy exists we will simply switch out the palceholder address.
<br/>
<br/>

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

Most of these attacks are only possible when the `VaultController` is misconfigured on deployment or its `owner` is compromised. The `owner` of `VaultController` should be a MultiSig which should make this process harder but nonetheless not impossible.<br/>

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

## Prerequisites

-   [Node.js](https://nodejs.org/en/) v16.16.0 (you may wish to use [nvm][1])
-   [yarn](https://yarnpkg.com/)
-   [foundry](https://github.com/foundry-rs/foundry)

<br/>
<br/>

## Installing Dependencies

```
foundryup

forge install

yarn install
```

<br/>
<br/>

## Testing

```
Add RPC urls to .env

forge build

forge test --no-match-contract 'Abstract'
```
