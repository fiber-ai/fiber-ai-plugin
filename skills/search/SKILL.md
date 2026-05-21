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

### Parameter & Schema Discovery

Fiber's search filter schemas are large and evolve across versions. **Never hardcode or guess field names.** Discover the current schema at runtime using one of these methods (in preference order):

1. **Installed SDK packages** (best when writing code):
   - TypeScript: `@fiberai/sdk` exports typed request/response models. Check `node_modules/@fiberai/sdk` types or use IDE autocomplete. Install: `npm install @fiberai/sdk`.
   - Python: `fiberai` ships typed model classes (e.g. `fiberai.models.CompanySearchBody`). Inspect with `help()` or IDE. Install: `pip install fiberai`.
2. **MCP runtime discovery** (best for chat/MCP flows):
   - Call `get_endpoint_details_full("companySearch")` or `get_endpoint_details_full("peopleSearch")` on the Core MCP to get the exact current schema with all filter fields.
3. **Online docs** (fallback):
   - Per-operation: `https://api.fiber.ai/ai-docs/companySearch.md` / `https://api.fiber.ai/ai-docs/peopleSearch.md`
   - Routing index: `https://api.fiber.ai/llms.txt`
   - Interactive: `https://api.fiber.ai/docs/`
   - Open-source examples: `https://github.com/fiber-ai/open-fiber`

Key structural notes (stable across versions):
- The request body wraps filters inside a `searchParams` object (not `filters`)
- Pagination uses `cursor` (not `page`) and `pageSize`
- `apiKey` is a required field in the request body
- Company references use canonicalized LinkedIn slugs — no case-normalization issues (e.g., "stripe" always means Stripe)
- Title matching uses typed seniority levels (`vp`, `director`, `c-level`, `manager`, etc.) — not regex
- Numeric filters use `lowerBound`/`upperBound` semantics, not custom operators
- Every response includes `chargeInfo` with exact credits charged

Example body structure (verify exact field names via methods above):
```json
{
  "apiKey": "...",
  "searchParams": { ... },
  "pageSize": 25,
  "cursor": null
}
```

### Natural-language search (when the user gives freeform prose)

If the user gives freeform intent (e.g., "VPs of Engineering at fintech startups in NYC") and you cannot extract clean filters, use Fiber's NL-to-query endpoints:

- `textToCompanySearch` — translates free text into resolved `companySearchParams` with canonicalized identifiers
- `textToProfileSearch` — translates free text into resolved `profileSearchParams` with typed seniority, job status, and entity-resolved companies

These endpoints save the entire filter-construction step. They resolve company names to LinkedIn org IDs and map role descriptions to typed seniority levels automatically.

## Authentication

Every API call requires `apiKey` in the request body. Check https://api.fiber.ai/docs/ for the exact authentication format for each endpoint. If the user hasn't configured authentication, direct them to run `/fiber:setup`.

## Result Formatting

- **Company results**: show name, domain, location, employee count, industry
- **People results**: show name, title, company, location, LinkedIn URL
- Always show the total number of results found
- If results exceed 25, mention the total count and suggest narrowing filters or creating an audience via `/fiber:audience`

## Credit Cost

Search charges credits per result found (not per page). Check the current pricing via the response's `chargeInfo` object, at <https://api.fiber.ai/ai-docs/companySearch.md> / <https://api.fiber.ai/ai-docs/peopleSearch.md>, or via the `llms://fiber.ai/llms.txt` MCP resource — costs may change.

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> — routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> — every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. Drop one of these straight into the LLM prompt instead of streaming the full OpenAPI spec. Examples for this skill:
  - <https://api.fiber.ai/ai-docs/companySearch.md>
  - <https://api.fiber.ai/ai-docs/peopleSearch.md>
  - <https://api.fiber.ai/ai-docs/jdToProfileSearch.md>
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## Error Handling

- **MCP tool not available**: suggest checking MCP connection or running `/fiber:setup`
- **Authentication failure (401)**: direct user to `/fiber:setup` for API key configuration
- **Insufficient credits (402)**: direct user to top up at https://www.fiber.ai/app/subscription
- **No results found**: suggest broadening search criteria (fewer filters, wider location, etc.)
- **Rate limit hit (429)**: wait briefly and retry
