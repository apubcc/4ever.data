import { useAccount } from 'wagmi';

export async function getServerSideProps(context) {
  const { id } = context.params;
  return {
    props: { datasetId: id }
  }
}
export default function Dataset({ datasetId }) {
  const { address, isConnected } = useAccount();

  return (
    <div className="max-w-5xl m-auto px-4 lg:px-0 py-8">
      {isConnected && (
        <>
          <div className="space-y-6">
            <h1 className="text-4xl font-bold">{ datasetId }</h1>
          </div>
        </>
      )}
    </div>
  )
}
