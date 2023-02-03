import { useAccount } from 'wagmi';

export default function Profile() {
  const { address, isConnected } = useAccount();

  return (
    <div className="max-w-5xl m-auto px-4 lg:px-0 py-8">
      {isConnected && (
        <>
          <div className="space-y-6">
            <h1 className="text-4xl font-bold">About</h1>
          </div>
        </>
      )}
    </div>
  )
}
