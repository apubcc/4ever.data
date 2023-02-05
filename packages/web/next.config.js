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
  },
  trailingSlash: true,
}

module.exports = nextConfig
