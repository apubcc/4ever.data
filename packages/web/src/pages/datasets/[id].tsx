import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { useAccount } from 'wagmi';

import supabase from '@/lib/supabase';
import { Dataset } from '@/lib/interfaces'

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
//   if (!res.verified) {
//     return {
//       redirect: {
//         destination: `/verify/${id}`,
//         permanent: false,
//       }
//     }
//   }
//
//   return {
//     props: { data: res }
//   }
// }

export default function Datasets() {
  const [data, setData] = useState<Dataset>(null)
  const router = useRouter();
  const { isConnected } = useAccount();

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
        if (!res.verified) router.push(`/verify/${id}`)
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
              <div className="flex gap-4 items-center">
                <p>{ data.file_name}</p>
                <a 
                  href=""
                  className="inline-block px-4 py-3 font-medium text-white bg-black rounded-lg"
                  download
                >
                  Download Dataset
                </a>
              </div>
            </div>
          }
        </>
      )}
    </div>
  )
}
