'use client'

import { Inter, Space_Grotesk } from "next/font/google";
import "./globals.css";
import { WalletProvider } from '@/contexts/WalletContext'
import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { config } from '@/lib/wagmi'
import { useState } from 'react'

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const spaceGrotesk = Space_Grotesk({
  variable: "--font-space-grotesk",
  subsets: ["latin"],
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const [queryClient] = useState(() => new QueryClient())

  return (
    <html lang="en">
      <body className={`${inter.variable} ${spaceGrotesk.variable} font-sans antialiased`}>
        <WagmiProvider config={config}>
          <QueryClientProvider client={queryClient}>
            <WalletProvider>
              {children}
            </WalletProvider>
          </QueryClientProvider>
        </WagmiProvider>
      </body>
    </html>
  );
}
