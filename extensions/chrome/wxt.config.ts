import { defineConfig } from "wxt";
import path from "path";
import fs from "fs";

export default defineConfig({
  modules: ["@wxt-dev/module-react"],
  srcDir: "src",
  hooks: {
    "build:done": async (wxt) => {
      // Copy icons to output
      const iconSizes = [16, 32, 48, 128];
      const outDir = wxt.config.outDir;
      const iconOutDir = path.join(outDir, "icon");

      if (!fs.existsSync(iconOutDir)) {
        fs.mkdirSync(iconOutDir, { recursive: true });
      }

      for (const size of iconSizes) {
        const src = path.join(__dirname, `public/icon/${size}.png`);
        const dest = path.join(iconOutDir, `${size}.png`);
        if (fs.existsSync(src)) {
          fs.copyFileSync(src, dest);
        }
      }
    },
  },
  manifest: {
    name: "Ente Auth",
    description: "Auto-fill TOTP codes from Ente Auth",
    icons: {
      16: "icon/16.png",
      32: "icon/32.png",
      48: "icon/48.png",
      128: "icon/128.png",
    },
    permissions: ["storage", "activeTab", "clipboardWrite", "alarms"],
    host_permissions: [
      "https://api.ente.io/*",
      "http://localhost:8080/*", // Self-hosted
    ],
    content_security_policy: {
      extension_pages:
        "script-src 'self' 'wasm-unsafe-eval'; object-src 'self'",
    },
  },
  vite: () => ({
    resolve: {
      alias: {
        // Force CJS version of libsodium to avoid ESM issues
        "libsodium-wrappers-sumo": path.resolve(
          __dirname,
          "node_modules/libsodium-wrappers-sumo/dist/modules-sumo/libsodium-wrappers.js"
        ),
      },
    },
    build: {
      rollupOptions: {
        // Ensure libsodium WASM is bundled correctly
        output: {
          manualChunks: undefined,
        },
      },
    },
  }),
});
