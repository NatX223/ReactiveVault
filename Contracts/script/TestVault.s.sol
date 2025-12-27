// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Script.sol";

// Interface for interacting with deployed vault
interface IVault {
    function deposit(uint256 amount) external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function currentPool() external view returns (uint8);
    function aaveRateFetcher() external view returns (uint256);
    function compoundRateFetcher() external view returns (uint256);
    function aaveWeth() external view returns (address);
    function compoundWeth() external view returns (address);
    function owner() external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract TestVaultScript is Script {
    address public constant VAULT_ADDRESS = 0x60E3567B0987c5bE1A01f21114ed79c3e9dB6A2E;
    address public constant AAVE_WETH = 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c;
    address public constant COMPOUND_WETH = 0x2D5ee574e710219a521449679A4A7f2B43f046ad;
    
    IVault public vault;

    function run() external {
        vault = IVault(VAULT_ADDRESS);
        
        console.log("=== Vault Contract Information ===");
        console.log("Vault Address:", VAULT_ADDRESS);
        console.log("Vault Name:", vault.name());
        console.log("Vault Symbol:", vault.symbol());
        console.log("Owner:", vault.owner());
        
        console.log("\n=== Token Addresses ===");
        console.log("Aave WETH:", vault.aaveWeth());
        console.log("Compound WETH:", vault.compoundWeth());
        
        console.log("\n=== Current State ===");
        console.log("Total Supply:", vault.totalSupply());
        console.log("Circulating Supply:", vault.circulatingSupply());
        console.log("Current Pool:", vault.currentPool() == 0 ? "Aave" : "Compound");
        
        console.log("\n=== Current Rates ===");
        try vault.aaveRateFetcher() returns (uint256 aaveRate) {
            console.log("Aave Rate:", aaveRate, "basis points");
        } catch {
            console.log("Could not fetch Aave rate");
        }
        
        try vault.compoundRateFetcher() returns (uint256 compoundRate) {
            console.log("Compound Rate:", compoundRate, "basis points");
        } catch {
            console.log("Could not fetch Compound rate");
        }
        
        console.log("\n=== Test Account Balance ===");
        address testAccount = vm.addr(vm.envUint("PRIVATE_KEY"));
        console.log("Test Account:", testAccount);
        console.log("Vault Token Balance:", vault.balanceOf(testAccount));
        console.log("ETH Balance:", testAccount.balance);
    }
}