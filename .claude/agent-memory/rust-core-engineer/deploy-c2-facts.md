---
name: deploy-c2-facts
description: zenith_deploy C2 - sabotage script trap (relative path + cd), upload_target binding, fixture facts
metadata:
  type: reference
---

Verified @ feat/deploy-c2 1340bb4941, 2026-11-26.

- Bash sabotage script that does `cd` before its EXIT trap must resolve the file to an ABSOLUTE path first, or the trap cannot restore it (it left ftp.rs sabotaged once; caught via git status).
- `secrets::upload_target(server)` = `target_account|anonymous` (memory only); `current_target`, `RemoteCopy.target`, panel `Described.target`, upload_decisions retain use it; Keychain/session passwords keep `target_account`.
- A sabotage that swaps only the `target_problem` check in remote_edit to `target_account` still passes the test (the mismatch refuses anyway): isolate by making both registration and check use target_account.
- Dialog tests: `dialog.servers = dialog.base.clone()` resets the edit state between cases; FakeKeychain secret bytes via `entries.values().next()`.
- on_save::fingerprint now includes excluded_local (default has 4 entries, so `.clear()` differs).
