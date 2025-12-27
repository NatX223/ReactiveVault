'use client'

import { useState } from 'react'
import { useWallet } from '@/contexts/WalletContext'
import { SimpleWalletConnect } from '@/components/SimpleWalletConnect'
import { ArrowLeft, Zap, Rocket, AlertTriangle, Loader2 } from 'lucide-react'
import Link from 'next/link'
import { launchReactiveLooper } from '@/lib/weth-transfer'

export default function AppPage() {
  const { isConnected, account } = useWallet()
  const [leverage, setLeverage] = useState(2)
  const [amount, setAmount] = useState('')
  const [isLaunching, setIsLaunching] = useState(false)

  const handleLaunch = async () => {
    if (!isConnected || !account) {
      alert('Please connect your wallet first!')
      return
    }
    if (!amount || parseFloat(amount) <= 0) {
      alert('Please enter a valid amount!')
      return
    }

    // Warn about high amounts
    if (parseFloat(amount) > 0.01) {
      const confirmed = confirm(
        `⚠️ You're about to use ${amount} WETH. For testing purposes, we recommend using smaller amounts (0.001 - 0.01 WETH). Do you want to continue?`
      )
      if (!confirmed) return
    }

    setIsLaunching(true)
    try {
      console.log('Launching ReactiveLooper with:', { leverage, amount, userAddress: account })
      
      const result = await launchReactiveLooper(account, leverage, amount)
      
      if (result.success) {
        alert(
          `🚀 ReactiveLooper Launched Successfully!\n\n` +
          `✅ ${amount} WETH transferred to contract\n` +
          `📄 Contract: ${result.contractAddress}\n` +
          `🔗 Transaction: ${result.txHash}\n\n` +
          `Your ${leverage}x leveraged position is now active!`
        )
      } else {
        alert(`❌ Launch Failed: ${result.error}`)
      }
    } catch (error: any) {
      console.error('Launch error:', error)
      alert(`❌ Launch Failed: ${error.message || 'Unknown error occurred'}`)
    } finally {
      setIsLaunching(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900">
      {/* Header */}
      <header className="container mx-auto px-6 py-6 flex justify-between items-center">
        <div className="flex items-center gap-4">
          <Link 
            href="/"
            className="flex items-center gap-2 text-gray-300 hover:text-white transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Back
          </Link>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                <Zap className="w-5 h-5 text-white" />
              </div>
              <h1 className="text-2xl font-clash font-bold text-white">ReactiveLooper</h1>
            </div>
            <Link 
              href="/dashboard"
              className="text-gray-300 hover:text-white transition-colors text-sm"
            >
              Dashboard
            </Link>
          </div>
        </div>
        <SimpleWalletConnect />
      </header>

      {/* Main App Section */}
      <main className="container mx-auto px-6 py-12">
        <div className="max-w-2xl mx-auto">
          {/* Title */}
          <div className="text-center mb-12">
            <h2 className="text-4xl md:text-5xl font-clash font-bold mb-4">
              <span className="bg-gradient-to-r from-blue-400 via-purple-500 to-purple-600 bg-clip-text text-transparent">
                Launch Your Loop
              </span>
            </h2>
            <p className="text-xl text-gray-300">
              Configure your leverage parameters and start optimizing your DeFi strategy
            </p>
          </div>

          {/* Advisory Notice */}
          <div className="bg-yellow-500/10 backdrop-blur-sm rounded-xl p-4 border border-yellow-500/30 mb-8">
            <div className="flex items-center gap-3">
              <AlertTriangle className="w-5 h-5 text-yellow-400 flex-shrink-0" />
              <div>
                <h3 className="font-clash font-semibold text-yellow-400 mb-1">Testing Advisory</h3>
                <p className="text-yellow-200 text-sm">
                  For testing purposes, please use small amounts (0.001 - 0.01 WETH). 
                  This is a demo environment - avoid using large amounts.
                </p>
              </div>
            </div>
          </div>

          {/* Configuration Card */}
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8 border border-white/20 mb-8">
            {/* Leverage Slider */}
            <div className="mb-8">
              <label className="block text-white font-clash font-semibold mb-4">
                Leverage Multiplier: <span className="text-purple-400">{leverage}x</span>
              </label>
              <div className="relative">
                <input
                  type="range"
                  min="1"
                  max="10"
                  step="0.1"
                  value={leverage}
                  onChange={(e) => setLeverage(parseFloat(e.target.value))}
                  className="w-full h-3 bg-gray-700 rounded-lg appearance-none cursor-pointer slider"
                />
                <div className="flex justify-between text-sm text-gray-400 mt-2">
                  <span>1x</span>
                  <span>5x</span>
                  <span>10x</span>
                </div>
              </div>
            </div>

            {/* Amount Input */}
            <div className="mb-8">
              <label className="block text-white font-clash font-semibold mb-4">
                Amount (ETH)
              </label>
              <div className="relative">
                <input
                  type="number"
                  step="0.001"
                  min="0"
                  max="1"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="0.001"
                  className="w-full px-4 py-4 bg-gray-800/50 border border-gray-600 rounded-xl text-white text-lg font-semibold placeholder-gray-400 focus:outline-none focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 transition-all"
                />
                <div className="absolute right-4 top-1/2 transform -translate-y-1/2">
                  <span className="text-gray-400 font-semibold">WETH</span>
                </div>
              </div>
              <p className="text-gray-400 text-sm mt-2">
                Enter the amount of WETH to transfer to the ReactiveLooper contract
              </p>
              <p className="text-yellow-400 text-xs mt-1">
                💡 Recommended: 0.001 - 0.01 WETH for testing
              </p>
            </div>

            {/* Launch Button */}
            <button
              onClick={handleLaunch}
              disabled={!isConnected || !amount || isLaunching}
              className="w-full flex items-center justify-center gap-3 px-8 py-4 bg-gradient-to-r from-blue-500 to-purple-600 text-white font-clash font-bold text-lg rounded-xl hover:shadow-lg hover:shadow-purple-500/25 transition-all duration-300 transform hover:scale-[1.02] disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
            >
              {isLaunching ? (
                <>
                  <Loader2 className="w-6 h-6 animate-spin" />
                  Launching...
                </>
              ) : (
                <>
                  <Rocket className="w-6 h-6" />
                  {!isConnected ? 'Connect Wallet to Launch' : 'Launch ReactiveLooper'}
                </>
              )}
            </button>
          </div>

          {/* Info Cards */}
          <div className="grid md:grid-cols-3 gap-4">
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
              <h3 className="font-clash font-bold text-white mb-2">WETH Transfer</h3>
              <p className="text-gray-300 text-sm">
                Your WETH will be transferred to a ReactiveLooper contract for automated leverage operations.
              </p>
            </div>
            
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
              <h3 className="font-clash font-bold text-white mb-2">Risk Warning</h3>
              <p className="text-gray-300 text-sm">
                Leveraged positions carry significant risk. Only use funds you can afford to lose.
              </p>
            </div>
            
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
              <h3 className="font-clash font-bold text-white mb-2">Atomic Execution</h3>
              <p className="text-gray-300 text-sm">
                All operations are bundled into a single transaction for maximum efficiency and safety.
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}