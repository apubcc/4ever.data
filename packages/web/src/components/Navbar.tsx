import Link from 'next/link';
import Image from 'next/image';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';

export default function Navbar() {
  const { address, isConnected } = useAccount();

  return (
    <header className="h-24 text-2xl font-bold">
      <div className="max-w-6xl m-auto h-full flex justify-between items-center px-4 lg:px-0">
        <nav className="space-x-6 hidden sm:block">
          <Link href="/">Home</Link>
          <Link href="/about">About</Link>
        </nav>

        <Link href="/" className="relative h-20 w-64">
          <Image src="/logo.png" alt="4ever.data logo" fill />
        </Link>

        <nav className="flex items-center gap-6">
          <Link href="#">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor" class="w-8 h-8">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a2.25 2.25 0 00-2.25-2.25H15a3 3 0 11-6 0H5.25A2.25 2.25 0 003 12m18 0v6a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 18v-6m18 0V9M3 12V9m18 0a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 9m18 0V6a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 6v3" />
            </svg>
          </Link>
          { isConnected 
              ? (
                <Link href="/profile">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-8 h-8">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M17.982 18.725A7.488 7.488 0 0012 15.75a7.488 7.488 0 00-5.982 2.975m11.963 0a9 9 0 10-11.963 0m11.963 0A8.966 8.966 0 0112 21a8.966 8.966 0 01-5.982-2.275M15 9.75a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </Link>
              )
              : <div className="inline-block bg-primary py-1 px-2">
                  <ConnectButton />
                </div> }
        </nav>
      </div>
    </header>
  )
}
