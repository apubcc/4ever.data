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
    <div className="max-w-6xl m-auto px-4 lg:px-0 py-8">
      {isConnected && (
        <>
          { data &&
            <div className="space-y-6">
              <h1 className="text-5xl font-bold">{ data.name }</h1>
              <p className="text-xl">{ data.desc }</p>

              <div className="space-y-2 border-t-4 border-white py-3">
                <p className="text-xl font-medium">Dataset Details:</p>
                <p>Uploaded by: { data.uploader }</p>
                <p>Size: { data.size }b</p>
                <p>IPFS hash: { data.ipfs_hash }</p>
                <p>
                  Dataset file: <a target="_blank" rel="noreferrer" href={`https://ipfs.io/ipfs/${data.ipfs_hash}`} className="text-primary underline">{data.file_name}</a>
                </p>
              </div>
              <button className="px-6 py-4 font-bold text-bg text-xl bg-primary">
                Verify Dataset
              </button>
            </div>
          }
        </>
      )}
    </div>
  )
}
