---
name: help
description: Show what Fiber AI can do and how to use it. Use when the user asks about Fiber AI capabilities, available commands, or needs general guidance.
user-invocable: true
argument-hint: (no arguments needed)
---

# Fiber AI — Capabilities and Commands

## What is Fiber AI?

Fiber AI provides B2B data enrichment APIs for finding companies, discovering prospects, and revealing verified contact information (work emails, phone numbers). It supports both direct API queries via MCP tools and programmatic access via TypeScript and Python SDKs.

## Available Commands

| Command | What It Does |
|---------|-------------|
| `/fiber:search "AI companies in NYC"` | Search for companies or people matching criteria |
| `/fiber:enrich "linkedin.com/in/someone"` | Reveal contact details (email, phone) for a person or company |
| `/fiber:audience "Series A fintech startups"` | Build a prospecting list with bulk search, enrichment, and export |
| `/fiber:sdk-ts "build a lead gen app"` | Get help writing TypeScript code with `@fiberai/sdk` |
| `/fiber:sdk-py "python enrichment script"` | Get help writing Python code with `fiberai` |
| `/fiber:setup` | Configure API key and verify MCP connection |
| `/fiber:help` | Show this help information |

## What You Can Do

### Search

Find companies by location, industry, employee count, tech stack, funding stage, and more. Find people by title, seniority, department, and company.

### Enrich

Reveal verified work emails and phone numbers for any professional via the three-tier contact reveal stack: `syncQuickContactReveal` (standard, balanced), `syncTurboContactEnrichment` (fastest, premium cost), or the async waterfall `triggerExhaustiveContactEnrichment` + `pollExhaustiveContactEnrichmentResult` (highest coverage). Get full company profiles via `companyLiveEnrich` or `kitchenSinkCompany`.

### Audiences (Bulk Operations)

Build prospecting lists at scale. The workflow: create audience, set search filters, build, poll status, estimate enrichment cost, enrich, poll enrichment status, export. Read the full guide via the MCP resource `llms://fiber.ai/docs/audience-workflow`.

### Build Applications

Use the TypeScript SDK (`@fiberai/sdk`) or Python SDK (`fiberai`) to build custom applications, integrations, or automations on top of Fiber AI APIs.

## MCP Architecture

Fiber AI provides two MCP endpoints:

- **V2** (`fiber-ai-v2`): Direct tools for high-priority operations like `companySearch_tool` and `peopleSearch_tool`. Best for common queries.
- **Core** (`fiber-ai-core`): 4 meta-tools (`search_endpoints`, `list_all_endpoints`, `get_endpoint_details_full`, `call_operation`) that give access to all 100+ API endpoints. Use `get_endpoint_details_full("operationId")` to discover exact schemas before calling any operation.

## Credit System

Most operations cost credits. Costs vary by operation type and may change. Check current pricing at https://api.fiber.ai/docs/ or read the `llms://fiber.ai/llms.txt` MCP resource. Always review cost estimates before bulk operations.

- **Check balance**: use `getOrgCredits` via Core MCP
- **Top up**: https://www.fiber.ai/app/subscription

## Useful Links

- **API Key**: https://fiber.ai/app/api
- **API Documentation**: https://api.fiber.ai/docs/
- **Credits and Billing**: https://www.fiber.ai/app/subscription

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> — routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> — every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. This is the canonical context to drop into an LLM prompt instead of streaming the full OpenAPI spec.
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index markdown at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.
