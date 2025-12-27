// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../lib/reactive-lib/src/abstract-base/AbstractCallback.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import "../lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {DataTypes} from "../lib/aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol";
import "./library/TransferHelper.sol";
import "./WethConverter.sol";
import "./IComet.sol";

/**
 * @title Reactive Yield Vault
 * @author ReactiveLooper Team
 * @notice A yield optimization vault that automatically switches between Aave and Compound v3 protocols
 * @dev Inherits from AbstractCallback for Reactive Network integration, Ownable for access control,
 *      ERC20 for vault token functionality, and WETHConverter for WETH management
 */
contract Vault is AbstractCallback, Ownable, ERC20, WETHConverter {
    /**
     * @notice Address of the Reactive Network service contract
     * @dev Used for callback authorization and reactive functionality
     */
    address public constant SERVICE = 0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA;
    
    /**
     * @notice Minimum yield difference required to trigger pool switching (in basis points)
     * @dev 100 basis points = 1%. Pool switching only occurs if yield difference exceeds this threshold
     */
    uint256 private constant YIELD_THRESHOLD = 100; // 1% in basis points (100 = 1.00%)
    
    /**
     * @notice Ray unit used in Aave calculations (10^27)
     * @dev Standard unit for high precision calculations in Aave protocol
     */
    uint256 private constant RAY = 1e27;
    
    /**
     * @notice Wad unit used in calculations (10^18)
     * @dev Standard unit for 18 decimal precision calculations
     */
    uint256 private constant WAD = 1e18;
    
    /**
     * @notice Number of seconds in a year for APY calculations
     * @dev Used to annualize interest rates from Compound protocol
     */
    uint256 private constant SECONDS_PER_YEAR = 31536000;

    /**
     * @notice Address of WETH token used in Aave protocol
     * @dev Immutable address set during contract deployment
     */
    address public immutable aaveWeth;
    
    /**
     * @notice Address of WETH token used in Compound protocol
     * @dev Immutable address set during contract deployment
     */
    address public immutable compoundWeth;
    
    /**
     * @notice Address of aToken representing WETH deposits in Aave
     * @dev Cached for gas efficiency during balance checks
     */
    address public immutable aTokenWeth; // Cached for gas efficiency
    
    /**
     * @notice Total amount of vault tokens currently in circulation
     * @dev Tracks the total supply of vault shares issued to users
     */
    uint256 public circulatingSupply;
    
    /**
     * @notice Identifier for the currently active lending pool
     * @dev 0 = Aave, 1 = Compound. Determines where funds are currently deployed
     */
    uint8 public currentPool; // 0 for Aave, 1 for Compound

    /**
     * @notice Interface to interact with Aave lending pool
     * @dev Used for supply, withdraw, and rate fetching operations
     */
    IPool public immutable Pool;
    
    /**
     * @notice Interface to interact with Compound v3 protocol
     * @dev Used for supply, withdraw, and rate fetching operations
     */
    IComet public immutable Comet;

    /**
     * @notice Emitted when a user deposits ETH into the vault
     * @param sender Address of the user making the deposit
     * @param amount Amount of ETH deposited
     * @param sharesMinted Amount of vault tokens minted to the user
     */
    event FundsDeposit(address indexed sender, uint256 amount, uint256 sharesMinted);
    
    /**
     * @notice Emitted when a user withdraws ETH from the vault
     * @param sender Address of the user making the withdrawal
     * @param amount Amount of ETH withdrawn
     * @param sharesBurned Amount of vault tokens burned from the user
     */
    event FundsWithdrawal(address indexed sender, uint256 amount, uint256 sharesBurned);
    
    /**
     * @notice Emitted when the current pool is determined to be optimal
     * @param currentPool The pool that remains active (0=Aave, 1=Compound)
     * @param aaveRate Current Aave lending rate in basis points
     * @param compoundRate Current Compound lending rate in basis points
     */
    event OptimalPoolActive(uint8 indexed currentPool, uint256 aaveRate, uint256 compoundRate);
    
    /**
     * @notice Emitted when funds are moved from one protocol to another
     * @param fromPool The source pool (0=Aave, 1=Compound)
     * @param toPool The destination pool (0=Aave, 1=Compound)
     * @param amount Total amount moved including accrued interest
     */
    event PoolSwitched(uint8 indexed fromPool, uint8 indexed toPool, uint256 amount);

    /**
     * @notice Initializes the Reactive Yield Vault with protocol addresses and configurations
     * @param _aaveWeth Address of WETH token for Aave protocol
     * @param _compoundWeth Address of WETH token for Compound protocol
     * @param _poolAddressProvider Address of Aave's pool addresses provider
     * @param _cometAddress Address of Compound v3 Comet contract
     * @param _name Name of the vault token (e.g., "ReactiveVault")
     * @param _symbol Symbol of the vault token (e.g., "RCTVLT")
     * @dev Sets up protocol interfaces, approvals, and determines initial optimal pool
     */
    constructor(
        address _aaveWeth,
        address _compoundWeth,
        address _poolAddressProvider,
        address _cometAddress,
        string memory _name,
        string memory _symbol
    )
        payable
        AbstractCallback(SERVICE)
        Ownable(msg.sender)
        ERC20(_name, _symbol)
        WETHConverter(_aaveWeth, _compoundWeth)
    {
        aaveWeth = _aaveWeth;
        compoundWeth = _compoundWeth;
        
        IPoolAddressesProvider provider = IPoolAddressesProvider(_poolAddressProvider);
        Pool = IPool(provider.getPool());
        Comet = IComet(_cometAddress);

        // Cache aToken address to save gas on balance checks
        aTokenWeth = Pool.getReserveData(_aaveWeth).aTokenAddress;

        // Infinite Approval to Protocol Contracts
        IERC20(_aaveWeth).approve(address(Pool), type(uint256).max);
        IERC20(_compoundWeth).approve(address(Comet), type(uint256).max);

        setPool();
    }

    /**
     * @notice Determines and sets the optimal lending pool based on current rates
     * @dev Compares Aave and Compound rates and sets currentPool to the higher yielding option
     */
    function setPool() internal {
        uint256 aaveRate = aaveRateFetcher();
        uint256 compRate = compoundRateFetcher();

        if (aaveRate > compRate) {
            currentPool = 0;
        } else if (compRate > aaveRate) {
            currentPool = 1;
        }
    }

    /**
     * @notice Deposits ETH into the vault and mints corresponding vault tokens
     * @param amount Amount of ETH to deposit (must match msg.value)
     * @dev Converts ETH to WETH, supplies to optimal protocol, and mints vault tokens 1:1
     */
    function deposit(uint256 amount) external payable {
        require(msg.value == amount, "Inconsistent ETH amount");
        
        // Wrap and supply
        _supply(amount);

        _mint(msg.sender, amount);
        circulatingSupply += amount;
        
        emit FundsDeposit(msg.sender, amount, amount);
    }

    /**
     * @notice Withdraws ETH from the vault by burning vault tokens
     * @param amount Amount of vault tokens to burn and ETH to withdraw
     * @dev Burns vault tokens, withdraws from current protocol, and sends ETH to user
     */
    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        circulatingSupply -= amount;

        // Withdraw from whichever pool is active
        _withdrawFromCurrentPool(amount);
        // Unwrap and send ETH
        withdrawAmount(currentPool, msg.sender, amount);

        emit FundsWithdrawal(msg.sender, amount, amount);
    }

    /**
     * @notice Main callback function triggered by the Reactive Network
     * @param sender Address of the callback sender (must be authorized)
     * @dev Compares current rates and switches pools if yield difference exceeds threshold
     */
    function callback(address sender) external authorizedSenderOnly rvmIdOnly(sender) {
        uint256 aaveRate = aaveRateFetcher();
        uint256 compRate = compoundRateFetcher();

        bool aaveBetter = (aaveRate > (compRate + YIELD_THRESHOLD)) && (currentPool == 1);
        bool compBetter = (compRate > (aaveRate + YIELD_THRESHOLD)) && (currentPool == 0);

        if (aaveBetter || compBetter) {
            _switchPool(aaveBetter ? 0 : 1);
        } else {
            emit OptimalPoolActive(currentPool, aaveRate, compRate);
        }
    }

    /**
     * @notice Fetches current lending rate from Aave protocol
     * @return Current Aave lending rate in basis points (e.g., 500 = 5%)
     * @dev Converts from RAY precision to basis points for easier comparison
     */
    function aaveRateFetcher() public view returns (uint256) {
        DataTypes.ReserveData memory data = Pool.getReserveData(aaveWeth);
        return (uint256(data.currentLiquidityRate) * 10000) / RAY;
    }

    /**
     * @notice Fetches current lending rate from Compound v3 protocol
     * @return Current Compound lending rate in basis points (e.g., 500 = 5%)
     * @dev Calculates annualized rate from per-second rate and converts to basis points
     */
    function compoundRateFetcher() public view returns (uint256) {
        uint256 utilization = Comet.getUtilization();
        uint256 supplyRate = uint256(Comet.getSupplyRate(utilization));
        return (supplyRate * SECONDS_PER_YEAR * 10000) / WAD;
    }

    /**
     * @notice Internal function to supply ETH to the currently optimal protocol
     * @param amount Amount of ETH to supply
     * @dev Converts ETH to appropriate WETH and supplies to current pool
     */
    function _supply(uint256 amount) internal {
        if (currentPool == 0) {
            obtainAaveWETH(amount);
            Pool.supply(aaveWeth, amount, address(this), 0);
        } else {
            obtainCompoundWETH(amount);
            Comet.supply(compoundWeth, amount);
        }
    }

    /**
     * @notice Core rebalancing logic that moves all funds to the target pool
     * @param targetPool The destination pool (0=Aave, 1=Compound)
     * @dev Withdraws all funds from current pool, converts WETH if needed, and supplies to target pool
     */
    function _switchPool(uint8 targetPool) internal {
        uint8 fromPool = currentPool;
        
        // 1. Withdraw ALL (including interest dust)
        if (currentPool == 0) {
            Pool.withdraw(aaveWeth, type(uint256).max, address(this));
        } else {
            Comet.withdraw(compoundWeth, type(uint256).max);
        }

        // 2. Identify new balance (Principal + Interest)
        uint256 totalToMove = IERC20(targetPool == 0 ? aaveWeth : compoundWeth).balanceOf(address(this));

        // 3. Supply to new target
        if (targetPool == 0) {
            convertwethComTowethAave(totalToMove);
            Pool.supply(aaveWeth, totalToMove, address(this), 0);
        } else {
            convertwethAaveTowethCom(totalToMove);
            Comet.supply(compoundWeth, totalToMove);
        }

        currentPool = targetPool;
        emit PoolSwitched(fromPool, targetPool, totalToMove);
    }

    /**
     * @notice Gets the total amount currently supplied to lending protocols
     * @return Total supplied amount including accrued interest
     * @dev Returns aToken balance for Aave or Comet balance for Compound
     */
    function _getTotalSupplied() internal view returns (uint256) {
        if (currentPool == 0) {
            return IERC20(aTokenWeth).balanceOf(address(this));
        } else {
            return Comet.balanceOf(address(this));
        }
    }

    /**
     * @notice Internal function to withdraw specified amount from current protocol
     * @param amount Amount to withdraw from the current lending pool
     * @dev Calls appropriate withdrawal function based on currentPool
     */
    function _withdrawFromCurrentPool(uint256 amount) internal {
        if (currentPool == 0) {
            Pool.withdraw(aaveWeth, amount, address(this));
        } else {
            Comet.withdraw(compoundWeth, amount);
        }
    }
}