// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IComet Interface
 * @author ReactiveLooper Team
 * @notice Interface for interacting with Compound v3 (Comet) protocol
 * @dev Defines essential functions for supply, withdraw, and rate calculations in Compound v3
 */
interface IComet {
    /**
     * @notice Supplies an asset to the Compound v3 protocol
     * @param asset Address of the asset to supply
     * @param amount Amount of the asset to supply
     * @dev Transfers tokens from user to protocol and starts earning interest
     */
    function supply(address asset, uint amount) external;

    /**
     * @notice Withdraws an asset from the Compound v3 protocol
     * @param asset Address of the asset to withdraw
     * @param amount Amount of the asset to withdraw
     * @dev Burns protocol tokens and transfers underlying asset to user
     */
    function withdraw(address asset, uint amount) external;

    /**
     * @notice Gets the current utilization rate of the protocol
     * @return utilization Current utilization rate as a percentage (scaled)
     * @dev Used to calculate dynamic interest rates based on supply/demand
     */
    function getUtilization() external view returns (uint256);

    /**
     * @notice Returns the balance of protocol tokens for an account
     * @param account Address to check balance for
     * @return balance Amount of protocol tokens held by the account
     * @dev Represents the user's share of the supplied assets plus accrued interest
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Calculates the supply rate for a given utilization
     * @param utilization The utilization rate to calculate supply rate for
     * @return supplyRate The annual supply rate (per second, scaled)
     * @dev Used to determine interest rates dynamically based on protocol utilization
     */
    function getSupplyRate(uint utilization) external view returns (uint64);
}