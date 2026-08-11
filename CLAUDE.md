# KartikOS — Claude Context

A personal life-OS dashboard. Built with Next.js 15 (App Router) + Supabase + Tailwind v4 + shadcn/ui.

This file is loaded into every Claude Code session. Keep it accurate and concise — link out for detail instead of pasting it here.

## Stack (locked)

| Layer          | Choice                                                                      |
| -------------- | --------------------------------------------------------------------------- |
| Framework      | Next.js 15 (App Router, React 19, typed routes)                             |
| Language       | TypeScript strict + `noUncheckedIndexedAccess`                              |
| Styling        | Tailwind v4 (PostCSS), shadcn/ui, `prettier-plugin-tailwindcss`             |
| UI primitives  | shadcn/ui (Radix + cva), `lucide-react` icons                               |
| Auth + DB      | Supabase (`@supabase/ssr`, `@supabase/supabase-js`)                         |
| Forms          | `react-hook-form` + `zod` via `@hookform/resolvers`                         |
| State (client) | `zustand`                                                                   |
| Charts         | `recharts`                                                                  |
| Dates          | `date-fns`                                                                  |
| Tests          | Vitest + Testing Library (unit/integration), Playwright (E2E)               |
| Lint/format    | ESLint (Next config + Prettier), Prettier, Husky + lint-staged + commitlint |
| Deploy         | Vercel                                                                      |

## Project layout

```
app/                  App Router routes
  (auth)/             Unauthenticated layout (login)
  auth/callback/      Supabase OAuth callback
  dashboard/          Authenticated app shell
components/           Shared React components (shadcn-generated primitives live in components/ui)
lib/
  supabase/           client.ts (browser), server.ts (RSC/Server Actions), middleware.ts (session refresh)
  utils.ts            cn() helper
tests/e2e/            Playwright specs
middleware.ts         Refreshes Supabase session on every request
```

The `@/*` path alias maps to the repo root.

## Commands

| Command             | What it does                                                                           |
| ------------------- | -------------------------------------------------------------------------------------- |
| `pnpm dev`          | Local dev server (port 3000)                                                           |
| `pnpm build`        | Production build                                                                       |
| `pnpm start`        | Run the production build locally                                                       |
| `pnpm lint`         | ESLint                                                                                 |
| `pnpm typecheck`    | `tsc --noEmit`                                                                         |
| `pnpm test`         | Vitest (watch by default; `-- --run` once)                                             |
| `pnpm test:e2e`     | Playwright (auto-starts `pnpm dev`)                                                    |
| `pnpm format`       | Prettier write                                                                         |
| `pnpm format:check` | Prettier check (used in CI)                                                            |
| `pnpm db:up`        | Apply pending migrations to the linked Supabase project (`supabase db push --linked`)  |
| `pnpm db:reset`     | Reset the linked project: drop, re-apply all migrations (`supabase db reset --linked`) |

Always use `pnpm` — there's a workspace lockfile and `pnpm-workspace.yaml`.

## Environment

Copy `.env.example` to `.env.local` and fill in Supabase values:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (server-only, optional — never expose to the client)

CI uses placeholder values for build-time type analysis. Real values are injected by Vercel at deploy.

## Linked dev project

There is no local Supabase stack. Development targets a single linked Supabase project
(Postgres + GoTrue + Storage + Studio + Edge Runtime) accessed over the network. No
Docker / Colima / Podman is required.

The Supabase CLI is a dev dependency (`supabase`); the project config lives in
`supabase/config.toml`. The CLI's stored access token (from `supabase login`) and the
linked project ref (from `supabase link`) authorize the CLI to push migrations and
inspect schema against the project.

```
supabase/
  config.toml          # project config (committed; ports, auth, etc.)
  migrations/          # versioned SQL migrations (applied in order)
  seed.sql             # dev-only seed; production guard at the top of the file
```

**One-time setup:**

```bash
supabase login                                    # opens browser, stores access token
supabase link --project-ref <ref from dashboard>  # binds the CLI to one project
```

The project ref is the subdomain in the dashboard URL
(`https://supabase.com/dashboard/project/<ref>`).

**Workflow:**

```bash
pnpm db:up       # apply any new migrations from supabase/migrations/ to the linked project
pnpm db:reset    # destructive: drops the project DB, re-applies all migrations (no seed)
```

`supabase/seed.sql` is gated by a top-of-file guard that aborts on the production guard
env var or a non-local DB URL, so it never runs against the linked project. For now
the linked project starts empty — seed real data by using the app once Phase 2 ships
pages. If a dev-only seed path is added later, it will live in a separate
`supabase/seed.dev.sql` gated for `--linked` use only.

**Migrations:**

- Migrations live in `supabase/migrations/` with `<timestamp>_<name>.sql` filenames.
- Each migration must be idempotent-safe (use `create table …` without `if exists` only on first creation).
- RLS is enabled on every public schema table. Add an owner policy keyed on `user_id = auth.uid()` whenever you add a table.
- Never edit a committed migration — add a new one.

## Conventions

- **Commits:** Conventional Commits via commitlint. Husky runs `lint-staged` on pre-commit and commitlint on `commit-msg`. Husky hooks live in `.husky/` (committed) and use `pnpm exec` — never `npx`.
- **Path alias:** `@/` → repo root. Don't use relative imports across directory boundaries.
- **Server vs client Supabase:** use `lib/supabase/server.ts` from Server Components, Server Actions, and Route Handlers; `lib/supabase/client.ts` from Client Components. The middleware helper (`lib/supabase/middleware.ts`) refreshes the session cookie.
- **Styling:** Tailwind v4 utilities + `cn()` from `lib/utils.ts`. No CSS modules, no styled-components.
- **shadcn/ui:** components land in `components/ui/<kebab-name>.tsx`. The `cn()` alias and `lucide-react` icons are wired up by default. Don't pull in a new icon package without checking first.
- **Strict TS:** `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` are on — handle `undefined` from array/record access, and use `prop?: T` rather than `prop: T | undefined` unless required.

## Testing

- **Vitest** for unit/integration. Tests live next to source as `*.test.ts` / `*.test.tsx`. `tests/e2e/**` is excluded.
- **Playwright** lives in `tests/e2e/`. The Playwright config auto-starts `pnpm dev` locally; in CI it points at the existing server.
- Write tests when adding non-trivial logic. Don't add tests for trivial wrappers.

## CI

`.github/workflows/ci.yml` runs on every PR and push to `main`:

1. **Lint** — `pnpm lint`
2. **Typecheck** — `pnpm typecheck`
3. **Unit tests** — `pnpm test -- --run`
4. **Build** — `pnpm build`
5. **E2E** — `pnpm test:e2e` (only runs when the PR touches `app/`, `components/`, `tests/`, `lib/`, `middleware.ts`, `next.config.ts`, or `playwright.config.ts`)

Concurrency group cancels superseded runs on the same ref.

## Deploy

Vercel. Import the repo at <https://vercel.com/new>, point it at `main`, and set the env vars from `.env.example`. No `vercel.json` is required — defaults are correct for Next.js 15. If we add custom build/output overrides later, they'll go in `vercel.json`.

## What NOT to do

- Don't install alternative icon libraries, CSS-in-JS, or competing UI kits — the stack is locked.
- Don't add `npx husky add` or similar — Husky is already initialized; edit `.husky/*.sh` directly.
- Don't commit `.env.local`, `.vercel/`, or anything in `.gitignore`.
- Don't bypass `lint-staged` with `--no-verify` unless you've already discussed it.
