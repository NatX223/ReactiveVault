// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../lib/reactive-lib/src/abstract-base/AbstractCallback.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import "../lib/aave-v3-core/contracts/interfaces/IPool.sol";
import "../lib/aave-v3-core/contracts/interfaces/IPriceOracle.sol";
import "./library/TransferHelper.sol";

contract Vault is AbstractCallback, Ownable, ERC20 {
    /** @dev Address of the reactive system service contract */
    address public constant SERVICE = 0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA;

    /** @dev Address of the WETH token on Aave*/
    address public aaveWeth;
    
    /** @dev Address of the WETH token on Compound*/
    address public compoundWeth;

    /** @dev Total amount of vault tokens in circulation*/
    uint256 public circulatingSupply;

    /** @dev The current protocol pool the funds and in at the moment - 0 for aave, 1 for compound */
    uint8 private currentPool;

    /** @dev Aave V3 pool addresses provider contract interface */
    IPoolAddressesProvider public immutable ADDRESS_PROVIDER;
    
    /** @dev Aave V3 pool contract interface for lending operations */
    IPool public immutable Pool;
    
    /** @dev Aave V3 price oracle interface for asset pricing */
    IPriceOracle public immutable priceOracle;

    /** @dev Aave V3 Base Currency (e.g., USD) uses 8 decimals for pricing */
    uint8 private constant BASE_CURRENCY_DECIMALS = 8;

    /** @dev Event emitted when collateral tokens are deposited into the vault */
    event fundsDeposit(address indexed sender, uint256 amount, uint256 mintAmount);

    /** @dev Event emitted when collateral tokens are withdrawn from the vault */
    event fundsWithdrawal(address indexed sender, uint256 amount, uint256 burnAmount);

    /**
     * @dev Initializes the Looper contract with required addresses and interfaces
     * @param _poolAddressProvider Address of Aave V3 pool addresses provider
     * @param name_ Name of the token minted to represent vault shares
     * @param symbol_ Symbol of the token minted to represent vault shares
     */
    constructor(
        address aaveWeth_,
        address compoundWeth_,
        address _poolAddressProvider,
        string memory name_,
        string memory symbol_
    ) payable AbstractCallback(SERVICE) Ownable(msg.sender) ERC20(name_, symbol_) {

        ADDRESS_PROVIDER = IPoolAddressesProvider(_poolAddressProvider);
        Pool = IPool(ADDRESS_PROVIDER.getPool());
    }

    function deposit(uint256 amount) external payable {
        require(msg.value == amount, "Deposit amount must match the sent value");

        uint256 mintValue = amount * 10;
        _mint(msg.sender, mintValue);
        circulatingSupply += mintValue;

        emit fundsDeposit(msg.sender, msg.value, mintValue);
    }

    function withdraw(uint256 amount) external {
        uint256 withdrawAmount = amount / 10;
        _burn(msg.sender, amount);
        circulatingSupply -= amount;

        emit fundsWithdrawal(msg.sender, amount, amount);
    }

}
