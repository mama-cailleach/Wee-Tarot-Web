import { copyFileSync, mkdirSync, readdirSync, statSync } from "node:fs";
import path from "node:path";
import { defineConfig, type Plugin } from "vite";
import { viteStaticCopy } from "vite-plugin-static-copy";

function copyDirNoChmod(src: string, dest: string): void {
  mkdirSync(dest, { recursive: true });
  for (const name of readdirSync(src)) {
    const from = path.join(src, name);
    const to = path.join(dest, name);
    if (statSync(from).isDirectory()) {
      copyDirNoChmod(from, to);
    } else {
      copyFileSync(from, to);
    }
  }
}

function copyGameAssetsBuild(): Plugin {
  return {
    name: "copy-game-assets-build",
    apply: "build",
    closeBundle() {
      copyDirNoChmod(path.resolve(__dirname, "assets"), path.resolve(__dirname, "dist/assets"));
    },
  };
}

export default defineConfig({
  base: process.env.GITHUB_PAGES === "true" ? "/Wee-Tarot-Web/" : "/",
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
    },
  },
  plugins: [
    ...viteStaticCopy({
      targets: [
        {
          src: "assets",
          dest: ".",
        },
      ],
    }).map((plugin) => ({ ...plugin, apply: "serve" as const })),
    copyGameAssetsBuild(),
  ],
  server: {
    port: 5173,
  },
  build: {
    rollupOptions: {
      input: {
        main: path.resolve(__dirname, "index.html"),
      },
    },
  },
});
