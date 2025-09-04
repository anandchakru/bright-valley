/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'dark-green': '#002626',
        'midnight-green': '#0e4749',
        'yellow-green': '#95c623',
        'persimmon': '#e55812',
        'alabaster': '#efe7da',
      }
    },
  },
  plugins: [],
}