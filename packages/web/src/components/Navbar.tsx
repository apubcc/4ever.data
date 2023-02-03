import Link from 'next/link';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';

export default function Navbar() {
  const { address, isConnected } = useAccount();

  return (
    <header className="h-16 border-b shadow-md border bg-white">
      <div className="max-w-5xl m-auto h-full flex justify-between items-center px-4 lg:px-0">
        <Link href="/">
          <div className="text-2xl font-bold">K3ggl4</div>
        </Link>
        <nav className="space-x-4 text-lg font-medium">
          <Link href="/about">About</Link>
          { isConnected 
              ? <Link href="/profile">Profile</Link>
              : <div className="inline-block"><ConnectButton /></div> }
        </nav>
      </div>
    </header>
  )
}
