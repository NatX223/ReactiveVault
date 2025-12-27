'use client'

import { useWallet } from '@/contexts/WalletContext'
import { SimpleWalletConnect } from '@/components/SimpleWalletConnect'
import { ArrowRight, Zap, Shield, TrendingUp } from 'lucide-react'
import Link from 'next/link'

export default function Home() {
  const { isConnected } = useWallet()

  const handleGetStarted = () => {
    if (!isConnected) {
      alert('Please connect your wallet first to get started!')
      return
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900">
      {/* Header */}
      <header className="container mx-auto px-6 py-6 flex justify-between items-center">
        <div className="flex items-center gap-2">
          <h1 className="text-2xl font-clash font-bold text-white">ReactiveVault</h1>
        </div>
        <SimpleWalletConnect />
      </header>

      {/* Hero Section */}
      <main className="container mx-auto px-6 py-12">
        <div className="max-w-4xl mx-auto text-center mb-16">
          <h2 className="text-5xl md:text-6xl font-clash font-bold mb-6 text-center">
            <span className="bg-gradient-to-r from-blue-400 via-purple-500 to-purple-600 bg-clip-text text-transparent block">
              Yield optimizing Vault
            </span>
          </h2>
          <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
            ReactiveVault chooses the best pools based on APY and invests funds into such pools
          </p>
          {isConnected ? (
            <Link href="/app">
              <button className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-blue-500 to-purple-600 text-white font-semibold rounded-xl hover:shadow-lg hover:shadow-purple-500/25 transition-all duration-300 transform hover:scale-105">
                Get Started
                <ArrowRight className="w-5 h-5" />
              </button>
            </Link>
          ) : (
            <button
              onClick={handleGetStarted}
              className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-blue-500 to-purple-600 text-white font-semibold rounded-xl hover:shadow-lg hover:shadow-purple-500/25 transition-all duration-300 transform hover:scale-105"
            >
              Get Started
              <ArrowRight className="w-5 h-5" />
            </button>
          )}
        </div>

        {/* Problem Statement */}
        <section className="mb-16">
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8 border border-white/20">
            <h3 className="text-2xl font-clash font-bold text-white mb-4 flex items-center gap-2">
              <Shield className="w-6 h-6 text-red-400" />
              Problem Statement
            </h3>
            <p className="text-gray-300 leading-relaxed">
            DeFi yields flip constantly between DeFi pools, yet capital remains stagnant. Traditional smart contracts lack on-chain monitoring, forced to rely on slow, centralized off-chain triggers. This "blindness" causes execution latency and Yield Erosion, preventing capital from autonomously capturing the market's best rates.
            </p>
          </div>
        </section>

        {/* Solution */}
        <section className="mb-16">
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8 border border-white/20">
            <h3 className="text-2xl font-clash font-bold text-white mb-4 flex items-center gap-2">
              <TrendingUp className="w-6 h-6 text-green-400" />
              Solution
            </h3>
            <p className="text-gray-300 leading-relaxed">
            Powered by Reactive Network’s native cron functionality, our vault operates with total autonomy, eliminating the need for centralized keepers. It continuously calculates real-time APYs across Aave and Compound, automatically migrating capital to the highest-yielding pool. This replaces passive stagnation with a self-optimizing, zero-intervention strategy that captures peak yield 24/7.
            </p>
          </div>
        </section>

        {/* How It Works */}
        <section className="mb-16">
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8 border border-white/20">
            <h3 className="text-2xl font-clash font-bold text-white mb-4 flex items-center gap-2">
              <Zap className="w-6 h-6 text-purple-400" />
              How It Works
            </h3>
            <p className="text-gray-300 leading-relaxed">
              ReactiveVault utilizes the Cron and Callback functionality from Reactive network 
              to periodically monitor and react accordingly to check for the optimal pool and supply 
              the vault funds to that pool. 
              There are also user facing functions that allow users to deposit into the pool and withdraw 
              thus enabling anyone invest in high yielding pools efectively.
            </p>
          </div>
        </section>

        {/* Features Grid */}
        <section className="grid md:grid-cols-3 gap-6 mb-16">
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <div className="w-12 h-12 bg-blue-500 rounded-lg flex items-center justify-center mb-4">
              <Zap className="w-6 h-6 text-white" />
            </div>
            <h4 className="font-clash font-bold text-white mb-2">Cron Monitoring</h4>
            <p className="text-gray-300 text-sm">
              Periodic monitoring for the optimal pool to supply to.
            </p>
          </div>
          
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <div className="w-12 h-12 bg-purple-500 rounded-lg flex items-center justify-center mb-4">
              <Shield className="w-6 h-6 text-white" />
            </div>
            <h4 className="font-clash font-bold text-white mb-2">Accurate yield calculation</h4>
            <p className="text-gray-300 text-sm">
              Accurate yield calculation on both pools to find the best one.
            </p>
          </div>
          
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <div className="w-12 h-12 bg-green-500 rounded-lg flex items-center justify-center mb-4">
              <TrendingUp className="w-6 h-6 text-white" />
            </div>
            <h4 className="font-clash font-bold text-white mb-2">Yield threshold</h4>
            <p className="text-gray-300 text-sm">
              strong yield threshold to avoid neglegible yield difference thus leading to gas optimization.
            </p>
          </div>
        </section>

        {/* CTA Section */}
        <section className="text-center">
          <div className="bg-gradient-primary rounded-2xl p-8 text-white">
            <h3 className="text-3xl font-clash font-bold mb-4">
              Ready to Optimize Your capita?
            </h3>
            <p className="text-white/90 mb-6 max-w-2xl mx-auto">
              Start exploring.
            </p>
            {isConnected ? (
              <Link href="/app">
                <button className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-blue-500 to-purple-600 text-white font-semibold rounded-xl hover:shadow-lg hover:shadow-purple-500/25 transition-all duration-300 transform hover:scale-105">
                  Launch App
                  <ArrowRight className="w-5 h-5" />
                </button>
              </Link>
            ) : (
              <button
                onClick={handleGetStarted}
                className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-blue-500 to-purple-600 text-white font-semibold rounded-xl hover:shadow-lg hover:shadow-purple-500/25 transition-all duration-300 transform hover:scale-105"
              >
                Connect Wallet to Start
                <ArrowRight className="w-5 h-5" />
              </button>
            )}
          </div>
        </section>
      </main>
    </div>
  )
}