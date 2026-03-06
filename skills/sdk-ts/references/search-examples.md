# TypeScript SDK — Search Examples

## Company Search

```typescript
import { createClient, companySearch } from "@fiberai/sdk";

const client = createClient({ baseUrl: "https://api.fiber.ai" });

const results = await companySearch({
  client,
  body: {
    apiKey: process.env.FIBER_API_KEY!,
    searchParams: {
      // Filter fields vary — check https://api.fiber.ai/docs/ for the current schema
      // Common filters include location, employee count, industry, tech stack, funding, etc.
    },
    pageSize: 25,
  },
});
```

## People Search

```typescript
import { createClient, peopleSearch } from "@fiberai/sdk";

const client = createClient({ baseUrl: "https://api.fiber.ai" });

const results = await peopleSearch({
  client,
  body: {
    apiKey: process.env.FIBER_API_KEY!,
    searchParams: {
      // Filter fields vary — check https://api.fiber.ai/docs/ for the current schema
      // Common filters include job title, seniority, department, current company, location, etc.
    },
    pageSize: 25,
  },
});
```

## Paginated Search Using Cursor

The API uses cursor-based pagination, not page numbers:

```typescript
import { createClient, companySearch } from "@fiberai/sdk";

const client = createClient({ baseUrl: "https://api.fiber.ai" });
const apiKey = process.env.FIBER_API_KEY!;

async function searchAllCompanies(searchParams: Record<string, unknown>) {
  const allResults: unknown[] = [];
  let cursor: string | null = null;

  do {
    const response = await companySearch({
      client,
      body: {
        apiKey,
        searchParams,
        pageSize: 25,
        ...(cursor ? { cursor } : {}),
      },
    });

    if (response.data) {
      allResults.push(...(response.data as any).results);
      cursor = (response.data as any).cursor ?? null;
    } else {
      cursor = null;
    }
  } while (cursor);

  return allResults;
}
```

## Important Notes

- `searchParams` is the correct field name (not `filters`)
- Pagination uses `cursor` (not `page`)
- `apiKey` goes in the request body
- Check https://api.fiber.ai/docs/ for exact `searchParams` field names — they are complex and version-dependent
- Credits are charged per result found, not per page
