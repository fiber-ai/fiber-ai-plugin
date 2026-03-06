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

### Individual Contact Enrichment

The primary endpoint for contact enrichment is `syncContactEnrichment` (`POST /v1/contact-details/sync`).

**Via Core MCP:**
1. Call `get_endpoint_details_full("syncContactEnrichment")` to get the exact parameter schema
2. Call `call_operation("syncContactEnrichment", {"body": {"apiKey": "...", "linkedinUrl": "...", "enrichmentType": {...}}})` with the correct parameters

**Via V2 MCP (if available as a generated tool):**
- Look for `syncContactEnrichment_tool` — it may be available depending on the server's tool generation priority

The `enrichmentType` object controls what data to fetch (e.g., work emails, personal emails, phone numbers). Always call `get_endpoint_details_full` to see the exact field names and options.

### Company Enrichment

For company data, the relevant operations include:
- `companyLiveEnrich` — live LinkedIn company data
- `kitchenSinkCompany` — comprehensive company profile lookup

**Via Core MCP:**
1. Call `get_endpoint_details_full("companyLiveEnrich")` or `get_endpoint_details_full("kitchenSinkCompany")` to see the schema
2. Call `call_operation("companyLiveEnrich", {"body": {...}})` with the correct parameters

### Batch Contact Enrichment (6-10+ contacts)

For multiple contacts (but not a full audience), use the batch endpoint:
- `startBatchContactEnrichment` — starts async batch processing
- `pollBatchContactEnrichment` — polls for results

For large-scale enrichment, recommend `/fiber:audience` instead.

## Important Rules

- **Always warn about credit cost before enriching.** Check current credit costs at https://api.fiber.ai/docs/ or via the `llms://fiber.ai/llms.txt` MCP resource, as costs vary by enrichment type and may change.
- For bulk enrichment (more than 5 contacts), suggest the `/fiber:audience` workflow instead — it's more efficient
- Show all revealed data fields clearly
- If a field was not found, say so explicitly rather than omitting it silently

## Authentication

`apiKey` is required in the request body for POST endpoints. Check https://api.fiber.ai/docs/ for the exact authentication format for each endpoint.

## Error Handling

- **Contact not found**: suggest trying alternative identifiers (LinkedIn URL is the most reliable identifier)
- **Insufficient credits (402)**: direct user to top up at https://www.fiber.ai/app/subscription
- **Authentication failure (401)**: direct user to `/fiber:setup`
- **Partial results**: show what was found and note which fields couldn't be resolved
