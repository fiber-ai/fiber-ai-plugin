---
name: find-similar-companies
description: Find lookalike companies from one or more seed accounts using Fiber AI. Use this when the user says "find companies like <seed>", "competitors of <seed>", "similar to <seed>", "lookalike accounts", "companies that look like our best customers", "ABM lookalikes", "seed-based company search", or otherwise asks to expand a known account into a larger candidate list.
user-invocable: true
argument-hint: <one or more seed companies - domain, URL, or name>
---

# Fiber AI: Find Similar Companies

Expand one or more seed accounts into a ranked list of lookalike companies. Resolve the seed to a canonical record, extract its signals (industry, headcount, keywords), then use those signals as filters for a broader search.

## When to use

- User names a specific company and asks for competitors, lookalikes, or similar firms
- User is building an ABM list seeded from a star customer
- User says "find companies like ...", "competitors of ...", "similar to ...", "lookalike accounts", "seed-based company search"
- User wants to expand a customer list into a prospect list using existing accounts as templates

## Do not use when

- User only needs a filter-based search without a seed account - use `/fiber:search`
- User wants to enrich a single known company with contact data - use `/fiber:enrich`
- User wants to build a persistent, exportable list of 500+ companies - use `/fiber:audience`
- User asked for code, not chat results - use `/fiber:sdk-ts` or `/fiber:sdk-py`

## Happy path

1. Resolve each seed to a canonical company record via [`kitchenSinkCompany`](https://api.fiber.ai/ai-docs/kitchenSinkCompany.md). Pass whatever the user gave (domain, LinkedIn URL, or name) and read back industries, headcount band, keywords, and region.
2. Confirm the extracted signals with the user in one line (e.g. "seed resolves to: productivity SaaS, 501-1000 employees, remote-first - expand on these?"). Let them trim or add filters.
3. Build filters and call [`companySearch`](https://api.fiber.ai/ai-docs/companySearch.md) with the signals the user confirmed. If the user only gave a freeform description ("in US, Series A+, fintech"), hand the whole prompt to the Core MCP `search_endpoints` meta-tool - it will pick the right route - rather than hand-authoring a natural-language query endpoint.
4. Before paginating, call [`companyCount`](https://api.fiber.ai/ai-docs/companyCount.md) with the same filters and surface the total ("2,314 companies match - want page 1 of 47?"). Never silently page past page 1.
5. For the shortlist the user picks (<= 5 companies), optionally call [`companyLiveEnrich`](https://api.fiber.ai/ai-docs/companyLiveEnrich.md) per row to pull the freshest LinkedIn record (funding, recent headcount, tech stack hints).

Always call `get_endpoint_details_full("<operationId>")` on the Core MCP before constructing the request body - the filter schema evolves.

## Cost & consent gates

- `kitchenSinkCompany`: charges credits per resolved company. Run once per seed.
- `companySearch`: charges credits per result returned. Keep `pageSize <= 50`. Always show `companyCount` first.
- `companyCount`: free.
- `companyLiveEnrich`: charges per call. Before running, ask: "Pull live LinkedIn data for these N companies? This will cost ~N x <credit-cost> credits."

Before pagination beyond page 1, confirm: "I found {count} companies matching these filters. Want me to pull the next page, or should we narrow first?"

## Error handling

- Seed does not resolve (ambiguous name): ask the user for a domain or LinkedIn URL and retry `kitchenSinkCompany`.
- `companyCount` returns 0: relax the narrowest filter first (usually headcount or region) and show the new count before re-running search.
- `companyCount` returns >5,000: the filters are too broad; ask the user to add an industry, funding, or keyword constraint before paginating.
- `companyLiveEnrich` 402 (insufficient credits): stop and surface `getOrgCredits` balance, then point the user at https://www.fiber.ai/app/subscription.
- Rate limited (429) during pagination: back off for 30s, then resume with the returned `cursor`.
- User gave a seed with no clear industry (e.g. a holding company): surface the `kitchenSinkCompany` output and ask which signal to lock on before searching.

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> - routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> - every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. Drop one of these into the LLM prompt instead of streaming the full OpenAPI spec. For this skill:
  - <https://api.fiber.ai/ai-docs/kitchenSinkCompany.md>
  - <https://api.fiber.ai/ai-docs/companySearch.md>
  - <https://api.fiber.ai/ai-docs/companyCount.md>
  - <https://api.fiber.ai/ai-docs/companyLiveEnrich.md>
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## SDK usage (optional)

TypeScript:

```typescript
import { createClient, kitchenSinkCompany, companySearch } from "@fiberai/sdk";

const client: ReturnType<typeof createClient> = createClient({ baseUrl: "https://api.fiber.ai" });
const apiKey: string = process.env.FIBER_API_KEY!;

const seed: Awaited<ReturnType<typeof kitchenSinkCompany>> = await kitchenSinkCompany({
  client,
  body: { apiKey, domain: "example.com" },
});

// Use the seed's signals as filters for the lookalike search
const lookalikes: Awaited<ReturnType<typeof companySearch>> = await companySearch({
  client,
  body: {
    apiKey,
    searchParams: {
      industries: seed.data?.industries,       // e.g. ["Software"]
      headcountRange: seed.data?.headcountRange, // e.g. { min: 50, max: 500 }
      countries: seed.data?.country ? [seed.data.country] : undefined,
    },
    pageSize: 25,
  },
});
```

Python:

```python
import os
from fiberai import Client
from fiberai.api.kitchen_sink.kitchen_sink_company import sync as kitchen_sink_company_sync
from fiberai.api.search.company_search import sync as company_search_sync
from fiberai.models.kitchen_sink_company_body import KitchenSinkCompanyBody
from fiberai.models.company_search_body import CompanySearchBody

client: Client = Client(base_url="https://api.fiber.ai")
api_key: str = os.environ["FIBER_API_KEY"]

seed = kitchen_sink_company_sync(client=client, body=KitchenSinkCompanyBody(api_key=api_key, domain="example.com"))
# Use the seed's signals as filters for the lookalike search
results = company_search_sync(
    client=client,
    body=CompanySearchBody(
        api_key=api_key,
        search_params={
            "industries": seed.industries,          # e.g. ["Software"]
            "headcount_range": seed.headcount_range, # e.g. {"min": 50, "max": 500}
            "countries": [seed.country] if seed.country else None,
        },
        page_size=25,
    ),
)
```
