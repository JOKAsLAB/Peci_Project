/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        background: '#121212',
        surface: '#1E1E1E',
        brand: '#00B140',
        success: '#00E676',
        error: '#CF6679',
        text: {
          primary: '#FFFFFF',
          secondary: 'rgba(255, 255, 255, 0.70)',
        }
      },
      fontFamily: {
        inter: ['Inter', 'sans-serif'],
      },
      borderRadius: {
        'card': '16px',
        'btn': '12px',
        'chip': '20px',
      }
    },
  },
  plugins: [],
}