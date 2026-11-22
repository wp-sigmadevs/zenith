# 40 — Next.js & React Tools (WebStorm Parity)

> **Status (2026-11-21):** code in `crates/zenith_nextjs`, merged into fork `zenith` @ `7ef1dc7da2` (from `feat/external-libraries` @ `3ec7baecab`); built + reviewed (code + security, 2 rounds, fixes landed), UNWIRED: workspace member only, no init/umbrella feature, so its actions/panels are unreachable in the app. Wiring = its own reviewed task. Milestone ✅ below means code and tests only.

## Goal

WebStorm-grade code intelligence, routing navigation, and architecture safety for React and Next.js (App Router & Pages Router).

## Parity Checklist

- [ ] Next.js project detection (`next` in `package.json`, `next.config.js` / `next.config.mjs` / `next.config.ts`) (must)
- [ ] App Router tree indexer:
  - Pages: `app/**/page.{tsx,jsx,js}`
  - Layouts: `app/**/layout.{tsx,jsx,js}`
  - Loading: `app/**/loading.{tsx,jsx,js}`
  - Errors: `app/**/error.{tsx,jsx,js}`
  - API Route Handlers: `app/**/route.{ts,js}` with HTTP method extraction (`GET`, `POST`, `PUT`, `DELETE`, etc.) (must)
- [ ] Route path calculation:
  - Route groups: `app/(marketing)/about/page.tsx` → `/about`
  - Dynamic segments: `app/blog/[slug]/page.tsx` → `/blog/:slug`
  - Catch-all segments: `app/shop/[...slug]/page.tsx` → `/shop/*`
  - Optional catch-all: `app/shop/[[...slug]]/page.tsx` → `/shop{/*}` (must)
- [ ] Route autocomplete in `<Link href="...">` and `router.push('...')` (must)
- [ ] React Server Component (RSC) vs Client Component analyzer:
  - Directive detection: `"use client"`, `"use server"`
  - Safety rule: flag client hook calls (`useState`, `useEffect`, `useRef`, `useContext`) in Server Components (without `"use client"`) (must)
- [ ] Server Actions indexer: functions marked with `"use server"` (must)

## Architecture

- Crate `zenith_nextjs` (GPL-3.0-or-later).
- Incremental route indexer and RSC scanner in pure Rust.

## Progress (crate `zenith_nextjs`)

| Step | State | Commit |
|---|---|---|
| M1 Next.js App Router Indexer & RSC Safety | ✅ Next.js project detector; App Router path calculator supporting route groups `(group)`, dynamic segments `[slug]`, catch-all `[...slug]`, optional catch-all `[[...slug]]`; page/layout/loading/error/route file categorization; API route HTTP method extraction (`GET`, `POST`, `PUT`, `DELETE`); route autocomplete (`route_completions`, not yet connected to any completion provider — audit 2026-11-22); React Server Component vs Client Component analyzer (`"use client"`, `"use server"`); client hook safety linter (`useState`, `useEffect`, etc.); clippy clean; sabotage tested. | `3954a0782a` |
| M2 Next.js App Router Panel UI | ✅ Dock panel (`NextJsPanel`) implementing `Panel`, `Focusable`, `EventEmitter`; All / Pages / APIs filter tabs; search filter; route badges (`PAGE`, `API`, `LAYOUT`, `ERROR`); URL paths with HTTP methods; file location jumping via `workspace.open_abs_path`; action `ToggleNextJsPanel`; tested with `gpui::test`. | `2acb39adf6` |
