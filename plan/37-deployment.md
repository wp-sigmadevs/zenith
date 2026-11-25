# 37 — Deployment (Remote Host tool window + Deployment dialog)

Status: 🟨 IN PROGRESS. Owner decisions made 2026-11-22 (see end). M1a and M1b are merged in fork `zenith` (2026-11-23, Opus-reviewed three rounds; tests/gate not run on the merged tree). Not done: M1 exit in a running app, Mappings/Excluded Paths and SFTP password auth (M2), edit remote file (M4a), auto-upload of mapped files (M4b). Today a Remote Host file opens as a read-only cached copy by design (`zenith_deploy/src/panel.rs:455`); the owner hit this as "can't edit", so M4a is built first. Open review items: `docs/guides/fork-findings.md` § "Review round (2026-11-23, work machine)". Facts verified against fork @ b4130a774e unless marked UNVERIFIED.

## Goal

JetBrains Deployment: upload a local project to a server (FTP/FTPS/SFTP) and browse it.

## Parity checklist

- [ ] Remote Host tool window: host dropdown (`<None>`), toolbar (upload, download, sync, disconnect), remote tree (must)
- [ ] Deployment dialog: connection config — type FTP/FTPS/SFTP, host, port, user, password (Keychain), root path, web URL, passive mode (must)
- [ ] Planned (plan 44, not built): Locate opened file (needs M2 mappings), "Use LIST command › Compatible with old version" (`list_compat`), root-path Autodetect and remote folder browse, Web path column in Mappings, errors as a child row in the tree. Security review mandatory (browse and Autodetect connect with stored credentials). Spec: [44](44-phpstorm-parity-round1.md) item 9.
- [ ] Mappings (local path to remote path) and excluded paths (must)
- [ ] Edit remote file (M4a): editable cached copy, upload on save through the session (must)
- [ ] Auto-upload of mapped project files (M4b; off by default; see Security)
- [ ] SSH hosts: use Zed remote projects (`remote/src/transport/ssh.rs:310-379`). Gap Zenith fills: FTP/FTPS, local-to-server mirror, upload on save.

## Architecture

- Crate `zenith_deploy` (feature `deploy`), M1a files: `zenith_deploy.rs`, `config.rs` (`paths::data_dir()/deployment/servers.json`, mode 0600), `secrets.rs`, `remote_path.rs`, `transport.rs`, `ftp.rs` (suppaftp, async smol; TLS from `http_client_tls::tls_config()`), `sftp.rs` (system `sftp -b -`, BatchMode, `StrictHostKeyChecking=yes`), `panel.rs`, `dialog.rs`. M2 adds `mapping.rs`, M3 `sync.rs`, M4a `remote_edit.rs`, M4b `on_save.rs` (names proposed).
- Secrets: `secrets.rs` in `zenith_deploy` until `zenith_core` exists (plan 15; it does not exist in the fork yet). It uses Keychain via `cx.write_credentials` / `read_credentials` / `delete_credentials` (`gpui/src/app.rs:2011/2039/2044`).
- Settings: `zenith.deploy.enabled` (default true), `zenith.deploy.dock` (default "right"). Upload on save is stored per server (default OFF), never in settings (a cloned project's local settings could switch it on).
- Panel activation priority 15.
- Upstream touches: root `Cargo.toml` member + dep + `suppaftp` (3 of 5); M3 project-panel "Deployment ▸" menu block next to "Local History…" (owner approved; budget reaches 5/5).
- NEVER use `zed_credentials_provider::global`: the Dev channel stores plaintext JSON (`zed_credentials_provider.rs:46-60,130-147`).

## Security (trust boundaries)

1. A cloned project's deployment file can name an attacker host with upload on save. Require per-server user confirmation; upload on save is off by default.
2. FTPS validates certificates. Plain FTP only behind an explicit insecure toggle. SFTP host keys come from OpenSSH `known_hosts`; no auto-accept.
3. Remote names reject `..`, absolute paths, NUL, and symlinks that escape the mapped root.
4. No secrets on argv; askpass or stdin only.
5. Excludes default to `.env`, `.git`, `node_modules`, `.zenith`.
6. Command injection: reject names containing CR/LF; the sftp batch builder never emits a line starting with `!`.
7. Reject a host beginning with `-`; put `--` before the host in the ssh/sftp argv.
8. Reject `..` and names containing `/` in remote listings and cache paths.
9. Never trust upload-on-save settings that arrive with a cloned repo's config (trust gate). Same for the M4a toggle.

## Milestones

| Milestone | Days | Owner | Scope |
|---|---|---|---|
| M1a | 3 | rust-core-engineer | scaffold, config, secrets, remote_path, transport, ftp, sftp (key or agent auth) |
| M1b | 3 | gpui-ui-engineer | Deployment dialog Connection tab (server list +/−/✓, Advanced, "Username is not specified" warning, plain-FTP insecure callout, Test Connection, OK/Cancel) as a `ModalView` overlay; Remote Host panel (host dropdown `<None>`, "…" opens the dialog, toolbar collapse/refresh/disconnect/settings, lazy tree, file opens as a read-only cached copy) |
| M2 | 4 | — | Mappings and Excluded Paths tabs; SFTP password auth via ssh ControlMaster + askpass (owner approved: M2, not M1), reusing upstream's `askpass` crate (`AskPassSession`) so the password travels over a local socket, not an env var or argv (*verify* API fit); download to project through a mapping. Mappings keyed per project (today a shared server has one mapping list for all projects, `config.rs:95`). Default excludes include `.env` |
| M3 | 4 | — | upload, download, sync (size + mtime); connection pool and keep-alive; project-panel menu |
| M4a | 2 | — | Edit remote file (no mappings needed, built first): editable cached copy; upload on every save through the existing session, written in place (no temp name, no rename: that would reset the remote file's mode and owner and leave a readable temp `.php`); remote-changed check with Overwrite / Compare / Cancel; setting upload-on-save default OFF per server with a one-time confirmation; Disconnect refuses to delete the cache while any cached buffer is unsaved or an upload is pending. Needs transport put/stat: built in C1, see "M4a decisions" below |
| M4b | 2 | — | auto-upload of mapped project files (needs M2); overwrite check by timestamp and size; needs explicit-save vs autosave distinction: UNVERIFIED whether Zed's `Saved` event / `SaveIntent` carries it |

M1 exit: in the running app, the owner saves a server as FTPS and as FTP, Test Connection reports OK or the error, the panel browses the root, and a file opens. security-engineer reviews after M1a and before merge.

Total ≈ 18 d plus reviews (M4 split; days per half are a guess).

## Tests

Not written yet. One or more per security rule: traversal, injection, symlinks never followed, new server defaults to ftps, no password on argv or disk and file mode 0600, no `dangerous()`, StrictHostKeyChecking=yes, default excludes + upload on save off.

## M4a decisions (planner + security review, 2026-11-25)

Status: C1 transport merged on fork branch `feat/plan37-m4a-edit-remote` @ `0cffe2ae20` (commits `fa9a6180a3`, `0cffe2ae20`; not yet on `zenith`). C2 index/uploader, C3 panel UI, C4 Compare via `FileDiffView`: not built (this doc, 2026-11-25).

- **Write in place.** No temp + rename: rename would reset remote mode/owner and leave a readable temp `.php`.
- **Deadline scales with size:** 30 s + 1 s per 64 KiB (a flat 30 s truncated uploads). Local upload file is created 0644 in a 0700 dir.
- **`stat` over SFTP:** lists the parent with `ls -lan`, refuses symlinks, treats ambiguous or duplicate lines as errors. FTP cannot detect server-side symlinks: the confirmation says so; plain FTP also says "clear text".
- **`stat` returned None = ask first, never go ahead.**
- **Upload gate:** target only from the download index, bytes from the buffer. Upload on save is OFF per server and confirmed once per server per session (session-only in M4a; persisted toggle with M4b). Never read from project settings. No uploads when the project is shared / non-local.
- **Cache lifetime:** Disconnect and server deletion keep the cache while a copy has a live/dirty buffer or a running upload. Orphan restored copies are read-only.
- **Security checklist** (from a comparison with Vega, MIT, iRemote-derived, GPL crates; we copy no code): host starting with `-` rejected and `--` used; names with `..` or `/` rejected; project config never trusted for uploads.
- **Known limits:** stamps have minute resolution; servers older than OpenSSH 9.1 unverified (longname without folder prefix handled by bare-name match); FTPS finish against a real TLS server untested; `put` mode retention verified only on local macOS sftp-server.

## Risks

- Keychain prompts on ad-hoc-signed Dev builds — UNVERIFIED.
- Transport `put`/`stat` for M4a: built (C1, below). No `rename` by design.
- Upstream `askpass` fit for the sftp child process — *verify*.

## Owner decisions (2026-11-22)

- Protocols: SFTP + FTP/FTPS together in the first version (owner deploys over FTP).
- New dependency `suppaftp` (rustls for FTPS): approved.
- Plain FTP: allowed per server, with a visible "insecure: password sent in clear text" warning; FTPS is the default type.
- Owner hit read-only remote files (2026-11-25): M4a (edit remote file) goes before M2/M3; M4b waits for mappings. Upload-on-save default OFF per server with a one-time confirmation. (Sequencing: pending owner confirmation.)
- Server definitions: Zenith user data dir, with a "Visible only for this project" flag (not a project file). Passwords in the Keychain.

## Effort

≈ 18 d plus reviews (see Milestones).
