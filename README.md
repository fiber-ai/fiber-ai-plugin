# Fiber AI Plugin

Use Fiber AI with your AI coding agent. Search companies, find contacts, enrich data, and manage audiences — directly from Claude Code, Cursor, VS Code, Windsurf, and 40+ other AI agents.

## Quick Start

### Claude Code (Full Plugin)

```bash
/plugin marketplace add fiber-ai/fiber-ai-plugin
/plugin install fiber@fiber-tools
```

This installs MCP tools, skills, and hooks automatically. Run `/fiber:help` to see available commands.

### Cursor

**Option A — Deeplink (recommended):**

[Install Fiber AI MCP in Cursor](cursor://anysphere.cursor-deeplink/mcp/install?name=fiber-ai-v2&config=eyJ0eXBlIjoiaHR0cCIsInVybCI6Imh0dHBzOi8vbWNwLmZpYmVyLmFpL21jcC92MiJ9)

**Option B — Manual:**

Copy `cursor/mcp.json` to your project's `.cursor/mcp.json`, or add to Cursor Settings > Features > MCP:

- **Name**: `fiber-ai-v2`
- **Type**: `HTTP`
- **URL**: `https://mcp.fiber.ai/mcp/v2`

**Optional — Add agent rules:**

Copy `cursor/rules/fiber-api.mdc` to your project's `.cursor/rules/` directory.

### VS Code

Copy `vscode/mcp.json` to your project's `.vscode/mcp.json`, or add to your VS Code settings:

```json
{
  "mcpServers": {
    "fiber-ai-v2": {
      "type": "http",
      "url": "https://mcp.fiber.ai/mcp/v2"
    }
  }
}
```

### Windsurf

Add the MCP server URL in Windsurf settings:

- **URL**: `https://mcp.fiber.ai/mcp/v2`
- **Transport**: HTTP

Copy `windsurf/rules/fiber-api.md` to your project's Windsurf rules directory for agent guidance.

### Other Agents (via skills.sh)

Install individual skills for any agent that supports [skills.sh](https://skills.sh):

```bash
npx skills add fiber-ai/fiber-ai-plugin --skill search
npx skills add fiber-ai/fiber-ai-plugin --skill enrich
npx skills add fiber-ai/fiber-ai-plugin --skill audience
npx skills add fiber-ai/fiber-ai-plugin --skill sdk-ts
npx skills add fiber-ai/fiber-ai-plugin --skill sdk-py
npx skills add fiber-ai/fiber-ai-plugin --skill setup
npx skills add fiber-ai/fiber-ai-plugin --skill help
```

### Team Sharing

Commit an MCP config to your repository so teammates get Fiber AI automatically:

**Claude Code** — add to `.mcp.json` at project root:

```json
{
  "mcpServers": {
    "fiber-ai-v2": {
      "type": "http",
      "url": "https://mcp.fiber.ai/mcp/v2"
    }
  }
}
```

**Cursor** — add to `.cursor/mcp.json` at project root (same format as above).

---

## Authentication

1. Get your API key from [fiber.ai/app/api](https://fiber.ai/app/api)
2. Set it as an environment variable:

```bash
export FIBER_API_KEY=sk_live_...
```

Add to your shell profile (`~/.zshrc` or `~/.bashrc`) for persistence.

---

## Available Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **search** | `/fiber:search "query"` | Search for companies or people by criteria |
| **enrich** | `/fiber:enrich "target"` | Reveal emails, phones, and profiles for contacts or companies |
| **audience** | `/fiber:audience "description"` | Build prospecting lists with bulk search, enrichment, and export |
| **sdk-ts** | `/fiber:sdk-ts "what to build"` | Help writing TypeScript code with `@fiberai/sdk` |
| **sdk-py** | `/fiber:sdk-py "what to build"` | Help writing Python code with `fiberai` |
| **setup** | `/fiber:setup` | Configure API key and verify MCP connection |
| **help** | `/fiber:help` | Show capabilities and available commands |

---

## MCP Servers

Fiber AI provides two MCP endpoints with different trade-offs:

| Endpoint | URL | Tools | Best For |
|----------|-----|-------|----------|
| **V2** | `https://mcp.fiber.ai/mcp/v2` | ~10 curated, direct API tools | Most users — common operations like search, enrich, audience management |
| **Core** | `https://mcp.fiber.ai/mcp` | 4 meta-tools (search, list, details, call) | Power users who need access to all 100+ API endpoints |

Both use **HTTP (Streamable HTTP)** transport.

---

## SDKs

For building applications programmatically:

- **TypeScript**: `npm install @fiberai/sdk` — [GitHub](https://github.com/fiber-ai/typescript-sdk)
- **Python**: `pip install fiberai` — [GitHub](https://github.com/fiber-ai/python-sdk)

---

## Project Structure

```
fiber-ai-plugin/
├── .claude-plugin/          # Claude Code plugin manifests
│   ├── plugin.json
│   └── marketplace.json
├── .mcp.json                # MCP server configuration
├── hooks/
│   └── hooks.json           # Claude Code lifecycle hooks
├── skills/                  # Skills (Claude Code + skills.sh)
│   ├── search/              # Company and people search
│   ├── enrich/              # Contact and company enrichment
│   ├── audience/            # Bulk audience workflows
│   ├── setup/               # Environment configuration
│   ├── help/                # Capabilities overview
│   ├── sdk-ts/              # TypeScript SDK guidance + references
│   └── sdk-py/              # Python SDK guidance + references
├── cursor/                  # Cursor-specific configs
│   ├── mcp.json
│   └── rules/fiber-api.mdc
├── vscode/                  # VS Code config template
│   └── mcp.json
├── windsurf/                # Windsurf config template
│   └── rules/fiber-api.md
├── LICENSE
└── README.md
```

---

## Links

- [Fiber AI](https://fiber.ai)
- [API Documentation](https://docs.fiber.ai)
- [API Key Management](https://fiber.ai/app/api)
- [Credits and Billing](https://www.fiber.ai/app/subscription)

---

## License

MIT — Fiber AI 2026
