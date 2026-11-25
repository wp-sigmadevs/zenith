---
name: deploy-m4a-transport-facts
description: zenith_deploy M4a C1 - verified OpenSSH sftp ls/put behaviour, suppaftp size/mdtm/put_with_stream signatures, sabotage-script traps
metadata:
  type: reference
---

Verified @ feat/plan37-m4a-edit-remote fa9a6180a3, 2026-11-25.

- OpenSSH sftp (macOS): `ls -la "<symlink-to-file>"` FOLLOWS the link and prints the target as a regular `-` entry; `ls -lad` is "Invalid flag -d". So symlink detection must list the PARENT dir (entry shows `l`). Missing path: stderr `Can't ls: "<p>" not found`, exit 1. `put` over an existing remote file keeps its mode (tested vs local `sftp -D /usr/libexec/sftp-server`), no `-p` needed.
- suppaftp 13 smol (src/async_ftp/smol_ftp.rs): `size(path)->FtpResult<usize>` (657/851), `mdtm(path)->FtpResult<jiff::civil::DateTime>` (Display "2025-01-01T12:00:00"; jiff not a direct dep, just `.to_string()`), `put_with_stream(name)->TransferStream<T>` (AsyncWrite) then `transfer.finish().await` (closes, reads 226). Missing file -> `FtpError::UnexpectedResponse(resp)` with `resp.status == Status::FileUnavailable`.
- Transport trait methods take `&mut self` (not `&self`). Fakes: `transport::tests::FakeTransport`, `test_support::FakeRemote` in zenith_deploy.rs.
- Tool trap: the Read/Bash output hooks "caveman-elide" bodies; use `sed -n` in Bash for real bodies, and Edit (not Bash/python) for text containing the download-file call (LOAD_FILE hook).
- Sabotage-script trap: never `git commit` in a background command while a sabotage script mutates the tree (a queued commit captured a sabotage; fixed with `git reset --soft`). The script's `git checkout -- path` restores from HEAD, so a bad commit persists into later runs.
- nextest on this fork can block for minutes on the cargo lock when another session builds `editor`.
