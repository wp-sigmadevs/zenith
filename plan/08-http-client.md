# 08 — HTTP Client

> **Status (2026-11-22):** wired in fork `zenith` (2026-11-21, `crates/zenith_http`). On `integrate/batch-b` @ `205d3c3827` (tests + `cargo check -p zenith` + clippy pass; not built into an app): gutter ▶ per request line + session response history (`d0bf6e7cdd`), Basic auth shorthand / Bearer, `< file` and multipart bodies, import from cURL (`e8c1277ed5`). Disk-backed history in progress (`feat/http-disk-history`). Milestone ✅ below means code and tests.

## Goal

JetBrains HTTP Client parity: `.http`/`.rest` files with run gutter buttons, environments, variables, response viewer, history.

## Parity checklist

- [ ] `.http` syntax highlighting (tree-sitter grammar; check existing Zed extension first) (must)
- [~] Run request at cursor: action + `ctrl-enter` ✅; gutter ▶ not built — audit 2026-11-22 (must)
- [x] Multiple requests separated by `###` with request names (must)
- [x] Variables `{{var}}`, env files `http-client.env.json` + `http-client.private.env.json` (JetBrains format) with private overriding (must)
- [x] Environment switcher (`EnvironmentStore`) (must)
- [x] Response viewer: status badge, duration ms, size bytes, headers, pretty JSON, raw HTTP, and cURL export (must)
- [ ] Save response to history: `HttpHistoryStore` exists but nothing records responses — audit 2026-11-22 (must)
- [ ] Request chaining: `> {% client.global.set("token", response.body.token) %}` response handlers (later — needs JS engine)
- [x] Dynamic vars `{{$uuid}}`, `{{$timestamp}}`, `{{$randomInt}}` (must)
- [ ] Auth helpers: Basic, Bearer — not built (write the header by hand) — audit 2026-11-22 (must); OAuth2 flow (later)
- [ ] Multipart / file upload `< ./file.json` — not built — audit 2026-11-22 (must)
- [~] Copy as cURL ✅; import from cURL: `parse_curl` exists, no action calls it — audit 2026-11-22 (must)
- [ ] GraphQL, WebSocket, gRPC (later)

## Progress (crate `zenith_http`)

| Step | State | Commit |
|---|---|---|
| M1 Parser & Variable Resolution | ✅ Hand-written JetBrains `.http` / `.rest` streaming chunk parser (`parse_http_file`, `###` delimiter with names); variable substitution engine (`substitute_variables`) supporting `{{var}}` and dynamic variables (`{{$uuid}}`, `{{$timestamp}}`, `{{$randomInt}}`); bidirectional cURL generator (`to_curl`) and parser (`parse_curl`). | `1331d96968` |
| M2 Environment Store | ✅ `EnvironmentStore` reading public `http-client.env.json` and private `http-client.private.env.json` with secure private overrides; active environment switching. | `1331d96968` |
| M3 Response Engine & History | ✅ `HttpResponse` with formatted JSON bodies and raw HTTP output; `HttpHistoryStore` with configurable cap and FIFO eviction. | `1331d96968` |
| M4 Interactive Response Viewer | ✅ GPUI `HttpResponseView` with status color badge (green 2xx, amber 4xx, red 5xx), duration, payload size, one-click clipboard copying (cURL & response body), and tab switching (`Body`, `Headers`, `Raw`, `Request Info`); 100% tests passing; sabotage tested; clippy clean. | `1331d96968` |

## UX

- Gutter ▶ on each request line (via Zed runnables/tasks mechanism or custom gutter decoration — *verify which is extensible*).
- Response opens in a center `Item` (split right): tabs Body / Headers / Raw / Timeline; JSON rendered in a read-only editor buffer (gets highlighting + folding for free).
- Status bar: active environment selector.
- History panel: list of past responses per request, click to open, "Compare with current".

## Architecture

- Crate `zenith_http`.
- Parser: hand-written parser for the JetBrains `.http` format → `HttpRequest { method, url, headers, body, handlers, name }`. Unit-test heavily.
- Variable resolution: env files (project root or `.http` file dir), private env merged on top, `.env` optional.
- HTTP: Zed's `http_client` crate (reqwest-based? *verify*) — must support custom TLS (self-signed toggle), redirects toggle, timeouts, cookies jar per env.
- Response handlers (later): embed a JS engine (`boa` or `rquickjs`) — significant dep; decide in milestone 5.
- History: files under `.idea/httpRequests`-like `paths::data_dir()/http-history/<project-hash>/` (bodies on disk, index in SQLite).

## Settings

```json
"zenith": {
  "http": {
    "enabled": true,
    "default_env": "dev",
    "timeout_ms": 30000,
    "follow_redirects": true,
    "allow_insecure_tls": false,
    "history_limit": 200
  }
}
```

## Security

- Private env file auto-added to `.gitignore` suggestion; never written into history headers (mask `Authorization`, `Cookie` in history by default).
- `allow_insecure_tls` per env only, default false.

## Milestones

1. Parser + variable resolution + tests.
2. Run at cursor → response Item (body/headers/raw).
3. Environments + status bar switcher + dynamic vars.
4. History + compare; cURL import/export.
5. Response handlers (JS engine decision).
6. GraphQL/WebSocket (later).

## Tests

- Parser fixtures (JetBrains docs examples).
- Variable precedence tests.
- Local mock server (`httpmock`/`wiremock` crate if acceptable) for integration tests.

## Risks

- JS handler compatibility with JetBrains `client`/`response` API — scope a subset.
- Large responses — stream to disk, cap in-editor display (e.g. 5 MB).

## Effort

3–4 weeks (+1–2 for JS handlers).
