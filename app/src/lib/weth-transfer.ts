import { ethers } from 'ethers'

// WETH contract address (the one you specified)
export const WETH_CONTRACT_ADDRESS = "0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c"

// WETH ABI (minimal - just the functions we need)
const WETH_ABI = [
  "function transfer(address to, uint256 amount) returns (bool)",
  "function balanceOf(address account) view returns (uint256)",
  "function allowance(address owner, address spender) view returns (uint256)",
  "function approve(address spender, uint256 amount) returns (bool)"
]

export interface ContractAddressResponse {
  success: boolean
  contractAddress?: string
  userAddress?: string
  leverage?: number
  amount?: string
  message?: string
  estimatedGas?: string
  network?: string
  error?: string
}

export interface TransferResult {
  success: boolean
  txHash?: string
  contractAddress?: string
  amount?: string
  error?: string
}

// Get contract address from API
export async function getContractAddress(
  userAddress: string, 
  leverage: number, 
  amount: string
): Promise<ContractAddressResponse> {
  try {
    const response = await fetch('/api/contract-address', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ userAddress, leverage, amount }),
    })

    const data = await response.json()
    
    if (!response.ok) {
      throw new Error(data.error || 'Failed to get contract address')
    }

    return data
  } catch (error: any) {
    console.error('Contract address request failed:', error)
    return {
      success: false,
      error: error.message || 'Failed to get contract address'
    }
  }
}

// Transfer WETH to contract
export async function transferWETH(
  contractAddress: string,
  amount: string,
  userAddress: string
): Promise<TransferResult> {
  try {
    // Check if window.ethereum is available
    if (!window.ethereum) {
      throw new Error('Please install MetaMask or another Web3 wallet!')
    }

    // Create provider and signer
    const provider = new ethers.BrowserProvider(window.ethereum)
    const signer = await provider.getSigner()

    // Verify the signer address matches the user address
    const signerAddress = await signer.getAddress()
    if (signerAddress.toLowerCase() !== userAddress.toLowerCase()) {
      throw new Error('Wallet address mismatch. Please reconnect your wallet.')
    }

    // Create WETH contract instance
    const wethContract = new ethers.Contract(WETH_CONTRACT_ADDRESS, WETH_ABI, signer)

    // Convert amount to wei
    const amountWei = ethers.parseEther(amount)

    // Check user's WETH balance
    const balance = await wethContract.balanceOf(userAddress)
    if (balance < amountWei) {
      throw new Error(`Insufficient WETH balance. You have ${ethers.formatEther(balance)} WETH but need ${amount} WETH.`)
    }

    // Execute transfer
    console.log(`Transferring ${amount} WETH to contract ${contractAddress}...`)
    const tx = await wethContract.transfer(contractAddress, amountWei)
    
    console.log('Transaction submitted:', tx.hash)
    
    // Wait for confirmation
    const receipt = await tx.wait()
    
    if (receipt.status === 1) {
      return {
        success: true,
        txHash: receipt.hash,
        contractAddress,
        amount
      }
    } else {
      throw new Error('Transaction failed')
    }

  } catch (error: any) {
    console.error('WETH transfer failed:', error)
    
    // Handle specific error types
    if (error.code === 'ACTION_REJECTED') {
      return {
        success: false,
        error: 'Transaction was rejected by user'
      }
    }
    
    if (error.code === 'INSUFFICIENT_FUNDS') {
      return {
        success: false,
        error: 'Insufficient ETH for gas fees'
      }
    }

    return {
      success: false,
      error: error.message || 'Failed to transfer WETH'
    }
  }
}

// Complete ReactiveLooper launch process
export async function launchReactiveLooper(
  userAddress: string,
  leverage: number,
  amount: string
): Promise<TransferResult> {
  try {
    // Step 1: Get contract address
    console.log('Getting contract address...')
    const contractResponse = await getContractAddress(userAddress, leverage, amount)
    
    if (!contractResponse.success || !contractResponse.contractAddress) {
      throw new Error(contractResponse.error || 'Failed to get contract address')
    }

    // Step 2: Transfer WETH to contract
    console.log('Transferring WETH to contract...')
    const transferResult = await transferWETH(
      contractResponse.contractAddress,
      amount,
      userAddress
    )

    if (transferResult.success) {
      return {
        ...transferResult,
        contractAddress: contractResponse.contractAddress
      }
    } else {
      throw new Error(transferResult.error || 'Transfer failed')
    }

  } catch (error: any) {
    console.error('ReactiveLooper launch failed:', error)
    return {
      success: false,
      error: error.message || 'Failed to launch ReactiveLooper'
    }
  }
}