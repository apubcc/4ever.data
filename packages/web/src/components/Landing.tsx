import Lottie from 'react-lottie';
import animationData from '@/lib/crypto.json';

export default function Landing() {
  const defaultOptions = {
    loop: true,
    autoplay: true,
    animationData,
  }
  return (
    <>
    <div className="flex items-center relative z-10">
      <div className="absolute -top-4 -left-52 w-[32rem] h-[32rem] bg-tertiary rounded-full mix-blend-multiply filter blur-3xl opacity-40 animate-blob"></div>
      <div className="absolute -bottom-32 left-32 w-96 h-96 bg-secondary rounded-full mix-blend-multiply filter blur-3xl opacity-40 animate-blob animation-delay-4000"></div>
      <div className="absolute -top-8 -right-16 w-[24rem] h-[24rem] bg-primary rounded-full mix-blend-multiply filter blur-3xl opacity-40 animate-blob animation-delay-2000"></div>
      <div className="z-20">
        <h1 className="text-8xl font-bold mb-16">Home of Decentralized Data Science</h1>
        <button className="px-6 py-4 font-bold text-bg text-xl bg-primary flex items-center gap-2">
          Get Started
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2.5} stroke="currentColor" className="w-6 h-6">
            <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12h15m0 0l-6.75-6.75M19.5 12l-6.75 6.75" />
          </svg>

        </button>
      </div>
      <div className="w-[64rem]">
        <Lottie options={defaultOptions} />
      </div>
    </div>
    </>
  )
}
