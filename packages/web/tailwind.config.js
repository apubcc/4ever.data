/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/**/*.{js,ts,jsx,tsx}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Space Grotesk', 'Arial', 'sans-serif']
      },
      colors: {
        primary: '#27ffff',
        secondary: '#ff3694',
        tertiary: '#370fff',
        bg: '#070029',
      }
    },
  },
  plugins: [],
}
