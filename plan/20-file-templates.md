# 20 — File & Project Templates (F2)

> **Status (2026-11-22):** 🟨 M1 merged in `zenith` (`297f274e5e`, `ee96cc2821`; not seen in an app): template format + renderer, PSR-4 resolver, New PHP Class dialog. Not built: right-click "New ▸", framework template sets, artisan generators, scaffolds, PhpStorm import. See Progress.

## Goal

PhpStorm "New → PHP Class" flow: correct namespace from PSR-4, proper file name, plus project scaffolds.

## Parity checklist

- [x] New PHP Class / Interface / Trait / Enum: dialog (name, kind, extends, implements, final/abstract, strict_types) (must)
- [x] Namespace computed from `composer.json` `autoload.psr-4` (+ `autoload-dev`) for the target directory (must)
- [ ] New from project panel context menu (target dir = selected dir) (must)
- [ ] Templates for: PHPUnit/Pest test, Laravel controller/model/migration (prefer `artisan make:*` when available), WP plugin main file (header), WP theme files, Gutenberg block (`block.json` + index), TS/React component (must)
- [x] User templates: `~/.config/zenith/templates/` + project `.zenith/templates/` (trusted worktrees only) (must)
- [ ] Variables: `${NAME}`, `${NAMESPACE}`, `${DATE}`, `${USER}`, `${PACKAGE}`, `${TEXT_DOMAIN}` (WP), custom prompts (must) — built: `${NAME}` `${CLASS_NAME}` `${NAMESPACE}` `${DATE}` `${YEAR}` `${USER}` `${CURSOR}` + custom prompts; not: `${PACKAGE}`, `${TEXT_DOMAIN}`
- [ ] Import PhpStorm file templates (`.idea/fileTemplates`, Velocity syntax subset) — see 31 (later)
- [ ] Project scaffolds: WP plugin, WP theme, Laravel package (later)

## UX

- Project panel right-click → "New ▸" submenu listing templates for this context (PHP dir → PHP templates first).
- Action `zenith_templates::NewFromTemplate` (`cmd-n` in project panel, like JetBrains `alt-insert`/`cmd-n`).
- Modal: template picker → fields form → preview path → Create → opens file with cursor at `${CURSOR}`.

## Architecture

- Crate `zenith_templates`.
- Template format (as built, `297f274e5e`): folder per template id:
  ```
  php-class/
    manifest.json   # template metadata, prompts
    template.php    # body with ${VARS}, ${CURSOR}  (template.<ext>)
  ```
  A template in `~/.config/zenith/templates/<id>/` replaces the built-in one with the same id; so does `<worktree>/.zenith/templates/<id>/` in a trusted local worktree. (Planned `template.toml` + `content.<ext>` and `.zed/templates/` were not used.)
- PSR-4 resolver from `zenith_core::detect::composer`: longest-prefix match dir → namespace; warn if dir isn't PSR-4-mapped.
- Built-in templates shipped in `assets/zenith/templates/`.
- Framework generators: if Laravel detected and template has `generator = "php artisan make:controller ${NAME}"`, run via `zenith_core::process` (with interpreter prefix from 11), then open created file.

## Milestones

1. Template engine + PSR-4 resolver + New PHP Class/Interface/Trait/Enum.
2. Project panel menu + user templates.
3. Test/WP/Laravel/TS templates; artisan generators.
4. Project scaffolds.

## Progress

| Step | State | Commit |
|---|---|---|
| M1 engine + PSR-4 + New PHP Class | 🟨 merged in `zenith`: renderer, PSR-4 from the nearest `composer.json` `autoload`/`autoload-dev`, dialog (class/interface/trait/enum, extends/implements, final/abstract, strict_types), built-ins in `assets/zenith/templates/` | `297f274e5e`, `ee96cc2821` |
| M2 project panel menu + user templates | 🟨 user + project template dirs built; right-click "New ▸" not built | `297f274e5e` |
| M3 framework templates, artisan generators | ⬜ | |
| M4 scaffolds; PhpStorm import (31) | ⬜ | |

## Tests

PSR-4 resolution fixtures (multiple prefixes, autoload-dev, nested); template rendering golden tests.

## Effort

1 week (+3 days scaffolds).
