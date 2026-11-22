# 35 — PHP Toolchain, Zero Setup

## Goal

Open a WordPress, Laravel or plain PHP project and have PHPCS (with WPCS), PHPStan, Pint or PHP-CS-Fixer working without the user installing anything. PhpStorm ships its inspections; Zenith gets the same feel by detecting what a project already has and installing the rest into its own managed folder, once, after asking.

Why now: every PHP feature in the plan (19 WordPress, 21 inspections, 25 Laravel, the `zed-php-fmt` formatter) assumes these tools exist. Setting them up by hand on the home machine (2026-11-17) took two phpcs copies, a WPCS that refuses PHP_CodeSniffer 4, a Composer downgrade and a `~/.zshrc` edit. Users should never see that.

## Parity checklist

- [ ] Detect the project type: WordPress (plugin/theme headers, `wp-config.php`, `style.css` theme header), Laravel (`artisan`, `laravel/framework` in `composer.json`), plain PHP (must)
- [ ] Project tools first: use `vendor/bin/{phpcs,phpcbf,phpstan,pint,php-cs-fixer}` when present; never install over a project's own versions (must)
- [ ] Managed tools: install the missing ones into `~/.local/share/zenith/tools/php/<profile>/` with Zenith's own `composer.json` + `composer.lock` (must)
- [ ] Profiles with pinned, tested versions (must):
  - WordPress: PHP_CodeSniffer 3.13.x, WPCS 3.x, PHPCompatibilityWP, PHPStan + `szepeviktor/phpstan-wordpress`
  - Laravel: Pint, PHPStan + Larastan
  - Plain PHP: PHPStan, PHP-CS-Fixer
- [ ] Ask once per profile before downloading or running anything ("Install WordPress tools (≈ 15 MB)?"); remember the answer; never on a remote or untrusted project (must)
- [ ] Background install with status-bar progress and a log; failures show the Composer error and a retry (must)
- [ ] Never touch the user's global Composer, `PATH`, shell profile or Homebrew (must)
- [ ] PHP detection: Herd, Valet, Homebrew, system `php`, project `.php-version`/`composer.json` `require.php`; report the version in use (must)
- [ ] No PHP found: one-click guide (Herd / Homebrew links), no silent install (must)
- [ ] Composer: use the user's if present, else download `composer.phar` into the managed folder and verify its published SHA-256 (must)
- [ ] Hand the resolved tool paths to 21 inspections, the formatter (03 `zed-php-fmt`) and 19/25 (must)
- [ ] Commands: "Zenith: PHP tools: status", "…: reinstall", "…: update", "…: remove" (must)
- [ ] Updates only on request or a Zenith release that bumps the pinned set; never on its own (must)
- [ ] Docker/remote interpreters (11): run tools inside the container instead of installing locally (later)
- [ ] Xdebug ready without configuration; per-project PHP version switching (later, with 11/30)

## UX

- First PHP project: a non-modal banner — "Zenith can set up WordPress tools: PHPCS + WordPress standards, PHPStan. [Install] [Not now] [Never]".
- Status bar while installing: "Installing PHP tools… 3/5"; click opens the log.
- "PHP tools: status" lists each tool, version, source (project / Zenith / system) and path.

## Architecture

- Detection (project type, PHP binary, project `vendor/bin`) in `zenith_core::detect` (plan 15).
- New crate `zenith_php_tools`: profiles (pinned `composer.json` + `composer.lock` checked into the Zenith repo as assets), install/update/remove through `zenith_core::process`, state in `zenith_core::store`, paths under `zenith_core::paths` data dir (`~/.local/share/zenith/`).
- Resolution order per tool: project `vendor/bin` → Zenith managed → system `PATH` → missing.
- Consumers ask `zenith_php_tools::resolve(project, Tool::Phpcs)`; nothing else hard-codes paths.
- Composer runs with `COMPOSER_HOME` pointed into the managed folder so global config is untouched.
- Verified against fork `feat/look` @ `65c87e35ba` (2026-11-17):
  - **Trust**: `crates/project/src/trusted_worktrees.rs`. `TrustedWorktrees::try_get_global(cx)` → `TrustedWorktreesStore::can_trust(worktree_store, worktree_id, cx)` (`&mut`; true when `session.trust_all_worktrees` is set); `TrustedWorktrees::has_restricted_worktrees(worktree_store, cx)`; subscribe to `TrustedWorktreesEvent::Trusted` to offer the install once the user trusts the project. Offer nothing while restricted.
  - **Banner**: `Workspace::show_notification(NotificationId, cx, …)` with `workspace::notifications::simple_message_notification::MessageNotification` — `primary_message`/`primary_on_click` (Install), `secondary_message`/`secondary_on_click` (Not now), `more_info_message`/`more_info_url`. Only two action buttons: "Never" goes in settings (`profiles.<name>: "never"`) or as the secondary button.
  - **Status bar**: `workspace.status_bar().update(cx, |bar, cx| bar.add_right_item(entity, window, cx))` with an entity implementing `workspace::StatusItemView`. Upstream adds its items in `crates/zed/src/zed.rs` (~line 636); `go_to_line` tests add one from inside a workspace update, so a `zenith_*` crate can do it from `cx.observe_new::<Workspace>` with no upstream hook. Same pattern as upstream: `crates/zed/src/zed.rs:552` `cx.observe_new(|workspace: &mut Workspace, window, cx|` guards `let Some(window) = window else { return }`, then adds its items (~636). The window is `None` only for workspaces built without one; skip those the same way.

## Settings

```json
"zenith": {
  "php_tools": {
    "auto_offer": true,
    "profiles": { "wordpress": "ask", "laravel": "ask", "php": "ask" },
    "php_binary": null,
    "prefer_project_tools": true
  }
}
```

`php_binary` is the chosen CLI interpreter (set from the PHP modal, plan 39). User settings only: a project-chosen binary would run repo code. Project settings are ignored for this key.

## Progress (fork `feat/look`, crate `zenith_php_tools`)

| Step | State | Commit |
|---|---|---|
| M1a Detection | ✅ WordPress (plugin/theme header, `wp-config.php`, `wp-content`), Laravel (`artisan` + `laravel/framework`), plain PHP; `resolve()` project `vendor/bin` → system `PATH`; PHP candidates Herd → Homebrew → `PATH`; version from `php -v` | `b2422817f0` |
| M1b Status | ✅ `PHP 8.5` status bar item in PHP projects (hidden elsewhere); "zenith php tools: status" message lists project type, PHP path, each tool's source. Not seen in the app yet | `6841dc9d4d` `c63de8e982` |
| M2a Managed folder | ✅ `~/.local/share/zenith/tools/php/<profile>/vendor/bin`; profile `composer.json` for WordPress / Laravel / plain PHP (ranges); resolution project → managed → system, tested; status shows "Zenith" as a source | `be31d8abb1` |
| M2b Consent + install | ✅ banner in a trusted, local PHP project (PHP found, no tool in sight): **Install** / **Never** (closing = not now); answer remembered per profile in `consent.json`; Composer (the user's, else Zenith downloads `composer.phar` and keeps it only if the SHA-256 matches getcomposer.org's published one) runs with `COMPOSER_HOME` inside the managed folder; pinned `composer.lock` per profile checked in under `crates/zenith_php_tools/profiles/` (installed end to end on this Mac: WordPress standards, Pint, PHPStan, PHP-CS-Fixer present); status bar shows "Installing PHP tools…"; output in `install.log`; failure shows Composer's error with **Retry**. Banner and flow untested in the app. **Not done:** CI install job (touches CI — owner decision), log viewer command | `6639a8c85c` `324a7d63a3` + Composer download commit |
| M3–M5 | ⬜ | — |

Nothing here downloads or runs a tool yet.

## Milestones

1. Detection (project type, PHP, project `vendor/bin`) + "PHP tools: status".
2. WordPress profile: pinned set, consent, background install, resolve() used by the formatter.
3. Laravel and plain PHP profiles.
4. Wire into 21 inspections and 19/25; update/remove commands.
5. Docker interpreters (11).

## Tests

- Detection fixtures per project type (WordPress plugin, theme, Laravel app, plain library).
- Resolution order: project vendor beats managed beats system (temp dirs, fake binaries).
- Profile lock files install cleanly on the supported PHP versions (CI job, network).
- Consent: nothing downloads or runs before the user accepts (test with a fake process runner).

## Risks

- Pinned sets drift behind upstream (WPCS on PHP_CodeSniffer 3 today): bump in Zenith releases with the CI install job as the gate.
- Running Composer = running code from Packagist: consent first, lock files with hashes, never for untrusted projects.
- Disk: ~15–40 MB per profile; "remove" command and a size shown in status.

## Effort

2–3 weeks (after 15).
