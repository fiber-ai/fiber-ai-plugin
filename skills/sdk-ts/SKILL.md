---
name: sdk-ts
description: Help writing TypeScript or JavaScript code using the @fiberai/sdk package. Use when the user wants to build an application, integration, or automation that calls Fiber AI APIs programmatically.
user-invocable: true
argument-hint: <what you want to build>
---

# Fiber AI TypeScript SDK

Help the user write TypeScript or JavaScript code using the `@fiberai/sdk` package.

## When to Use

- User wants to BUILD an application using Fiber AI (not just query via MCP)
- User says "build", "create app", "write code", "typescript", "javascript", "node"
- User wants a wrapper, integration, data pipeline, or product on top of Fiber APIs

## Do Not Use When

- User just wants to search or enrich via chat — use `/fiber:search` or `/fiber:enrich` instead
- User wants to write Python code — use `/fiber:sdk-py` instead

## Quick Start

```typescript
import { createClient, companySearch } from "@fiberai/sdk";

const client = createClient({
  baseUrl: "https://api.fiber.ai",
});

const result = await companySearch({
  client,
  body: {
    apiKey: process.env.FIBER_API_KEY!,
    searchParams: { /* filters */ },
    pageSize: 25,
  },
});
```

## Key Concepts

- The SDK provides typed functions for every API endpoint
- Each API operationId becomes a **named exported function** (e.g., `companySearch`, `peopleSearch`, `syncQuickContactReveal`)
- `apiKey` is passed **in the request body** (for POST) or **query string** (for GET), not as a header
- Search filters go inside a `searchParams` object, not a `filters` object
- Pagination uses `cursor`, not `page`
- All functions are async and return typed responses
- `zod` is included for runtime validation schemas

## Important Rules

- Always use environment variables for API keys — never hardcode secrets
- Always pass `apiKey` in the request body or query, not as a header
- Handle HTTP error responses: 401 (auth), 402 (insufficient credits), 429 (rate limit)
- For bulk operations, use the audience workflow (create, set params, build, estimate, enrich, export)
- Check https://api.fiber.ai/docs/ for the current API schema — parameters and response shapes may change between SDK versions

## Detailed Examples

See the `references/` folder for:
- Full client setup with error handling
- Company and people search with the correct body structure
- Contact enrichment patterns

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> — routing policy + critical rules (read before generating code).
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> — every public operation, grouped by tag. Use it to discover the right `operationId` for a task.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. Drop this straight into an LLM prompt — it describes request/response shapes, credit costs, and routing hints for that one operation.
- **Full corpus (RAG):** <https://api.fiber.ai/llms-full.txt> — every per-operation page concatenated for one-shot indexing.
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.
