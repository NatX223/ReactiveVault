// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/reactive-lib/src/interfaces/ISystemContract.sol";
import "../lib/reactive-lib/src/abstract-base/AbstractPausableReactive.sol";
import "../lib/reactive-lib/src/interfaces/IReactive.sol";

/**
 * @title CronReactive
 * @dev Reactive contract that monitors ReserveDataUpdated event from the Aave pool contract
 * @notice This contract listens for reserve data updated events and checks the APY diference
 *         between Aave and Compound before sending a callback to the Vault contract.
 */
contract CronReactive is IReactive, AbstractPausableReactive {
    /** @dev Maximum gas limit allocated for callback execution to prevent out-of-gas errors */
    uint64 private constant GAS_LIMIT = 1000000;
    
    /** @dev Address of the reactive system service contract that manages event subscriptions */
    address public constant SERVICE = 0x0000000000000000000000000000000000fffFfF;

    /** @dev Event topic hash used to subscribe to cron events */
    uint256 private cron_topic;

    /** @dev Address of the Vault contract that will receive callback notifications */
    address public vault;

    /** @dev Chain ID for Ethereum Sepolia testnet */
    uint256 private chainId = 11155111;

    /*
     * Event emitted when the contract receives Ether payments
     * @param origin The original transaction initiator (tx.origin)
     * @param sender The direct sender of the transaction (msg.sender)
     * @param value The amount of Ether received in wei
     */
    event Received(
        address indexed origin,
        address indexed sender,
        uint256 indexed value
    );

    /**
     * @dev Initializes the SwapReactive contract and sets up event subscription
     * @param _vault Address of the Vault contract that will receive callback notifications
     * @param _cron_topic Cron topic for the time frame the user wants
     * @notice Automatically subscribes to reserve data updated from the pool address
     */
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

    /*
     * Returns the list of event subscriptions that can be paused/unpaused.
     * Required implementation for AbstractPausableReactive functionality.
     * @return Array of Subscription structs containing subscription configuration details
     */
    function getPausableSubscriptions()
        internal
        view
        override
        returns (Subscription[] memory)
    {
        Subscription[] memory result = new Subscription[](1);
        result[0] = Subscription(
            chainId,
            address(SERVICE),
            cron_topic,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        return result;
    }

    /**
     * @dev Reacts to reserve data updated events and triggers the rebalance operation in vault contract
     * @param log The log record containing the reserve data updated event data
     * @notice Periodic check sent to the Vault contract to check for best yeild and rebalance
     */
    function react(LogRecord calldata log) external vmOnly {

        /** @dev Encode callback payload for supply operation (operation 0) */
        bytes memory payload = abi.encodeWithSignature(
            "callback(address)",
            address(0)
        );

        emit Callback(chainId, vault, GAS_LIMIT, payload);
    }

    /*
     * Handles incoming Ether payments to the contract.
     * Emits a Received event to log transaction details for monitoring purposes.
     */
    receive() external payable override(AbstractPayer, IPayer) {
        emit Received(tx.origin, msg.sender, msg.value);
    }
}
