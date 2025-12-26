// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract WETHConverter {
    IWETH public immutable wethAave;
    IWETH public immutable wethCom;

    event WETHConverted(
        address indexed user,
        address indexed fromWETH,
        address indexed toWETH,
        uint256 amount
    );

    event WETHObtained(
        address indexed user,
        address indexed wethAddress,
        uint256 amount
    );

    constructor(address _wethAave, address _wethCom) {
        require(_wethAave != address(0), "Invalid WETH wethAave address");
        require(_wethCom != address(0), "Invalid WETH wethCom address");
        require(_wethAave != _wethCom, "WETH addresses must be different");

        wethAave = IWETH(_wethAave);
        wethCom = IWETH(_wethCom);
    }

    function convertwethAaveTowethCom(uint256 amount) public {
        _convert(wethAave, wethCom, amount);
    }

    function convertwethComTowethAave(uint256 amount) public {
        _convert(wethCom, wethAave, amount);
    }

    /**
     * @dev Obtain Aave WETH by depositing ETH
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
     * @dev Obtain Compound WETH by depositing ETH
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

    // function to withdraw and weth
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