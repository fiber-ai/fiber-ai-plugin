---
name: setup
description: Set up Fiber AI tools in the current environment. Use when the user needs to configure API keys, verify MCP connection, or install SDKs.
user-invocable: true
argument-hint: (no arguments needed)
---

# Fiber AI Setup

Configure Fiber AI for the current environment.

## When to Use

- User says "setup fiber", "install fiber", "configure fiber"
- MCP tools are not responding or returning authentication errors
- User is missing an API key or needs to verify their configuration
- First time using Fiber AI in this environment

## Setup Steps

### 1. Check API Key

Check if the `FIBER_API_KEY` environment variable is set in the current shell.

- **If set**: verify it works by calling the credits endpoint via Core MCP:
  `call_operation("getOrgCredits", {"query": {"apiKey": "..."}})`
  If the call succeeds, show "Fiber AI is connected" with the credit balance.
- **If not set**: instruct the user to:
  1. Get their API key from https://fiber.ai/app/api
  2. Set it as an environment variable:
     ```bash
     export FIBER_API_KEY=sk_live_...
     ```
  3. For persistence, add the export to their shell profile (`~/.zshrc` or `~/.bashrc`)

### 2. Verify MCP Connection

After the API key is configured:

- Try calling a Core MCP tool like `list_all_endpoints` to verify connectivity
- If successful: confirm "Fiber AI MCP is connected and working."
- If unsuccessful: check that the editor supports HTTP (Streamable HTTP) MCP transport and that network access to `mcp.fiber.ai` is not blocked

### 3. SDK Installation (Optional)

Only if the user intends to write application code (not just use MCP tools):

- **TypeScript**: `npm install @fiberai/sdk`
- **Python**: `pip install fiberai`

### 4. Quick Verification

Suggest the user run a quick test to confirm everything works:

> Try running `/fiber:search "technology companies in San Francisco"` to verify your setup.

## Authentication Notes

- For POST/PATCH/PUT API endpoints: `apiKey` is passed in the **request body**
- For GET API endpoints: `apiKey` is passed in the **query string**
- Check https://api.fiber.ai/docs/ for the exact authentication format per endpoint

## Troubleshooting

- **MCP not connecting**: verify the editor supports HTTP (Streamable HTTP) MCP transport
- **Authentication errors (401)**: API key is invalid or expired — regenerate at https://fiber.ai/app/api
- **Insufficient credits (402)**: top up at https://www.fiber.ai/app/subscription
- **Rate limit errors (429)**: wait a moment and retry
- **Network errors**: ensure outbound HTTPS to `mcp.fiber.ai` is allowed by firewall or proxy

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> — routing policy + critical rules. Read this before making any API call.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> — every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. Drop this straight into the LLM prompt as the canonical context for the operation you're about to call.
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.
