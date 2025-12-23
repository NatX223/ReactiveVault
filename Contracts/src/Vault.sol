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
import "./WethConverter.sol";
import "./IComet.sol";

contract Vault is AbstractCallback, Ownable, ERC20, WETHConverter {
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

    /** @dev Compound V3 comet(cWETHv3) contract interface for lending operations */
    IComet public immutable Comet;

    /** @dev Aave V3 price oracle interface for asset pricing */
    IPriceOracle public immutable priceOracle;

    /** @dev Aave V3 Base Currency (e.g., USD) uses 8 decimals for pricing */
    uint8 private constant BASE_CURRENCY_DECIMALS = 8;

    /** @dev Event emitted when collateral tokens are deposited into the vault */
    event fundsDeposit(
        address indexed sender,
        uint256 amount,
        uint256 mintAmount
    );

    /** @dev Event emitted when collateral tokens are withdrawn from the vault */
    event fundsWithdrawal(
        address indexed sender,
        uint256 amount,
        uint256 burnAmount
    );

    // /**
    //  * @dev Initializes the Looper contract with required addresses and interfaces
    //  * @param _poolAddressProvider Address of Aave V3 pool addresses provider
    //  * @param name_ Name of the token minted to represent vault shares
    //  * @param symbol_ Symbol of the token minted to represent vault shares
    //  */
    constructor(
        address aaveWeth_,
        address compoundWeth_,
        address _poolAddressProvider,
        address _cometAddress,
        string memory name_,
        string memory symbol_
    )
    payable AbstractCallback(SERVICE) Ownable(msg.sender) ERC20(name_, symbol_) WETHConverter(aaveWeth_, compoundWeth_) {
        ADDRESS_PROVIDER = IPoolAddressesProvider(_poolAddressProvider);
        Pool = IPool(ADDRESS_PROVIDER.getPool());
        Comet = IComet(_cometAddress);
    }

    function deposit(uint256 amount) external payable {
        require(msg.value == amount, "Deposit amount must match the sent value");

        _supply(amount);

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

    /**
     * @dev Internal function to supply funds to the current active pool
     * @param amount The amount of ETH to supply to the lending pool
     */
    function _supply(uint256 amount) internal {
        require(amount > 0, "Supply amount must be greater than 0");

        if (currentPool == 0) {
            // Supply to Aave pool
            _supplyToAave(amount);
        } else if (currentPool == 1) {
            // Supply to Compound pool
            _supplyToCompound(amount);
        } else {
            revert("Invalid pool identifier");
        }
    }

    /**
     * @dev Internal function to supply ETH to Aave V3 pool
     * @param amount The amount of ETH to supply
     */
    function _supplyToAave(uint256 amount) internal {
        // get aave weth
        obtainAaveWETH(amount);
        // Supply ETH to Aave pool 
        TransferHelper.safeApprove(aaveWeth, address(Pool), amount);
        Pool.supply(
            aaveWeth,
            amount,
            address(this),
            0
        );
    }

    /**
     * @dev Internal function to supply ETH to Compound pool
     * @param amount The amount of ETH to supply
     */
    function _supplyToCompound(uint256 amount) internal {
        obtainCompoundWETH(amount);
        
        // Supply ETH to Compound pool
        TransferHelper.safeApprove(compoundWeth, address(Comet), amount);
        Comet.supply(
            compoundWeth,
            amount
        );
        revert("Compound supply not yet implemented");
    }
}
