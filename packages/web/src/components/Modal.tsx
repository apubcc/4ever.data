import { useState } from 'react';

export default function Modal({ isOpen, toggleModal }) { 
  console.log('fuck')
  return (
    <>
      {isOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-40 z-50 flex justify-center items-center">
          <div className="min-w-[42rem] bg-white p-6 border rounded-lg shadow-lg transition space-y-6">
            <p className="text-2xl font-bold">Upload your dataset</p>

            <div className="space-y-3">
              <div className="flex flex-col">
                <label htmlFor="title">Dataset Title</label>
                <input id="title" className="px-2 py-1 border rounded-md"/>
              </div>
              <div className="flex flex-col">
                <label htmlFor="desc">Short description of your dataset</label>
                <input id="desc" className="px-2 py-1 border rounded-md"/>
              </div>
              <div className="flex flex-col">
                <label htmlFor="file_input">Upload file</label>
                <input 
                  type="file" 
                  id="file_input" 
                  className="border rounded-md file:mr-5 file:py-2 file:px-6 file:rounded-md 
                    file:border-0 file:bg-black file:text-white
                    file:font-bold file:hover:cursor-pointer" 
                />
                <p className="text-sm">.csv, .tsv, or .xls/.xlsx files only (max size: 32GB)</p>
              </div>
            </div>

            <div className="flex justify-end gap-4">
              <button 
                onClick={toggleModal}
                className="px-4 py-3 min-w-[6rem] rounded-lg border-2 border-black font-medium"
              >
                Cancel
              </button>
              <button 
                onClick={toggleModal}
                className="px-4 py-3 min-w-[6rem] rounded-lg font-medium bg-black text-white"
              >
                Upload
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
