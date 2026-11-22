#!/usr/bin/env bash
# shellcheck disable=SC2016 # sh -c bodies below expand in the child shell, on purpose
# Zenith zed-kit installer. Idempotent: installs only what is missing, never overwrites config.
# Usage: zed-kit/install.sh [--dry-run] [--yes] [--with-xdebug]
#   --dry-run      print what would run; change nothing
#   --yes          don't ask before each install step
#   --with-xdebug  also pecl install xdebug
# No `curl | sh`: a missing Homebrew is reported, not installed.
# Versions are not pinned (plan/03 pins none); Zed's PHP extension also picks
# up the global intelephense via PATH.
set -euo pipefail

kit="$(cd "$(dirname "$0")" && pwd)"
dry=0; yes=0; xdebug=0
for a in "$@"; do
  case "$a" in
    --dry-run) dry=1 ;;
    --yes) yes=1 ;;
    --with-xdebug) xdebug=1 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

ok() { echo "ok   $*"; }
todo() { echo "TODO $*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# step <description> <command...>: dry-run prints, otherwise asks (unless --yes) and runs.
step() {
  local desc="$1"; shift
  if [ "$dry" = 1 ]; then echo "  would run: $*"; return 0; fi
  if [ "$yes" != 1 ]; then
    local r=""
    read -r -p "$desc? [y/N] " r </dev/tty || r=""
    case "$r" in [yY]*) ;; *) echo "skip $desc"; return 0 ;; esac
  fi
  "$@" && ok "$desc"
}

echo "== Homebrew packages"
brew_pkgs=(php composer node php-cs-fixer)
if have brew; then
  for p in "${brew_pkgs[@]}"; do
    if brew list --formula "$p" >/dev/null 2>&1; then ok "brew $p"
    elif have "$p"; then ok "$p (not from brew: $(command -v "$p"))"
    else step "brew install $p" brew install "$p"; fi
  done
else
  todo "Homebrew missing: install it from https://brew.sh (read the script first), then rerun"
  for p in "${brew_pkgs[@]}"; do if have "$p"; then ok "$p"; else todo "$p missing"; fi; done
fi

echo "== npm global tools"
if have intelephense; then ok "intelephense"
elif have npm || [ "$dry" = 1 ]; then step "npm install -g intelephense" npm install -g intelephense
else todo "npm missing; skipped intelephense (Zed's PHP extension downloads its own copy)"; fi

echo "== Composer global tools"
# WordPress coding standard for phpcs/phpcbf, and WP/WooCommerce stubs for Intelephense
# (the wordpress template points intelephense.environment.includePaths at them).
composer_pkgs=(
  dealerdirect/phpcodesniffer-composer-installer
  wp-coding-standards/wpcs
  php-stubs/wordpress-globals
  php-stubs/woocommerce-stubs
)
if have composer || [ "$dry" = 1 ]; then
  missing=()
  for p in "${composer_pkgs[@]}"; do
    if have composer && composer global show "$p" >/dev/null 2>&1; then ok "composer global $p"
    else missing+=("$p"); fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    # Composer 2.2+ refuses unlisted plugins in non-interactive runs.
    step "allow the phpcs installer plugin" \
      composer global config --no-interaction allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
    step "composer global require ${missing[*]}" composer global require --no-interaction "${missing[@]}"
  fi
else
  todo "composer missing; skipped ${composer_pkgs[*]}"
fi

echo "== Formatter wrapper"
target="$HOME/.local/bin/zed-php-fmt"
if [ "$(readlink "$target" 2>/dev/null)" = "$kit/bin/zed-php-fmt" ]; then ok "zed-php-fmt linked"
elif [ -e "$target" ] || [ -L "$target" ]; then todo "$target exists and is not ours; left untouched"
else step "link $target" sh -c 'mkdir -p "$(dirname "$2")" && ln -s "$1" "$2"' _ "$kit/bin/zed-php-fmt" "$target"; fi

echo "== Phpactor global config"
pa="$HOME/.config/phpactor/phpactor.json"
if [ -e "$pa" ]; then todo "$pa exists; merge $kit/phpactor/phpactor.json by hand"
else step "install $pa" sh -c 'mkdir -p "$(dirname "$2")" && cp "$1" "$2"' _ "$kit/phpactor/phpactor.json" "$pa"; fi

echo "== PHPCS / WordPress standard"
if have phpcs && phpcs -i 2>/dev/null | grep -q WordPress; then ok "phpcs + WordPress"
else todo "phpcs does not list WordPress yet (after the composer step, check: phpcs -i)"; fi

echo "== PATH"
# Shell profile edits are left to you.
for d in "$HOME/.local/bin" "$HOME/.composer/vendor/bin"; do
  case ":$PATH:" in *":$d:"*) ok "$d on PATH" ;; *) todo "add to ~/.zshrc: export PATH=\"$d:\$PATH\"" ;; esac
done

echo "== Xdebug"
if php -m 2>/dev/null | grep -qi xdebug; then ok "xdebug loaded"
elif [ "$xdebug" = 1 ]; then step "pecl install xdebug" pecl install xdebug
else todo "Xdebug not loaded (rerun with --with-xdebug, or use Herd/Valet's PHP)"; fi

echo "== Intelephense premium"
# Only checks the file exists; never reads or prints the key.
if [ -f "$HOME/intelephense/licence.txt" ]; then ok "licence file found"; else todo "optional: put the licence key in ~/intelephense/licence.txt (see README)"; fi

echo
echo "Next: merge $kit/settings.global.jsonc into ~/.config/zed/settings.json"
echo "      apply a project template: $kit/apply-template.sh <wordpress|laravel|node> <project-dir>"
