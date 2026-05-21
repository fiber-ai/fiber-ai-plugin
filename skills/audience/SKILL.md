---
name: audience
description: Create and manage Fiber AI audiences for bulk operations — search, enrich, and export lists of companies or contacts at scale. Use when the user wants to build a prospecting list or do bulk data operations.
user-invocable: true
argument-hint: <describe the audience you want to build>
---

# Fiber AI Audience Workflow

Audiences are the core workflow for bulk operations in Fiber AI. They allow searching, enriching, and exporting lists at scale.

For the complete, up-to-date workflow guide, read the MCP resource `llms://fiber.ai/docs/audience-workflow` via the Core MCP.

## When to Use

- User wants to build a prospecting list
- User wants to bulk enrich contacts (more than 5 people)
- User wants to export data to CSV or download a list
- User says "create audience", "build list", "bulk enrich", "export", "prospecting list"

## Do Not Use When

- User wants to search without saving results — use `/fiber:search` instead
- User wants to enrich a single contact — use `/fiber:enrich` instead
- User wants to write code for audience management — use `/fiber:sdk-ts` or `/fiber:sdk-py` instead

## The Audience Lifecycle

Each step must be completed in order. Do not skip steps. Build and enrichment are async — you must poll for completion.

```
Create → Set Search Params → Build → Poll Build Status → Estimate Cost → Enrich → Poll Enrichment Status → Export
```

## How to Execute

All audience operations must go through the **Core MCP** using `call_operation`. They are not available as V2 direct tools.

Before calling any operation, use `get_endpoint_details_full("operationId")` to get the exact parameter schema. Parameters change over time — do not guess field names.

### Step 1: Create Audience

- operationId: `createAudience`
- Method: `POST /v1/audiences/create`
- `apiKey` goes in the request body
- Save the returned audience ID for all subsequent steps
- Confirm creation with the user

### Step 2: Set Search Parameters

- operationId: `updateAudienceSearchParams`
- Method: `PATCH /v1/audiences/{audienceId}/search-params`
- `apiKey` goes in the request body
- The body contains `companySearchParams` and/or `prospectSearchParams` — these are separate filter objects with different schemas
- Call `get_endpoint_details_full("updateAudienceSearchParams")` to see available filter fields
- Show the user what filters were applied and confirm before proceeding
- Can only be set while audience status is `DRAFT`

### Step 3: Build the Audience

- operationId: `buildAudience`
- Method: `POST /v1/audiences/{audienceId}/build`
- **This step charges credits — always confirm with the user first**
- Credits are charged per company found and per profile found
- Only after explicit confirmation: call the operation
- Status transitions: `DRAFT` → `BUILDING` → `NORMAL` (or `FAILED`)

### Step 4: Poll Build Status

- **Build is async — you must poll until complete**
- Call `call_operation("getAudience", {"query": {"apiKey": "..."}, "path": {"audienceId": "..."}})` or equivalent to check audience status
- Wait until status becomes `NORMAL` before proceeding
- Poll every 10-30 seconds
- Report the number of entities found once build completes

### Step 5: Estimate Enrichment Cost

- operationId: `estimateEnrichmentCost`
- Method: `POST /v1/audiences/{audienceId}/enrichment/estimate`
- Call `get_endpoint_details_full("estimateEnrichmentCost")` for parameters including enrichment type options and limits
- Present the estimate clearly: number of contacts, cost breakdown, total credits needed
- **Always get user confirmation before proceeding to enrichment**
- This step is free (no credits charged)

### Step 6: Enrich

- operationId: `triggerEnrichment`
- Method: `POST /v1/audiences/{audienceId}/enrich`
- Only after the user confirms the cost estimate
- Call `get_endpoint_details_full("triggerEnrichment")` for exact parameters
- Enrichment types include work emails, personal emails, phone numbers, live profile enrichment, and more

### Step 7: Poll Enrichment Status

- **Enrichment is async — you must poll until complete**
- operationId: `getEnrichmentStatus`
- Method: `GET /v1/audiences/{audienceId}/enrichment/status`
- `apiKey` goes in the **query string** (not body) for GET requests
- Poll every 30 seconds until enrichment is complete
- Report progress percentage to the user

### Step 8: Export

Two separate export endpoints exist:
- operationId: `exportCompanies` — `POST /v1/audiences/{audienceId}/export/companies`
- operationId: `exportProspects` — `POST /v1/audiences/{audienceId}/export/prospects`
- Provide the download link to the user
- This step is free (no credits charged)

## Important Rules

- **NEVER skip the cost estimate step** — always show costs and get confirmation before any credit-charging operation
- **NEVER proceed to build or enrich without explicit user confirmation**
- **Always poll for completion** after build and enrichment — they are async operations
- Show the audience summary at each step: name, filter count, entity count, status
- If the user seems unsure about costs, suggest checking their credit balance first via `getOrgCredits`
- Keep the user informed of which step they are on in the lifecycle

## Authentication

- For POST/PATCH endpoints: `apiKey` is in the **request body**
- For GET endpoints: `apiKey` is in the **query string**
- Check https://api.fiber.ai/docs/ for exact auth format per endpoint

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> — routing policy + critical rules (the canonical audience lifecycle is documented here).
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> — every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. Drop one of these straight into the LLM prompt instead of streaming the full OpenAPI spec. Audience lifecycle operations:
  - <https://api.fiber.ai/ai-docs/createAudience.md>
  - <https://api.fiber.ai/ai-docs/updateAudienceSearchParams.md>
  - <https://api.fiber.ai/ai-docs/buildAudience.md>
  - <https://api.fiber.ai/ai-docs/estimateEnrichmentCost.md>
  - <https://api.fiber.ai/ai-docs/triggerEnrichment.md>
  - <https://api.fiber.ai/ai-docs/getEnrichmentStatus.md>
  - <https://api.fiber.ai/ai-docs/exportCompanies.md> / <https://api.fiber.ai/ai-docs/exportProspects.md>
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## Error Handling

- **Audience creation fails**: check API key and permissions via `/fiber:setup`
- **Build finds 0 results**: suggest broadening search criteria (fewer filters, wider location range)
- **Enrichment too expensive**: suggest reducing audience size, narrowing filters, or selecting fewer enrichment types
- **Export fails**: verify the audience has been enriched and enrichment status is complete before attempting export
- **Build status FAILED**: check search parameters and retry, or create a new audience
