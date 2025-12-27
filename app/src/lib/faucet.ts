export interface FaucetResponse {
  success: boolean
  txHash?: string
  amount?: string
  token?: string
  recipient?: string
  message?: string
  error?: string
}

export async function requestWETH(address: string): Promise<FaucetResponse> {
  try {
    const response = await fetch('/api/faucet', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ address }),
    })

    const data = await response.json()
    
    if (!response.ok) {
      throw new Error(data.error || 'Failed to request WETH')
    }

    return data
  } catch (error: any) {
    console.error('Faucet request failed:', error)
    return {
      success: false,
      error: error.message || 'Failed to request WETH'
    }
  }
}