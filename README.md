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
6. [Setup and Deployment](#setup-and-deployment)  
7. [Future Improvements](#future-improvements)  
8. [Acknowledgments](#acknowledgments)  

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

- Callback functionality - The CronReactive contract calls the callback function on the vault contract to check for the current optimal pool. The vault contract checks for the best pool and checks the yield difference and if it is more the threshold (set to 1%). The vault contract calls the withdraw function on the current pool. The vault contract calls the supply function on the optimal pool with the redeemed WETH. Below are the code snippets that show how this was implemented.

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
```

The full code can be found [here](https://github.com/NatX223/ReactiveVault/blob/main/Contracts/src/Vault.sol)

<!--
- Bridging Tokens - In order to fund dev accounts with ETH from Base, we built a mini base bridge that devs can deposit to then the emitted 
"Received(address,uint256)" is tracked by a reactive contract deployed n REACT mainnet and a corresponding callback to dispense the REACT tokens.
Here are some code snippets
receive function on base bridge contract
```solidity
    receive() external payable {
        if (msg.value > 0.00024 ether) {
            (bool success, ) = msg.sender.call{value: msg.value}("");
            require(success, "Payment value exceeded.");
        } else {
            emit Received(
            msg.sender,
            msg.value
        );
        }
    }
```
bridge react function
```solidity
    function react(LogRecord calldata log) external vmOnly {
        address recipient = address(uint160(log.topic_1));
        uint256 sentValue = uint256(log.topic_2);

        bytes memory payload = abi.encodeWithSignature(
            "callback(address, address, uint256)",
            address(0),
            recipient,
            sentValue
        );

        emit Callback(
        REACT_ID,
        callbackHandler,
        GAS_LIMIT,
        payload
    );
    }
```
callback on the bridge callback contract
```solidity
    function callback(address sender, address recipient, uint256 sentValue) external authorizedSenderOnly rvmIdOnly(sender) {
        address devAccount = IAccountFactory(accountFactoryContract).devAccounts(recipient);
        if (devAccount == address(0)) {
            uint256 receiveValue = (sentValue * rateNum) / rateDen;
            (bool success, ) = recipient.call{value: receiveValue}("");
            require(success, "brdging failed.");

            emit bridgeHandled(recipient, sentValue, receiveValue);
        } else {
            uint256 receiveValue = (sentValue * rateNum) / rateDen;
            (bool success, ) = devAccount.call{value: receiveValue}("");
            require(success, "brdging failed.");

            emit bridgeHandled(recipient, sentValue, receiveValue);
        }
    }
```

- Smart contract factories were utilized to make it easier to quickly deploy the needed contracts here their addresses on the react mainnet.

| **Contract**            | **Addres**                                 | **Function**                                                             |
|-------------------------|--------------------------------------------|--------------------------------------------------------------------------|
| **AccountFactory**      | 0xD2401b212eFc78401b51C68a0CC92B1163b1e6db | Deploying dev accounts for users - these are used to fund their contracts|
| **FunderFactory**       | 0x504731A1b6a7706dCef75f42DEE72565D41B097C | Deploying funder callback contracts.                                     |
| **ReactiveFactory**     | 0x534028e697fbAF4D61854A27E6B6DBDc63Edde8c | Deploying reactive contracts that track callback.                        |
| **DebtPayerFactory**    | 0x3054Ea734dd290DcC3bf032bE50493ABd4361910 | Deploying debt payer callback contracts.                                 |
| **DebtReactiveFactory** | 0xB89f13F648c554cb18A120BA82E42Beda4557792 | Deploying reactive contracts that track contract status.                 |

Below is a table showing example contracts and their transaction hashes.

| **Contract**            | **Function**                               | **TransactionHash**                                                      |
|-------------------------|--------------------------------------------|--------------------------------------------------------------------------|
| **DevAccount**          | Dev Account funding                        | 0xabde594de4e1f00badd7d9b85b4e50d41b578908a8ef51fe744facdd9908541e       |
| **FunderReactive**      | Tracking event on callback contract        | 0x3001c5bccb5f7f492307b1acf73a04c37a667c4a543b5e1f510f17da08066b8d       |
| **FunderContract**      | Funding reactive and/or callback contract  | 0x060fef5c78bcaee31648f9698c2904c36a93c84cc9bbcf70f05837c4264dc046       |

### Node.js

The project utilizes a backend to improve the user experience, especially when deploying contracts like the funder and debt payer contracts. The backend was
developed using Node.js and Express.js, it handles user registration, contract deployment, and other related tasks.

## Setup and Deployment  

### Prerequisites  

- Node.js v16+  
- Solidity development environment(Foundry)

### Local Setup  

The repository has to be cloned first

```bash  
  git clone https://github.com/NatX223/Reactivate  
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
  REACT_RPC_URL=https://mainnet-rpc.rnk.dev/
  ```  
4. Compile smart contracts:  
  ```bash  
  forge build 
  ```  
5. Run deployment scripts:
  deploy dev account
  - using the factory
  ```bash
  cast send --rpc-url $REACT_RPC_URL --private-key $PRIVATE_KEY accountFactoryAddress "createAccount(address)" 0xyouraddress --value initialfundamountether
  ```
  - deploying directly
  ```bash
  forge create --broadcast --rpc-url $REACT_RPC_URL --private-key $PRIVATE_KEY src/account/devAccount.sol:DevAccount --value initialfundamountether --constructor-args 0xyouraddress
  ```
  deploy funder(callback) contract
  - using the factory
  ```bash
  cast send --rpc-url $REACT_RPC_URL --private-key $PRIVATE_KEY funderFactoryAddress "createFunder(address,address,address,uint256,uint256)" 0xyouraddress 0xcallbackContract 0xreactiveContract refillValue refillthreshold --value initialfundamountether
  ```
  - deploying directly
  ```bash
  forge create --broadcast --rpc-url $REACT_RPC_URL --private-key $PRIVATE_KEY src/funder/funder.sol:Funder --value initialfundamountether --constructor-args 0xcallbackContract 0xreactiveContract refillValue refillthreshold 0xyourDevAccount
  ```
  deploy reactive contract
  - getting funder contract address
  ```bash
  cast call --rpc-url $REACT_RPC_URL funderFactoryAddress "latestDeployed()"
  ```
  - using the factory
  ```bash
  cast send --rpc-url $REACT_RPC_URL --private-key $PRIVATE_KEY reactiveFactoryAddress "createReactive(address,address,uint256)" 0xdeployedfunderaddress 0xcallbackContract calleventtopic --value initialfundamountether
  ```
  - deploying directly
  ```bash
  forge create --broadcast --rpc-url $REACT_RPC_URL --private-key $PRIVATE_KEY src/funder/reactive.sol:Reactive --value initialfundamountether --constructor-args 0xdeployedfunderaddress 0xcallbackContract calleventtopic
  ```
  deploy debt payer contract
  - using debt payer factory
  ```bash
  cast send --rpc-url $REACT_RPC_URL --private-key $PRIVATE_KEY debtPayerFactoryAddress "createPayer(address,address,address)" 0xyouraddress 0xcallbackContract 0xreactiveContract --value initialfundamountether
  ```
  - deploying directly
  ```bash
  forge create --broadcast --rpc-url $REACT_RPC_URL --private-key $PRIVATE_KEY src/debtPayer/debtPayer.sol:DebtPayer --value initialfundamountether --constructor-args 0xcallbackContract 0xreactiveContract
  ```
  deploy debt reactive contract
  - getting debt payer address
  ```bash
  cast call --rpc-url $REACT_RPC_URL debtPayerFactoryAddress "latestDeployed()"
  ```
  - using debt reactive factory
  ```bash
  cast send --rpc-url $REACT_RPC_URL --private-key $PRIVATE_KEY debtReactiveFactoryAddress "createPayerReactive(address,address,address)" 0xyouraddress 0xdebtpayerContract 0xfunderContract --value initialfundamountether
  ```
  - deploying directly
  ```bash
  forge create --broadcast --rpc-url $REACT_RPC_URL --private-key $PRIVATE_KEY src/debtPayer/debtPayerReactive.sol:DebtPayerReactive --value initialfundamountether --constructor-args 0xyouraddress 0xdebtpayerContract 0xfunderContract
  ```
---  

## Future Improvements

1. Enable funding contracts to track callback events from other chains.
2. Extensive audits on the protocol's smart contracts.
3. Purchasing more REACT tokens to aid seamless payment "bridging".

---  

## Acknowledgments  

Special thanks to **BUIDL WITH REACT x Dorahacks Hackathon 2025** organizers: REACT and other sponsors like Base. The REACT products played a pivotal role in building Reactivate functionality and impact. Special thanks to all builders and mentors - Ivan and Constantine for all the help rendered during the build phase. -->