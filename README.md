# Fiber AI Plugin

Use Fiber AI with your AI coding agent. Search companies, find contacts, enrich data, and manage audiences — directly from Claude Code, Cursor, VS Code, Windsurf, and 40+ other AI agents.

## Quick Start

### Claude Code

```bash
claude plugin marketplace add fiber-ai/fiber-ai-plugin --scope project
claude plugin install fiber --scope project
```

This installs MCP tools, skills, and hooks automatically. Run `/fiber:help` to see available commands.

### Cursor

```bash
cursor-plugin marketplace add fiber-ai/fiber-ai-plugin --scope project
cursor-plugin install fiber-ai --scope project
```

This installs MCP servers, skills, rules, and slash commands (`/fiber-search`, `/fiber-enrich`, `/fiber-audience`, `/fiber-setup`).

**Or add MCP only via deeplink** — copy and paste into your browser:

```
cursor://anysphere.cursor-deeplink/mcp/install?name=fiber-ai-v2&config=eyJ0eXBlIjoiaHR0cCIsInVybCI6Imh0dHBzOi8vbWNwLmZpYmVyLmFpL21jcC92MiJ9
```

For the Core MCP server (all 100+ endpoints via meta-tools):

```
cursor://anysphere.cursor-deeplink/mcp/install?name=fiber-ai-core&config=eyJ0eXBlIjoiaHR0cCIsInVybCI6Imh0dHBzOi8vbWNwLmZpYmVyLmFpL21jcCJ9
```

**Option B — Manual:**

Copy `cursor/mcp.json` to your project's `.cursor/mcp.json`, or add to Cursor Settings > Features > MCP:

| Name            | Type   | URL                           | Best For                                  |
| --------------- | ------ | ----------------------------- | ----------------------------------------- |
| `fiber-ai-v2`   | `HTTP` | `https://mcp.fiber.ai/mcp/v2` | ~10 direct tools for common operations    |
| `fiber-ai-core` | `HTTP` | `https://mcp.fiber.ai/mcp`    | 4 meta-tools accessing all 100+ endpoints |

**Optional — Add agent rules:**

Copy `cursor/rules/fiber-api.mdc` to your project's `.cursor/rules/` directory.

### VS Code

Add to your `.vscode/mcp.json`:

```json
{
  "mcpServers": {
    "fiber-ai-v2": {
      "type": "http",
      "url": "https://mcp.fiber.ai/mcp/v2"
    },
    "fiber-ai-core": {
      "type": "http",
      "url": "https://mcp.fiber.ai/mcp"
    }
  }
}
```

### Windsurf

Add MCP servers in Windsurf settings (Transport: HTTP):

- **V2**: `https://mcp.fiber.ai/mcp/v2` — direct tools for common operations
- **Core**: `https://mcp.fiber.ai/mcp` — meta-tools for all 100+ endpoints

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
    },
    "fiber-ai-core": {
      "type": "http",
      "url": "https://mcp.fiber.ai/mcp"
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

## Available Commands

| Command                         | Description                                                      |
| ------------------------------- | ---------------------------------------------------------------- |
| `/fiber:search "query"`         | Search for companies or people by criteria                       |
| `/fiber:enrich "target"`        | Reveal emails, phones, and profiles for contacts or companies    |
| `/fiber:audience "description"` | Build prospecting lists with bulk search, enrichment, and export |
| `/fiber:sdk-ts "what to build"` | Help writing TypeScript code with `@fiberai/sdk`                 |
| `/fiber:sdk-py "what to build"` | Help writing Python code with `fiberai`                          |
| `/fiber:setup`                  | Configure API key and verify MCP connection                      |
| `/fiber:help`                   | Show capabilities and available commands                         |

---

## MCP Servers

Fiber AI provides two MCP endpoints:

| Endpoint | URL                           | Tools                                      | Best For                                         |
| -------- | ----------------------------- | ------------------------------------------ | ------------------------------------------------ |
| **V2**   | `https://mcp.fiber.ai/mcp/v2` | ~10 curated, direct API tools              | Most users — search, enrich, audience management |
| **Core** | `https://mcp.fiber.ai/mcp`    | 4 meta-tools (search, list, details, call) | Power users — access to all 100+ API endpoints   |

Both use **HTTP (Streamable HTTP)** transport.

---

## SDKs

For building applications programmatically:

- **TypeScript**: `npm install @fiberai/sdk` — [GitHub](https://github.com/fiber-ai/typescript-sdk)
- **Python**: `pip install fiberai` — [GitHub](https://github.com/fiber-ai/python-sdk)

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
