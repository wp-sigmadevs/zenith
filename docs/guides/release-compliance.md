# Release compliance (fork of Zed)

Checked 2026-11-20. Not legal advice; Zed's own trademark policy text was not found (only zed.dev/brand), re-check before a public release.

## Licences
- Fork source: GPL-3.0-or-later (225 crates) + Apache-2.0 (37 crates, incl. GPUI). No AGPL in the tree. Keep `LICENSE-GPL`, `LICENSE-APACHE`, per-crate licence files and upstream copyright headers.
- New `zenith_*` crates: GPL-3.0-or-later. This docs repo: MIT.
- Keep the "View Dependency Licenses" menu item (third-party notice).

## Before giving anyone a build
1. Commit everything in `wp-sigmadevs/zed`; build from a clean tree only. Tag the commit.
2. Release notes link the tag (this is the GPL source offer): `https://github.com/wp-sigmadevs/zed/tree/<tag>`.
3. Fork README keeps the Zenith / not-affiliated paragraph (added 2026-11-20); About window keeps the credit line.
4. Name/logo: no Zed name or logo as Zenith's own. "Zed Agent" stays as Zed's feature name (owner 2026-11-20).
5. Copy every line of "Pending release notes" below into the notes, then empty that list.

## Pending release notes

Lines for the next release that users must read. Remove each one once it has shipped.

- Deployment: FTP/FTPS/SFTP passwords saved by builds from before 2026-11-23 are not found any more, because Keychain entries are now tied to user, host, port and protocol. Enter each saved password once more in Deployment Settings (Remote Host panel).
- HTTP client history: URLs are now stored without `user:password@`, and without default ports or uppercase schemes; more field names are masked (`pin`, `otp`, `cvv`, `ssn`, card numbers, `tokens`, `refresh` and others).

## Zed's hosted services
- Sign-in, Zed Agent hosted models, collab, extensions registry: Zed Industries' Terms (`legal/terms.md` in the fork). Do not imply Zed supports Zenith.
- Defaults checked 2026-11-20: telemetry diagnostics/metrics `false`; `auto_update` set to `false` (was `true`: it would replace Zenith with stock Zed).
- Still open: where sign-in, hosted models and the extension registry point at Zed's servers; decide off / own endpoint / keep with Zed's terms visible.
