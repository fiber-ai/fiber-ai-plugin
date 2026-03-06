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

- The SDK is auto-generated from the OpenAPI spec using `@hey-api/openapi-ts`
- Each API operationId becomes a **named exported function** (e.g., `companySearch`, `peopleSearch`, `syncContactEnrichment`)
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
