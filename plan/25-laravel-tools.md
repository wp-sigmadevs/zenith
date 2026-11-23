# 25 — Laravel Tools (F7)

> **Status (2026-11-22):** wired in fork `zenith` (2026-11-21, `crates/zenith_laravel`). Route names complete inside `route()` strings (`eed27708e2`, merged in `zenith` via `integrate/batch-b` (not built into an app)).

## Goal

Laravel Idea–level navigation and tooling.

## Parity checklist

- [ ] Artisan panel: all commands (`php artisan list --format=json`), run with args form (must)
- [ ] Routes panel: `php artisan route:list --json` → method, URI, name, action; click → controller method (must)
- [ ] Go-to: `route('name')` → route def; `view('a.b')` → Blade file; `config('x.y')` → config key; `trans('…')`/`__()` → lang key; `env('X')` → `.env` (must)
- [ ] Completion for route names, view names, config keys, translation keys, env keys (must)
- [ ] Blade: `<x-component>` → component class/view; `@include('…')` go-to (must)
- [ ] Eloquent: model attributes/relations completion → via `barryvdh/laravel-ide-helper` generated stubs (03) (must)
- [ ] Migrations panel: status, run/rollback (confirm) (later)
- [ ] Tinker console (REPL in terminal) (must, trivial)
- [ ] Log viewer for `storage/logs/laravel.log` with level filter (later)
- [ ] Sail/Herd/Valet detection → interpreter (11) (must)

## Architecture (extension-first, 16)

- **Use the existing `laravel-official` Zed extension (Official Laravel LSP)** before building anything; `laravel-ls` only for gaps (check first for an existing maintained Laravel LS compatible with Zed; reuse if good):
  - Index: routes (from `route:list --json`, refreshed on routes file save), views (`resources/views/**`), config (parse `config/*.php` arrays via tree-sitter), lang files, `.env`.
  - LSP: definition, completion, hover inside the relevant string literals.
- **`zenith_laravel`** crate: Artisan + Routes (+ Migrations, Logs) panels; commands via `zenith_core::process`.
- IDE helper: action "Generate IDE helpers" runs `php artisan ide-helper:generate && ide-helper:models -N && ide-helper:meta`.

## Progress (crate `zenith_laravel`)

| Step | State | Commit |
|---|---|---|
| M1 Navigation & Code Intelligence Indexer | ✅ Laravel project detection (`artisan`, `bootstrap/app.php`, `composer.json`); view dot-name mapping (`resources/views/**/*.blade.php`), view completion; Blade `<x-component>` tag mapping; route parsing (`routes/web.php`, `routes/api.php`) with method, URI, action, name completions (index functions only; not yet connected to any completion provider — audit 2026-11-22); nested config key parsing (`config/*.php`) for `config('app.name')`; `.env` variable parsing and completion; clippy clean; sabotage tested. | `993be8275c` |
| M2 Artisan & Routes Panels | ✅ Dock panel (`LaravelPanel`) implementing `Panel`, `Focusable`, `EventEmitter`; Routes & Views tabs; search filter; method badges (`GET`, `POST`, `DELETE`); route name, URI, and controller action; file location jumping via `workspace.open_abs_path`; action `ToggleLaravelPanel`; tested with `gpui::test`. | `4649576782` |

## Milestones

1. Survey existing Laravel LS options.
2. Artisan + Routes panels.
3. LS: views/routes/config go-to + completion.
4. Blade components; translations; env.
5. Migrations + log viewer.

## Effort

2–3 weeks.
