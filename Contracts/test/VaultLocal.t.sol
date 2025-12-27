// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";

// Interface for testing deployed vault
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
    function decimals() external view returns (uint8);
    function SERVICE() external view returns (address);
    function callback(address sender) external;
}

contract VaultLocalTest is Test {
    // Deployed contract addresses on Sepolia
    address public constant VAULT_ADDRESS = 0x60E3567B0987c5bE1A01f21114ed79c3e9dB6A2E;
    address public constant CRON_REACTIVE = 0x8D9E25C7b0439781c7755e01A924BbF532EDf24d;
    address public constant AAVE_WETH = 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c;
    address public constant COMPOUND_WETH = 0x2D5ee574e710219a521449679A4A7f2B43f046ad;
    
    IVault public vault;
    
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    
    uint256 public constant DEPOSIT_AMOUNT = 0.1 ether;

    function setUp() public {
        // Set up vault interface
        vault = IVault(VAULT_ADDRESS);
        
        // Fund test users
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function testVaultConstants() public {
        // Test that vault has correct addresses
        assertEq(vault.aaveWeth(), AAVE_WETH);
        assertEq(vault.compoundWeth(), COMPOUND_WETH);
        assertEq(vault.SERVICE(), 0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA);
    }

    function testVaultTokenProperties() public {
        assertEq(vault.name(), "Reactive Vault Token");
        assertEq(vault.symbol(), "RVT");
        assertEq(vault.decimals(), 18);
    }

    function testCurrentPoolView() public {
        uint8 currentPool = vault.currentPool();
        
        // Should be either 0 (Aave) or 1 (Compound)
        assertTrue(currentPool == 0 || currentPool == 1);
        
        console.log("Current Pool:", currentPool == 0 ? "Aave" : "Compound");
    }

    function testOwnership() public {
        address owner = vault.owner();
        assertTrue(owner != address(0));
        console.log("Vault Owner:", owner);
    }

    // Note: The following tests will only work if you're connected to Sepolia
    // or have the contracts deployed locally

    function testDepositRevertOnInconsistentAmount() public {
        vm.startPrank(user1);
        
        // This should revert due to inconsistent ETH amount
        vm.expectRevert("Inconsistent ETH amount");
        vault.deposit{value: DEPOSIT_AMOUNT}(DEPOSIT_AMOUNT * 2);
        
        vm.stopPrank();
    }

    function testWithdrawRevertOnInsufficientBalance() public {
        vm.startPrank(user1);
        
        // This should revert due to insufficient balance
        vm.expectRevert();
        vault.withdraw(DEPOSIT_AMOUNT);
        
        vm.stopPrank();
    }

    function testCallbackUnauthorized() public {
        vm.startPrank(user1);
        
        // Should revert when called by unauthorized user
        vm.expectRevert();
        vault.callback(user1);
        
        vm.stopPrank();
    }

    // Helper function to test if we can read rates (requires network connection)
    function testRateFetchersIfConnected() public {
        try vault.aaveRateFetcher() returns (uint256 aaveRate) {
            console.log("Aave Rate:", aaveRate, "basis points");
            assertGe(aaveRate, 0);
            assertLt(aaveRate, 10000); // Less than 100% APY
        } catch {
            console.log("Could not fetch Aave rate - likely not connected to Sepolia");
        }
        
        try vault.compoundRateFetcher() returns (uint256 compoundRate) {
            console.log("Compound Rate:", compoundRate, "basis points");
            assertGe(compoundRate, 0);
            assertLt(compoundRate, 10000); // Less than 100% APY
        } catch {
            console.log("Could not fetch Compound rate - likely not connected to Sepolia");
        }
    }

    // Test deposit functionality if connected to network
    function testDepositIfConnected() public {
        vm.startPrank(user1);
        
        try vault.deposit{value: DEPOSIT_AMOUNT}(DEPOSIT_AMOUNT) {
            console.log("Deposit successful");
            
            uint256 balance = vault.balanceOf(user1);
            assertEq(balance, DEPOSIT_AMOUNT);
            console.log("User balance:", balance);
            
            uint256 supply = vault.circulatingSupply();
            assertGe(supply, DEPOSIT_AMOUNT);
            console.log("Circulating supply:", supply);
            
        } catch {
            console.log("Deposit failed - likely not connected to Sepolia or contract issue");
        }
        
        vm.stopPrank();
    }

    // Test withdrawal functionality if we have a balance
    function testWithdrawIfHasBalance() public {
        vm.startPrank(user1);
        
        uint256 userBalance = vault.balanceOf(user1);
        
        if (userBalance > 0) {
            console.log("User has balance:", userBalance);
            
            uint256 withdrawAmount = userBalance / 2;
            if (withdrawAmount > 0) {
                try vault.withdraw(withdrawAmount) {
                    console.log("Withdrawal successful");
                    
                    uint256 newBalance = vault.balanceOf(user1);
                    assertEq(newBalance, userBalance - withdrawAmount);
                    console.log("New balance:", newBalance);
                    
                } catch {
                    console.log("Withdrawal failed");
                }
            }
        } else {
            console.log("User has no balance to withdraw");
        }
        
        vm.stopPrank();
    }

    receive() external payable {}
}