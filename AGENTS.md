# AGENTS.md — fiber-ai-plugin

This repository ships Fiber AI as a first-class plugin for AI coding agents (Claude Code, Cursor, Codex, OpenCode, Copilot CLI, Gemini CLI, VS Code, Windsurf). If you are an agent inspecting this repo to fix something or extend it, read this file first.

## What this repo contains

- `skills/` — per-workflow skills (Markdown). Each skill has a `SKILL.md` with YAML frontmatter (`name`, `description`, `user-invocable`, `argument-hint`). The `description` is what other agents match against to auto-load the skill, so it must contain realistic user trigger phrases.
- `agents/` — persona subagent files (Claude Code / Cursor / OpenCode compatible). Flat `.md` files; each is a full subagent system prompt with YAML frontmatter. See "Persona authoring rules" below. Current personas: `ai-recruiter`, `ai-sdr`, `gtm-strategist`, `signal-scout`, `data-quality-auditor`, `product-engineer`, `fiber-sde`.
- `cursor/agents/` — Cursor-compatible copies of the persona files (plain `cp` from `agents/`).
- `.opencode/agents/` — OpenCode-compatible copies of the persona files (`cp` + frontmatter swap: `name`/`tools`/`skills`/`mcpServers`/`color` removed, `mode: subagent` added).
- `.codex/agents/` — Codex CLI TOML translations of the persona files. Generated from `agents/*.md` via a small bash script; the developer instructions body is copied verbatim, not re-authored.
- `.mcp.json`, `cursor/mcp.json`, `vscode/mcp.json`, `gemini-extension.json` — MCP server configuration for each supported environment. All three Fiber MCP endpoints should appear in every config:
  - `https://mcp.fiber.ai/mcp/v2` — direct tools for the top ~10 priority operations, API-key auth.
  - `https://mcp.fiber.ai/mcp/v3` — direct tools for every public operation with compact descriptions, OAuth (SSO) auth.
  - `https://mcp.fiber.ai/mcp` — 5 meta-tools (`search_endpoints`, `list_tag_packs`, `list_all_endpoints`, `get_endpoint_details_full`, `call_operation`) over every public operation, API-key auth (same shape as V2).
- `.claude-plugin/`, `.cursor-plugin/` — manifest files for the Claude Code and Cursor plugin formats. Both register `agents/` alongside `skills/`.
- `cursor/rules/`, `windsurf/rules/` — rule files surfaced to the agent inside those IDEs.
- `hooks/` — Claude Code lifecycle hooks (`hooks/hooks.json`). Do **not** also set `"hooks"` in `.claude-plugin/plugin.json`; Claude Code auto-discovers `hooks/hooks.json` and a duplicate manifest entry loads hooks twice.
- `.opencode/INSTALL.md` — fetch-and-follow install instructions for OpenCode.

## Canonical docs live on the API, not in this repo

Do NOT hard-code operation schemas in skills. The canonical, always-current docs are:

- Routing policy + critical rules: <https://api.fiber.ai/llms.txt>
- Per-operation markdown (100+ operations): <https://api.fiber.ai/ai-docs/index.md> and `<https://api.fiber.ai/ai-docs/{operationId}.md>`
- Machine-readable spec: <https://api.fiber.ai/openapi.json> (send `Accept: text/markdown` for the agent-friendly version)

When a skill references an operation, link to `https://api.fiber.ai/ai-docs/<operationId>.md` rather than copying the schema inline.

## Skill authoring rules

- **Use real operationIds only.** Verify against `https://api.fiber.ai/ai-docs/index.md` (the canonical list). Never invent operationIds — they will 404 at `/ai-docs/<op>.md`.
- **Preserve casing** exactly as registered (e.g. `KitchenSinkProfile`, `kitchenSinkCompany`).
- **No em-dashes, no curly quotes, no emojis** in skill files. Plain ASCII only.
- **Frontmatter description must include natural-language trigger phrases** (e.g. "find companies like", "enrich these LinkedIn URLs"). That is how Claude Code / Cursor auto-load the skill.
- **Cost-charging operations** (`buildAudience`, `triggerEnrichment`, `syncQuickContactReveal`, `syncTurboContactEnrichment`, `triggerExhaustiveContactEnrichment`, `startBatchContactDetails`, `profileLiveEnrich`, `companyLiveEnrich`) must have an explicit confirmation gate in the happy path. Never charge silently.
- **Section order** in every SKILL.md: frontmatter → H1 + mission → `## When to use` → `## Do not use when` → `## Happy path` → `## Cost & consent gates` → `## Error handling` → `## For AI agents: machine-readable docs` → optional `## SDK usage`.

## Persona authoring rules

Personas live in `agents/<name>.md` (canonical source). A persona is a domain-expert subagent that the user can invoke with `@<name>` and that carries full Fiber product knowledge plus operator-grade domain expertise.

- **Canonical source is `agents/<name>.md`.** Cursor and OpenCode copies are `cp`-derived; Codex TOML is script-derived. Never edit a derived copy directly - edit `agents/<name>.md` and re-run the distribution steps (see below).
- **Frontmatter fields (Claude Code plugin):** `name` (matches filename), `description` (trigger phrases + "Use PROACTIVELY when ..."), `tools`, `skills` (preload list). Note: `mcpServers`, `color`, `model`, and `permissionMode` are NOT supported for plugin-shipped agents per the Claude Code plugin spec -- MCP servers from `.mcp.json` are available globally.
- **Frontmatter fields (Cursor variant):** same as Claude Code plus `mcpServers`, `model: inherit`, `color` (Cursor supports these fields).
- **Frontmatter fields (OpenCode variant):** `description`, `mode: subagent`, `model: inherit`. Everything else lives in the HTML comment block at the top of the body.
- **Section order in the body:** `# Identity` -> `## Hard rules (never violated)` -> `## Standard workflows you execute autonomously` -> `## Fiber operation cheatsheet` -> `## <domain>-specific tradeoffs you know cold` -> `## Tone` -> `## When to escalate or hand off` -> `## Canonical reference docs for agents`.
- **Every operationId cited in a persona must exist** in `https://api.fiber.ai/ai-docs/index.md` (the canonical list) or appear in `https://api.fiber.ai/ai-docs/index.md`. Hidden / dev-only operations (`textToCompanySearch`, `textToProfileSearch`, deprecated `bulkReverseEmailLookup`, etc.) are forbidden.
- **Personas must enforce cost gates.** Any charged operation (`syncQuickContactReveal`, `syncTurboContactEnrichment`, `triggerExhaustiveContactEnrichment`, `startBatchContactDetails`, `buildAudience`, `triggerEnrichment`, `profileLiveEnrich`, `companyLiveEnrich`) must be preceded by a free count / estimate step and explicit user confirmation.
- **Plain ASCII only** (no em-dashes, no curly quotes, no emojis) inside persona files, same rule as SKILL.md.
- **Hand-offs across personas** are explicit: each persona lists which persona to delegate to for out-of-scope asks.

### Distributing a new or renamed persona

After editing or adding `agents/<name>.md`:

```bash
# Cursor (identical frontmatter works for Cursor):
cp agents/<name>.md cursor/agents/<name>.md

# OpenCode (swap frontmatter to `mode: subagent`):
cp agents/<name>.md .opencode/agents/<name>.md
# ...then edit the frontmatter block: remove name/tools/skills/mcpServers/color,
# add `mode: subagent`, and move the dropped fields into the HTML comment at top of body.

# Codex CLI (run the generator at the root of the plugin):
bash scripts/generate-codex-agents.sh   # see AGENTS.md for the one-liner we currently use
```

Also update `README.md` Personas table and the persona list in this file.

## Changes that require cross-repo updates

If you add or rename a skill:

- Update `README.md` `## Available Commands` table (if the skill is user-invocable via slash command).
- If the skill adds a new MCP server, update `.mcp.json`, `cursor/mcp.json`, `vscode/mcp.json`, and `gemini-extension.json` together.

If you add or rename a persona:

- Update `README.md` Personas table.
- Update the persona list at the top of this file and in `.opencode/INSTALL.md`.
- Re-run the distribution steps above so `cursor/agents/`, `.opencode/agents/`, and `.codex/agents/` stay in sync with `agents/`.

## Testing locally

Skills are Markdown-only — no build step. Verify with:

```
ls skills/
wc -l skills/*/SKILL.md
```

Every `SKILL.md` should start with a `---` frontmatter block whose `name` matches the parent folder name.

## MCP authentication

V2 and Core accept an API key; users export `FIBER_API_KEY` in their shell and the MCP server reads it from the client's request headers. V3 uses OAuth (SSO) and does not need `FIBER_API_KEY`; the client completes the Clerk login flow on first use and the session token is reused on subsequent calls. No env var or token is baked into any config in this repo.

## Support

- Runtime issues with MCP: <https://docs.fiber.ai/article/using-mcp-in-llms>
- API key management: <https://fiber.ai/app/api>
- Plugin issues: file in this repo.
