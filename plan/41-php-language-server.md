# 41 — PHP language server decision

Status: PROPOSED (owner review pending). Date: 2026-11-21. Fork `zenith` @ `85ae9afa91`.
Source: read-only audit by `lead-engineer` (agent ac1152b5951dd2416). Not run against binaries; items marked UNVERIFIED need M0.

## Question
Can Zenith have its own free "Intelephense" (find usages, "N usages" code lens, references, implementations, rename) like PhpStorm? Owner will not buy Intelephense Premium.

## Recommendation
**Do not write our own PHP language server. Make PHPantom the default PHP LS and wire WordPress stubs and code lens around it.** About 1–2 weeks, no new crate, 3 upstream lines.

## What the fork has today
| Server | Source / licence | Capabilities | Problem |
|---|---|---|---|
| PHPantom | third party `PHPantom-dev/phpantom_lsp`, Rust, MIT | completion, hover, signature, definition, references, rename, implementation, call/type hierarchy, code lens (framework lenses), diagnostics, inlay, WP hook-name completion, Eloquent inference (from its README; UNVERIFIED on the installed 0.11.1) | Currently OFF in the fork. The `Function 'x' not found` messages came from missing WordPress stubs |
| DEVSENSE `phptools` | proprietary freemium | free tier plus licence-locked premium | cannot extend; reject |
| Intelephense | proprietary freemium | free: references, hover, completion. Premium: rename, implementations, code lens (fork-findings:122) | owner will not pay |
| Phpactor | MIT | references, rename, implementations, no lens | crashes on PHP 8.5 (`Amp\Failure`), no WP stubs, noisy, slow |
| `zenith_php_tools` | own crate | not an LS: phpcs/phpstan installer and status item | n/a |
| `zenith_wordpress`, `zenith_laravel` | own crates | indexers and panels, no LSP | wiring in progress (`feat/wire-tools`) |

No `wp-hooks-ls` or `laravel-ls` exists. Fork default today: `["intelephense","!phpactor","!phptools","!phpantom","..."]` (`assets/settings/default.json:2638`, `:3073`, commit `29ab1ddb12`).

## Options
- **(a) Extend phpantom/phptools:** phptools is closed; phpantom is not ours, so (a) = (c) plus pull requests.
- **(b) Own Rust LS on tree-sitter-php:** a name-only index is about 3–4 weeks but wrong for `$x->foo()`. Method references and rename need type inference; parity is 4–6+ months. Rejected.
- **(c) PHPantom (chosen):** free, MIT, covers every target feature. Their benchmark: ready in 2 s, 578 MB on a 33k-file Laravel app (UNVERIFIED by us).
- **(d) Keep Phpactor:** broken on PHP 8.5, slow. Rejected.

## Plan
- **M0 verify (2 days, lead + owner):** run the latest PHPantom on a WordPress plugin and a Laravel fixture. Record from the LSP log: initialize capabilities, lens titles and commands, macOS `$XDG_CONFIG_HOME` resolution, init-option key `stubs.paths` (array; PHPantom config-schema has no `stubs.path`), whether `~` expands.
- **M1 defaults:** `default.json:2638` and `:3073` → `["phpantom","!intelephense","!phpactor","!phptools","..."]`. Run the touched crates' tests and `cargo check -p zenith`.
- **M2 WordPress stubs:** in `zenith_php_tools`, behind the existing consent banner, write `lsp.phpantom.initialization_options.stubs.paths = [<managed_root>/wordpress/vendor/php-stubs/wordpress-stubs]` via `update_settings_file` (built, fork `878e868254`, whether PHPantom reads it from init options is UNVERIFIED). Idempotent, WordPress projects only. Tests: path builder, idempotent write, consent never defaults to yes. Sabotage each.
- **M3 code lens:** turn `code_lens` on (per-language key UNVERIFIED; global default is `"off"` at `default.json:468`). A lens click needs a command `editor.action.showReferences|goToLocations|peekLocations` with args[2] = `Location[]` (`code_lens.rs:85-88`, `:190-195`). If PHPantom lacks "N usages / N implementations" lenses, send them a pull request in that shape. Zero fork code.
- **M4 usages popup:** the PhpStorm-style popup is covered by the PhpStorm-parity plan (M3 there, `zenith_search::ShowUsages`). Routing a lens click into it needs one hook in `code_lens.rs` (hot editor code).

Upstream touches: 3 of the 5-line budget, all in `default.json`. Reviewers: security (M1 unpinned download, M2 settings write), performance (M1 RAM).

## Risks
- PHPantom is pre-1.0 and fast-moving.
- Zed's PHP extension downloads the latest PHPantom release unpinned (supply chain). Fix: pin via `lsp.phpantom.binary.path` to a managed copy.
- PHPantom also runs phpstan/phpcs/mago, which duplicates `zenith_inspections` (plan 21). Turning it off needs `.phpantom.toml`; the editor option subset covers only indexing, stubs and inlay hints.
- Global `code_lens` also enables other servers' lenses. Blade files also go to PHPantom.

## Doc fixes to follow (docs-editor)
Plan 19 (shrink wp-hooks-ls: PHPantom has hook completion), plan 09:13 (rename), plan 16 A3 row 19, zed-kit README and `settings.global.jsonc`, fork-findings:95 (add the stubs root cause), fork-findings:122 ("default is Phpactor" is stale: it is Intelephense since `29ab1ddb12`).

## Open items
- UNKNOWN: does PHPantom emit usage and implementation lenses with a ShowLocations-compatible command? (M0)
- UNKNOWN: init-option key, `~` expansion, macOS config path. (M0)
- UNKNOWN: per-language `code_lens` setting (`settings_content/src/editor.rs:575-583`).
- NOT DONE: nobody ran the installed `phpantom_lsp`; capabilities come from upstream docs.
