import { http, createConfig } from 'wagmi'
import { sepolia, mainnet } from 'wagmi/chains'
import { injected } from 'wagmi/connectors'

export const config = createConfig({
  chains: [sepolia, mainnet],
  connectors: [
    injected(),
  ],
  transports: {
    [sepolia.id]: http(),
    [mainnet.id]: http(),
  },
})

declare module 'wagmi' {
  interface Register {
    config: typeof config
  }
}