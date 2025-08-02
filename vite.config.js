import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  root: 'src',
  publicDir: '../public',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'src/index.html')
      }
    },
    minify: 'terser',
    sourcemap: true,
    target: 'es2015'
  },
  server: {
    port: 3000,
    open: true,
    host: true
  },
  preview: {
    port: 4173,
    open: true,
    host: true
  },
  css: {
    devSourcemap: true
  },
  optimizeDeps: {
    include: []
  }
});