/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  typescript: {
    // TODO: fix type errs later
    ignoreBuildErrors: true,
  },
  images: {
    loader: 'akamai',
    path: '',
    unoptimized: true,
  },
  trailingSlash: true,
}

module.exports = nextConfig
