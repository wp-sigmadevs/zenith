---
name: deploy-c6-facts
description: zenith_deploy C6 stage 1 - fingerprint persistence design, test helper split, sabotage runner traps
metadata:
  type: reference
---

Verified @ feat/deploy-c6 31e6107736, 2026-11-27.

- `on_save::confirmation_matches(server)` = flag && stored `upload_on_save_fingerprint == fingerprint(server)`; used by `confirmation_holds` (old branch) and `auto_upload_problem` (-> `RECONFIRM`, `upload_mapped` returns Refused for it). Store `save` restamps/clears the fingerprint.
- remote_edit tests: `Mapped::edit_servers` restamps the fingerprint of confirmed servers (a confirmed edit); `edit_servers_by_hand` does not (hand edit). Tests that edit mapping/root via edit_servers would otherwise hit RECONFIRM first.
- `FakeRemote.connect_gate` (once, like pwd_gate) awaits inside `connect_fn`; `FakeRemote::log()` has "connect <host> ..." and "disconnect" lines.
- nextest filters: pass space-separated substrings, NOT `test(/re/)` regexes in a single arg via subprocess (ran 0 tests, exit 4 silently). Python `re.sub` repl `\&` stays literal.
- Supercharger git-safety hook can time out under load ("blocking because onFailure is block"): retry the git command alone.
