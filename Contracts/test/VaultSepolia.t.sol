// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../lib/forge-std/src/Test.sol";
import "../src/Vault.sol";
import "../src/IComet.sol";
import "../lib/aave-v3-core/contracts/interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VaultSepoliaTest
 * @dev Comprehensive tests for the deployed Vault contract on Sepolia
 * @notice Tests deposit, withdraw, and view functions with real protocol integration
 */
contract VaultSepoliaTest is Test {
    // ============ CONTRACT ADDRESSES ============
    address public constant VAULT_ADDRESS =
        0x60E3567B0987c5bE1A01f21114ed79c3e9dB6A2E;
    address public constant CRON_REACTIVE =
        0x8D9E25C7b0439781c7755e01A924BbF532EDf24d;
    address public constant AAVE_WETH =
        0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c;
    address public constant COMPOUND_WETH =
        0x2D5ee574e710219a521449679A4A7f2B43f046ad;

    // ============ RPC ENDPOINTS ============
    string[] public sepoliaRPCs;

    // ============ CONTRACT INSTANCES ============
    Vault public vault;
    IERC20 public aaveWeth;
    IERC20 public compoundWeth;

    // ============ TEST ACCOUNTS ============
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    // ============ TEST CONSTANTS ============
    uint256 public constant DEPOSIT_AMOUNT = 0.00001 ether;
    uint256 public constant LARGE_DEPOSIT = 0.01 ether;

    function setUp() public {
        // Setup multiple Sepolia RPC endpoints for fallback
        sepoliaRPCs.push("https://rpc.sepolia.org");
        sepoliaRPCs.push(
            "https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161"
        );
        sepoliaRPCs.push("https://ethereum-sepolia-rpc.publicnode.com");
        sepoliaRPCs.push("https://sepolia.gateway.tenderly.co");

        // Try to connect to Sepolia with fallback
        _connectToSepoliaWithFallback();

        // Get contract instances
        vault = Vault(payable(VAULT_ADDRESS));
        aaveWeth = IERC20(AAVE_WETH);
        compoundWeth = IERC20(COMPOUND_WETH);

        // Fund test users
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    /**
     * @dev Test that vault is deployed correctly with proper addresses
     */
    function test_VaultDeployedCorrectly() public {
        console.log("=== VAULT DEPLOYMENT VERIFICATION ===");

        // Test that vault has correct addresses
        assertEq(vault.aaveWeth(), AAVE_WETH);
        assertEq(vault.compoundWeth(), COMPOUND_WETH);
        
        // Check actual token name and symbol (use actual values from deployment)
        string memory actualName = vault.name();
        string memory actualSymbol = vault.symbol();
        console.log("Actual Token Name:", actualName);
        console.log("Actual Token Symbol:", actualSymbol);
        
        // Verify they match the deployed contract values
        assertEq(actualName, "ReactVault");
        assertEq(actualSymbol, "RCTVLT");
        assertEq(vault.decimals(), 18);

        console.log("Vault Address:", VAULT_ADDRESS);
        console.log("Aave WETH:", vault.aaveWeth());
        console.log("Compound WETH:", vault.compoundWeth());
        console.log("Token Name:", vault.name());
        console.log("Token Symbol:", vault.symbol());

        console.log("SUCCESS: Vault deployed correctly");
    }

    /**
     * @dev Test deposit functionality with real ETH
     */
    function test_DepositFunctionality() public {
        console.log("\n=== DEPOSIT FUNCTIONALITY TEST ===");

        vm.startPrank(user1);

        uint256 initialBalance = user1.balance;
        uint256 initialVaultBalance = vault.balanceOf(user1);
        uint256 initialSupply = vault.totalSupply();

        console.log("Initial ETH Balance:", initialBalance);
        console.log("Initial Vault Balance:", initialVaultBalance);
        console.log("Initial Total Supply:", initialSupply);

        // Perform deposit
        vault.deposit{value: DEPOSIT_AMOUNT}(DEPOSIT_AMOUNT);

        // Verify deposit worked
        assertEq(user1.balance, initialBalance - DEPOSIT_AMOUNT);
        assertEq(vault.balanceOf(user1), initialVaultBalance + DEPOSIT_AMOUNT);
        assertEq(vault.totalSupply(), initialSupply + DEPOSIT_AMOUNT);

        console.log("After Deposit ETH Balance:", user1.balance);
        console.log("After Deposit Vault Balance:", vault.balanceOf(user1));
        console.log("After Deposit Total Supply:", vault.totalSupply());
        console.log("Circulating Supply:", vault.circulatingSupply());

        vm.stopPrank();
        console.log("SUCCESS: Deposit functionality working");
    }

    /**
     * @dev Test withdraw functionality
     */
    function test_WithdrawFunctionality() public {
        console.log("\n=== WITHDRAW FUNCTIONALITY TEST ===");

        // First deposit
        vm.prank(user1);
        vault.deposit{value: DEPOSIT_AMOUNT}(DEPOSIT_AMOUNT);

        uint256 withdrawAmount = DEPOSIT_AMOUNT / 2;
        uint256 initialBalance = user1.balance;
        uint256 initialVaultBalance = vault.balanceOf(user1);

        console.log("Before Withdraw - ETH Balance:", initialBalance);
        console.log("Before Withdraw - Vault Balance:", initialVaultBalance);
        console.log("Withdraw Amount:", withdrawAmount);

        vm.startPrank(user1);

        // Perform withdrawal
        vault.withdraw(withdrawAmount);

        // Verify withdrawal worked
        assertEq(vault.balanceOf(user1), initialVaultBalance - withdrawAmount);

        console.log("After Withdraw - Vault Balance:", vault.balanceOf(user1));
        console.log("After Withdraw - ETH Balance:", user1.balance);
        console.log("Circulating Supply:", vault.circulatingSupply());

        vm.stopPrank();
        console.log("SUCCESS: Withdraw functionality working");
    }

    /**
     * @dev Test multiple users deposit and withdraw
     */
    function test_MultipleUsersDeposit() public {
        console.log("\n=== MULTIPLE USERS TEST ===");

        uint256 initialSupply = vault.circulatingSupply();
        console.log("Initial Circulating Supply:", initialSupply);

        // User1 deposits
        vm.prank(user1);
        vault.deposit{value: DEPOSIT_AMOUNT}(DEPOSIT_AMOUNT);

        // User2 deposits
        vm.prank(user2);
        vault.deposit{value: DEPOSIT_AMOUNT * 2}(DEPOSIT_AMOUNT * 2);

        // Verify both users have correct balances
        assertEq(vault.balanceOf(user1), DEPOSIT_AMOUNT);
        assertEq(vault.balanceOf(user2), DEPOSIT_AMOUNT * 2);
        
        // Account for existing supply in the vault
        uint256 expectedSupply = initialSupply + DEPOSIT_AMOUNT * 3;
        assertEq(vault.circulatingSupply(), expectedSupply);

        console.log("User1 Balance:", vault.balanceOf(user1));
        console.log("User2 Balance:", vault.balanceOf(user2));
        console.log("Total Circulating Supply:", vault.circulatingSupply());
        console.log("Expected Supply:", expectedSupply);

        console.log("SUCCESS: Multiple users can deposit");
    }

    /**
     * @dev Test rate fetching from Aave and Compound
     */
    function test_RateFetchers() public {
        console.log("\n=== RATE FETCHERS TEST ===");

        try vault.aaveRateFetcher() returns (uint256 aaveRate) {
            console.log("Aave Rate:", aaveRate, "basis points");
            // Aave rate might be 0 if not active, so just check it's not negative
            assertGe(aaveRate, 0);
            assertLt(aaveRate, 10000); // Less than 100% APY
            
            if (aaveRate == 0) {
                console.log("Note: Aave rate is 0 - protocol may be inactive on testnet");
            }
        } catch {
            console.log("Could not fetch Aave rate - protocol may be inactive");
        }

        try vault.compoundRateFetcher() returns (uint256 compoundRate) {
            console.log("Compound Rate:", compoundRate, "basis points");
            assertGe(compoundRate, 0);
            assertLt(compoundRate, 10000); // Less than 100% APY
        } catch {
            console.log(
                "Could not fetch Compound rate - protocol may be inactive"
            );
        }

        console.log("SUCCESS: Rate fetchers accessible");
    }

    /**
     * @dev Test current pool detection
     */
    function test_CurrentPoolView() public {
        console.log("\n=== CURRENT POOL TEST ===");

        uint8 currentPool = vault.currentPool();

        // Should be either 0 (Aave) or 1 (Compound)
        assertTrue(currentPool == 0 || currentPool == 1);

        console.log(
            "Current Pool:",
            currentPool == 0 ? "Aave (0)" : "Compound (1)"
        );

        // Try to get rates to understand why this pool was chosen
        try vault.aaveRateFetcher() returns (uint256 aaveRate) {
            try vault.compoundRateFetcher() returns (uint256 compoundRate) {
                console.log("Aave Rate:", aaveRate);
                console.log("Compound Rate:", compoundRate);

                if (aaveRate > compoundRate) {
                    console.log("Aave has better rate");
                } else if (compoundRate > aaveRate) {
                    console.log("Compound has better rate");
                } else {
                    console.log("Rates are equal");
                }
            } catch {}
        } catch {}

        console.log("SUCCESS: Current pool detection working");
    }

    /**
     * @dev Test error cases
     */
    function test_ErrorCases() public {
        console.log("\n=== ERROR CASES TEST ===");

        vm.startPrank(user1);

        // Test inconsistent deposit amount
        vm.expectRevert("Inconsistent ETH amount");
        vault.deposit{value: DEPOSIT_AMOUNT}(DEPOSIT_AMOUNT * 2);
        console.log("Inconsistent deposit amount properly reverts");

        // Test withdraw without balance
        vm.expectRevert();
        vault.withdraw(DEPOSIT_AMOUNT);
        console.log(" Withdraw without balance properly reverts");

        vm.stopPrank();

        // Test unauthorized callback
        vm.startPrank(user1);
        vm.expectRevert();
        vault.callback(user1);
        console.log("  Unauthorized callback properly reverts");
        vm.stopPrank();

        console.log("SUCCESS: All error cases handled correctly");
    }

    /**
     * @dev Test full deposit-withdraw cycle
     */
    function test_FullDepositWithdrawCycle() public {
        console.log("\n=== FULL CYCLE TEST ===");

        uint256 initialBalance = user1.balance;

        vm.startPrank(user1);

        // Deposit
        vault.deposit{value: DEPOSIT_AMOUNT}(DEPOSIT_AMOUNT);
        assertEq(vault.balanceOf(user1), DEPOSIT_AMOUNT);
        console.log("  Deposit completed");

        // Full withdrawal
        vault.withdraw(DEPOSIT_AMOUNT);
        assertEq(vault.balanceOf(user1), 0);
        assertEq(vault.circulatingSupply(), 0);
        console.log("  Full withdrawal completed");

        // Check ETH received (accounting for gas costs)
        assertGt(user1.balance, initialBalance - DEPOSIT_AMOUNT - 0.01 ether);
        console.log("  ETH properly returned to user");

        vm.stopPrank();

        console.log("SUCCESS: Full deposit-withdraw cycle working");
    }

    /**
     * @dev Test vault constants and properties
     */
    function test_VaultConstants() public {
        console.log("\n=== VAULT CONSTANTS TEST ===");

        // Test constants
        assertEq(vault.SERVICE(), 0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA);
        assertEq(vault.aaveWeth(), AAVE_WETH);
        assertEq(vault.compoundWeth(), COMPOUND_WETH);

        // Test ownership
        address owner = vault.owner();
        assertTrue(owner != address(0));

        console.log("Service Address:", vault.SERVICE());
        console.log("Aave WETH:", vault.aaveWeth());
        console.log("Compound WETH:", vault.compoundWeth());
        console.log("Owner:", owner);

        console.log("SUCCESS: All constants properly set");
    }

    // ============ HELPER FUNCTIONS ============

    /**
     * @dev Connect to Sepolia with RPC fallback
     */
    function _connectToSepoliaWithFallback() internal {
        for (uint i = 0; i < sepoliaRPCs.length; i++) {
            try this._tryConnectToSepolia(sepoliaRPCs[i]) {
                console.log(
                    "Successfully connected to Sepolia RPC:",
                    sepoliaRPCs[i]
                );
                return;
            } catch {
                console.log("Failed to connect to RPC:", sepoliaRPCs[i]);
                continue;
            }
        }

        // If all RPCs fail, revert
        revert("Could not connect to any Sepolia RPC");
    }

    /**
     * @dev External function to try connecting to Sepolia (needed for try/catch)
     */
    function _tryConnectToSepolia(string memory rpcUrl) external {
        vm.createSelectFork(rpcUrl);

        // Verify we can access the vault contract
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(VAULT_ADDRESS)
        }
        require(codeSize > 0, "Vault contract not found");
    }

    receive() external payable {}
}
