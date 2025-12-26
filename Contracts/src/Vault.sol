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
 * @notice Optimizes yield by switching between Aave and Compound v3 using Reactive Network callbacks.
 */
contract Vault is AbstractCallback, Ownable, ERC20, WETHConverter {
    // --- Constants ---
    address public constant SERVICE = 0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA;
    uint256 private constant YIELD_THRESHOLD = 100; // 1% in basis points (100 = 1.00%)
    uint256 private constant RAY = 1e27;
    uint256 private constant WAD = 1e18;
    uint256 private constant SECONDS_PER_YEAR = 31536000;

    // --- State Variables ---
    address public immutable aaveWeth;
    address public immutable compoundWeth;
    address public immutable aTokenWeth; // Cached for gas efficiency
    uint256 public circulatingSupply;
    
    uint8 public currentPool; // 0 for Aave, 1 for Compound

    IPool public immutable Pool;
    IComet public immutable Comet;

    // --- Events ---
    event FundsDeposit(address indexed sender, uint256 amount, uint256 sharesMinted);
    event FundsWithdrawal(address indexed sender, uint256 amount, uint256 sharesBurned);
    event OptimalPoolActive(uint8 indexed currentPool, uint256 aaveRate, uint256 compoundRate);
    event PoolSwitched(uint8 indexed fromPool, uint8 indexed toPool, uint256 amount);

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
     * @notice Deposits ETH, wraps to WETH, and supplies to the current optimal pool.
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
     * @notice Withdraws ETH from the vault by burning shares.
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
     * @notice Main callback triggered by the Reactive Network.
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

    // --- Rate Fetchers ---

    function aaveRateFetcher() public view returns (uint256) {
        DataTypes.ReserveData memory data = Pool.getReserveData(aaveWeth);
        return (uint256(data.currentLiquidityRate) * 10000) / RAY;
    }

    function compoundRateFetcher() public view returns (uint256) {
        uint256 utilization = Comet.getUtilization();
        uint256 supplyRate = uint256(Comet.getSupplyRate(utilization));
        return (supplyRate * SECONDS_PER_YEAR * 10000) / WAD;
    }

    // --- Internal Logic ---

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
     * @dev Core rebalancing logic. Moves 100% of funds to the target pool.
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

    function _getTotalSupplied() internal view returns (uint256) {
        if (currentPool == 0) {
            return IERC20(aTokenWeth).balanceOf(address(this));
        } else {
            return Comet.balanceOf(address(this));
        }
    }

    function _withdrawFromCurrentPool(uint256 amount) internal {
        if (currentPool == 0) {
            Pool.withdraw(aaveWeth, amount, address(this));
        } else {
            Comet.withdraw(compoundWeth, amount);
        }
    }
}