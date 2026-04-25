---
name: find-and-enrich-by-role
description: Find prospects by role + company criteria and enrich a shortlist with contact details using Fiber AI. Use this when the user says "find VPs of Engineering at fintech startups", "CMOs at Series B SaaS", "heads of sales at X companies", "find me 20 CTOs in healthcare", "prospect by role + company", "sales target research", or otherwise wants to discover people by role and immediately get emails / phones back.
user-invocable: true
argument-hint: <role + company criteria - e.g. "VPs of Engineering at Series B fintechs in NYC">
---

# Fiber AI: Find and Enrich By Role

Discover prospects by role and company, then reveal contact details for the shortlist the user actually wants to reach. The default sales-prospecting combo skill.

## When to use

- User asks for people by role + company criteria ("VPs of Eng at fintech startups")
- User wants a short, chat-time list (under 50 rows) with emails/phones attached
- User says "prospect by role", "sales target research", "find me N <role>s in <industry>"
- User wants a quick pass before deciding whether to build a full audience

## Do not use when

- User wants a saved, exportable list of 100+ prospects - use `/fiber:audience` or `/fiber:build-recruiting-audience`
- User already has LinkedIn URLs - use `/fiber:enrich-linkedin-csv`
- User only wants to search, not reveal contacts - use `/fiber:search`
- User wants code - use `/fiber:sdk-ts` or `/fiber:sdk-py`

## Happy path

One search entry, one shared enrichment tail.

1. Map the user's brief into `peopleSearch`'s `searchParams`. If the user only gave freeform prose (e.g. "VPs of Engineering at Series B fintechs in NYC") and you cannot extract clean filters, hand the whole prompt to the Core MCP `search_endpoints` meta-tool so it picks the correct route; do not invent fields. Run `get_endpoint_details_full("peopleSearch")` on the Core MCP for the current `searchParams` schema.
2. Call [`peopleSearch`](https://api.fiber.ai/ai-docs/peopleSearch.md) with the mapped filters. Always echo the filters you used back to the user in one line so they can correct before paginating ("using: title=VP Engineering, industry=Fintech, funding=Series B, location=NYC - edit or proceed?").
3. Before paginating, call [`peopleSearchCount`](https://api.fiber.ai/ai-docs/peopleSearchCount.md) with the same filters and surface the total ("4,120 people match - show page 1 of 25, or narrow first?"). Never silently page past page 1. Keep `pageSize <= 50`.
4. User picks a shortlist (typically <= 25). For each row, call [`syncQuickContactReveal`](https://api.fiber.ai/ai-docs/syncQuickContactReveal.md). For shortlists of 26-500, use [`startBatchContactDetails`](https://api.fiber.ai/ai-docs/startBatchContactDetails.md) + [`pollBatchContactDetails`](https://api.fiber.ai/ai-docs/pollBatchContactDetails.md) instead - cheaper per row and async.
5. If the shortlist grows past ~50 or the user asks to export, stop and hand off to [`/fiber:build-recruiting-audience`](../build-recruiting-audience/SKILL.md) or [`/fiber:audience`](../audience/SKILL.md). Those flows are cheaper and more robust at that scale.

## Cost & consent gates

- `peopleSearch`: charges credits per result returned. Never paginate without first showing `peopleSearchCount` and asking.
- `peopleSearchCount`: free.
- `syncQuickContactReveal`: charges per reveal. Required script before looping: "Reveal work emails for these N prospects? Estimated cost: ~N x <credit-cost> credits. Proceed?"
- `startBatchContactDetails`: charges per reveal but generally cheaper per row than sync loops. Required script: "Batch-reveal contact details for all N prospects. Estimated cost: ~N x <credit-cost> credits (partial results stream back). Proceed?"
- Check [`getOrgCredits`](https://api.fiber.ai/ai-docs/getOrgCredits.md) before any multi-row reveal.

Never run a reveal without the user seeing the shortlist first. Search results and contact reveals are charged separately - do not combine them into a single prompt that looks like one action.

## Error handling

- Filter mapping was ambiguous (common on titles like "head of engineering"): show the user the exact filters you used and let them correct, then re-run.
- `peopleSearchCount` returns 0: relax the narrowest filter (usually seniority or funding). Confirm the new count before re-running search.
- `peopleSearchCount` returns >10,000: the query is too broad; suggest adding an industry, headcount band, or location constraint, or switching to the audience flow for anything at that scale.
- Reveal returns no contact on some rows: flag the miss in the output table. Offer [`triggerExhaustiveContactEnrichment`](https://api.fiber.ai/ai-docs/triggerExhaustiveContactEnrichment.md) + [`pollExhaustiveContactEnrichmentResult`](https://api.fiber.ai/ai-docs/pollExhaustiveContactEnrichmentResult.md) as the fallback - confirm extra cost first.
- 402 insufficient credits: stop, show balance from `getOrgCredits`, point to https://www.fiber.ai/app/subscription.
- 429 rate limited during the sync reveal loop: back off 30s, resume, or switch to batch.
- User keeps adding filters after each page: re-run `peopleSearchCount` on every filter change rather than paginating through a stale result set.

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> - routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> - every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. For this skill:
  - <https://api.fiber.ai/ai-docs/peopleSearch.md>
  - <https://api.fiber.ai/ai-docs/peopleSearchCount.md>
  - <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md>
  - <https://api.fiber.ai/ai-docs/startBatchContactDetails.md>
  - <https://api.fiber.ai/ai-docs/pollBatchContactDetails.md>
  - <https://api.fiber.ai/ai-docs/triggerExhaustiveContactEnrichment.md>
  - <https://api.fiber.ai/ai-docs/pollExhaustiveContactEnrichmentResult.md>
  - <https://api.fiber.ai/ai-docs/getOrgCredits.md>
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## SDK usage (optional)

TypeScript:

```typescript
import { createClient, peopleSearch, syncQuickContactReveal } from "@fiberai/sdk";

const client: ReturnType<typeof createClient> = createClient({ baseUrl: "https://api.fiber.ai" });
const apiKey: string = process.env.FIBER_API_KEY!;

const search: Awaited<ReturnType<typeof peopleSearch>> = await peopleSearch({
  client,
  body: { apiKey, searchParams: {}, pageSize: 25 },
});

const reveal: Awaited<ReturnType<typeof syncQuickContactReveal>> = await syncQuickContactReveal({
  client,
  body: { apiKey, linkedinUrl: "https://www.linkedin.com/in/example" },
});
```

Python (search step shown below; check if your installed `fiberai` package exports `syncQuickContactReveal` for the reveal step - if not, call `/v1/contact-details/single` directly or via the MCP):

```python
import os
from fiberai import Client
from fiberai.api.search.people_search import sync as people_search_sync
from fiberai.models.people_search_body import PeopleSearchBody

client: Client = Client(base_url="https://api.fiber.ai")
api_key: str = os.environ["FIBER_API_KEY"]

search = people_search_sync(client=client, body=PeopleSearchBody(api_key=api_key, search_params={}, page_size=25))
```
