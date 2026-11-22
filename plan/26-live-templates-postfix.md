# 26 — Live Templates & Postfix Completion (F8)

> **Status (2026-11-21):** code in `crates/zenith_postfix`, merged into fork `zenith` @ `7ef1dc7da2` (from `feat/external-libraries` @ `3ec7baecab`); built + reviewed (code + security, 2 rounds, fixes landed), UNWIRED: workspace member only, no init/umbrella feature, so its actions/panels are unreachable in the app. Wiring = its own reviewed task. Milestone ✅ below means code and tests only.

## Goal

PhpStorm live templates (abbreviation → expandable snippet with tab stops & expressions) and postfix completion (`$x.if` → `if ($x) {}`).

## Parity checklist

- [~] Live templates per language: `$END$` cursor only; no tab stops or defaults — audit 2026-11-22 (must)
- [~] Template expressions (`expand_live_template` handles all; the wired call fills only `$CLASS_NAME$` — audit 2026-11-22): `$CLASS_NAME$`, `$METHOD_NAME$`, `$FILE_NAME$`, `$DATE$`, `$YEAR$`, `$NAMESPACE$` (must)
- [x] Surround-with templates (select → wrap in `try/catch`, `if`, `foreach`, `while`, `function`) (must)
- [x] Postfix PHP: `.if .notnull .null .foreach .return .var .isset .empty .throw .par .not .echo .dd .dump` with intelligent singular deduction (e.g. `$users` -> `$user`) (must)
- [x] Postfix JS/TS: `.if .const .let .return .log .await .forof .not .par` (must)
- [ ] Custom postfix templates (later)
- [ ] Import PhpStorm live templates XML (31) (later)

## Progress (crate `zenith_postfix`)

| Step | State | Commit |
|---|---|---|
| M1 PHP & JS/TS Postfix Engine | ✅ Preceding expression backtracking parser with parentheses, quotes, and operator depth tracking; full PHP suite (`.if`, `.not`, `.notnull`, `.null`, `.foreach` with singular deduction, `.return`, `.var`, `.isset`, `.empty`, `.throw`, `.par`, `.echo`, `.dd`, `.dump`); full JS/TS suite (`.if`, `.not`, `.const`, `.let`, `.return`, `.log`, `.await`, `.forof`, `.par`). | `92f12b1d56` |
| M2 Surround-With & Live Templates | ✅ `surround_with` for `TryCatch`, `If`, `Foreach`, `While`, `Function` with language-specific exception types (`\Throwable $e` vs `error`); `expand_live_template` with dynamic variable substitution (`$CLASS_NAME$`, `$METHOD_NAME$`, `$NAMESPACE$`, `$DATE$`, `$YEAR$`); 100% test pass; sabotage tested; clippy clean. | `92f12b1d56` |

## Architecture (extension-first, 16)

- **Expressions in snippets**: Zed snippet variables are limited (*verify* supported variables). Options:
  - A. `zenith-snippets-ls`: LS that provides completions with `insertTextFormat: Snippet`, computing expression values server-side (class name via tree-sitter, file name, etc.). Works in stock Zed.
  - B. Fork-side snippet variable resolver.
  - Pick **A**.
- **Postfix**: same LS: when completion triggered after `.` on an expression, return postfix items whose `textEdit` replaces the expression range (expression found via tree-sitter: nearest complete expression ending at cursor).
- **Surround-with**: code action from LS on non-empty selection → templates list → `WorkspaceEdit`.
- Template storage: JSON per language in `~/.config/zenith/live-templates/` + built-ins.

## Milestones

1. LS skeleton + PHP postfix (`.if .foreach .var .return .dd`).
2. JS/TS postfix.
3. Live templates with expressions.
4. Surround-with.
5. Custom templates + import.

## Risks

Completion noise: postfix items must only appear after `.` on a valid expression and rank below real member completions; in PHP `.` is concatenation — trigger only when followed by a known postfix key prefix.

## Effort

1–2 weeks.
