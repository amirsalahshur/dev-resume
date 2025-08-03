import { defineConfig } from 'vite';
import { resolve } from 'path';
import { fileURLToPath, URL } from 'node:url';
import autoprefixer from 'autoprefixer';
import cssnano from 'cssnano';

const __dirname = fileURLToPath(new URL('.', import.meta.url));

export default defineConfig(({ command, mode }) => {
  const isProduction = mode === 'production';
  
  return {
    root: 'src',
    publicDir: '../public',
    build: {
      outDir: '../dist',
      emptyOutDir: true,
      rollupOptions: {
        input: {
          main: resolve(__dirname, 'src/index.html')
        },
        output: {
          manualChunks: {
            vendor: ['vite']
          },
          chunkFileNames: 'assets/js/[name]-[hash].js',
          entryFileNames: 'assets/js/[name]-[hash].js',
          assetFileNames: (assetInfo) => {
            const info = assetInfo.name.split('.');
            const extType = info[info.length - 1];
            if (/\.(mp4|webm|ogg|mp3|wav|flac|aac)$/.test(assetInfo.name)) {
              return 'assets/media/[name]-[hash].[ext]';
            } else if (/\.(png|jpe?g|svg|gif|tiff|bmp|ico)$/.test(assetInfo.name)) {
              return 'assets/images/[name]-[hash].[ext]';
            } else if (extType === 'css') {
              return 'assets/css/[name]-[hash].[ext]';
            } else if (/\.(woff2?|eot|ttf|otf)$/.test(assetInfo.name)) {
              return 'assets/fonts/[name]-[hash].[ext]';
            }
            return 'assets/[name]-[hash].[ext]';
          }
        }
      },
      minify: isProduction ? 'terser' : false,
      terserOptions: {
        compress: {
          drop_console: isProduction,
          drop_debugger: isProduction,
          pure_funcs: isProduction ? ['console.log', 'console.info'] : []
        },
        format: {
          comments: false
        }
      },
      sourcemap: !isProduction,
      target: 'es2015',
      assetsInlineLimit: 4096,
      reportCompressedSize: true,
      chunkSizeWarningLimit: 1600
    },
    server: {
      port: 3000,
      open: true,
      host: true,
      cors: true,
      headers: {
        'Cross-Origin-Embedder-Policy': 'require-corp',
        'Cross-Origin-Opener-Policy': 'same-origin'
      }
    },
    preview: {
      port: 4173,
      open: true,
      host: true,
      cors: true,
      headers: {
        'Cache-Control': 'public, max-age=31536000',
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block'
      }
    },
    css: {
      devSourcemap: !isProduction,
      preprocessorOptions: {
        css: {
          charset: false
        }
      },
      postcss: {
        plugins: isProduction ? [
          autoprefixer,
          cssnano({
            preset: ['default', {
              discardComments: { removeAll: true },
              normalizeWhitespace: true
            }]
          })
        ] : []
      }
    },
    optimizeDeps: {
      include: [],
      exclude: []
    },
    esbuild: {
      drop: isProduction ? ['console', 'debugger'] : [],
      legalComments: 'none'
    },
    define: {
      __PROD__: JSON.stringify(isProduction),
      __DEV__: JSON.stringify(!isProduction)
    }
  };
});