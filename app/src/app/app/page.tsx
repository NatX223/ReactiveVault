"use client";

import { useState } from "react";
import { useWallet } from "@/contexts/WalletContext";
import { SimpleWalletConnect } from "@/components/SimpleWalletConnect";
import { ArrowLeft, Loader2, Coins } from "lucide-react";
import Link from "next/link";
import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { parseEther } from "viem";

// Vault contract address
const VAULT_ADDRESS = "0x60E3567B0987c5bE1A01f21114ed79c3e9dB6A2E" as const;

// Vault ABI for deposit and withdraw functions
const VAULT_ABI = [
  {
    inputs: [{ name: "amount", type: "uint256" }],
    name: "deposit",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [{ name: "amount", type: "uint256" }],
    name: "withdraw",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

export default function AppPage() {
  const { isConnected, account } = useWallet();
  const [amount, setAmount] = useState("");
  const [isProcessing, setIsProcessing] = useState(false);

  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    });

  const handleDeposit = async () => {
    if (!isConnected || !account) {
      alert("Please connect your wallet first!");
      return;
    }
    if (!amount || parseFloat(amount) <= 0) {
      alert("Please enter a valid amount!");
      return;
    }

    // Warn about high amounts
    if (parseFloat(amount) > 0.01) {
      const confirmed = confirm(
        `⚠️ You're about to use ${amount} ETH. we recommend using smaller amounts (0.001 - 0.01 ETH). Do you want to continue?`
      );
      if (!confirmed) return;
    }

    setIsProcessing(true);
    try {
      console.log("Depositing to ReactiveVault:", {
        amount,
        vaultAddress: VAULT_ADDRESS,
        userAddress: account,
      });

      const amountInWei = parseEther(amount);

      writeContract({
        address: VAULT_ADDRESS,
        abi: VAULT_ABI,
        functionName: "deposit",
        args: [amountInWei],
        value: amountInWei,
      });

      console.log("Transaction initiated");

      alert(
        `🚀 Deposit Transaction Initiated!\n\n` +
          `✅ ${amount} ETH deposit started\n` +
          `📄 Contract: ${VAULT_ADDRESS}\n\n` +
          `Please confirm the transaction in your wallet...`
      );
    } catch (error: any) {
      console.error("Deposit error:", error);

      let errorMessage = "Unknown error occurred";
      if (error.message) {
        if (
          error.message.includes("User rejected") ||
          error.message.includes("user rejected")
        ) {
          errorMessage = "Transaction was rejected by user";
        } else if (error.message.includes("insufficient funds")) {
          errorMessage = "Insufficient ETH balance";
        } else if (error.message.includes("gas")) {
          errorMessage = "Gas estimation failed - check your ETH balance";
        } else {
          errorMessage = error.message;
        }
      }

      alert(`❌ Deposit Failed: ${errorMessage}`);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleWithdraw = async () => {
    if (!isConnected || !account) {
      alert("Please connect your wallet first!");
      return;
    }
    if (!amount || parseFloat(amount) <= 0) {
      alert("Please enter a valid amount!");
      return;
    }

    setIsProcessing(true);
    try {
      console.log("Withdrawing from ReactiveVault:", {
        amount,
        vaultAddress: VAULT_ADDRESS,
        userAddress: account,
      });

      const amountInWei = parseEther(amount);

      writeContract({
        address: VAULT_ADDRESS,
        abi: VAULT_ABI,
        functionName: "withdraw",
        args: [amountInWei],
      });

      console.log("Withdrawal transaction initiated");

      alert(
        `🚀 Withdrawal Transaction Initiated!\n\n` +
          `✅ ${amount} vault tokens withdrawal started\n` +
          `📄 Contract: ${VAULT_ADDRESS}\n\n` +
          `Please confirm the transaction in your wallet...`
      );
    } catch (error: any) {
      console.error("Withdrawal error:", error);

      let errorMessage = "Unknown error occurred";
      if (error.message) {
        if (
          error.message.includes("User rejected") ||
          error.message.includes("user rejected")
        ) {
          errorMessage = "Transaction was rejected by user";
        } else if (error.message.includes("insufficient")) {
          errorMessage = "Insufficient vault token balance";
        } else if (error.message.includes("gas")) {
          errorMessage = "Gas estimation failed";
        } else {
          errorMessage = error.message;
        }
      }

      alert(`❌ Withdrawal Failed: ${errorMessage}`);
    } finally {
      setIsProcessing(false);
    }
  };

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
              <h1 className="text-2xl font-clash font-bold text-white">
                ReactiveVault
              </h1>
            </div>
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
                Interact with vault
              </span>
            </h2>
            <p className="text-xl text-gray-300">
              Deposit and withdraw to interact with pool
            </p>
          </div>

          {/* Advisory Notice */}
          <div className="bg-green-500/10 backdrop-blur-sm rounded-xl p-4 border border-green-500/30 mb-8">
            <div className="flex items-center gap-3">
              <Coins className="w-5 h-5 text-green-400 flex-shrink-0" />
              <div>
                <p className="text-green-400 text-sm">
                  💡 Deposit ETH to receive vault tokens that represent your
                  share in the yield-optimized pool
                </p>
              </div>
            </div>
          </div>

          {/* Configuration Card */}
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8 border border-white/20 mb-8">
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
                  <span className="text-gray-400 font-semibold">ETH</span>
                </div>
              </div>
              <p className="text-gray-400 text-sm mt-2">
                Enter the amount of ETH to deposit to the ReactiveVault
                contract.
              </p>
              <p className="text-green-400 text-xs mt-1">
                💡 Note: You will be minted with an equivalent amount of vault
                tokens
              </p>
            </div>

            {/* Action Buttons */}
            {isConnected ? (
              <div className="space-y-4">
                {/* Transaction Status */}
                {hash && (
                  <div className="bg-blue-500/10 backdrop-blur-sm rounded-xl p-4 border border-blue-500/30">
                    <div className="flex items-center gap-3">
                      <Loader2 className="w-5 h-5 text-blue-400 animate-spin" />
                      <div>
                        <p className="text-blue-400 text-sm font-semibold">
                          Transaction Pending
                        </p>
                        <p className="text-gray-400 text-xs">
                          Hash: {hash.slice(0, 10)}...{hash.slice(-8)}
                        </p>
                        {isConfirming && (
                          <p className="text-yellow-400 text-xs">
                            Waiting for confirmation...
                          </p>
                        )}
                        {isConfirmed && (
                          <p className="text-green-400 text-xs">
                            ✅ Transaction confirmed!
                          </p>
                        )}
                      </div>
                    </div>
                  </div>
                )}

                <div className="flex gap-4">
                  <button
                    onClick={handleDeposit}
                    disabled={!amount || isProcessing || isPending}
                    className="flex-1 flex items-center justify-center gap-3 px-8 py-4 bg-gradient-to-r from-blue-500 to-purple-600 text-white font-clash font-bold text-lg rounded-xl hover:shadow-lg hover:shadow-purple-500/25 transition-all duration-300 transform hover:scale-[1.02] disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                  >
                    {isProcessing || isPending ? (
                      <>
                        <Loader2 className="w-6 h-6 animate-spin" />
                        {isPending ? "Confirm in wallet..." : "Processing..."}
                      </>
                    ) : (
                      <>Deposit</>
                    )}
                  </button>
                  <button
                    onClick={handleWithdraw}
                    disabled={!amount || isProcessing || isPending}
                    className="flex-1 flex items-center justify-center gap-3 px-8 py-4 bg-gradient-to-r from-red-500 to-orange-600 text-white font-clash font-bold text-lg rounded-xl hover:shadow-lg hover:shadow-red-500/25 transition-all duration-300 transform hover:scale-[1.02] disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                  >
                    {isProcessing || isPending ? (
                      <>
                        <Loader2 className="w-6 h-6 animate-spin" />
                        {isPending ? "Confirm in wallet..." : "Processing..."}
                      </>
                    ) : (
                      <>Withdraw</>
                    )}
                  </button>
                </div>
              </div>
            ) : (
              <button
                disabled={true}
                className="w-full flex items-center justify-center gap-3 px-8 py-4 bg-gradient-to-r from-blue-500 to-purple-600 text-white font-clash font-bold text-lg rounded-xl opacity-50 cursor-not-allowed"
              >
                Connect Wallet to interact with vault
              </button>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
