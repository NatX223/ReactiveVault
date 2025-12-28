# ReactiveVault
ReactiveVault - yield optimizing DeFi vault

---  

## Live Link - https://reactive-vault.vercel.app/
## Demo - https://www.loom.com/share/f11531ac7b4c4b71bfe6ac87bfcf7465

## Table of Contents  

1. [Overview](#overview)  
2. [Problem Statement](#problem-statement)  
3. [Solution](#solution)  
4. [How It Works](#how-it-works)  
5. [Technologies Used](#technologies-used)  
6. [Addresses and TX hashes](#addresses-and-tx-hashes)
7. [Setup and Deployment](#setup-and-deployment)  
8. [Future Improvements](#future-improvements)  
9. [Acknowledgments](#acknowledgments)  

---  

## Overview  

Yield optimization between Aave and Compound traditionally requires manual monitoring or fragile off-chain bots. These methods are 
prone to execution latency and "Yield Erosion," where capital sits in sub-optimal pools while market rates shift. Because standard 
smart contracts are "blind" to external state changes, they cannot move funds autonomously when opportunities arise.

ReactiveVault eliminates this friction. By leveraging the Reactive Network’s native cron functionality, the vault monitors real-time 
APY differentials and executes rebalancing logic directly on-chain. If a rate flip exceeds the defined threshold, the vault 
autonomously migrates 100% of the capital to the highest-yielding pool. This makes yield farming self-sustaining, trustless, and 
perpetually optimized without a single manual transaction.

---  

## Problem Statement  

DeFi yields flip constantly between Aave and Compound, yet capital remains stagnant. Traditional smart contracts lack on-chain 
monitoring, forced to rely on slow, centralized off-chain triggers. This "blindness" causes execution latency and Yield Erosion, 
preventing capital from autonomously capturing the market's best rates.

---  

## Solution  

Powered by Reactive Network’s native cron functionality, our vault operates with total autonomy, eliminating the need for centralized 
keepers. It continuously calculates real-time APYs across Aave and Compound, automatically migrating capital to the highest-yielding 
pool. This replaces passive stagnation with a self-optimizing, zero-intervention strategy that captures peak yield 24/7.

---  

## How It Works 

The working mechanism of the project can be broken down into 3 workflows - switching pools, deposit ancd withdraw workflows

1. **Pool Switching**:
   - The CronReactive contract reacts cron events from the system contract.
   - The CronReactive calls the callback function on the vault contract to check for the current optimal pool.
   - The vault contract checks for the best pool and checks the yield difference and if it is more the threshold (set to 1%).
   - The vault contract calls the withdraw function on the current pool.
   - The vault contract calls the supply function on the optimal pool with the redeemed WETH.
2. **Deposit**:
   - A user calls the deposit function with some ETH to be deposited in the vault.
   - The vault contract calls the deposit function on the WETH contracts to obtain WETH.
   - The vault contract then calls the supply function on the current pool - the pool with the best yield.
   - An equivalent value of vault tokens are minted to the user.
3. **Withdraw**:
   - The user calls the withdraw function with the amount they want to withdraw.
   - The user's vault tokens are burnt.
   - The vault contract calls the withdraw function on the current pool.
   - The vault contract also calls the withdraw function on WETH contract and sends the redeemed ETH to the user.

The diagrams below describe the above mentioned workflows

<p align="center">
  <img src="https://github.com/NatX223/ReactiveVault/blob/main/assets/deposit_withdraw.png" width="500" alt="deposit/withdraw">
</p>

<p align="center">
  <img src="https://github.com/NatX223/ReactiveVault/blob/main/assets/pool_switching.png" width="500" alt="pool-switching">
</p>

---  

## Technologies Used  

| **Technology**    | **Purpose**                                              |  
|-------------------|----------------------------------------------------------|
| **Reactive**      | Use of Reactive's cron and callback functionality.       |  
| **Aave**          | Supplying to Aave WETH pool.                             |
| **Compound**      | Supplying to Compound WETH pool.                         | 
| **Next.js**       | Frontend framework for building the user interface.      |  

### Reactive

ReactiveVault was built to leverage the Reactive Network's native cron functionality, allowing the vault to autonomously monitor
real-time APY differentials and execute rebalancing logic on-chain. This approach eliminates the need for centralized off-chain
triggers, ensuring that capital is autonomously captured by the vault. The Reactive Network's cron functionality allows the vault to
continuously calculate real-time APYs across Aave and Compound, automatically migrating capital to the highest-yielding pool.

Another use of the reactive network is the use of callback in Vault contract to execute pool switching.
Below is a description of the reactive stack was used in the project.

- Cron functionality - The CronReactive contract subscribes to the cron event from the system contract and reacts to them by calling the callback function on the vault contract.
Below are the code snippets that show how this was implemented.

subscribing to cron event
```solidity
constructor(address _vault, uint256 _cron_topic) payable {
    vault = _vault;
    cron_topic = _cron_topic;
    service = ISystemContract(payable(SERVICE));
    if (!vm) {
        service.subscribe(
            block.chainid,
            address(service),
            _cron_topic,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }
}
```
 
calling the callback function
```solidity
function react(LogRecord calldata log) external vmOnly {

    /**
     * @dev Encode callback payload for vault optimization check
     * Calls the callback function on the vault with zero address parameter
     */
    bytes memory payload = abi.encodeWithSignature(
        "callback(address)",
        address(0)
    );

    emit Callback(chainId, vault, GAS_LIMIT, payload);
}
```

The full code can be found [here](https://github.com/NatX223/ReactiveVault/blob/main/Contracts/src/CronReactive.sol)

- Callback functionality - The CronReactive contract calls the callback function on the vault contract to check for the current optimal pool. The vault contract checks for the best pool and checks the yield difference and if it is more the threshold (set to 1%). The vault contract calls the withdraw function on the current pool. The vault contract calls the supply function on the optimal pool with the redeemed WETH.
Below are the code snippets that show how this was implemented.

```solidity
function callback(address sender) external authorizedSenderOnly rvmIdOnly(sender) {
    uint256 aaveRate = aaveRateFetcher();
    uint256 compRate = compoundRateFetcher();

    bool aaveBetter = (aaveRate > (compRate + YIELD_THRESHOLD)) && (currentPool == 1);
    bool compBetter = (compRate > (aaveRate + YIELD_THRESHOLD)) && (currentPool == 0);

    if (aaveBetter || compBetter) {
        _switchPool(aaveBetter ? 0 : 1);
    } else {
        emit OptimalPoolActive(currentPool, aaveRate, compRate);
    }
}

function _switchPool(uint8 targetPool) internal {
    uint8 fromPool = currentPool;
    
    // 1. Withdraw ALL (including interest dust)
    if (currentPool == 0) {
        Pool.withdraw(aaveWeth, type(uint256).max, address(this));
    } else {
        Comet.withdraw(compoundWeth, type(uint256).max);
    }

    // 2. Identify new balance (Principal + Interest)
    uint256 totalToMove = IERC20(targetPool == 0 ? aaveWeth : compoundWeth).balanceOf(address(this));

    // 3. Supply to new target
    if (targetPool == 0) {
        convertwethComTowethAave(totalToMove);
        Pool.supply(aaveWeth, totalToMove, address(this), 0);
    } else {
        convertwethAaveTowethCom(totalToMove);
        Comet.supply(compoundWeth, totalToMove);
    }

    currentPool = targetPool;
    emit PoolSwitched(fromPool, targetPool, totalToMove);
}
```

The full code can be found [here](https://github.com/NatX223/ReactiveVault/blob/main/Contracts/src/Vault.sol)

### Aave

Aave was used as one of the pools used in the project, the supply and withdraw functions were called in the vault contract.
The Aave yield was calculated to get the best yiled.
Below are the code snippets that show how this was implemented.

supply function
```solidity
function _supply(uint256 amount) internal {
    if (currentPool == 0) {
        obtainAaveWETH(amount);
        Pool.supply(aaveWeth, amount, address(this), 0);
    } else {
        obtainCompoundWETH(amount);
        Comet.supply(compoundWeth, amount);
    }
}
```

withdraw function
```solidity
function _withdrawFromCurrentPool(uint256 amount) internal {
    if (currentPool == 0) {
        Pool.withdraw(aaveWeth, amount, address(this));
    } else {
        Comet.withdraw(compoundWeth, amount);
    }
}
```

calculating yield
```solidity
/**
 * @notice Fetches current lending rate from Aave protocol
 * @return Current Aave lending rate in basis points (e.g., 500 = 5%)
 * @dev Converts from RAY precision to basis points for easier comparison
 */
function aaveRateFetcher() public view returns (uint256) {
    DataTypes.ReserveData memory data = Pool.getReserveData(aaveWeth);
    return (uint256(data.currentLiquidityRate) * 10000) / RAY;
}
```

### Compound

Compound was used as one of the pools used in the project, the supply and withdraw functions were called in the vault contract.
The Compound yield was calculated to get the best yiled.
Below are the code snippets that show how this was implemented.

supply function
```solidity
function _supply(uint256 amount) internal {
    if (currentPool == 0) {
        obtainAaveWETH(amount);
        Pool.supply(aaveWeth, amount, address(this), 0);
    } else {
        obtainCompoundWETH(amount);
        Comet.supply(compoundWeth, amount);
    }
}
```

withdraw function
```solidity
function _withdrawFromCurrentPool(uint256 amount) internal {
    if (currentPool == 0) {
        Pool.withdraw(aaveWeth, amount, address(this));
    } else {
        Comet.withdraw(compoundWeth, amount);
    }
}
```

calculating yield
```solidity
/**
 * @notice Fetches current lending rate from Compound v3 protocol
 * @return Current Compound lending rate in basis points (e.g., 500 = 5%)
 * @dev Calculates annualized rate from per-second rate and converts to basis points
 */
function compoundRateFetcher() public view returns (uint256) {
    uint256 utilization = Comet.getUtilization();
    uint256 supplyRate = uint256(Comet.getSupplyRate(utilization));
    return (supplyRate * SECONDS_PER_YEAR * 10000) / WAD;
}
```

## Addresses and TX hashes
The project was deployed on the sepolia and lasna with the following addresses.

| **Contract**            | **Addres**                                 |
|-------------------------|--------------------------------------------|
| **Vault**      | [0x60E3567B0987c5bE1A01f21114ed79c3e9dB6A2E](https://sepolia.etherscan.io/address/0x60E3567B0987c5bE1A01f21114ed79c3e9dB6A2E) |
| **CronReactive**       | [0x8D9E25C7b0439781c7755e01A924BbF532EDf24d](https://lasna.reactscan.net/address/0x58e95d9300254fbba4a6b0b8abc5e94bf9dc4c52/contract/0x8D9E25C7b0439781c7755e01A924BbF532EDf24d) |

Below is a table the transaction hashes.

| **Function**                               | **TransactionHash**                                                      |
|--------------------------------------------|--------------------------------------------------------------------------|
| **Deposit**          | [0xe019afa6cf31ade3acfa87aee03179ccdb29d0753105c26f6555e1ed24f17b7f](https://sepolia.etherscan.io/tx/0xe019afa6cf31ade3acfa87aee03179ccdb29d0753105c26f6555e1ed24f17b7f) |
| **Withdraw**      | [0xb3cd834bcab7638fec4ddc3e48c09ab9c815ba44566456de5b00f5634aa05236](https://sepolia.etherscan.io/tx/0xb3cd834bcab7638fec4ddc3e48c09ab9c815ba44566456de5b00f5634aa05236) |
| **Reacting to Cron Event**      | [0xfe925fba647ddd857e04a866811f7413a75a887c95db5139856a8e4dc6b810a6](https://lasna.reactscan.net/address/0x58e95d9300254fbba4a6b0b8abc5e94bf9dc4c52/9429) |
| **Callback**      | [0x5fe2e88128b2ba3f813d3aea0bd074b37484f651b474baebac23b7ab7ce67ae5](https://sepolia.etherscan.io/tx/0x5fe2e88128b2ba3f813d3aea0bd074b37484f651b474baebac23b7ab7ce67ae5) |


## Setup and Deployment  

### Prerequisites  

- Node.js v16+  
- Solidity development environment(Foundry)

### Local Setup  

The repository has to be cloned first

```bash  
  git clone https://github.com/NatX223/ReactiveVault  
```
- Smart contracts

1. Navigate to the smart contracts directory:  
  ```bash  
  cd Contracts  
  ```  
2. Install dependencies:  
  ```bash  
  forge install
  ```  
3. Set up environment variables:
  ```  
  PRIVATE_KEY=<private key>
  LASNA_RPC_URL=https://lasna-rpc.rnk.dev/
  SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com

  ```  
4. Compile smart contracts:  
  ```bash  
  forge build 
  ```  
5. Run deployment scripts:
  deploy the Vault contract
  ```bash
  forge create --broadcast --rpc-url sepoliaRPC --private-key $PRIVATE_KEY src/Vault.sol:Vault --value 0.1ether --constructor-args 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c 0x2D5ee574e710219a521449679A4A7f2B43f046ad 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A 0x2943ac1216979aD8dB76D9147F64E61adc126e96 ReactVault RCTVLT
  ```
  - deploy CronReactive
  ```bash
  forge create --broadcast --rpc-url lasnaRPC --private-key $PRIVATE_KEY src/CronReactive.sol:CronReactive --value 1ether --constructor-args 0xVaultAddress 0xPreferedCronTopic
  ```
## Testing

### Run Tests

```bash
# Run all tests
forge test -vv

# Run specific test contracts
forge test --match-contract VaultSepolia.t.sol -vv

# Run with gas reporting
forge test --gas-report -vv
```
---  

## Future Improvements

1. Deploying a hybrid system to monitor events that could cause huge changes to APY.

---  

## Acknowledgments  

Special thanks to **REACTIVE NETWORK x Dorahacks** for organizing the Reactive bounties 2.0. Honorable mention to Aave and Compound.