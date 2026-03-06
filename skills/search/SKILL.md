---
name: search
description: Search for companies or people using Fiber AI. Use when the user wants to find companies by criteria (location, industry, size, tech stack) or search for individual prospects.
user-invocable: true
argument-hint: <search query in natural language>
---

# Fiber AI Search

Search for companies or people matching criteria using Fiber AI MCP tools.

## When to Use

- User wants to find companies (by location, industry, employee count, tech stack, etc.)
- User wants to find people or prospects (by title, company, seniority, etc.)
- User says "search", "find companies", "find people", "look up", "prospect"

## Do Not Use When

- User wants to enrich or reveal contact info for a known person — use `/fiber:enrich` instead
- User wants to do bulk operations on a list — use `/fiber:audience` instead
- User wants to write code that calls the API — use `/fiber:sdk-ts` or `/fiber:sdk-py` instead

## How to Execute

### Using V2 MCP (if connected to `fiber-ai-v2`)

The V2 MCP has direct tools for search. Tool names follow the pattern `{operationId}_tool`:

- **Company search**: `companySearch_tool`
- **People search**: `peopleSearch_tool`

### Using Core MCP (if connected to `fiber-ai-core`)

1. Call `get_endpoint_details_full("companySearch")` or `get_endpoint_details_full("peopleSearch")` to get the exact parameter schema
2. Call `call_operation("companySearch", {"body": {...}})` or `call_operation("peopleSearch", {"body": {...}})` with the correct parameters

### Parameter Discovery

**Always call `get_endpoint_details_full` before constructing search parameters.** The filter schemas are complex and change over time. Do not guess parameter names — fetch the current schema from the MCP or refer to https://api.fiber.ai/docs/ for the interactive API documentation.

Key structural notes:
- The request body wraps filters inside a `searchParams` object (not `filters`)
- Pagination uses `cursor` (not `page`) and `pageSize`
- `apiKey` is a required field in the request body

Example body structure (verify exact field names via `get_endpoint_details_full`):
```json
{
  "apiKey": "...",
  "searchParams": { ... },
  "pageSize": 25,
  "cursor": null
}
```

## Authentication

Every API call requires `apiKey` in the request body. Check https://api.fiber.ai/docs/ for the exact authentication format for each endpoint. If the user hasn't configured authentication, direct them to run `/fiber:setup`.

## Result Formatting

- **Company results**: show name, domain, location, employee count, industry
- **People results**: show name, title, company, location, LinkedIn URL
- Always show the total number of results found
- If results exceed 25, mention the total count and suggest narrowing filters or creating an audience via `/fiber:audience`

## Credit Cost

Search charges credits per result found (not per page). Check the current pricing at https://api.fiber.ai/docs/ or via the `llms://fiber.ai/llms.txt` MCP resource, as costs may change.

## Error Handling

- **MCP tool not available**: suggest checking MCP connection or running `/fiber:setup`
- **Authentication failure (401)**: direct user to `/fiber:setup` for API key configuration
- **Insufficient credits (402)**: direct user to top up at https://www.fiber.ai/app/subscription
- **No results found**: suggest broadening search criteria (fewer filters, wider location, etc.)
- **Rate limit hit (429)**: wait briefly and retry
