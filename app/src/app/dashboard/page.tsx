'use client'

import { useState, useEffect } from 'react'
import { useWallet } from '@/contexts/WalletContext'
import { SimpleWalletConnect } from '@/components/SimpleWalletConnect'
import { ArrowLeft, ExternalLink, Activity, Copy, CheckCircle } from 'lucide-react'
import Link from 'next/link'

// Contract addresses mapped to users
const CONTRACT_ADDRESSES = {
  swapper: "0xa72B2d49db7CA4Ac669e2016c51BC608BCca9EF8",
  looper: "0x78D49B70CCe71E527af992ce1e7e15331C41F151",
  swapreactive: "0xc7000f3A7FE3606C664F78f5BFbF8614dd520285",
  borrowreactive: "0xf72BE3492988BCDeF396722229A76e18b6902d31",
  supplyreactive: "0xDcB9984F6d19d15dA03F90F2a1e0cc8EF6392C98",
  transferreactive: "0x36fBD788F67a90FB5D9095AEa52C8B3A9471B117"
}

// Mock user data - in production this would come from your backend based on connected wallet
const getUserContracts = (userAddress: string) => {
  // Return user-specific contract data
  return [
    {
      userAddress: userAddress,
      contracts: CONTRACT_ADDRESSES,
      leverage: "3.5x",
      amount: "0.005 WETH",
      status: "Active",
      timestamp: "2024-12-17 14:30:00"
    }
  ]
}

export default function DashboardPage() {
  const { isConnected, account } = useWallet()
  const [copiedAddress, setCopiedAddress] = useState<string | null>(null)
  
  // Get contracts for the connected user
  const userContracts = account ? getUserContracts(account) : []

  const copyToClipboard = async (address: string) => {
    try {
      await navigator.clipboard.writeText(address)
      setCopiedAddress(address)
      setTimeout(() => setCopiedAddress(null), 2000)
    } catch (err) {
      console.error('Failed to copy address:', err)
    }
  }

  const getExplorerLink = (address: string, contractName?: string) => {
    // Use ReactScan for reactive contracts, Sepolia Etherscan for others
    const reactiveContracts = {
      "0xc7000f3A7FE3606C664F78f5BFbF8614dd520285": "https://lasna.reactscan.net/address/0x58e95d9300254fbba4a6b0b8abc5e94bf9dc4c52/contract/0xc7000f3a7fe3606c664f78f5bfbf8614dd520285",
      "0xf72BE3492988BCDeF396722229A76e18b6902d31": "https://lasna.reactscan.net/address/0x58e95d9300254fbba4a6b0b8abc5e94bf9dc4c52/contract/0xf72be3492988bcdef396722229a76e18b6902d31",
      "0xDcB9984F6d19d15dA03F90F2a1e0cc8EF6392C98": "https://lasna.reactscan.net/address/0x58e95d9300254fbba4a6b0b8abc5e94bf9dc4c52/contract/0xdcb9984f6d19d15da03f90f2a1e0cc8ef6392c98",
      "0x36fBD788F67a90FB5D9095AEa52C8B3A9471B117": "https://lasna.reactscan.net/address/0x58e95d9300254fbba4a6b0b8abc5e94bf9dc4c52/contract/0x36fbd788f67a90fb5d9095aea52c8b3a9471b117"
    }
    
    const normalizedAddress = address.toLowerCase()
    const reactiveLink = Object.entries(reactiveContracts).find(([addr]) => 
      addr.toLowerCase() === normalizedAddress
    )
    
    if (reactiveLink) {
      return reactiveLink[1]
    }
    
    // Default to Sepolia Etherscan for non-reactive contracts
    return `https://sepolia.etherscan.io/address/${address}`
  }

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'active':
        return 'text-green-400 bg-green-400/10'
      case 'completed':
        return 'text-blue-400 bg-blue-400/10'
      case 'failed':
        return 'text-red-400 bg-red-400/10'
      default:
        return 'text-gray-400 bg-gray-400/10'
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900">
      {/* Header */}
      <header className="container mx-auto px-6 py-6 flex justify-between items-center">
        <div className="flex items-center gap-4">
          <Link 
            href="/app"
            className="flex items-center gap-2 text-gray-300 hover:text-white transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Back to App
          </Link>
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
              <Activity className="w-5 h-5 text-white" />
            </div>
            <h1 className="text-2xl font-clash font-bold text-white">Dashboard</h1>
          </div>
        </div>
        <SimpleWalletConnect />
      </header>

      {/* Main Dashboard */}
      <main className="container mx-auto px-6 py-12">
        <div className="max-w-6xl mx-auto">
          {/* Title */}
          <div className="text-center mb-12">
            <h2 className="text-4xl md:text-5xl font-clash font-bold mb-4">
              <span className="bg-gradient-to-r from-blue-400 via-purple-500 to-purple-600 bg-clip-text text-transparent">
                ReactiveLooper Dashboard
              </span>
            </h2>
            <p className="text-xl text-gray-300">
              Monitor contract addresses and track user activity
            </p>
          </div>

          {/* Contract Addresses Overview */}
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8 border border-white/20 mb-8">
            <h3 className="text-2xl font-clash font-bold text-white mb-6">Contract Addresses</h3>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
              {Object.entries(CONTRACT_ADDRESSES).map(([name, address]) => (
                <div key={name} className="bg-white/5 rounded-xl p-4 border border-white/10">
                  <div className="flex items-center justify-between mb-2">
                    <h4 className="font-clash font-semibold text-white capitalize">
                      {name.replace('reactive', ' Reactive')}
                    </h4>
                    <div className="flex gap-2">
                      <button
                        onClick={() => copyToClipboard(address)}
                        className="p-1 text-gray-400 hover:text-white transition-colors"
                        title="Copy address"
                      >
                        {copiedAddress === address ? (
                          <CheckCircle className="w-4 h-4 text-green-400" />
                        ) : (
                          <Copy className="w-4 h-4" />
                        )}
                      </button>
                      <a
                        href={getExplorerLink(address)}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="p-1 text-gray-400 hover:text-white transition-colors"
                        title="View on Etherscan"
                      >
                        <ExternalLink className="w-4 h-4" />
                      </a>
                    </div>
                  </div>
                  <p className="text-gray-300 text-sm font-mono break-all">
                    {address}
                  </p>
                </div>
              ))}
            </div>
          </div>

          {/* User Activity */}
          {isConnected && account ? (
            <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8 border border-white/20">
              <h3 className="text-2xl font-clash font-bold text-white mb-6">Your Activity</h3>
              <div className="space-y-6">
                {userContracts.map((user, index) => (
                <div key={index} className="bg-white/5 rounded-xl p-6 border border-white/10">
                  <div className="flex flex-col lg:flex-row lg:items-center justify-between mb-4">
                    <div className="flex items-center gap-4 mb-4 lg:mb-0">
                      <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                        <span className="text-white font-bold">{account[2]?.toUpperCase()}</span>
                      </div>
                      <div>
                        <h4 className="font-clash font-semibold text-white">Your Contracts</h4>
                        <p className="text-gray-400 text-sm font-mono">{account.slice(0, 6)}...{account.slice(-4)}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="text-right">
                        <p className="text-white font-semibold">{user.leverage}</p>
                        <p className="text-gray-400 text-sm">Leverage</p>
                      </div>
                      <div className="text-right">
                        <p className="text-white font-semibold">{user.amount}</p>
                        <p className="text-gray-400 text-sm">Amount</p>
                      </div>
                      <div className="text-right">
                        <span className={`px-3 py-1 rounded-full text-sm font-semibold ${getStatusColor(user.status)}`}>
                          {user.status}
                        </span>
                        <p className="text-gray-400 text-xs mt-1">{user.timestamp}</p>
                      </div>
                    </div>
                  </div>
                  
                  {/* User's Contract Addresses */}
                  <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-3">
                    {Object.entries(user.contracts).map(([name, address]) => (
                      <div key={name} className="bg-white/5 rounded-lg p-3 border border-white/5">
                        <div className="flex items-center justify-between">
                          <span className="text-gray-300 text-sm capitalize">
                            {name.replace('reactive', ' Reactive')}
                          </span>
                          <div className="flex gap-1">
                            <button
                              onClick={() => copyToClipboard(address)}
                              className="p-1 text-gray-500 hover:text-gray-300 transition-colors"
                            >
                              {copiedAddress === address ? (
                                <CheckCircle className="w-3 h-3 text-green-400" />
                              ) : (
                                <Copy className="w-3 h-3" />
                              )}
                            </button>
                            <a
                              href={getExplorerLink(address)}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="p-1 text-gray-500 hover:text-gray-300 transition-colors"
                            >
                              <ExternalLink className="w-3 h-3" />
                            </a>
                          </div>
                        </div>
                        <p className="text-gray-400 text-xs font-mono mt-1">
                          {address.slice(0, 10)}...{address.slice(-8)}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
              </div>
            </div>
          ) : (
            <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8 border border-white/20 text-center">
              <h3 className="text-2xl font-clash font-bold text-white mb-4">Connect Your Wallet</h3>
              <p className="text-gray-300 mb-6">
                Please connect your wallet to view your ReactiveLooper contracts and activity.
              </p>
              <div className="flex justify-center">
                <SimpleWalletConnect />
              </div>
            </div>
          )}

          {/* Quick Actions */}
          <div className="grid md:grid-cols-3 gap-6 mt-8">
            <Link href="/app">
              <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 hover:bg-white/15 transition-all cursor-pointer">
                <h4 className="font-clash font-bold text-white mb-2">Launch New Loop</h4>
                <p className="text-gray-300 text-sm">
                  Create a new ReactiveLooper instance with custom parameters
                </p>
              </div>
            </Link>
            
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
              <h4 className="font-clash font-bold text-white mb-2">Your Contracts</h4>
              <p className="text-3xl font-bold text-purple-400">{Object.keys(CONTRACT_ADDRESSES).length}</p>
            </div>
            
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
              <h4 className="font-clash font-bold text-white mb-2">Status</h4>
              <p className="text-3xl font-bold text-green-400">
                {isConnected && userContracts.length > 0 ? userContracts[0].status : 'N/A'}
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}