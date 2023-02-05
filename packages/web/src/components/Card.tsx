import Image from 'next/image';
import Link from 'next/link';

import { Dataset } from '@/lib/interfaces';

export default function Card({ data }: { data: Dataset }) {
  return (
    <Link href={ data.verified ? `/datasets/${data.id}` : `/verify/${data.id}` }>
      <div className="border rounded-lg shadow-lg min-h-[16rem] hover:cursor-pointer">
        <div className="relative w-full min-h-[12rem] border-b">
          <Image src="/favicon.ico" alt="dataset thumbnail" fill className="object-contain" />
        </div>
        <div className="p-2">
          <p className="font-bold text-xl">{ data.name }</p>
          <p>{ data.desc }</p>
        </div>
      </div>
    </Link>
  )
}
