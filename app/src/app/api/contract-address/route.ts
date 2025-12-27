import { NextRequest, NextResponse } from 'next/server'

// Mock contract addresses pool
// In production, these would be dynamically generated or retrieved from your contract factory
let CONTRACT_ADDRESSES = [
  "0x78D49B70CCe71E527af992ce1e7e15331C41F151"
]

export async function POST(request: NextRequest) {
  try {
    const { userAddress, leverage, amount } = await request.json()

    // Validate inputs
    if (!userAddress || !leverage || !amount) {
      return NextResponse.json(
        { error: 'Missing required parameters: userAddress, leverage, amount' },
        { status: 400 }
      )
    }

    // Check if we have available addresses
    if (CONTRACT_ADDRESSES.length === 0) {
      return NextResponse.json(
        { error: 'No contract addresses available. Please try again later.' },
        { status: 503 }
      )
    }

    // Get the first available address
    const contractAddress = CONTRACT_ADDRESSES[0]

    // Remove the address from the pool (simulate contract deployment/assignment)
    CONTRACT_ADDRESSES = CONTRACT_ADDRESSES.slice(1)

    // Simulate some processing time
    await new Promise(resolve => setTimeout(resolve, 500))

    return NextResponse.json({
      success: true,
      contractAddress,
      userAddress,
      leverage,
      amount,
      message: `Contract assigned for ${leverage}x leverage with ${amount} WETH`,
      estimatedGas: "0.002", // Mock gas estimate
      network: "sepolia",
      remainingAddresses: CONTRACT_ADDRESSES.length
    })

  } catch (error: any) {
    console.error('Contract address generation error:', error)
    return NextResponse.json(
      { error: 'Failed to generate contract address' },
      { status: 500 }
    )
  }
}

export async function GET() {
  return NextResponse.json({
    message: 'ReactiveLooper Contract Address API',
    usage: 'POST with { "userAddress": "0x...", "leverage": 2.5, "amount": "0.1" }',
    availableAddresses: CONTRACT_ADDRESSES.length
  })
}