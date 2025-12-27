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
          <div className="w-8 h-8 bg-gradient-primary rounded-lg flex items-center justify-center">
            <Zap className="w-5 h-5 text-white" />
          </div>
          <h1 className="text-2xl font-clash font-bold text-white">ReactiveLooper</h1>
        </div>
        <SimpleWalletConnect />
      </header>

      {/* Hero Section */}
      <main className="container mx-auto px-6 py-12">
        <div className="max-w-4xl mx-auto text-center mb-16">
          <h2 className="text-5xl md:text-6xl font-clash font-bold mb-6 text-center">
            <span className="bg-gradient-to-r from-blue-400 via-purple-500 to-purple-600 bg-clip-text text-transparent block">
              Optimize Your DeFi Leverage
            </span>
          </h2>
          <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
            Execute complex multi-step DeFi operations in a single atomic transaction, 
            eliminating gas waste and price risk exposure.
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
              Achieving optimal leverage in decentralized finance typically involves complex, 
              multi-step transaction sequences which are vulnerable to high gas costs and 
              critical exposure to price risk between operations.
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
              The project introduces a custom smart contract architecture that utilizes 
              Reactive network's smart contract automation to orchestrate the multi-step execution. 
              This automation enables the seamless operation of the recursive supply-borrow-swap 
              loop within a single, atomic transaction, saving critical time and eliminating the 
              exposure window to asset volatility, which is a major risk when transactions must 
              be submitted individually.
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
              ReactiveLooper utilizes the Reactive and Callback functionality from Reactive network 
              to monitor and react accordingly to supply and borrow events from the Aave V3 pool contract. 
              It also monitors the swapper contract (specifically created for this project to swap 
              between the collateral and borrow assets). All steps in the loop are contained in one 
              call back contract.
            </p>
          </div>
        </section>

        {/* Features Grid */}
        <section className="grid md:grid-cols-3 gap-6 mb-16">
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <div className="w-12 h-12 bg-blue-500 rounded-lg flex items-center justify-center mb-4">
              <Zap className="w-6 h-6 text-white" />
            </div>
            <h4 className="font-clash font-bold text-white mb-2">Atomic Execution</h4>
            <p className="text-gray-300 text-sm">
              All operations execute in a single transaction, eliminating intermediate risks.
            </p>
          </div>
          
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <div className="w-12 h-12 bg-purple-500 rounded-lg flex items-center justify-center mb-4">
              <Shield className="w-6 h-6 text-white" />
            </div>
            <h4 className="font-clash font-bold text-white mb-2">Risk Mitigation</h4>
            <p className="text-gray-300 text-sm">
              Minimize exposure to price volatility and MEV attacks during execution.
            </p>
          </div>
          
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <div className="w-12 h-12 bg-green-500 rounded-lg flex items-center justify-center mb-4">
              <TrendingUp className="w-6 h-6 text-white" />
            </div>
            <h4 className="font-clash font-bold text-white mb-2">Gas Optimization</h4>
            <p className="text-gray-300 text-sm">
              Reduce overall gas costs by batching multiple operations efficiently.
            </p>
          </div>
        </section>

        {/* CTA Section */}
        <section className="text-center">
          <div className="bg-gradient-primary rounded-2xl p-8 text-white">
            <h3 className="text-3xl font-clash font-bold mb-4">
              Ready to Optimize Your DeFi Strategy?
            </h3>
            <p className="text-white/90 mb-6 max-w-2xl mx-auto">
              Join the future of decentralized finance with automated, risk-minimized leverage operations.
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