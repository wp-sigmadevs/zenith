---
name: deploy-m1a-facts
description: zenith_deploy (plan 37 M1a) verified facts - suppaftp 13 smol/rustls API, sftp -D testing trick, sftp quoting/glob quirks, hook trap on "download_file("
metadata:
  type: reference
---

Verified @ zed-deploy feat/deploy-m1a (base 66bdccbd97), 2026-11-22.

- suppaftp 13.0.0 (MIT/Apache, edition 2024, rust 1.88): feature `smol-rustls-aws-lc-rs` (default-features=false). It does NOT re-export futures_rustls, so `futures-rustls = 0.26 (default-features=false, features=["tls12"])` is a direct dep. API: `suppaftp::smol::{AsyncFtpStream, AsyncRustlsFtpStream, AsyncRustlsConnector, ImplAsyncFtpStream, SmolTlsStream}`; FTPS = `AsyncRustlsFtpStream::connect((host,port)).await?.into_secure(AsyncRustlsConnector::from(futures_rustls::TlsConnector::from(Arc<ClientConfig>)), host)`. Domain must be a DNS name (IP host fails TLS). `retr_as_stream` -> `TransferStream` (AsyncRead; call `.finish()`), `mlsd(Some(path))`, `list(Some(arg))`, `transfer_type(FileType::Binary)` (default is ASCII!), `active_mode(Duration)` consuming builder, `quit()`.
- suppaftp MLSD parser only knows `type=file|dir|cdir|pdir|link`; `type=OS.unix=slink:/x` => parse error (dropped); `type=file;unix.slink=..` parses as FILE. Zenith adds `mlsd_symlink` pre-check in ftp.rs. suppaftp rejects CR/LF in commands itself and logs `PASS <pw>` at TRACE level (command.rs `trace!("CC OUT")`).
- `ListParser::parse_mlsd/parse_posix/parse_dos(&str) -> ParseResult<File>`; File has name()/is_symlink()/is_directory()/size()/modified().
- OpenSSH sftp on macOS: `sftp -b - -D /usr/libexec/sftp-server` talks to a local sftp-server with no ssh/network - use via a wrapper `sh` script as the `program` in tests. `ls -la <dir>` prints the FULL PATH in the name column and `?` for nlink; `get` of a symlink downloads the link target; backslash-escaping glob chars (`\*`) does NOT work (double-escaped, "not found") so Zenith rejects `* ? [ \` in remote sftp paths; `\"` inside double quotes works; batch echo lines start `sftp> `; `pwd` prints `Remote working directory: <p>`.
- `util::command::new_command` (macOS = custom posix_spawn `Command`): `.kill_on_drop(true)`, `.stdin(Stdio::piped())`, `child.stdin.take()` is `Option<Async<File>>` (futures AsyncWrite), `child.output().await`; `Stdio` re-exported from `util::command`.
- gpui: `cx.write_credentials(url,user,&[u8]) -> Task<Result<()>>`, `read_credentials(url) -> Task<Result<Option<(String, Vec<u8>)>>>`, `delete_credentials`; need `use gpui::AppContext as _` for `cx.background_spawn` on `&App`, `BorrowAppContext` for `update_global`. `FutureExt::with_timeout(dur, &BackgroundExecutor) -> Result<T, Timeout>` (gpui/src/util.rs:67); test with `cx.executor().advance_clock(..)`.
- Settings test recipe: `SettingsStore::test(cx)` + `cx.set_global`, `Setting::register(cx)`, then `cx.update_global::<SettingsStore,_>(|s, cx| s.update_user_settings(cx, |c| ..))`.
- Hook trap: the Supercharger Bash hook blocks any command text containing `download_file(` (case-insensitive match for MySQL LOAD_FILE( ). Write such code via Edit/Write tools, not heredocs/python in Bash.
- Post-edit formatter hook rewrites crate files after Edit/Write (rustfmt); re-Read before the next Edit of the same region.
- `tempfile::NamedTempFile` is 0600 by default on unix, so set_permissions(0o600) is belt-and-braces; sabotage chmod 0o644 to prove the mode test.
- No `zenith_core` crate exists in the fork yet (plan says zenith_core::trace/secrets); M1a has its own secrets.rs.
