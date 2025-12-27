// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../lib/forge-std/src/Script.sol";

/**
 * @title RunVaultTests
 * @dev Script to run vault tests and display results
 */
contract RunVaultTests is Script {
    address public constant VAULT_ADDRESS = 0x60E3567B0987c5bE1A01f21114ed79c3e9dB6A2E;
    address public constant AAVE_WETH = 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c;
    address public constant COMPOUND_WETH = 0x2D5ee574e710219a521449679A4A7f2B43f046ad;
    
    // Multiple Sepolia RPC endpoints
    string[] public sepoliaRPCs;

    function run() external {
        console.log("=== VAULT TEST RUNNER ===");
        
        // Setup RPC endpoints
        sepoliaRPCs.push("https://rpc.sepolia.org");
        sepoliaRPCs.push("https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161");
        sepoliaRPCs.push("https://ethereum-sepolia-rpc.publicnode.com");
        sepoliaRPCs.push("https://sepolia.gateway.tenderly.co");
        
        console.log("Testing connection to Sepolia...");
        
        bool connected = false;
        for (uint i = 0; i < sepoliaRPCs.length && !connected; i++) {
            try this._testConnection(sepoliaRPCs[i]) {
                console.log("  Connected to:", sepoliaRPCs[i]);
                connected = true;
                
                // Run basic contract checks
                _runBasicChecks();
                
            } catch {
                console.log("  Failed to connect to:", sepoliaRPCs[i]);
            }
        }
        
        if (!connected) {
            console.log("Could not connect to any Sepolia RPC");
            console.log("Please check your internet connection or try running tests locally");
        }
        
        console.log("\n=== TEST INSTRUCTIONS ===");
        console.log("To run the full test suite:");
        console.log("1. Local tests (no network): forge test --match-contract VaultLocalTest -vv");
        console.log("2. Sepolia tests: forge test --match-contract VaultSepoliaTest --fork-url https://rpc.sepolia.org -vv");
        console.log("3. With specific RPC: forge test --match-contract VaultSepoliaTest --fork-url <RPC_URL> -vv");
    }

    function _testConnection(string memory rpcUrl) external {
        vm.createSelectFork(rpcUrl);
        
        // Check if vault contract exists
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(VAULT_ADDRESS)
        }
        require(codeSize > 0, "Vault contract not found");
    }

    function _runBasicChecks() internal {
        console.log("\n=== BASIC CONTRACT CHECKS ===");
        
        // Check contract exists
        uint256 vaultCodeSize;
        assembly {
            vaultCodeSize := extcodesize(VAULT_ADDRESS)
        }
        
        if (vaultCodeSize > 0) {
            console.log("  Vault contract exists at:", VAULT_ADDRESS);
        } else {
            console.log("  Vault contract not found");
            return;
        }
        
        // Check WETH contracts
        uint256 aaveCodeSize;
        uint256 compoundCodeSize;
        
        assembly {
            aaveCodeSize := extcodesize(AAVE_WETH)
            compoundCodeSize := extcodesize(COMPOUND_WETH)
        }
        
        if (aaveCodeSize > 0) {
            console.log("  Aave WETH contract exists at:", AAVE_WETH);
        } else {
            console.log("  Aave WETH contract not found");
        }
        
        if (compoundCodeSize > 0) {
            console.log("  Compound WETH contract exists at:", COMPOUND_WETH);
        } else {
            console.log("  Compound WETH contract not found");
        }
        
        console.log("Basic checks completed");
    }
}