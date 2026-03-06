# TypeScript SDK — Client Setup

## Installation

```bash
npm install @fiberai/sdk
```

## Basic Client

The SDK exports `createClient` for configuring the HTTP client and named functions for each API operation.

```typescript
import { createClient } from "@fiberai/sdk";

const client = createClient({
  baseUrl: "https://api.fiber.ai",
});
```

## Making API Calls

Each API operation is a named export. Pass the `client` instance and request body:

```typescript
import { createClient, companySearch, getOrgCredits } from "@fiberai/sdk";

const client = createClient({
  baseUrl: "https://api.fiber.ai",
});

// Check credits (GET endpoint — apiKey in query)
const credits = await getOrgCredits({
  client,
  query: {
    apiKey: process.env.FIBER_API_KEY!,
  },
});

// Company search (POST endpoint — apiKey in body)
const results = await companySearch({
  client,
  body: {
    apiKey: process.env.FIBER_API_KEY!,
    searchParams: {
      // Use https://api.fiber.ai/docs/ for current filter schema
    },
    pageSize: 25,
  },
});
```

## Authentication

The API key is passed **per-request** in the body (POST/PATCH) or query string (GET). It is NOT passed as a header.

```typescript
function getApiKey(): string {
  const key = process.env.FIBER_API_KEY;
  if (!key) {
    throw new Error(
      "FIBER_API_KEY environment variable is required. Get your key at https://fiber.ai/app/api"
    );
  }
  return key;
}
```

## Error Handling

The SDK returns typed response objects. For error handling, check the response status or use `throwOnError`:

```typescript
import { createClient, companySearch } from "@fiberai/sdk";

const client = createClient({
  baseUrl: "https://api.fiber.ai",
  throwOnError: true, // Throws on non-2xx responses
});

try {
  const result = await companySearch({
    client,
    body: {
      apiKey: getApiKey(),
      searchParams: {},
      pageSize: 25,
    },
  });
} catch (error) {
  // Handle based on status code:
  // 401 — Invalid API key
  // 402 — Insufficient credits (top up at https://www.fiber.ai/app/subscription)
  // 429 — Rate limit exceeded
  console.error(error);
}
```

## API Reference

For the full list of available operations, parameter schemas, and response types, see:
- Interactive API docs: https://api.fiber.ai/docs/
- SDK source: check `node_modules/@fiberai/sdk/dist/` after installation for available operations and types
