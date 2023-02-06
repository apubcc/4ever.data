import React, { useState } from 'react';
import lighthouse from '@lighthouse-web3/sdk';
import { useAccount } from 'wagmi';

import supabase from '@/lib/supabase';

// TODO: add proper type annotations
export default function Modal({ isOpen, toggleModal }: { isOpen: boolean, toggleModal: any }) {
  const [loading, setLoading] = useState(false);
  const { address } = useAccount();

  const onSubmit = async (e: React.FormEventHandler<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    const { title, desc, file } = e.target
    const babi = { 
      persist: () => true,
      target: {
        files: file.files
      }
    }
    // @ts-ignore
    const output = await lighthouse.upload(babi, process.env.NEXT_PUBLIC_LIGHTHOUSE_API_KEY)
    console.log(output)
    if (!output || !output.data) {
      console.log('error: ', output)
      return
    }
    const { error } = await supabase
      .from('datasets').insert({
        // @ts-ignore
        name: title.value,
        desc: desc.value,
        ipfs_hash: output.data.Hash,
        filecoin_hash: '',
        uploader: address,
        file_name: output.data.Name,
        size: output.data.Size,
        verified: false,
    })
    if (error) console.log(error);
    toggleModal();
  }

  return (
    <>
      {isOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-40 z-50 flex justify-center items-center">
          <form onSubmit={onSubmit} className="min-w-[42rem] bg-bg p-6 border-4 duration-100 space-y-6">
            <p className="text-3xl font-bold">Upload your dataset</p>

            <div className="space-y-3">
              <div className="flex flex-col">
                <label htmlFor="title">Dataset Title</label>
                <input required id="title" className="p-2 bg-bg border-2 border-white focus:outline-none"/>
              </div>
              <div className="flex flex-col">
                <label htmlFor="desc">Short description of your dataset</label>
                <input id="desc" className="p-2 bg-bg border-2 border-white focus:outline-none"/>
              </div>
              <div className="flex flex-col">
                <label htmlFor="file">Upload file</label>
                <input 
                  onChange={(e) => console.log('FUCKCKC', e)}
                  required  
                  type="file" 
                  id="file" 
                  accept=".csv,.tsv,.xls,.xlsx,.txt"
                  className="border file:mr-5 file:py-3 file:px-6 border-2 border-white
                    file:border-0 file:bg-secondary file:text-bg
                    file:font-bold file:hover:cursor-pointer" 
                />
                <p className="text-sm">.csv, .tsv, or .xls/.xlsx files only (max size: 32GB)</p>
              </div>
            </div>

            <div className="flex justify-end gap-4">
              <button 
                onClick={toggleModal}
                className="px-6 py-4 min-w-[6rem] font-bold text-xl"
              >
                Cancel
              </button>
              <button 
                type="submit"
                className="px-6 py-4 font-bold text-bg text-xl bg-primary"
              >
                { !loading
                  ? 'Upload'
                  : (<svg
                      className="w-6 h-6"
                      viewBox="0 0 30 30"
                      fill="none"
                     >
                       <path
                         fillRule="evenodd"
                         clipRule="evenodd"
                         d="M15 30c8.284 0 15-6.716 15-15 0-8.284-6.716-15-15-15C6.716 0 0 6.716 0 15c0 8.284 6.716 15 15 15zm0-4.5c5.799 0 10.5-4.701 10.5-10.5S20.799 4.5 15 4.5 4.5 9.201 4.5 15 9.201 25.5 15 25.5z"
                         fill="white"
                       ></path>
                       <path
                         d="M15 0C6.716 0 0 6.716 0 15h4.5C4.5 9.201 9.201 4.5 15 4.5V0z"
                         fill="black"
                         className={`origin-center animate-spin`}
                       />
                     </svg>)}
              </button>
            </div>
          </form>
        </div>
      )}
    </>
  )
}
