---
name: phpantom-config-facts
description: PHPantom 0.11.1 config facts: global file path, no stubs key exists (checked 2026-11-22)
metadata:
  type: reference
---

- Global config: `<etcetera choose_base_strategy config_dir>/phpantom_lsp/.phpantom.toml`; macOS = XDG (`$XDG_CONFIG_HOME` else `~/.config`), not Library/Application Support (docs.rs src/config.rs doc comment + binary strings).
- 0.11.1 config-schema.json and the binary's serde field list have NO `stubs` key (top-level: php, diagnostics, indexing, semantic_tokens, laravel, formatting, phpstan, phpcs, phpmd, mago). `stubs.paths` in init options or toml is ignored.
- Binary: `~/Library/Application Support/Zenith/extensions/work/php/phpantom_lsp-0.11.1/phpantom_lsp`; `strings -a` on it is a fast way to check config keys.
- Without composer.json it scans the workspace only ("Scanning workspace for PHP classes"); with one it scans vendor packages.
