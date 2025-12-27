'use client'

import { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import { requestWETH } from '@/lib/faucet'

// Ethereum provider types
interface EthereumProvider {
  request: (args: { method: string; params?: any[] }) => Promise<any>
  on: (event: string, callback: (...args: any[]) => void) => void
  removeListener: (event: string, callback: (...args: any[]) => void) => void
  isMetaMask?: boolean
}

declare global {
  interface Window {
    ethereum?: EthereumProvider
  }
}

interface WalletContextType {
  account: string | null
  isConnected: boolean
  connectWallet: () => Promise<void>
  disconnectWallet: () => void
  isRequestingWETH: boolean
}

const WalletContext = createContext<WalletContextType | undefined>(undefined)

export function WalletProvider({ children }: { children: ReactNode }) {
  const [account, setAccount] = useState<string | null>(null)
  const [isRequestingWETH, setIsRequestingWETH] = useState(false)

  useEffect(() => {
    // Check if already connected
    if (typeof window !== 'undefined' && window.ethereum) {
      window.ethereum.request({ method: 'eth_accounts' })
        .then((accounts: string[]) => {
          if (accounts.length > 0) {
            setAccount(accounts[0])
          }
        })
        .catch(console.error)
    }
  }, [])

  const handleWETHRequest = async (address: string) => {
    setIsRequestingWETH(true)
    try {
      const result = await requestWETH(address)
      if (result.success) {
        alert(`🎉 Success! You received ${result.amount} ${result.token}!\nTransaction: ${result.txHash}`)
      } else {
        console.error('WETH request failed:', result.error)
        // Don't show error alert for rate limiting or common issues
        if (!result.error?.includes('hour') && !result.error?.includes('insufficient')) {
          alert(`Failed to receive WETH: ${result.error}`)
        }
      }
    } catch (error) {
      console.error('WETH request error:', error)
    } finally {
      setIsRequestingWETH(false)
    }
  }

  const connectWallet = async () => {
    if (typeof window === 'undefined' || !window.ethereum) {
      alert('Please install MetaMask or another Web3 wallet!')
      return
    }

    try {
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      })
      const newAccount = accounts[0]
      setAccount(newAccount)
      
      // Automatically request WETH for new connections
      if (newAccount) {
        await handleWETHRequest(newAccount)
      }
    } catch (error) {
      console.error('Failed to connect wallet:', error)
      alert('Failed to connect wallet. Please try again.')
    }
  }

  const disconnectWallet = () => {
    setAccount(null)
  }

  return (
    <WalletContext.Provider value={{
      account,
      isConnected: !!account,
      connectWallet,
      disconnectWallet,
      isRequestingWETH
    }}>
      {children}
    </WalletContext.Provider>
  )
}

export function useWallet() {
  const context = useContext(WalletContext)
  if (context === undefined) {
    throw new Error('useWallet must be used within a WalletProvider')
  }
  return context
}