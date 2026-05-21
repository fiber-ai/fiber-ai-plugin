---
name: build-recruiting-audience
description: Build a recruiting-grade audience of candidates using Fiber AI - search, enrich work and personal emails, reveal phones, and export prospect CSVs. Use this when the user says "build a recruiting list", "find me candidates for role X at companies like Y", "talent audience", "recruiting audience", "sourcing list", "candidate outreach list", "recruiting prospect list", or otherwise asks for a saved, exportable list of people for hiring.
user-invocable: true
argument-hint: <role + target companies or JD - e.g. "staff iOS engineers at Series B fintechs">
---

# Fiber AI: Build a Recruiting Audience

Stand up a persistent, exportable audience optimized for recruiting - prospects first, company metadata as context. This is the right flow when the user wants a saved candidate list, not just a chat-time search.

## When to use

- User asks to "build a recruiting list", "talent audience", "sourcing list", "candidate pipeline"
- User wants to enrich hundreds or thousands of candidates with work + personal email + phone
- User wants a CSV export at the end, not just chat results
- User has a JD or a role spec and wants to find people who fit, at scale

## Do not use when

- User only needs 1-5 candidates revealed right now - use `/fiber:enrich`
- User just wants to see who exists without saving a list - use `/fiber:search` or `/fiber:find-and-enrich-by-role`
- User is enriching a seller / marketing list, not recruiting - use `/fiber:audience` (more generic)
- User wants to generate this in code - use `/fiber:sdk-ts` or `/fiber:sdk-py`

## Happy path

If the user pasted a JD instead of a structured brief, first sanity-check candidates with [`jdToProfileSearch`](https://api.fiber.ai/ai-docs/jdToProfileSearch.md) and show the top 10. Then move into the audience lifecycle:

1. Create the audience via [`createAudience`](https://api.fiber.ai/ai-docs/createAudience.md) in `DRAFT`. For people-first recruiting flows, set `creationMethod: START_FROM_PROSPECTS` so the audience prioritizes prospect results over companies. Save the `audienceId`.
2. Attach targeting via [`updateAudienceSearchParams`](https://api.fiber.ai/ai-docs/updateAudienceSearchParams.md) on the same `audienceId`. Recruiting-relevant `prospectSearchParams` fields typically include `seniority`, `departments`, `jobTitleV2`, `yearsOfExperience`, and `location`. Call `get_endpoint_details_full("updateAudienceSearchParams")` on the Core MCP for the exact current schema - do not guess field names. Echo the filters back to the user and confirm.
3. Get explicit user consent, then call [`buildAudience`](https://api.fiber.ai/ai-docs/buildAudience.md). Poll [`getAudienceStatus`](https://api.fiber.ai/ai-docs/getAudienceStatus.md) every 30 seconds until `status === "NORMAL"`. Report the prospect count when done.
4. Call [`estimateEnrichmentCost`](https://api.fiber.ai/ai-docs/estimateEnrichmentCost.md) selecting recruiter-relevant enrichment types (work emails, personal emails, phone numbers, and optionally live profile). This step is free.
5. Surface the estimate verbatim - total credits, breakdown, estimated duration - and get explicit user consent. Only then call [`triggerEnrichment`](https://api.fiber.ai/ai-docs/triggerEnrichment.md). Poll [`getEnrichmentStatus`](https://api.fiber.ai/ai-docs/getEnrichmentStatus.md) every 30 seconds until `progressPercent === 100`.
6. Export via [`exportProspects`](https://api.fiber.ai/ai-docs/exportProspects.md). Recruiting cares about prospects, not companies - skip [`exportCompanies`](https://api.fiber.ai/ai-docs/exportCompanies.md) unless the user asks.

## Cost & consent gates

This flow has two charged steps. Never auto-advance past either.

- `createAudience` and `updateAudienceSearchParams`: free.
- `buildAudience`: charges credits per entity found. Required script: "Building this audience will scan for prospects matching your filters and charge credits per match. Ready to build?" Wait for an explicit "yes".
- `estimateEnrichmentCost`: free, and never skippable. Always run it before `triggerEnrichment`.
- `triggerEnrichment`: charges credits per successful reveal. Required script: "The estimate is {totalCredits} credits ({breakdown}). Your balance is {getOrgCredits}. Proceed with enrichment?" Wait for an explicit "yes".
- Exports: free.

Call [`getOrgCredits`](https://api.fiber.ai/ai-docs/getOrgCredits.md) before presenting each estimate. If headroom looks thin, flag it.

## Error handling

- Build returns 0 prospects: widen filters. The most common mistake is over-constraining `jobTitleV2` - try broader seniority or additional departments. Do not re-build until filters change; re-builds charge again.
- Build status `ERROR`: check filter validity (enum mismatches are the usual cause), then create a fresh audience rather than mutating a failed one.
- Enrichment stalls at the same `progressPercent` for > 10 minutes: keep polling but tell the user and offer to wait or cancel. Never call `triggerEnrichment` twice on the same audience - it re-charges.
- User changes their mind on filters after build: filters cannot be edited post-build. Create a new audience.
- 402 insufficient credits during enrich: job may partially complete. Surface what was enriched and point to https://www.fiber.ai/app/subscription.
- Export returns empty CSV: confirm enrichment hit `progressPercent === 100` before exporting.
- Filter enum mismatch on `updateAudienceSearchParams` (e.g. a made-up industry string): the API will 400. Surface the error verbatim and use `getIndustries` / `getRegions` to show valid enum values.
- `creationMethod` set to `NORMAL` when the user wanted people-first: the audience will over-index on companies. Delete and recreate with `START_FROM_PROSPECTS`.

## Recruiting-specific tips

- Start tighter than you think - 50 great candidates beats 5,000 mediocre ones. Err on the side of narrower `seniority` + `yearsOfExperience` bands on the first pass.
- `jobTitleV2` accepts multiple normalized title variants; include common synonyms ("Staff Engineer", "Staff Software Engineer") rather than a single string.
- Personal emails matter more for recruiting than sales. Turn on the personal-email enrichment type in `estimateEnrichmentCost` unless the user explicitly opts out.
- If the user has a target-company list, pass it as an additional filter on `prospectSearchParams` rather than running two separate audiences.
- Recruiting searches across geographies often fail silently on missing `location` normalization - always surface the audience's post-build location histogram before triggering enrichment.
- Watch the `getRateLimits` response if the user is running several audiences back-to-back; polling cadence is not the bottleneck - per-org build concurrency is.

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> - routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> - every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. For this skill:
  - <https://api.fiber.ai/ai-docs/jdToProfileSearch.md>
  - <https://api.fiber.ai/ai-docs/createAudience.md>
  - <https://api.fiber.ai/ai-docs/updateAudienceSearchParams.md>
  - <https://api.fiber.ai/ai-docs/buildAudience.md>
  - <https://api.fiber.ai/ai-docs/getAudienceStatus.md>
  - <https://api.fiber.ai/ai-docs/estimateEnrichmentCost.md>
  - <https://api.fiber.ai/ai-docs/triggerEnrichment.md>
  - <https://api.fiber.ai/ai-docs/getEnrichmentStatus.md>
  - <https://api.fiber.ai/ai-docs/exportProspects.md>
  - <https://api.fiber.ai/ai-docs/getOrgCredits.md>
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## SDK usage (optional)

The full audience lifecycle is scripted in [`/fiber:sdk-ts`](../sdk-ts/SKILL.md) and [`/fiber:sdk-py`](../sdk-py/SKILL.md) reference folders. The agent path (MCP `call_operation`) is primary here - writing this as one-off code is rarely the right move for recruiting workflows. Use the SDK only when embedding this flow into a product.
