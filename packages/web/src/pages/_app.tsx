import { useState, useEffect } from 'react';
import type { AppProps } from 'next/app'
import { RainbowKitProvider, getDefaultWallets, lightTheme } from '@rainbow-me/rainbowkit';
import { configureChains, createClient, WagmiConfig } from 'wagmi';
import { mainnet, polygon, optimism, arbitrum } from 'wagmi/chains';
import { alchemyProvider } from 'wagmi/providers/alchemy';
import { publicProvider } from 'wagmi/providers/public';
import '@rainbow-me/rainbowkit/styles.css';

import '../styles/globals.css';
import Navbar from '@/components/Navbar';

const { chains, provider } = configureChains(
  [mainnet, polygon, optimism, arbitrum],
  [
    alchemyProvider({ apiKey: process.env.ALCHEMY_ID ?? '' }),
    publicProvider()
  ]
);
const { connectors } = getDefaultWallets({
  appName: 'BridgeXchange',
  chains
});
const wagmiClient = createClient({
  autoConnect: true,
  connectors,
  provider
})


export default function App({ Component, pageProps }: AppProps) {
  // this part is to avoid hydration issue
  const [mounted, setMounted] = useState(false)
  useEffect(() => setMounted(true), [])
  if (!mounted) return null

  return (
  <WagmiConfig client={wagmiClient}>
    <RainbowKitProvider 
      appInfo={{ appName: 'BridgeXchange' }}
      chains={chains}
      theme={lightTheme({ accentColor: "black" })}
    >
      <div className="min-h-screen text-lg">
        <Navbar />
        <Component {...pageProps} />
      </div>
    </RainbowKitProvider>
  </WagmiConfig>
  )
}
