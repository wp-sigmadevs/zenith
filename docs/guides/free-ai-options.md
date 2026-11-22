# Free AI options for Zenith users

Research of 2026-11-23 (home session). Not a plan yet: the owner decides whether a "Free AI" first-run step gets a plan doc.

**Caveat:** most numbers come from third-party guides, and the sources disagree. Free tiers change often. Re-check every limit on the provider's own page before it appears in Zenith's UI.

## What Zenith already has

The fork inherits Zed's model providers (`crates/language_models/src/provider/`):

- Built-in: `anthropic`, `bedrock`, `copilot_chat`, `deepseek`, `google`, `llama_cpp`, `lmstudio`, `mistral`, `ollama`, `open_ai`, `open_router`, `opencode`, `vercel_ai_gateway`, `x_ai`.
- `open_ai_compatible` / `api_compatible` cover the others (Groq, Cerebras, NVIDIA NIM) as a settings entry, with no code.
- External agents run over ACP (Agent Client Protocol) through `agent_servers`, e.g. Pi and OpenCode.

## Ranked free options

| # | Option | Free limit (reported) | Trains on prompts? | In Zenith |
|---|---|---|---|---|
| 1 | Local: Ollama / LM Studio / llama.cpp | unlimited (your hardware) | no, nothing leaves the Mac | built-in |
| 2 | Groq | ≈ 30 req/min, 1,000 req/day; ≈ 200K tokens/day is the likely binding limit (a few agent turns) | not reported | OpenAI-compatible |
| 3 | Google Gemini (AI Studio key) | Flash models free; daily caps reported from 20 to 1,500 depending on model and date | **yes**, outside EU/EEA/UK/CH (paid tier: no) | built-in `google` |
| 4 | Mistral Codestral (Experiment tier) | ≈ 1B tokens/month | **yes**, opt-in required | built-in `mistral` |
| 5 | OpenRouter `:free` models | 50 req/day (1,000/day after a one-time $10 top-up); often throttled upstream | depends on the model's host | built-in `open_router` |
| 6 | GitHub Copilot Free | 2,000 completions/month; chat moved to "AI credits" in June 2026 (size unconfirmed; older docs said 50 chat requests) | GitHub's terms | built-in `copilot_chat` |
| 7 | NVIDIA NIM | ≈ 40 req/min | — | OpenAI-compatible; **dev/test use only**, don't ship it to users |
| — | Cerebras | reported $5 credit, 1M tokens/day (unconfirmed) | — | OpenAI-compatible |
| — | OpenCode Zen free models | anonymous free access reported broken since 2026-09-23; no verified free model callable without a key | — | built-in `opencode` (Zen/Go need an `OPENCODE_API_KEY`) |

## Local models by Mac memory

- **32 GB:**
  - a Qwen coder around 27–30B (e.g. `qwen3-coder:30b`, a MoE with 3.3B active parameters, ≈ 19 GB at Q4_K_M)
  - Devstral Small 2 for agent work across many files

  Model tags differ between sources: check ollama.com before pulling.
- **16 GB:** 9–12B models. Gemma 4 12B supports tool calling natively. These are better for chat and autocomplete than for agents. macOS shares the memory, so 32 GB behaves like about 24 GB of VRAM.
- **Trap:** Ollama's default context is about 4K tokens, and agents silently drop old messages at that size. Set `num_ctx` (≥ 32K) when Zenith configures a model. Check tool-call support in the agent itself; the library page doesn't always show it.

## Pi and OpenCode

- **Pi in Zenith:**
  - Pi runs as an ACP agent from the ACP registry ("Pi" entry, Zed-managed Authenticate banner).
  - It needs Node plus the Pi CLI (`@mariozechner/pi-coding-agent`; newer releases are under `@earendil-works`) and its own provider keys.
  - There are several community adapters (`pi-acp` by svkozak and by victor-software-house, `pi-acpinator`, `@geohar/pi-acp`); Pi itself has no native ACP yet (discussion #4444).
- **OpenCode in Zenith:**
  - Built-in model provider `opencode` (Zen/Go).
  - Or an ACP agent: `"agent_servers": { "OpenCode": { "command": "opencode", "args": ["acp"] } }`. Use an absolute path if the binary isn't found; `--print-logs` before `acp` helps debug.
- **Pi with OpenCode models:**
  - Pi has built-in `opencode` and `opencode-go` providers (`OPENCODE_API_KEY`).
  - Some models are routed to the wrong wire protocol (400 errors); community fixes are `pi-opencode-provider` and `pi-opencode-zen`.
  - Zen is pay-as-you-go and Go is a subscription; neither is free (see table).
- **Removing Zed Agent from the fork:** not recommended. It means upstream merge churn and blows the plan 02 hook budget, and the Agent panel also hosts the ACP agents. A setting that hides only the built-in agent is unverified.
- **Zenith agent review (plan 23) with external ACP agents:** likely works through the shared ACP thread code. Unverified.

## Recommendation (owner to approve)

A "Free AI" step on the Welcome page:

1. **Ollama first** on Macs with ≥ 16 GB. Detect it, offer a one-click model pull and set `num_ctx`. It is the only option that is free, private and unlimited, which matters for client code.
2. **Groq** as the cloud fallback: a preset OpenAI-compatible entry; free, no card, no reported training.
3. **Gemini, Copilot Free and OpenRouter** as opt-ins, clearly labelled where the free tier trains on prompts.
4. **No** Zenith-hosted model: it needs accounts (plan 33), billing and abuse controls.
5. **No** reuse of Zed's hosted free tier: it is Zed Industries' service, and the trademark/terms risk is covered in `release-compliance.md`.

Track limits with [awesome-free-ai-coding](https://github.com/mvalentsev/awesome-free-ai-coding), which re-tests free tiers twice a week.

## Sources

- Free API comparisons:
  - [OpenRouter: free LLM APIs compared](https://openrouter.ai/blog/tutorials/free-llm-apis-compared/)
  - [StationX](https://app.stationx.net/articles/free-llm-api)
  - [Continuum](https://continuumcode.ai/guides/free-llm-api/)
  - [freellm.net](https://freellm.net/use-cases/coding)
  - [freellmapi.co](https://freellmapi.co/free-coding-llm-api)
  - [DEV](https://dev.to/shiva_prasad_cc614c6ee026/free-llm-apis-for-coding-assistants-11me)
  - [llmperks](https://llmperks.com/)
  - [free-llm.com](https://free-llm.com/guides/best-free-llm-apis-2026)
  - [awesome-free-ai-coding](https://github.com/mvalentsev/awesome-free-ai-coding)
- Gemini:
  - [rate limits](https://ai.google.dev/gemini-api/docs/rate-limits)
  - [pricing](https://ai.google.dev/gemini-api/docs/pricing)
  - [quota-cut forum thread](https://discuss.ai.google.dev/t/do-they-really-think-we-wouldnt-notice-a-92-free-tier-quota/111262)
  - [free-tier guide](https://neuraplus-ai.github.io/blog/gemini-api-free-tier.html)
- Copilot:
  - [plans](https://docs.github.com/en/enterprise-cloud%40latest/copilot/get-started/plans)
  - [usage-based billing](https://docs.github.com/en/copilot/concepts/billing/usage-based-billing-for-individuals)
  - [2026 W23 change](https://pricingsaas.com/companies/github/diffs/2026W23)
  - [usecarly](https://www.usecarly.com/blog/github-copilot-limits)
- Local models:
  - [Morph](https://www.morphllm.com/best-ollama-models)
  - [Hashnode](https://hashnode.com/blog/best-local-llm-for-coding)
  - [DEV: local agents](https://dev.to/dublecc/running-ai-coding-agents-locally-in-2026-what-actually-works-4ogl)
  - [16 GB MacBook](https://ammarnajjar.github.io/blog/local-ai-setup)
  - [modelfit](https://modelfit.io/guides/best-local-llm-for-coding/)
  - [Kilo](https://blog.kilo.ai/p/the-best-local-coding-models-for)
  - [Martin Fowler](https://martinfowler.com/articles/exploring-gen-ai/local-models-for-coding-factors.html)
- Pi and OpenCode:
  - [Zed ACP: Pi](https://zed.dev/acp/agent/pi)
  - [pi-acp (DxTa)](https://github.com/DxTa/pi-acp)
  - [pi-acp (victor-software-house)](https://github.com/victor-software-house/pi-acp)
  - [@geohar/pi-acp](https://pi.dev/packages/@geohar/pi-acp)
  - [Pi discussion #4444](https://github.com/earendil-works/pi/discussions/4444)
  - [Pi providers doc](https://app.unpkg.com/@mariozechner/pi-coding-agent@0.73.1/files/docs/providers.md)
  - [pi-opencode-provider](https://pi.dev/packages/pi-opencode-provider)
  - [pi-opencode-zen](https://pi.dev/packages/pi-opencode-zen)
  - [OpenCode Zen docs](https://opencode.ai/docs/zen)
  - [OpenCode ACP docs](https://opencode.ai/docs/cli/acp/)
  - [Zed ACP: OpenCode](https://zed.dev/acp/agent/opencode)
  - [Docker: OpenCode Zen](https://docs.docker.com/ai/docker-agent/providers/opencode-zen/)
