import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';

import { useModal } from '@/lib/hooks/useModal';
import { Dataset } from '@/lib/interfaces';
import supabase from '@/lib/supabase';
import Card from '@/components/Card';
import Modal from '@/components/Modal';

// export async function getServerSideProps() {
//   const { error, data } = await supabase.from('datasets').select();
//
//   if (error) console.log(error)
//
//   const datasets = data.reduce((r, a) => {
//         r[a.verified] = r[a.verified] || [];
//         r[a.verified].push(a);
//         return r;
//   }, Object.create(null));
//
//   return {
//     props: { datasets }
//   }
// }

export default function Home() {
  const [datasets, setDatasets] = useState<any>(null);
  const { isConnected } = useAccount();
  const [isOpen, toggleModal] = useModal();

  useEffect(() => {
    supabase.from('datasets').select()
      .then(({ error, data }) => {
        if (error) {
          console.log(error)
          return
        }
        const datasets = data.reduce((r, a) => {
          r[a.verified] = r[a.verified] || [];
          r[a.verified].push(a);
          return r;
        }, Object.create(null));

        setDatasets(datasets);
      }).catch((e) => console.log(e))
  }, [])

  return (
    <div className="max-w-5xl m-auto px-4 lg:px-0 py-8">
      {isConnected && (
        <>
          { datasets && <>
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
              { datasets.false && (
                <div>
                  <h2 className="text-3xl font-bold mb-3">Datasets Needing Verification</h2>
                  <div className="grid sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                    { datasets.false.map((data) => (
                      <Card key={data.id} data={data}/>
                    ))}
                  </div>
                </div>
              )}
              { datasets.true && (
                <div>
                  <h2 className="text-3xl font-bold mb-3">Verified Datasets</h2>
                  <div className="grid sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                    { datasets.true.map((data) => (
                      <Card key={data.id} data={data}/>
                    ))}
                  </div>
                </div>
              )}
            </div>
            <Modal isOpen={isOpen} toggleModal={toggleModal} />
          </>}
        </>
      )}
    </div>
  )
}
