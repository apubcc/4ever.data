import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';

export default function Home() {
  const { address, connector, isConnected } = useAccount();
  return (
    <div className="min-h-screen flex items-center justify-center">
      {isConnected 
      ? (
        <>
          hello { address }, connected to { connector?.name }
        </>
      ) 
      : (
        <ConnectButton />
      )
      }
    </div>
  )
}
