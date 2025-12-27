import { NextRequest, NextResponse } from 'next/server'
import { ethers } from 'ethers'

// WETH contract ABI (minimal - just the transfer function)
const WETH_ABI = [
  "function transfer(address to, uint256 amount) returns (bool)",
  "function balanceOf(address account) view returns (uint256)"
]

// WETH contract addresses for different networks
const WETH_ADDRESSES = {
  sepolia: "0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c", // Sepolia WETH
  // Add more networks as needed
}

export async function POST(request: NextRequest) {
  try {
    const { address } = await request.json()

    // Validate address
    if (!address || !ethers.isAddress(address)) {
      return NextResponse.json(
        { error: 'Invalid Ethereum address' },
        { status: 400 }
      )
    }

    // Get environment variables
    const privateKey = process.env.FAUCET_PRIVATE_KEY
    const rpcUrl = process.env.RPC_URL || 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY'
    const networkName = process.env.NETWORK || 'sepolia'

    if (!privateKey) {
      return NextResponse.json(
        { error: 'Faucet not configured' },
        { status: 500 }
      )
    }

    // Setup provider and wallet
    const provider = new ethers.JsonRpcProvider(rpcUrl)
    const wallet = new ethers.Wallet(privateKey, provider)

    // Get WETH contract address for the network
    const wethAddress = WETH_ADDRESSES[networkName as keyof typeof WETH_ADDRESSES]
    if (!wethAddress) {
      return NextResponse.json(
        { error: 'WETH not supported on this network' },
        { status: 400 }
      )
    }

    // Create WETH contract instance
    const wethContract = new ethers.Contract(wethAddress, WETH_ABI, wallet)

    // Amount to send: 0.0001 WETH (in wei)
    const amount = ethers.parseEther('0.0001')

    // Check faucet balance
    const faucetBalance = await wethContract.balanceOf(wallet.address)
    if (faucetBalance < amount) {
      return NextResponse.json(
        { error: 'Faucet has insufficient WETH balance' },
        { status: 500 }
      )
    }

    // Send WETH to user
    const tx = await wethContract.transfer(address, amount)

    // Wait for transaction confirmation
    const receipt = await tx.wait()

    return NextResponse.json({
      success: true,
      txHash: receipt.hash,
      amount: '0.0001',
      token: 'WETH',
      recipient: address,
      message: 'WETH sent successfully!'
    })

  } catch (error: any) {
    console.error('Faucet error:', error)

    // Handle specific error types
    if (error.code === 'INSUFFICIENT_FUNDS') {
      return NextResponse.json(
        { error: 'Faucet has insufficient ETH for gas fees' },
        { status: 500 }
      )
    }

    if (error.code === 'NONCE_EXPIRED' || error.code === 'REPLACEMENT_UNDERPRICED') {
      return NextResponse.json(
        { error: 'Transaction failed due to network congestion. Please try again.' },
        { status: 429 }
      )
    }

    return NextResponse.json(
      { error: 'Failed to send WETH. Please try again later.' },
      { status: 500 }
    )
  }
}

// Optional: Add rate limiting
const rateLimitMap = new Map()

function isRateLimited(address: string): boolean {
  const now = Date.now()
  const lastRequest = rateLimitMap.get(address)

  // Allow one request per hour per address
  if (lastRequest && now - lastRequest < 60 * 60 * 1000) {
    return true
  }

  rateLimitMap.set(address, now)
  return false
}

export async function GET() {
  return NextResponse.json({
    message: 'WETH Faucet API',
    usage: 'POST with { "address": "0x..." } to receive 0.0001 WETH',
    rateLimit: '1 request per hour per address'
  })
}