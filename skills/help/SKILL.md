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

### General skills

| Command | What It Does |
|---------|-------------|
| `/fiber:quickstart` | Guided first-run: verify key, search companies, reveal one contact |
| `/fiber:search "AI companies in NYC"` | Search for companies or people matching criteria |
| `/fiber:enrich "linkedin.com/in/someone"` | Reveal contact details (email, phone) for a person or company |
| `/fiber:audience "Series A fintech startups"` | Build a prospecting list with bulk search, enrichment, and export |
| `/fiber:sdk-ts "build a lead gen app"` | Get help writing TypeScript code with `@fiberai/sdk` |
| `/fiber:sdk-py "python enrichment script"` | Get help writing Python code with `fiberai` |
| `/fiber:setup` | Configure API key and verify MCP connection |
| `/fiber:help` | Show this help information |

### Playbook skills (workflow-specific)

| Command | What It Does |
|---------|-------------|
| `/fiber:find-similar-companies "Stripe"` | Find lookalike companies from a seed account |
| `/fiber:enrich-linkedin-csv` | Bulk enrich LinkedIn URLs with emails and phones |
| `/fiber:build-recruiting-audience "staff iOS engineers at Series B fintechs"` | Build a persistent, exportable recruiting candidate list |
| `/fiber:expand-from-email-list` | Reverse-resolve emails to LinkedIn profiles |
| `/fiber:enrich-github-handles` | Developer sourcing: GitHub handles to LinkedIn to contact details |
| `/fiber:find-and-enrich-by-role "VP Eng at fintech"` | Find people by role + company criteria and reveal contacts |
| `/fiber:track-signals "job-change alerts for these 200 accounts"` | Track job changes, hiring intent, social activity, and funding |
| `/fiber:benchmark-vs-competitor "100 LinkedIn URLs vs PDL"` | Run a reproducible, honest benchmark vs a competing provider |

## What You Can Do

### Search

Find companies by location, industry, employee count, tech stack, funding stage, and more. Find people by title, seniority, department, and company.

### Enrich

Reveal verified work emails and phone numbers for any professional via the three-tier contact reveal stack: `syncQuickContactReveal` (standard, balanced), `syncTurboContactEnrichment` (fastest, premium cost), or the async waterfall `triggerExhaustiveContactEnrichment` + `pollExhaustiveContactEnrichmentResult` (highest coverage). Get full company profiles via `companyLiveEnrich` or `kitchenSinkCompany`.

### Audiences (Bulk Operations)

Build prospecting lists at scale. The workflow: create audience, set search filters, build, poll status, estimate enrichment cost, enrich, poll enrichment status, export. Read the full guide via the MCP resource `llms://fiber.ai/docs/audience-workflow`.

### Build Applications

Use the TypeScript SDK (`@fiberai/sdk`) or Python SDK (`fiberai`) to build custom applications, integrations, or automations on top of Fiber AI APIs.

### Persona subagents (invoke via `@<name>`)

| Persona | Who it is |
|---------|-----------|
| `@ai-recruiter` | Senior recruiter: sourcing, JD to pipeline, GitHub + LinkedIn crosswalk |
| `@ai-sdr` | Senior SDR: outbound lists, ICP, buyer identification, list pruning |
| `@gtm-strategist` | Head of GTM: pipeline math, market sizing, ABM strategy, scoping |
| `@signal-scout` | Signal operator: job-change / hiring / social / funding alerts |
| `@data-quality-auditor` | Data analyst: honest, pre-registered benchmarks vs competing providers |
| `@product-engineer` | Product engineer: signup enrichment, real-time API integration, identity resolution |
| `@fiber-sde` | Software engineer: SDK usage, scripts, automations, custom integrations |

## MCP Architecture

Fiber AI provides three MCP endpoints:

- **V2** (`fiber-ai-v2`): Direct tools for high-priority operations like `companySearch_tool` and `peopleSearch_tool`. Best for common queries.
- **V3** (`fiber-ai-v3`): Direct tools for every public operation with compact descriptions. OAuth / SSO auth.
- **Core** (`fiber-ai-core`): 5 meta-tools (`search_endpoints`, `list_tag_packs`, `list_all_endpoints`, `get_endpoint_details_full`, `call_operation`) that give access to all 100+ API endpoints. Use `get_endpoint_details_full("operationId")` to discover exact schemas before calling any operation.

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
