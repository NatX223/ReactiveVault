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
<!-- 
## Overview  

Reactive and callback contracts need constant funding with REACT or native tokens to stay active. Without this, they become inactive, especially when tracking high-volume events. Developers are forced to manually monitor and top up contracts, leading to downtime and missed events.

Reactivate automates this process. It deploys monitoring and funding contracts that track events, check balances, and refill when needed. If a contract becomes inactive, coverDebt() is triggered to restore it. This makes Reactive contracts self-sustaining, reliable, and production-ready.

---  

## Problem Statement  

Reactive contracts and callback contracts need REACT tokens and native tokens on other chains to be kept active otherwise they will become inactive due to lack tokens to run them, thus there needs to be constant manual monitoring of these contracts by the developers especially for reactive contracts that track high volume events like token transfers and approvals.

---  

## Solution  

Reactivate solves this pain point by automated monitoring, topping up and reactivation of reactive and callback contracts using reactive contracts of it's own. The solution is well suited for reactive contracts and the reactive ecosystem because it tracks the event emiited in the callback contract the user specifies and checks the balance of both reactive and callback contracts after every event and if the balance is below a specific threshold or has become inactive, the reactivate callback contract automatically funds the user specified contracts and if needed calls the "coverDebt()" function to reactivate them.

---  

## How It Works  

The working mechanism of the dapp can be broken down into 4 steps

1. **User Registration**:
   - The user signs up by generating a funding account.
   - This can be funded with REACT tokens or ETH and USDC on Base and other supported chains.
2. **Making a Deployment**:
   - The user inputs the addresses of the reactive and callback contracts and the signature hash of the event they want to track.
   - The user sepicifiies the balance threshold and the refill amounts.
   - The monitoring reactive contract and the corresponding funding callback contract are deployed using the provided parameters.
3. **Monitoring a Trigger event**:
   - The monitoring reactive contract picks up an event from the callback contract being monitored and emits a "Callback" event to call the funding function on the funding contract.
   - The funding function on the funding contract is called by the system contract, if the contracts balances are below the user specified threshold then REACT/native tokens are sent to the user specified contracts to keep them active.
4. **Contract Reactivation**:
   - If the contracts are inactive then the "coverDebt()" function is called to reactivate them.

---  

## Technologies Used  

| **Technology**    | **Purpose**                                              |  
|-------------------|----------------------------------------------------------|
| **Reactive**      | Use of Reactive's reactive and callback contracts.       |  
| **Firestore**     | Tracking platform activity and metrics.                  |
| **Wagmi**         | Smart contract interaction.                              | 
| **Next.js**       | Frontend framework for building the user interface.      |  

### Reactive

Reactivate was built to prevent and solve inactive reactive and callback contracts, but in order to accomplish we also used these utilities.
Another problem that we aimed to solve with the project is the tideous process it takes for developers to get REACT mainnet tokens to power their contracts, 
to solve this we also made use of reactive contracts to make funding their dev accounts easier, this was accomplished by reactive contracts that handled the "bridging process".
Below is a description of the reactive stack was used in the project.

- Contract Funding - To keep track of a reactive contract's balance we wrote a reactive contract that tracks the contract's usage 
i.e a reactive contract that listens for the event that is emitted in a callback contract and then checks the balance of both 
the first reactive contract and that of it's callback if any of them have below the specified threshold then the funder contract 
sends the refill amount to the reactive contract and/or the callback and if the callback and/or reactive contract is inactive then it calls the "coverDebt()" function 
to reactivate them. Below are the code snippets that show how this was implemented.
deploying a funder contract
```solidity
  function createFunder(address dev, address callbackContract, address reactiveContract, uint256 refillValue, uint256 refillthreshold) payable external {
      address devAccount = IAccountFactory(accountFactory).devAccounts(dev);
      uint256 devAccountBalance = devAccount.balance;
      uint256 withdrawAmount = (refillValue * 2);
      uint256 initialFundAmount = withdrawAmount + 2 ether;

      require(devAccountBalance >= withdrawAmount, "Not enough REACT in dev account");

      Funder newReactiveFunder = new Funder{value: initialFundAmount}(callbackContract, reactiveContract, refillValue, refillthreshold, devAccount);
      address funderAddress = address(newReactiveFunder);

      IDevAccount(devAccount).withdraw(address(this), initialFundAmount);
      IDevAccount(devAccount).whitelist(funderAddress);

      latestDeployed = funderAddress;

      emit Setup(dev, funderAddress);
  }
```
deploying a reactive contract to track callback events
```solidity
    function createReactive(address funderContract, address callbackContract, uint256 eventTopic) payable external {
        Reactive newReactive = new Reactive{value: 2 ether}(funderContract, callbackContract, eventTopic);
        latestDeployed = address(newReactive);
        
        emit Setup(msg.sender, address(newReactive));
    }
```
funding a reactive and/or callback Contract
```solidity
    function callback(address sender) external authorizedSenderOnly rvmIdOnly(sender) {
        uint256 callbackBal = callbackReceiver.balance;
        if (callbackBal <= refillThreshold) {
            (bool success, ) = callbackReceiver.call{value: refillValue}("");
            require(success, "Payment failed.");

            IDevAccount(devAccount).withdraw(address(this), refillValue);

            emit refillHandled(address(this), callbackReceiver);
        } else {
            emit callbackHandled(address(this));
        }

        uint256 reactiveBal = reactiveReceiver.balance;
        if (reactiveBal <= refillThreshold) {
            (bool success, ) = reactiveReceiver.call{value: refillValue}("");
            require(success, "Payment failed.");

            IDevAccount(devAccount).withdraw(address(this), refillValue);

            emit refillHandled(address(this), reactiveReceiver);
        } else {
            emit callbackHandled(address(this));
        }

    }
```
reactivating an inactive contract
```solidity
    function callback(address sender) external authorizedSenderOnly rvmIdOnly(sender) {
        uint256 callbackDebt = ISystem(SYSTEM_CONTRACT).debts(callbackContract);
        uint256 reactiveDebt = ISystem(SYSTEM_CONTRACT).debts(reactiveContract);
        if (callbackDebt > 0) {
            IAbsctractPayer(callbackContract).coverDebt();
            emit debtPaid(address(this));
        }

        if (reactiveDebt > 0) {
            IAbsctractPayer(reactiveContract).coverDebt();
            emit debtPaid(address(this));
        }
    }
```
The full code can be found [here](https://github.com/NatX223/Reactivate/tree/main/Contracts/src)

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