'use client'

import { useWallet } from '@/contexts/WalletContext'
import { Wallet, LogOut } from 'lucide-react'

export function SimpleWalletConnect() {
  const { account, isConnected, connectWallet, disconnectWallet } = useWallet()

  if (isConnected && account) {
    return (
      <div className="flex items-center gap-4">
        <span className="text-sm text-gray-300">
          {account.slice(0, 6)}...{account.slice(-4)}
        </span>
        <button
          onClick={disconnectWallet}
          className="flex items-center gap-2 px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors"
        >
          <LogOut size={16} />
          Disconnect
        </button>
      </div>
    )
  }

  return (
    <button
      onClick={connectWallet}
      className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-600 hover:shadow-lg hover:shadow-purple-500/25 text-white rounded-lg transition-all"
    >
      <Wallet size={16} />
      Connect Wallet
    </button>
  )
}