# 37 — Deployment (Remote Host tool window + Deployment dialog)

Status: 🟨 IN PROGRESS. Owner decisions made 2026-11-22 (see end). M1a on fork branch `feat/deploy-m1a` (worktree `~/GithubProjects/zed-deploy`). Facts verified against fork @ b4130a774e unless marked UNVERIFIED.

## Goal

JetBrains Deployment: upload a local project to a server (FTP/FTPS/SFTP) and browse it.

## Parity checklist

- [ ] Remote Host tool window: host dropdown (`<None>`), toolbar (upload, download, sync, disconnect), remote tree (must)
- [ ] Deployment dialog: connection config — type FTP/FTPS/SFTP, host, port, user, password (Keychain), root path, web URL, passive mode (must)
- [ ] Mappings (local path to remote path) and excluded paths (must)
- [ ] Upload on save (must, off by default; see Security)
- [ ] SSH hosts: use Zed remote projects (`remote/src/transport/ssh.rs:310-379`). Gap Zenith fills: FTP/FTPS, local-to-server mirror, upload on save.

## Architecture

- Crate `zenith_deploy` (feature `deploy`), M1a files: `zenith_deploy.rs`, `config.rs` (`paths::data_dir()/deployment/servers.json`, mode 0600), `secrets.rs`, `remote_path.rs`, `transport.rs`, `ftp.rs` (suppaftp, async smol; TLS from `http_client_tls::tls_config()`), `sftp.rs` (system `sftp -b -`, BatchMode, `StrictHostKeyChecking=yes`), `panel.rs`, `dialog.rs`. M2 adds `mapping.rs`, M3 `sync.rs`, M4 `on_save.rs`.
- Secrets: `secrets.rs` in `zenith_deploy` until `zenith_core` exists (plan 15). It uses Keychain via `cx.write_credentials` / `read_credentials` / `delete_credentials` (`gpui/src/app.rs:2011/2039/2044`).
- Settings: `zenith.deploy.enabled` (default true), `zenith.deploy.dock` (default "right"). Upload on save is stored per server, never in settings (a cloned project's local settings could switch it on).
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

## Milestones

| Milestone | Days | Owner | Scope |
|---|---|---|---|
| M1a | 3 | rust-core-engineer | scaffold, config, secrets, remote_path, transport, ftp, sftp (key or agent auth) |
| M1b | 3 | gpui-ui-engineer | Deployment dialog Connection tab (server list +/−/✓, Advanced, "Username is not specified" warning, plain-FTP insecure callout, Test Connection, OK/Cancel) as a `ModalView` overlay; Remote Host panel (host dropdown `<None>`, "…" opens the dialog, toolbar collapse/refresh/disconnect/settings, lazy tree, file opens as a read-only cached copy) |
| M2 | 4 | — | Mappings and Excluded Paths tabs; SFTP password auth via ssh ControlMaster + askpass (owner approved: M2, not M1); download to project through a mapping |
| M3 | 4 | — | upload, download, sync (size + mtime); connection pool and keep-alive; project-panel menu |
| M4 | 2 | — | upload on save: per-server opt-in plus a one-time confirmation |

M1 exit: in the running app, the owner saves a server as FTPS and as FTP, Test Connection reports OK or the error, the panel browses the root, and a file opens. security-engineer reviews after M1a and before merge.

Total ≈ 16 d plus reviews.

## Tests

Not written yet. One or more per security rule: traversal, injection, symlinks never followed, new server defaults to ftps, no password on argv or disk and file mode 0600, no `dangerous()`, StrictHostKeyChecking=yes, default excludes + upload on save off.

## Risks

- Keychain prompts on ad-hoc-signed Dev builds — UNVERIFIED.

## Owner decisions (2026-11-22)

- Protocols: SFTP + FTP/FTPS together in the first version (owner deploys over FTP).
- New dependency `suppaftp` (rustls for FTPS): approved.
- Plain FTP: allowed per server, with a visible "insecure: password sent in clear text" warning; FTPS is the default type.
- Server definitions: Zenith user data dir, with a "Visible only for this project" flag (not a project file). Passwords in the Keychain.

## Effort

≈ 16 d plus reviews (see Milestones).
