import { useAccount } from 'wagmi';

import { useModal } from '@/lib/hooks/useModal';
import Card from '@/components/Card';
import Modal from '@/components/Modal';

export default function Home() {
  const [isOpen, toggleModal] = useModal();
  const { address, isConnected } = useAccount();

  const toVerify = { id: 1, title: 'Dataset to verify', desc: 'short description of the data', verified: false }
  const verified = { id: 1, title: 'Verified dataset', desc: 'short description of the data', verified: true }

  return (
    <div className="max-w-5xl m-auto px-4 lg:px-0 py-8">
      {isConnected && (
        <>
          <div className="space-y-6">
            <div className="flex justify-between items-center">
              <h1 className="text-4xl font-bold">Datasets</h1>
              <button 
                onClick={toggleModal}
                className="px-4 py-3 font-medium text-white bg-black rounded-lg"
              >
                Upload Dataset
              </button>
            </div>
            <div>
              <h2 className="text-3xl font-bold mb-3">Datasets Needing Verification</h2>
              <div className="grid sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
              { [1,2,3,4,5,6].map((i) => (
                <Card data={toVerify} key={i} />
              ))}
              </div>
            </div>
            <div>
              <h2 className="text-3xl font-bold mb-3">Verified Datasets</h2>
              <div className="grid sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
              { [1,2,3,4,5,6,7,8,9,0].map((i) => (
                <Card data={verified} key={i}/>
              ))}
              </div>
            </div>
          </div>
          <Modal isOpen={isOpen} toggleModal={toggleModal} />
        </>
      )}
    </div>
  )
}
