# AGENTS.md — fiber-ai-plugin

This repository ships Fiber AI as a first-class plugin for AI coding agents (Claude Code, Cursor, Codex, OpenCode, Copilot CLI, Gemini CLI, VS Code, Windsurf). If you are an agent inspecting this repo to fix something or extend it, read this file first.

## What this repo contains

- `skills/` — per-workflow skills (Markdown). Each skill has a `SKILL.md` with YAML frontmatter (`name`, `description`, `user-invocable`, `argument-hint`). The `description` is what other agents match against to auto-load the skill, so it must contain realistic user trigger phrases.
- `.mcp.json`, `cursor/mcp.json`, `vscode/mcp.json`, `gemini-extension.json` — MCP server configuration for each supported environment. All three Fiber MCP endpoints should appear in every config:
  - `https://mcp.fiber.ai/mcp/v2` — direct tools for the top ~10 priority operations, API-key auth.
  - `https://mcp.fiber.ai/mcp/v3` — direct tools for every public operation with compact descriptions, OAuth (SSO) auth.
  - `https://mcp.fiber.ai/mcp` — 5 meta-tools (`search_endpoints`, `list_tag_packs`, `list_all_endpoints`, `get_endpoint_details_full`, `call_operation`) over every public operation, supports both API-key and OAuth.
- `.claude-plugin/`, `.cursor-plugin/` — manifest files for the Claude Code and Cursor plugin formats.
- `cursor/rules/`, `windsurf/rules/` — rule files surfaced to the agent inside those IDEs.
- `hooks/` — Claude Code lifecycle hooks.
- `.opencode/INSTALL.md` — fetch-and-follow install instructions for OpenCode.

## Canonical docs live on the API, not in this repo

Do NOT hard-code operation schemas in skills. The canonical, always-current docs are:

- Routing policy + critical rules: <https://api.fiber.ai/llms.txt>
- Per-operation markdown (100+ operations): <https://api.fiber.ai/ai-docs/index.md> and `<https://api.fiber.ai/ai-docs/{operationId}.md>`
- Machine-readable spec: <https://api.fiber.ai/openapi.json> (send `Accept: text/markdown` for the agent-friendly version)

When a skill references an operation, link to `https://api.fiber.ai/ai-docs/<operationId>.md` rather than copying the schema inline.

## Skill authoring rules

- **Use real operationIds only.** Verify against `backend/clean/public/ai-docs/operation-sidecar.yaml` (the canonical list in the backend repo) or grep `backend/clean/src/api/routes/**`. Never invent operationIds — they will 404 at `/ai-docs/<op>.md`.
- **Preserve casing** exactly as registered (e.g. `KitchenSinkProfile`, `kitchenSinkCompany`).
- **No em-dashes, no curly quotes, no emojis** in skill files. Plain ASCII only.
- **Frontmatter description must include natural-language trigger phrases** (e.g. "find companies like", "enrich these LinkedIn URLs"). That is how Claude Code / Cursor auto-load the skill.
- **Cost-charging operations** (`buildAudience`, `triggerEnrichment`, `syncQuickContactReveal`, `syncTurboContactEnrichment`, `triggerExhaustiveContactEnrichment`, `startBatchContactDetails`, `profileLiveEnrich`, `companyLiveEnrich`) must have an explicit confirmation gate in the happy path. Never charge silently.
- **Section order** in every SKILL.md: frontmatter → H1 + mission → `## When to use` → `## Do not use when` → `## Happy path` → `## Cost & consent gates` → `## Error handling` → `## For AI agents: machine-readable docs` → optional `## SDK usage`.

## Changes that require cross-repo updates

If you add or rename a skill:

- Update `README.md` `## Available Commands` table (if the skill is user-invocable via slash command).
- If the skill adds a new MCP server, update `.mcp.json`, `cursor/mcp.json`, `vscode/mcp.json`, and `gemini-extension.json` together.

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
