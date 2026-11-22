# Zenith

A fork of [Zed](https://github.com/zed-industries/zed) aiming at full PhpStorm/WebStorm parity for classic and agentic PHP/JS/WordPress/Laravel development, while keeping Zed's speed.

> Status: **Phase 0 (foundation)**. The plan, the stock-Zed config layer and the engineer agents are done; the fork is cloned and its first build is in progress. Zenith is not affiliated with Zed Industries; "Zed" is their trademark.

## Repositories

| Repo | Purpose | Branches |
|---|---|---|
| [`wp-sigmadevs/zenith`](https://github.com/wp-sigmadevs/zenith) (this) | plan, `zed-kit` config, agents, issue tracking | `main` |
| [`wp-sigmadevs/zed`](https://github.com/wp-sigmadevs/zed) | Zenith source (fork of Zed) | `main` = mirror of upstream · `zenith` = integration · `feat/<name>` = one per feature |

Local layout: `~/GithubRepos/zenith` and `~/GithubRepos/zed`, side by side.

```
zenith/
  plan/           35 plan docs — start at plan/README.md
  zed-kit/        config layer for stock Zed (plan 03): install.sh, templates, zed-php-fmt
  .claude/agents/ 15 engineer agents + shared rules (README.md)
  .claude/hooks/  guard hooks (read-only bash, push guard, writer gate)
  docs/           task router (map/DOCS.md) + fork findings (guides/)
  CLAUDE.md       project rules for AI agents
  HANDOFF.md      current state + next steps (machine-to-machine handoff)
```

## Plan

Start at **[plan/README.md](plan/README.md)**: index, build order, timeline.

| Phase | Docs |
|---|---|
| 0 Foundation | 01 prerequisites · 02 architecture · 03 config layer · 15 zenith_core · 17 build · 18 performance |
| 1 Quick wins | 04 scratches · 14 toolbar UI · 05 local history · 20 templates · 27 TODO · 28 bookmarks |
| 2 Agentic | 06 IDE/MCP server · 23 agent review queue · 22 agent worktrees |
| 3 Daily depth | 21 inspections · 07 test runner · 19 WordPress · 08 HTTP client · 24 Composer/npm |
| 4 Heavy | 09 refactoring · 10 git merge/rebase · 11 Docker interpreters · 25 Laravel · 26 live templates |
| 5 Big / polish | 12 database tool · 29 settings UI · 31 PhpStorm migration · 30 profiler/coverage |
| Continuous | 13 maintenance · 16 upstream & extensions |

Progress: [Issues](../../issues) (one per plan doc) and [Milestones](../../milestones) (one per phase).

## Build

### Prerequisites (macOS)

| Need | How |
|---|---|
| Full Xcode | App Store (needs macOS ≥ 26.6), or Xcodes.app → Xcode 26.5 on macOS 26.5. Then, in the real Terminal: `sudo xcode-select -s /Applications/Xcode-<ver>.app/Contents/Developer && sudo xcodebuild -license accept` |
| Rust | `rustup`. The fork pins the version in `rust-toolchain.toml` (currently 1.98.1) |
| cmake, gh | `brew install cmake gh` |
| Metal Toolchain | `xcodebuild -downloadComponent MetalToolchain` (Xcode 26 no longer bundles it; GPUI shaders fail without it, ~700 MB) |
| Disk | ≥ 80 GB free (Xcode + `target/`) |

### Set up

```sh
cd ~/GithubRepos
git clone https://github.com/wp-sigmadevs/zenith.git
git clone --filter=blob:none https://github.com/wp-sigmadevs/zed.git
git -C zed remote add upstream https://github.com/zed-industries/zed.git
git -C zed switch zenith || git -C zed switch -c zenith
zenith/zed-kit/install.sh            # optional: stock-Zed config layer (plan 03)
```

### Build, run, test (inside `~/GithubRepos/zed`)

| Task | Command |
|---|---|
| Build (debug) | `cargo build -p zed` (first build 30–60 min) |
| Run dev Zenith | `cargo run` |
| Check one crate | `cargo check -p zenith_<feature>` |
| Test one crate | `cargo test -p zenith_<feature>` (or `cargo nextest run -p …`) |
| Lint | `script/clippy` |
| Release bundle | `script/bundle-mac` (flags: see plan 01/13; *verify*) |

Speed tips (plan 17): only build the crate you touch, use `sccache`, and compile out features with `--no-default-features --features <feature>`.

## Workflow

```
Issue (zenith repo) → plan doc → feat/<name> branch (fork) → implement → gates → PR into `zenith` → merge → update plan status
                                                           ↑ weekly: merge upstream/main → main → zenith
```

1. **Pick work**: the next open issue in the current phase milestone. Each issue links its plan doc.
2. **Plan first**: anything new (a crate, an upstream hook, LS vs fork) gets a short plan from the lead engineer before code. The plan doc is the spec; update it if reality differs.
3. **Branch**: `git -C ~/GithubRepos/zed switch -c feat/<name> zenith`.
4. **Implement** in a new `crates/zenith_<feature>` crate. Upstream Zed files only get one-line hooks (plan 02). Prefer an extension or language server when the feature allows (plan 16).
5. **Gates** before a PR: `cargo check` + `cargo test` for each changed `zenith_*` crate, `script/clippy`, and a manual smoke test in `cargo run`.
6. **Review**: code review, plus security/performance/accessibility review when the change touches those areas.
7. **PR** into `zenith` on `wp-sigmadevs/zed`, with `Closes wp-sigmadevs/zenith#<n>`. Squash-merge.
8. **Close out**: set the plan doc's status in `plan/README.md` (⬜ → 🟨 → ✅) and close the issue.
9. **Upstream sync** (weekly, plan 13): `git fetch upstream` → fast-forward `main` → merge `main` into `zenith` → build + test.

Rules:
- Conventional commits: `feat(<crate>):`, `fix(<crate>):`, `docs:`, `chore:`. A hook rejects anything else.
- Fork naming: crates `zenith_*`, settings key `"zenith"`, data dir `paths::data_dir()` (macOS `~/Library/Application Support/Zenith`), app `Zenith.app`.
- Zed internals in plan docs are marked *verify*; check them against the fork's source before relying on them.
- Never use Zed's name or logo for Zenith.

## How to work — humans

- Read `HANDOFF.md` for the current state and next step, then the plan doc for the issue you pick.
- Follow the workflow above. Keep PRs to one feature; split anything over ~500 lines.
- Use `zed-kit` on your own machine (`zed-kit/README.md`), and merge Zed settings by hand.
- Admin tasks (repo settings, visibility, collaborators) are done as `wp-sigmadevs` (`gh auth switch -u wp-sigmadevs`; switch back to `smrafiz` after).
- Moving machines: update `HANDOFF.md` before you stop.

## How to work — AI agents

**Claude Code**: start the session in this repo so the project rules and agents load:

```sh
cd ~/GithubRepos/zenith && claude
> Read HANDOFF.md and CLAUDE.md, then continue with the next step.
```

- `CLAUDE.md` holds the project rules every session must follow.
- `.claude/agents/README.md` holds the roster, routing per phase, and shared rules all agents read first.

| Need | Agent |
|---|---|
| Route a multi-step task across engineers | `orchestrator` |
| Plan a feature, crate boundaries, upstream hooks | `lead-engineer` (read-only) |
| `zenith_core`, feature crates, storage, async | `rust-core-engineer` |
| Panels, views, toolbar, stripes (GPUI) | `gpui-ui-engineer` |
| Zed extensions, Rust language servers | `lsp-extension-engineer` |
| WordPress, Laravel, PHP tooling, `zed-kit` | `php-wordpress-laravel-engineer` |
| MCP/IDE server, ACP, agent worktrees, review queue | `agentic-integrations-engineer` |
| Build, upstream sync, bundling, CI | `release-ops-engineer` |
| Tests, QA checklist | `test-engineer` |
| Review / debug / security / perf / a11y | `code-reviewer` · `debugger` · `security-engineer` · `performance-engineer` · `accessibility-engineer` (all read-only) |
| Plans, README, changelog | `docs-editor` |

Guard rails (enforced by `.claude/hooks/`):
- Read-only agents can't write files or run mutating shell commands.
- Agents never push; a human, or the main session on explicit request, does.
- Writer agents must pass the writer gate (`cargo check`/`test` on changed `zenith_*` crates, script syntax checks) before handing back.
- Every report ends with an `## Issues` list (BROKEN / RISK / NOT DONE / UNKNOWN).

**Other agents** (Codex, Cursor, Zed Agent): use `CLAUDE.md` as the rules file and `.claude/agents/<role>.md` as role prompts. Same workflow and gates.

**Agents in the fork**: project agents only load where the session starts. Work from `~/GithubRepos/zenith` and address the fork as `../zed` (`git -C ../zed …`), or symlink `.claude/agents` and `.claude/hooks` into the fork.

## Licence

- This repository (plan docs, `zed-kit` config): [MIT](LICENSE).
- Zenith fork code: follows Zed's licences (GPL-3.0 editor, AGPL-3.0 server parts, Apache-2.0 GPUI); new `zenith_*` crates are GPL-3.0-or-later.
- Standalone language servers (`wp-hooks-ls`, `laravel-ls`, …): MIT, in their own repositories.

Security issues: see [SECURITY.md](SECURITY.md).
