---
name: enrich-linkedin-csv
description: Enrich a list of LinkedIn URLs with work emails, personal emails, and phone numbers using Fiber AI. Use this when the user says "enrich these LinkedIn URLs", "I have a CSV of people", "bulk reveal emails for these profiles", "get contact info for this list", "decorate these contacts with phone/email", or otherwise hands over a set of LinkedIn identifiers and wants contact data back.
user-invocable: true
argument-hint: <a list of LinkedIn URLs - paste, CSV path, or count>
---

# Fiber AI: Enrich a List of LinkedIn URLs

Take a list of LinkedIn URLs and return work emails, personal emails, and phone numbers. Route by list size so cost and latency stay predictable.

## When to use

- User pastes or attaches 2+ LinkedIn URLs and asks for emails or phones
- User has a CSV of profiles and wants it decorated
- User says "bulk reveal", "enrich these profiles", "get contact info for this list"
- User needs contact details for a discrete set of known people (not a search query)

## Do not use when

- User has just one profile to enrich - use `/fiber:enrich`
- User is still figuring out who to target - use `/fiber:search` or `/fiber:find-and-enrich-by-role`
- User needs an exportable list with company data too - use `/fiber:audience` or `/fiber:build-recruiting-audience`
- User wants to generate enrichment code - use `/fiber:sdk-ts` or `/fiber:sdk-py`

## Happy path

Route strictly by list size. Never upgrade the user to turbo by default.

1. **1-5 URLs** - loop [`syncQuickContactReveal`](https://api.fiber.ai/ai-docs/syncQuickContactReveal.md) one at a time. If the user explicitly asks for the fastest possible return and accepts higher cost, use [`syncTurboContactEnrichment`](https://api.fiber.ai/ai-docs/syncTurboContactEnrichment.md) instead.
2. **10-2,000 URLs** - call [`startBatchContactDetails`](https://api.fiber.ai/ai-docs/startBatchContactDetails.md) once with the full list, then poll [`pollBatchContactDetails`](https://api.fiber.ai/ai-docs/pollBatchContactDetails.md) no more often than every 5 seconds. Surface partial results between polls so the user sees progress.
3. **2,000+ URLs, or needs persistent storage / CSV export** - hand off to [`/fiber:build-recruiting-audience`](../build-recruiting-audience/SKILL.md) or [`/fiber:audience`](../audience/SKILL.md). Those flows handle export, dedup, and long-term list management.
4. **Misses (any size)** - for rows that returned no contact, fall back to [`triggerExhaustiveContactEnrichment`](https://api.fiber.ai/ai-docs/triggerExhaustiveContactEnrichment.md) and poll [`pollExhaustiveContactEnrichmentResult`](https://api.fiber.ai/ai-docs/pollExhaustiveContactEnrichmentResult.md) every 5-15 seconds. Only do this after confirming extra cost with the user.

For the 6-9 URL grey zone, prefer `startBatchContactDetails` - the batch endpoint is cheaper per row than looping sync calls.

Before any reveal, ask the user which enrichment types they want (work email, personal email, phone) — each one is priced separately. Call `get_endpoint_details_full("syncQuickContactReveal")` to surface current `enrichmentType` field names. Every response includes `chargeInfo` with exact credits charged, so agents can track and audit cost per row programmatically. All enrichment tiers work on standard self-serve API keys — no enterprise gate required.

## Cost & consent gates

Every operation in this skill except the poll endpoints charges credits. Confirm before running.

- Before `syncQuickContactReveal` loop: "Reveal work emails for these N profiles? Estimated cost: ~N x <credit-cost> credits. Proceed?"
- Before `startBatchContactDetails`: "Batch-reveal contact details for all N profiles. Estimated cost: ~N x <credit-cost> credits (partial results stream back). Proceed?"
- Before `syncTurboContactEnrichment`: explicitly flag that turbo costs more than quick. Never pick it silently.
- Before `triggerExhaustiveContactEnrichment` on misses: "We found nothing on M of the N rows. Run the exhaustive waterfall on those M? Each success charges credits; misses do not."
- Always call [`getOrgCredits`](https://api.fiber.ai/ai-docs/getOrgCredits.md) first if the user hasn't confirmed they have headroom.

## Error handling

- 402 insufficient credits: stop immediately, show current balance from `getOrgCredits`, and point the user to https://www.fiber.ai/app/subscription.
- 401 auth failure: direct the user to `/fiber:setup`.
- Individual row returns no contact: flag the miss in the output table rather than silently dropping it. Offer the exhaustive fallback.
- Batch job stalls in `PENDING` > 10 minutes: keep polling but tell the user and ask whether to wait or cancel. Do not re-trigger - you will double-charge.
- 429 rate limited during the sync loop: back off 30s and resume. If it repeats, switch to the batch endpoint.
- LinkedIn URL looks malformed (not `https://www.linkedin.com/in/...`): normalize or ask the user to fix before submitting; the API will 400 on bad URLs.

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> - routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> - every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. For this skill:
  - <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md>
  - <https://api.fiber.ai/ai-docs/syncTurboContactEnrichment.md>
  - <https://api.fiber.ai/ai-docs/startBatchContactDetails.md>
  - <https://api.fiber.ai/ai-docs/pollBatchContactDetails.md>
  - <https://api.fiber.ai/ai-docs/triggerExhaustiveContactEnrichment.md>
  - <https://api.fiber.ai/ai-docs/pollExhaustiveContactEnrichmentResult.md>
  - <https://api.fiber.ai/ai-docs/getOrgCredits.md>
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## SDK usage (optional)

TypeScript - sync single path (loop with a small concurrency cap):

```typescript
import { createClient, syncQuickContactReveal } from "@fiberai/sdk";

const client: ReturnType<typeof createClient> = createClient({ baseUrl: "https://api.fiber.ai" });
const apiKey: string = process.env.FIBER_API_KEY!;
const urls: string[] = ["https://www.linkedin.com/in/example"];

for (const url of urls) {
  const result: Awaited<ReturnType<typeof syncQuickContactReveal>> = await syncQuickContactReveal({
    client,
    body: { apiKey, linkedinUrl: url },
  });
  console.log(result.data);
}
```

The batch endpoints (`startBatchContactDetails` + `pollBatchContactDetails`) are available at `https://api.fiber.ai/ai-docs/startBatchContactDetails.md` and `https://api.fiber.ai/ai-docs/pollBatchContactDetails.md`. Check if your installed `@fiberai/sdk` version exports these functions; if not, call them via `fetch` or the MCP.

Python - check if your installed `fiberai` package exports `syncQuickContactReveal` (inspect `fiberai.api.contact_details`). If not available in your version, call the endpoint directly with `httpx` or use the MCP:

```python
import os
import httpx

urls: list[str] = ["https://www.linkedin.com/in/example"]
api_key: str = os.environ["FIBER_API_KEY"]

with httpx.Client(base_url="https://api.fiber.ai", timeout=60.0) as client:
    for url in urls:
        response: httpx.Response = client.post(
            "/v1/contact-details/single",
            json={"apiKey": api_key, "linkedinUrl": url},
        )
        response.raise_for_status()
        print(response.json())
```
