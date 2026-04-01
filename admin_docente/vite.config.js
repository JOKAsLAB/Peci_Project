import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [vue()],
  server: {
    host: true,
    port: 5174,
    strictPort: true,
    cors: true,
    allowedHosts: true,
    ['ngrok-skip-browser-warning']: 'true',
  },
});
