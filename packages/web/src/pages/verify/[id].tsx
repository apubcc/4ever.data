import { useAccount } from 'wagmi';

import supabase from '@/lib/supabase';

export async function getServerSideProps(context) {
  const { id } = context.params;
  const { data, error } = await supabase
    .from('datasets')
    .select()
    .eq('id', id)
    .limit(1)

  if (error) console.log(error)

  const res = data[0]
  if (res.verified) {
    return {
      redirect: {
        destination: `/datasets/${id}`,
        permanent: false,
      }
    }
  }

  return {
    props: { data: res }
  }
}
export default function Dataset({ data }) {
  const { isConnected } = useAccount();

  return (
    <div className="max-w-5xl m-auto px-4 lg:px-0 py-8">
      {isConnected && (
        <>
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
        </>
      )}
    </div>
  )
}
