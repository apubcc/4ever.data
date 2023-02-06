import Link from 'next/link';

import { Dataset } from '@/lib/interfaces';

export default function Card({ data, color }: { data: Dataset, color: string }) {
  return (
    <Link href={ data.verified ? `/datasets/${data.id}` : `/verify/${data.id}` }>
      <div className="border-b-4 border-white h-full hover:cursor-pointer pr-4 pb-4 hover:bg-white hover:text-bg duration-100">
        <div className="p-2">
          <p>#{ data.id }</p>
          <p className="font-bold text-3xl">{ data.name }</p>
          <p>{ data.desc }</p>
        </div>
      </div>
    </Link>
  )
}
