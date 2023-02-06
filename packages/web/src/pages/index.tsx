import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { Chat } from "@pushprotocol/uiweb";

import { useModal } from '@/lib/hooks/useModal';
import { Dataset } from '@/lib/interfaces';
import supabase from '@/lib/supabase';
import Card from '@/components/Card';
import Modal from '@/components/Modal';
import Landing from '@/components/Landing';

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
  const { address, isConnected } = useAccount();
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
    <div className="max-w-6xl m-auto px-4 lg:px-0 py-8 pb-24">
      {isConnected 
        ? (
        <>
          { datasets && <>
            <div className="space-y-12">
              <div className="flex justify-between items-center">
                <h1 className="text-5xl font-bold">Datasets</h1>
                <button 
                  onClick={toggleModal}
                  className="px-6 py-4 font-bold text-bg text-xl bg-primary"
                >
                  Upload Dataset
                </button>
              </div>
              { datasets.false && (
                <div className="border-t-4 border-secondary py-4 px-6">
                  <h2 className="text-3xl font-bold bg-secondary inline-block text-bg leading-relaxed relative -top-10">&nbsp;Datasets Needing Verification&nbsp;</h2>
                  <div className="grid sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                    { datasets.false.map((data) => (
                      <Card key={data.id} data={data} color="secondary" />
                    ))}
                    { datasets.false.map((data) => (
                      <Card key={data.id} data={data} color="secondary" />
                    ))}
                    { datasets.false.map((data) => (
                      <Card key={data.id} data={data} color="secondary" />
                    ))}
                    <p className="text-2xl text-white font-bold flex items-end gap-4">See all
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12h15m0 0l-6.75-6.75M19.5 12l-6.75 6.75" />
                      </svg>
                    </p>
                  </div>
                </div>
              )}
              { datasets.true && (
                <div className="border-t-4 border-tertiary py-4 px-6">
                  <h2 className="text-3xl font-bold bg-tertiary inline-block text-bg leading-relaxed relative -top-10">&nbsp;Verified Datasets&nbsp;</h2>
                  <div className="grid sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                    { datasets.true.map((data) => (
                      <Card key={data.id} data={data} color="tertiary" />
                    ))}
                    { datasets.true.map((data) => (
                      <Card key={data.id} data={data} color="tertiary" />
                    ))}
                    { datasets.true.map((data) => (
                      <Card key={data.id} data={data} color="tertiary" />
                    ))}
                    { datasets.true.map((data) => (
                      <Card key={data.id} data={data} color="tertiary" />
                    ))}
                    { datasets.true.map((data) => (
                      <Card key={data.id} data={data} color="tertiary" />
                    ))}
                    { datasets.true.map((data) => (
                      <Card key={data.id} data={data} color="tertiary" />
                    ))}
                    { datasets.true.map((data) => (
                      <Card key={data.id} data={data} color="tertiary" />
                    ))}
                    { datasets.true.map((data) => (
                      <Card key={data.id} data={data} color="tertiary" />
                    ))}
                    <p className="text-2xl text-white font-bold flex items-end gap-4">See all
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12h15m0 0l-6.75-6.75M19.5 12l-6.75 6.75" />
                      </svg>
                    </p>
                  </div>
                </div>
              )}
            </div>
            <Modal isOpen={isOpen} toggleModal={toggleModal} />
            <Chat
              account={address}
              supportAddress="0xd9c1CCAcD4B8a745e191b62BA3fcaD87229CB26d" //support address
              apiKey="jVPMCRom1B.iDRMswdehJG7NpHDiECIHwYMMv6k2KzkPJscFIDyW8TtSnk4blYnGa8DIkfuacU0"
              env="staging"
              primaryColor="#27ffff"
            />
          </>}
        </>
      )
      : <Landing />}
    </div>
  )
}
