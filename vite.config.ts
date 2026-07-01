import path from "node:path";
import { defineConfig } from "vite";
import { viteStaticCopy } from "vite-plugin-static-copy";

export default defineConfig({
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
    },
  },
  plugins: [
    viteStaticCopy({
      targets: [
        {
          src: "assets/**/*",
          dest: "assets",
        },
      ],
    }),
  ],
  server: {
    port: 5173,
  },
});
