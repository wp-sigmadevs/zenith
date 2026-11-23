# Zenith — Project Context for Claude

Zenith = fork of Zed aiming at full PhpStorm/WebStorm parity (classic + agentic PHP/JS/WordPress/Laravel dev) while keeping Zed's speed. Owner builds WordPress themes/plugins (RadiusTheme) and Laravel/Node apps.

## Read first

- State, next steps, machine setup: `HANDOFF.md` (§2 state, §4 next steps) + the one `.claude/handoff-*.md` brief.
- Roadmap: `plan/README.md`. Fork gotchas: `docs/guides/fork-findings.md`.
- Code disagrees with a doc ⇒ code wins; fix the doc. Zed internal APIs in plan docs are from memory and marked *verify* — check against current Zed source before implementing.

## Repo & accounts

- Repo: `wp-sigmadevs/zenith` (public). Local: `~/GithubRepos/zenith` (work) / `~/GithubProjects/zenith` (home; fork at `~/GithubProjects/zed`). Default branch `main`.
- Accounts, admin tasks, repo security settings, licences, issue tracking: `docs/guides/repo-admin.md`.
- Never use Zed name/logo for Zenith (trademark).

## Layout

- `plan/` 44 plan docs (start at `plan/README.md`) · `zed-kit/` plan 03 config layer for stock Zed (`zed-kit/README.md`) · `docs/` router + guides · `.github/` issue and PR templates.

## Conventions

- Commits: conventional (`docs:`, `feat(zed-kit):`, `fix:`, `chore:`) — a hook rejects others.
- Fork naming: crates `zenith_*`, umbrella `zenith`, settings key `"zenith"`, branch `zenith`, data dir `paths::data_dir()` (macOS `~/Library/Application Support/Zenith`), bundle `Zenith.app`. New `zenith_*` crates: GPL-3.0-or-later.
- All fork code in new crates; upstream files get one-line hooks only (plan/02). Extension/LS-first where possible (plan/16). Shared infra in `zenith_core` (plan/15).
- Supercharger hook blocks writes under `~/.config/` — give the user the exact edit instead; never work around it.

## Fork reflexes

Details and evidence: `docs/guides/fork-findings.md`.

- Fork's own `CLAUDE.md` hard rule: any source edit ⇒ prepend `> [!IMPORTANT]` + review line to README.md; only the human removes it.
- Nothing user-visible says "Zed" (owner rule, 2026-11-16), EXCEPT: upstream credit (About window, README) and "Zed Agent" (their feature/service name; owner 2026-11-20, avoid trademark trouble). Keep upstream LICENSE files; new crates GPL-3.0-or-later.
- Upstream edit that can't be one line ⇒ append a block at end of file. Title bar: add Zenith UI as ONE section (6th section panics). Don't edit upstream default keymaps; use `assets/keymaps/zenith.json`.
- Changed `assets/settings/default.json` ⇒ run the touched crates' tests (upstream tests assume old defaults).
- New non-test fork code ⇒ `cargo check -p zenith` (tests and clippy enable `test-support` and hide app-build errors).
- Before any test/clippy/bundle run: `df -h ~` ≥ 30 GiB. Never `cargo clean`/delete `target/` while a build or clippy runs.
- Agent sensitive-path tests hang instead of failing: a hang = fail.

## Engineers

15 subagents in `.claude/agents/` — roster, routing per phase, setup and sources in `.claude/agents/README.md`. `lead-engineer` plans anything new (crates, upstream hooks, LS-vs-fork); one implementer per planned chunk; `code-reviewer` (+ security/performance/accessibility as relevant) before merge; `debugger` for a red gate. Read-only agents can't write; agents never push. Guard hooks live in `.claude/hooks/` (read-only-bash, guard-push, writer-gate).

## Project map

- Start at `docs/map/DOCS.md`: open the row for the task, then only the files it links.
- A change that adds, moves or removes a file a router names updates that router in the same change.
- Status goes to `HANDOFF.md` §2, new findings to `docs/guides/fork-findings.md`, other reference to `docs/` — not here. Keep this file under ~8 KB.
