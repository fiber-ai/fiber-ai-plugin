# Fiber AI Plugin

Use Fiber AI with any AI coding agent. Search companies, find contacts, enrich data, and manage audiences — directly from Claude Code, Cursor, OpenCode, Gemini CLI, Codex CLI, GitHub Copilot CLI, VS Code, Windsurf, and 40+ other AI agents.

Fiber MCP ships three HTTP endpoints:

| Endpoint  | URL                           | Auth          | Tools                                                                                                                               | Best For                                                                 |
| --------- | ----------------------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| **V2**    | `https://mcp.fiber.ai/mcp/v2` | API key       | Auto-generated direct tools for the top ~10 priority operations                                                                     | Fastest path for common flows: search companies/people, enrich contacts  |
| **V3**    | `https://mcp.fiber.ai/mcp/v3` | OAuth (SSO)   | Auto-generated direct tools for every public operation, with compact descriptions the model can expand on demand                    | Power users who want SSO login and full tool coverage without meta-tools |
| **Core**  | `https://mcp.fiber.ai/mcp`    | API key or OAuth | 5 meta-tools: `search_endpoints`, `list_tag_packs`, `list_all_endpoints`, `get_endpoint_details_full`, `call_operation` over every public operation | Low-tool-count surface; agent discovers endpoints at runtime             |

All three use **Streamable HTTP** transport. You can register any combination; the MCP server names stay distinct (`fiber-ai-v2`, `fiber-ai-v3`, `fiber-ai-core`).

---

## Install

All install paths give you the MCP servers, 15 built-in skills (7 general + 8 playbook workflows), and 5 persona subagents (`ai-recruiter`, `ai-sdr`, `gtm-strategist`, `signal-scout`, `data-quality-auditor`) that do the work like a human teammate with full Fiber product knowledge.

### Claude Code

```bash
/plugin marketplace add fiber-ai/fiber-ai-plugin
/plugin install fiber@fiber-tools
```

This installs MCP tools, skills, rules, and hooks in one shot. Run `/fiber:help` to list commands.

Team sharing (optional) — commit a `.mcp.json` at the project root so teammates get Fiber AI automatically:

```json
{
  "mcpServers": {
    "fiber-ai-v2": { "type": "http", "url": "https://mcp.fiber.ai/mcp/v2" },
    "fiber-ai-v3": { "type": "http", "url": "https://mcp.fiber.ai/mcp/v3" },
    "fiber-ai-core": { "type": "http", "url": "https://mcp.fiber.ai/mcp" }
  }
}
```

### Cursor

**Option A — Deeplink (paste in your browser, Cursor must be installed):**

V2 (recommended for most users, API key auth):

```
cursor://anysphere.cursor-deeplink/mcp/install?name=fiber-ai-v2&config=eyJ0eXBlIjoiaHR0cCIsInVybCI6Imh0dHBzOi8vbWNwLmZpYmVyLmFpL21jcC92MiJ9
```

V3 (every public operation, OAuth / SSO auth):

```
cursor://anysphere.cursor-deeplink/mcp/install?name=fiber-ai-v3&config=eyJ0eXBlIjoiaHR0cCIsInVybCI6Imh0dHBzOi8vbWNwLmZpYmVyLmFpL21jcC92MyJ9
```

Core (5 meta-tools over every public operation):

```
cursor://anysphere.cursor-deeplink/mcp/install?name=fiber-ai-core&config=eyJ0eXBlIjoiaHR0cCIsInVybCI6Imh0dHBzOi8vbWNwLmZpYmVyLmFpL21jcCJ9
```

**Option B — Manual:** copy `cursor/mcp.json` from this repo to your project's `.cursor/mcp.json`. Optionally copy `cursor/rules/fiber-api.mdc` to `.cursor/rules/` for inline agent guidance.

**Persona subagents:** Cursor picks up subagents from `.cursor/agents/`. Copy the persona files into your project:

```bash
mkdir -p .cursor/agents && cp path/to/fiber-ai-plugin/cursor/agents/*.md .cursor/agents/
```

### OpenCode

In your OpenCode session, tell the agent:

```
Fetch and follow instructions from https://raw.githubusercontent.com/fiber-ai/fiber-ai-plugin/main/.opencode/INSTALL.md
```

The agent will register the Fiber MCP servers (V2, V3, Core), clone the skills, copy the persona subagents into `.opencode/agents/`, and append a "Fiber AI skills and personas" section to your project `AGENTS.md`.

### Gemini CLI

```bash
gemini extensions install https://github.com/fiber-ai/fiber-ai-plugin
```

To update later:

```bash
gemini extensions update fiber-ai
```

The repo ships a `gemini-extension.json` that registers all three Fiber MCP endpoints (V2, V3, Core) and exposes the skills via the `AGENTS.md` context file.

### OpenAI Codex CLI

Codex CLI reads MCP servers from `~/.codex/config.toml`. Append:

```toml
[mcp_servers.fiber-ai-v2]
url = "https://mcp.fiber.ai/mcp/v2"
transport = "http"

[mcp_servers.fiber-ai-v3]
url = "https://mcp.fiber.ai/mcp/v3"
transport = "http"

[mcp_servers.fiber-ai-core]
url = "https://mcp.fiber.ai/mcp"
transport = "http"
```

Then export your API key (V2 and Core support API-key auth; V3 uses OAuth SSO instead):

```bash
export FIBER_API_KEY=sk_live_...
```

To load the playbook skills, clone this repo next to your project and reference it in your Codex system prompt, or copy individual `skills/*/SKILL.md` files into your Codex skills directory.

**Persona subagents for Codex CLI:** the plugin ships TOML-format subagents under `.codex/agents/`. Copy them into your Codex agents directory:

```bash
mkdir -p .codex/agents && cp path/to/fiber-ai-plugin/.codex/agents/*.toml .codex/agents/
```

Then invoke any of `@ai-recruiter`, `@ai-sdr`, `@gtm-strategist`, `@signal-scout`, or `@data-quality-auditor` inside Codex.

### GitHub Copilot CLI

Copilot CLI reads MCP servers from `~/.config/github-copilot/mcp.json`:

```json
{
  "mcpServers": {
    "fiber-ai-v2": { "type": "http", "url": "https://mcp.fiber.ai/mcp/v2" },
    "fiber-ai-v3": { "type": "http", "url": "https://mcp.fiber.ai/mcp/v3" },
    "fiber-ai-core": { "type": "http", "url": "https://mcp.fiber.ai/mcp" }
  }
}
```

Copilot CLI picks up `AGENTS.md` automatically — clone or symlink this repo into your workspace to surface the skills to the agent.

### VS Code

Add to your `.vscode/mcp.json`:

```json
{
  "mcpServers": {
    "fiber-ai-v2": { "type": "http", "url": "https://mcp.fiber.ai/mcp/v2" },
    "fiber-ai-v3": { "type": "http", "url": "https://mcp.fiber.ai/mcp/v3" },
    "fiber-ai-core": { "type": "http", "url": "https://mcp.fiber.ai/mcp" }
  }
}
```

The skills live in `skills/` — VS Code agents such as GitHub Copilot Chat honor the `AGENTS.md` file in your workspace root.

### Windsurf

Add the three MCP servers in Windsurf Settings (Transport: HTTP):

- **V2** (API key): `https://mcp.fiber.ai/mcp/v2`
- **V3** (OAuth): `https://mcp.fiber.ai/mcp/v3`
- **Core** (API key or OAuth): `https://mcp.fiber.ai/mcp`

Copy `windsurf/rules/fiber-api.md` from this repo to your Windsurf rules directory.

### Any other agent (via skills.sh)

Install individual skills for any agent that supports [skills.sh](https://skills.sh):

```bash
npx skills add fiber-ai/fiber-ai-plugin --skill find-similar-companies
npx skills add fiber-ai/fiber-ai-plugin --skill enrich-linkedin-csv
npx skills add fiber-ai/fiber-ai-plugin --skill build-recruiting-audience
npx skills add fiber-ai/fiber-ai-plugin --skill expand-from-email-list
npx skills add fiber-ai/fiber-ai-plugin --skill enrich-github-handles
npx skills add fiber-ai/fiber-ai-plugin --skill find-and-enrich-by-role
npx skills add fiber-ai/fiber-ai-plugin --skill track-signals
npx skills add fiber-ai/fiber-ai-plugin --skill benchmark-vs-competitor
npx skills add fiber-ai/fiber-ai-plugin --skill search
npx skills add fiber-ai/fiber-ai-plugin --skill enrich
npx skills add fiber-ai/fiber-ai-plugin --skill audience
npx skills add fiber-ai/fiber-ai-plugin --skill sdk-ts
npx skills add fiber-ai/fiber-ai-plugin --skill sdk-py
npx skills add fiber-ai/fiber-ai-plugin --skill setup
npx skills add fiber-ai/fiber-ai-plugin --skill help
```

---

## Authentication

1. Get your API key from [fiber.ai/app/api](https://fiber.ai/app/api).
2. Set it as an environment variable:

   ```bash
   export FIBER_API_KEY=sk_live_...
   ```

   Add to `~/.zshrc` / `~/.bashrc` for persistence.

The MCP servers read your key from the client's request headers. Nothing is stored inside the plugin itself.

---

## What you get

Fiber ships 5 persona subagents + 15 skills. Personas are the "hire an AI teammate" unit - they carry domain expertise (recruiting, sales, GTM, signal tracking, data QA) plus full Fiber product knowledge so the user does not have to teach their LLM about either. Skills are the underlying workflow primitives the personas call into.

### Persona subagents (auto-load on matching intent, or invoke via `@<name>`)

| Persona                  | Who it is                                                                     | Trigger phrases                                                                                                                                           |
| ------------------------ | ----------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `@ai-recruiter`          | Senior in-house / agency recruiter; 10+ years sourcing engineers and GTM      | "build a recruiting list", "source engineers", "find candidates for <role>", "I am hiring a <role>", "JD attached", "talent audience", "passive candidates" |
| `@ai-sdr`                | Senior SDR / AE; runs outbound for B2B SaaS scale-ups                         | "build outbound list", "target accounts", "accounts like <seed>", "who should I reach at <company>", "find the buyer", "SDR list", "prospect list"        |
| `@gtm-strategist`        | Head of Sales / Head of GTM; thinks in pipeline math before running anything  | "GTM plan", "ABM strategy", "grow from $X to $Y", "pipeline math", "scope this campaign", "territory planning", "how many accounts do I need"             |
| `@signal-scout`          | Intent-signal operator; turns a static list into a live feed of buying events | "track signals", "watch these accounts", "job-change alerts", "who is hiring at my targets", "recent funding at my accounts", "signal-driven outbound"    |
| `@data-quality-auditor`  | Rigorous, vendor-agnostic data-quality analyst; runs reproducible bake-offs   | "compare Fiber to <vendor>", "bake-off", "benchmark data quality", "evaluate Fiber AI", "should I switch from <vendor>", "which provider is better for my segment" |

Each persona:

- Comes preloaded with domain expertise (recruiter tradeoffs vs SDR tradeoffs vs GTM strategy vs signal noise filtering vs benchmarking rigor).
- Knows every relevant Fiber operationId by name (no meta-tool round-trips for common operations).
- Calls into the plugin's skills automatically rather than hand-rolling HTTP calls.
- Enforces the same cost / consent gates as the skills - never charges silently.
- `@data-quality-auditor` never recommends a vendor - it presents numbers (including where Fiber underperformed) and lets the user decide.

### Playbook skills (auto-trigger on buyer / recruiter intent)

| Skill                              | Trigger phrases                                                                 |
| ---------------------------------- | ------------------------------------------------------------------------------- |
| `/fiber:find-similar-companies`    | "find companies like <seed>", "competitors of <seed>", "ABM lookalikes"         |
| `/fiber:enrich-linkedin-csv`       | "enrich these LinkedIn URLs", "bulk reveal emails for this list"                |
| `/fiber:build-recruiting-audience` | "build a recruiting list", "sourcing list for VP Eng at fintech"                |
| `/fiber:expand-from-email-list`    | "I have emails - give me LinkedIn + company", "reverse lookup emails"           |
| `/fiber:enrich-github-handles`     | "enrich these GitHub users", "find LinkedIn for these contributors"             |
| `/fiber:find-and-enrich-by-role`   | "find VPs of Engineering at Series B SaaS", "CMOs in healthcare"                |
| `/fiber:track-signals`             | "job-change alerts", "hiring signals for these companies", "intent data feed"   |
| `/fiber:benchmark-vs-competitor`   | "compare Fiber to <vendor>", "bake-off", "benchmark data quality on my sample"  |

### General skills

| Skill             | Description                                                        |
| ----------------- | ------------------------------------------------------------------ |
| `/fiber:search`   | Search companies or people by criteria                             |
| `/fiber:enrich`   | Reveal emails, phones, and profiles for a known contact or company |
| `/fiber:audience` | Build and export lists via the full audience lifecycle             |
| `/fiber:sdk-ts`   | Help writing TypeScript code with `@fiberai/sdk`                   |
| `/fiber:sdk-py`   | Help writing Python code with `fiberai`                            |
| `/fiber:setup`    | Configure API key and verify MCP connection                        |
| `/fiber:help`     | Show capabilities and available commands                           |

---

## SDKs

For building applications programmatically:

- **TypeScript**: `npm install @fiberai/sdk` — [GitHub](https://github.com/fiber-ai/typescript-sdk)
- **Python**: `pip install fiberai` — [GitHub](https://github.com/fiber-ai/python-sdk)

Both SDKs ship their own `llms.txt` pointing back at the canonical API docs.

---

## For AI agents (machine-readable)

Point your LLM / coding agent at these endpoints when building against Fiber:

- **Routing index + critical rules:** <https://api.fiber.ai/llms.txt>
- **Operation index (Stripe-style):** <https://api.fiber.ai/ai-docs/index.md>
- **Per-operation pages:** `https://api.fiber.ai/ai-docs/<operationId>.md` (e.g. [`companySearch`](https://api.fiber.ai/ai-docs/companySearch.md), [`syncQuickContactReveal`](https://api.fiber.ai/ai-docs/syncQuickContactReveal.md), [`syncTurboContactEnrichment`](https://api.fiber.ai/ai-docs/syncTurboContactEnrichment.md), [`triggerExhaustiveContactEnrichment`](https://api.fiber.ai/ai-docs/triggerExhaustiveContactEnrichment.md))
- **Full concatenated corpus (RAG):** <https://api.fiber.ai/llms-full.txt>
- **OpenAPI (JSON):** <https://api.fiber.ai/openapi.json> — send `Accept: text/markdown` on the same URL for the agent-friendly markdown index
- **MCP:** `https://mcp.fiber.ai/mcp/v2` (direct tools, API key) · `https://mcp.fiber.ai/mcp/v3` (direct tools over every public operation, OAuth / SSO) · `https://mcp.fiber.ai/mcp` (5 meta-tools, API key or OAuth)
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>

Authoring rules for anyone extending this plugin: see [`AGENTS.md`](./AGENTS.md).

---

## Links

- [Fiber AI](https://fiber.ai)
- [Fiber Documentation](https://docs.fiber.ai)
- [API Documentation](https://api.fiber.ai/docs/)
- [API Key Management](https://fiber.ai/app/api)
- [Credits and Billing](https://www.fiber.ai/app/subscription)

---

## License

MIT — Fiber AI 2026
