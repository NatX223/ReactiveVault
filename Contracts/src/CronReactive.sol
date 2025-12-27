// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/reactive-lib/src/interfaces/ISystemContract.sol";
import "../lib/reactive-lib/src/abstract-base/AbstractPausableReactive.sol";
import "../lib/reactive-lib/src/interfaces/IReactive.sol";

/**
 * @title CronReactive
 * @author ReactiveLooper Team
 * @notice Reactive contract that monitors cron events and triggers periodic callbacks to the Vault
 * @dev Implements time-based reactive functionality to periodically check and rebalance yield strategies
 *      Inherits from IReactive and AbstractPausableReactive for reactive network integration
 */
contract CronReactive is IReactive, AbstractPausableReactive {
    /**
     * @notice Maximum gas limit allocated for callback execution
     * @dev Set to prevent out-of-gas errors during callback execution
     */
    uint64 private constant GAS_LIMIT = 1000000;
    
    /**
     * @notice Address of the reactive system service contract
     * @dev Manages event subscriptions and reactive network functionality
     */
    address public constant SERVICE = 0x0000000000000000000000000000000000fffFfF;

    /**
     * @notice Event topic hash used to subscribe to cron events
     * @dev Defines the specific cron interval for periodic callbacks
     */
    uint256 private cron_topic;

    /**
     * @notice Address of the Vault contract that receives callback notifications
     * @dev Target contract for yield optimization callbacks
     */
    address public vault;

    /**
     * @notice Chain ID for Ethereum Sepolia testnet
     * @dev Used for cross-chain event subscription configuration
     */
    uint256 private chainId = 11155111;

    /**
     * @notice Emitted when the contract receives Ether payments
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
     * @notice Initializes the CronReactive contract with vault and cron configuration
     * @param _vault Address of the Vault contract that will receive callback notifications
     * @param _cron_topic Cron topic defining the time interval for periodic callbacks
     * @dev Automatically subscribes to cron events for the specified time frame
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

    /**
     * @notice Returns the list of event subscriptions that can be paused/unpaused
     * @return result Array of Subscription structs containing subscription configuration details
     * @dev Required implementation for AbstractPausableReactive functionality
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
     * @notice Reacts to cron events and triggers yield optimization checks in the vault
     * @param log The log record containing the cron event data
     * @dev Sends periodic callback to Vault contract to check for optimal yield and rebalance if needed
     */
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

    /**
     * @notice Handles incoming Ether payments to the contract
     * @dev Emits a Received event to log transaction details for monitoring purposes
     *      Overrides receive functions from both AbstractPayer and IPayer interfaces
     */
    receive() external payable override(AbstractPayer, IPayer) {
        emit Received(tx.origin, msg.sender, msg.value);
    }
}
