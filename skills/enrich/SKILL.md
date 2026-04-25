---
name: enrich
description: Enrich companies or contacts with emails, phone numbers, and detailed profiles using Fiber AI. Use when the user wants to reveal contact information or get more details about a company or person.
user-invocable: true
argument-hint: <what to enrich — a person, company, LinkedIn URL, or domain>
---

# Fiber AI Enrich

Reveal work emails, phone numbers, and detailed profiles for companies and individuals.

## When to Use

- User wants work emails or phone numbers for a specific person
- User provides a LinkedIn URL and wants contact details
- User wants to enrich a company profile (full details, tech stack, funding, etc.)
- User says "enrich", "reveal", "get email", "get phone", "find contact info", "look up contact"

## Do Not Use When

- User wants to search for companies or people they haven't identified yet — use `/fiber:search` instead
- User wants to enrich more than 5 contacts at once — use `/fiber:audience` instead
- User wants to write code for enrichment — use `/fiber:sdk-ts` or `/fiber:sdk-py` instead

## How to Execute

### Individual Contact Enrichment — routing policy

Fiber exposes three tiers for single-profile contact reveal. Pick by latency vs cost:

1. **Standard (default):** `syncQuickContactReveal` — `POST /v1/contact-details/single`. Balanced speed and cost. Start here.
2. **Premium (fastest, most expensive):** `syncTurboContactEnrichment` — `POST /v1/contact-details/turbo/sync`. Use when absolute latency matters.
3. **Async waterfall (highest coverage):** `triggerExhaustiveContactEnrichment` — `POST /v1/contact-details/exhaustive/start`. Returns a `taskId`; poll with `pollExhaustiveContactEnrichmentResult` (`GET /v1/contact-details/exhaustive/poll`). Use as a fallback when both sync tiers return nothing.

**Via Core MCP:**
1. Call `get_endpoint_details_full("syncQuickContactReveal")` to get the exact parameter schema.
2. Call `call_operation("syncQuickContactReveal", {"body": {"apiKey": "...", "linkedinUrl": "...", "enrichmentType": {...}}})`.

**Via V2 MCP (if available as a generated tool):**
- Look for `syncQuickContactReveal_tool` — it may be available depending on the server's tool generation priority.

The `enrichmentType` object controls what data to fetch (e.g., work emails, personal emails, phone numbers). Fiber's schemas are large and evolve across versions — never hardcode field names. Discover the current schema via:

1. **Installed SDK packages**: `@fiberai/sdk` (TypeScript) or `fiberai` (Python) export typed models with all fields. Install: `npm install @fiberai/sdk` / `pip install fiberai`.
2. **MCP**: call `get_endpoint_details_full("syncQuickContactReveal")` on the Core MCP for the exact current schema.
3. **Online docs**: `https://api.fiber.ai/ai-docs/syncQuickContactReveal.md`, `https://api.fiber.ai/llms.txt`, or `https://api.fiber.ai/docs/`.
4. **Open-source examples**: `https://github.com/fiber-ai/open-fiber`.

### Company Enrichment

For company data, the relevant operations include:
- `companyLiveEnrich` — live LinkedIn company data
- `kitchenSinkCompany` — comprehensive company profile lookup

**Via Core MCP:**
1. Call `get_endpoint_details_full("companyLiveEnrich")` or `get_endpoint_details_full("kitchenSinkCompany")` to see the schema
2. Call `call_operation("companyLiveEnrich", {"body": {...}})` with the correct parameters

### Batch Contact Enrichment (10–2,000 identifiers)

For multiple contacts (but not a full audience), use the batch endpoints:
- `startBatchContactDetails` — `POST /v1/contact-details/batch/start`. Starts async batch processing.
- `pollBatchContactDetails` — polls for results.

For larger-scale enrichment, recommend `/fiber:audience` instead.

## Important Rules

- **Always warn about credit cost before enriching.** Check current credit costs on the response's `chargeInfo` object, on `https://api.fiber.ai/ai-docs/<operationId>.md`, or via the `llms://fiber.ai/llms.txt` MCP resource — costs vary by enrichment type and change over time.
- For bulk enrichment (more than 5 contacts), suggest the `/fiber:audience` workflow instead — it's more efficient.
- Show all revealed data fields clearly.
- If a field was not found, say so explicitly rather than omitting it silently.

## Authentication

`apiKey` is required in the request body for POST endpoints. Check https://api.fiber.ai/docs/ for the exact authentication format for each endpoint.

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> — routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> — every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. Drop one of these straight into the LLM prompt instead of streaming the full OpenAPI spec. Examples for this skill:
  - <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md>
  - <https://api.fiber.ai/ai-docs/syncTurboContactEnrichment.md>
  - <https://api.fiber.ai/ai-docs/triggerExhaustiveContactEnrichment.md>
  - <https://api.fiber.ai/ai-docs/pollExhaustiveContactEnrichmentResult.md>
  - <https://api.fiber.ai/ai-docs/startBatchContactDetails.md> / <https://api.fiber.ai/ai-docs/pollBatchContactDetails.md>
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index markdown at the same URL (Stripe pattern) instead of the full JSON.
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## Error Handling

- **Contact not found**: suggest trying alternative identifiers (LinkedIn URL is the most reliable identifier), then escalate to the exhaustive tier.
- **Insufficient credits (402)**: direct user to top up at https://www.fiber.ai/app/subscription.
- **Authentication failure (401)**: direct user to `/fiber:setup`.
- **Partial results**: show what was found and note which fields couldn't be resolved.
