// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IWETH Interface
 * @notice Interface for Wrapped Ether (WETH) token functionality
 * @dev Defines standard WETH functions for deposit, withdraw, and ERC20 operations
 */
interface IWETH {
    /**
     * @notice Deposits ETH and mints equivalent WETH tokens
     * @dev Payable function that wraps ETH into WETH
     */
    function deposit() external payable;

    /**
     * @notice Withdraws ETH by burning WETH tokens
     * @param amount Amount of WETH tokens to burn for ETH
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Transfers WETH tokens to specified address
     * @param to Recipient address
     * @param amount Amount of WETH to transfer
     * @return success True if transfer succeeded
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @notice Transfers WETH tokens from one address to another (requires approval)
     * @param from Source address
     * @param to Destination address
     * @param amount Amount of WETH to transfer
     * @return success True if transfer succeeded
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Returns WETH balance of specified account
     * @param account Address to check balance for
     * @return balance WETH balance of the account
     */
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title WETHConverter
 * @author ReactiveLooper Team
 * @notice Handles conversion between different WETH implementations and ETH wrapping/unwrapping
 * @dev Manages Aave WETH and Compound WETH tokens, providing conversion and utility functions
 */
contract WETHConverter {
    /**
     * @notice WETH token interface for Aave protocol
     * @dev Immutable reference to Aave's WETH implementation
     */
    IWETH public immutable wethAave;
    
    /**
     * @notice WETH token interface for Compound protocol
     * @dev Immutable reference to Compound's WETH implementation
     */
    IWETH public immutable wethCom;

    /**
     * @notice Emitted when WETH is converted from one implementation to another
     * @param user Address of the user performing the conversion
     * @param fromWETH Address of the source WETH contract
     * @param toWETH Address of the destination WETH contract
     * @param amount Amount of WETH converted
     */
    event WETHConverted(
        address indexed user,
        address indexed fromWETH,
        address indexed toWETH,
        uint256 amount
    );

    /**
     * @notice Emitted when WETH is obtained by depositing ETH
     * @param user Address of the user obtaining WETH
     * @param wethAddress Address of the WETH contract used
     * @param amount Amount of WETH obtained
     */
    event WETHObtained(
        address indexed user,
        address indexed wethAddress,
        uint256 amount
    );

    /**
     * @notice Initializes the WETH converter with Aave and Compound WETH addresses
     * @param _wethAave Address of Aave WETH token contract
     * @param _wethCom Address of Compound WETH token contract
     * @dev Validates that addresses are non-zero and different from each other
     */
    constructor(address _wethAave, address _wethCom) {
        require(_wethAave != address(0), "Invalid WETH wethAave address");
        require(_wethCom != address(0), "Invalid WETH wethCom address");
        require(_wethAave != _wethCom, "WETH addresses must be different");

        wethAave = IWETH(_wethAave);
        wethCom = IWETH(_wethCom);
    }

    /**
     * @notice Converts Aave WETH to Compound WETH
     * @param amount Amount of Aave WETH to convert
     * @dev Withdraws ETH from Aave WETH and deposits to Compound WETH
     */
    function convertwethAaveTowethCom(uint256 amount) public {
        _convert(wethAave, wethCom, amount);
    }

    /**
     * @notice Converts Compound WETH to Aave WETH
     * @param amount Amount of Compound WETH to convert
     * @dev Withdraws ETH from Compound WETH and deposits to Aave WETH
     */
    function convertwethComTowethAave(uint256 amount) public {
        _convert(wethCom, wethAave, amount);
    }

    /**
     * @notice Obtains Aave WETH by depositing ETH
     * @param amount Amount of ETH to deposit for Aave WETH
     * @dev Wraps ETH into Aave WETH tokens
     */
    function obtainAaveWETH(uint256 amount) public {
        require(amount > 0, "Must send ETH to obtain WETH");

        // Deposit ETH to get Aave WETH
        wethAave.deposit{value: amount}();

        // Transfer WETH to the caller
        // require(
        //     wethAave.transfer(msg.sender, msg.value),
        //     "WETH transfer failed"
        // );

        emit WETHObtained(msg.sender, address(wethAave), amount);
    }

    /**
     * @notice Obtains Compound WETH by depositing ETH
     * @param amount Amount of ETH to deposit for Compound WETH
     * @dev Wraps ETH into Compound WETH tokens
     */
    function obtainCompoundWETH(uint256 amount) public {
        require(amount > 0, "Must send ETH to obtain WETH");

        // Deposit ETH to get Compound WETH
        wethCom.deposit{value: amount}();

        // Transfer WETH to the caller
        // require(
        //     wethCom.transfer(msg.sender, msg.value),
        //     "WETH transfer failed"
        // );

        emit WETHObtained(msg.sender, address(wethCom), amount);
    }

    /**
     * @notice Internal function to convert between WETH implementations
     * @param fromWETH Source WETH contract interface
     * @param toWETH Destination WETH contract interface
     * @param amount Amount of WETH to convert
     * @dev Withdraws ETH from source WETH and deposits to destination WETH
     */
    function _convert(IWETH fromWETH, IWETH toWETH, uint256 amount) internal {
        require(amount > 0, "Amount must be greater than 0");

        // Withdraw ETH from the source WETH
        fromWETH.withdraw(amount);

        // Deposit ETH to the target WETH
        toWETH.deposit{value: amount}();

        emit WETHConverted(
            msg.sender,
            address(fromWETH),
            address(toWETH),
            amount
        );
    }

    /**
     * @notice Withdraws WETH as ETH and sends to specified address
     * @param currentPool Pool identifier (0=Aave, 1=Compound)
     * @param to Address to receive the ETH
     * @param amount Amount of WETH to withdraw as ETH
     * @dev Unwraps WETH from the specified pool and transfers ETH to recipient
     */
    function withdrawAmount(uint256 currentPool, address to, uint256 amount) public {
        if (currentPool == 0) {
            wethAave.withdraw(amount);
            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            wethCom.withdraw(amount);
            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "ETH transfer failed");            
        }
    }
}