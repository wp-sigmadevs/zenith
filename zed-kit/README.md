# zed-kit

Zenith plan 03 — the config layer. It works on **stock Zed** today; no fork needed.

## Language server roles (PHP)

| Server | Does |
|---|---|
| Intelephense | completion, navigation, hover, rename (premium licence), diagnostics |
| Phpactor | code actions (import, extract, generate, implement), PHPStan/PHPCS diagnostics. Its completion is **disabled** to avoid duplicates. |

## Install

```sh
zed-kit/install.sh --dry-run      # see what it would do
zed-kit/install.sh                # asks before each step
zed-kit/install.sh --yes          # no questions
zed-kit/install.sh --with-xdebug  # also pecl install xdebug
```

It installs only what is missing: brew `php composer node php-cs-fixer`, npm `intelephense`, composer global `wpcs` (+ phpcs installer plugin), `php-stubs/wordpress-globals`, `php-stubs/woocommerce-stubs`; then links `zed-php-fmt` and copies the Phpactor config if absent. It never installs Homebrew, edits your shell profile or overwrites config; those show as `TODO`. Versions are not pinned.

Then merge `settings.global.jsonc` into `~/.config/zed/settings.json`. Merge by hand; don't replace the file.

## Project templates

```sh
zed-kit/apply-template.sh wordpress ~/path/to/plugin
zed-kit/apply-template.sh laravel   ~/path/to/app
zed-kit/apply-template.sh node      ~/path/to/app
```
Existing files are never overwritten.

| Template | Gives |
|---|---|
| wordpress | tabs, WordPress stubs + WordPress globals/WooCommerce stubs (from the global Composer home), phpcbf formatter (on demand), PHPCS diagnostics via Phpactor, `phpcs.xml.dist` (set text domain and prefixes), tasks, Xdebug |
| laravel | Pint on save, PHPStan diagnostics via Phpactor, `laravel-official` extension, artisan/test tasks, Xdebug |
| node | ESLint fix + Prettier on save (JS/TS/TSX, Prettier for JSON/CSS), npm and tsc tasks, Node debug |

## Intelephense premium licence

Put the key in `~/intelephense/licence.txt`; Intelephense reads that file itself, so no setting is needed. To keep it elsewhere, set `lsp.intelephense.initialization_options.licenceKey` to the file's absolute path (a value containing `/` is read as a path; `~` is not expanded). Never paste the key itself into settings: settings files get shared and committed.

## `zed-php-fmt`

Zed sends the buffer to formatters on stdin. Pint, phpcbf and php-cs-fixer only rewrite files in place, so this wrapper bridges them. It prefers `vendor/bin/<tool>` and uses the project's `phpcs.xml(.dist)` for phpcbf.

Self-check: `zed-kit/bin/test-zed-php-fmt.sh`

## Verify after install (plan/03 checklist)

- [ ] Go to definition, find references, rename in a PHP file
- [ ] A Phpactor code action appears (e.g. "Import class")
- [ ] WP project: PHPCS warning shows inline after save
- [ ] Laravel project: PHPStan error shows inline after save; Pint formats on save
- [ ] An Xdebug breakpoint hits ("PHP: Listen to Xdebug")
- [ ] No duplicate completion items
