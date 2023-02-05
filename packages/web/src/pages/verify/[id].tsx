import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { useAccount } from 'wagmi';

import supabase from '@/lib/supabase';
import { Dataset } from '@/lib/interfaces';

// export async function getServerSideProps(context) {
//   const { id } = context.params;
//   const { data, error } = await supabase
//     .from('datasets')
//     .select()
//     .eq('id', id)
//     .limit(1)
//
//   if (error) console.log(error)
//
//   const res = data[0]
//   if (res.verified) {
//     return {
//       redirect: {
//         destination: `/datasets/${id}`,
//         permanent: false,
//       }
//     }
//   }
//
//   return {
//     props: { data: res }
//   }
// }

export default function Verify() {
  const [data, setData] = useState<Dataset>(null)
  const { isConnected } = useAccount();
  const router = useRouter();

  useEffect(() => {
    if(!router.isReady) return;
    const { id } = router.query;

    supabase
      .from('datasets')
      .select()
      .eq('id', id)
      .limit(1)
      .then(({ data, error }) => {
        if (error) {
          console.log(error)
          return 
        }
        const res = data[0]
        if (res.verified) router.push(`/datasets/${id}`)
        setData(res)
      }).catch((error) => console.log(error)) 
  }, [router])

  return (
    <div className="max-w-5xl m-auto px-4 lg:px-0 py-8">
      {isConnected && (
        <>
          { data &&
            <div className="space-y-6">
              <h1 className="text-4xl font-bold">{ data.name }</h1>
              <p>{ data.desc }</p>
              <p>Uploaded by: { data.uploader }</p>
              <p>Size: { data.size }b</p>
              <p>IPFS hash: { data.ipfs_hash }</p>
              <p>Filecoin hash: { data.filecoin_hash }</p>
              <p>
                Dataset file: <a target="_blank" rel="noreferrer" href={`https://ipfs.io/ipfs/${data.ipfs_hash}`} className="text-blue-500 underline">{data.file_name}</a>
              </p>
              <button
                className="px-4 py-3 font-medium text-white bg-black rounded-lg"
              >
                Verify Dataset
              </button>
            </div>
          }
        </>
      )}
    </div>
  )
}
