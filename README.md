# KartikOS

A personal life-OS dashboard — todos, finance, habits, journaling, anything else that's useful to live next to. Built with Next.js 15, Supabase, Tailwind v4, and shadcn/ui. Deployed on Vercel.

This is a single-user app. See [`CLAUDE.md`](./CLAUDE.md) for the full stack and conventions used by Claude Code.

## Quickstart

```bash
pnpm install
cp .env.example .env.local      # fill in Supabase creds
pnpm dev
```

Open <http://localhost:3000>.

## Scripts

| Command             | What it does                               |
| ------------------- | ------------------------------------------ |
| `pnpm dev`          | Local dev server (port 3000)               |
| `pnpm build`        | Production build                           |
| `pnpm start`        | Run the production build locally           |
| `pnpm lint`         | ESLint                                     |
| `pnpm typecheck`    | `tsc --noEmit`                             |
| `pnpm test`         | Vitest (watch by default; `-- --run` once) |
| `pnpm test:e2e`     | Playwright (auto-starts `pnpm dev`)        |
| `pnpm format`       | Prettier write                             |
| `pnpm format:check` | Prettier check                             |

## Deploy

Pushes to `main` are deployed automatically via Vercel. To set up a fresh Vercel project:

1. Import the repo at <https://vercel.com/new>.
2. Vercel auto-detects Next.js; the included `vercel.json` pins the install/build commands, output dir, and region (`iad1`).
3. Set the environment variables from `.env.example` in the Vercel project settings (Production + Preview).
4. Optional: connect a custom domain under Settings → Domains.

CI runs in `.github/workflows/ci.yml` on every PR and push to `main`.
