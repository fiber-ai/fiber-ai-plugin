---
name: sdk-py
description: Help writing Python code using the fiberai package. Use when the user wants to build a Python application, script, or automation that calls Fiber AI APIs programmatically.
user-invocable: true
argument-hint: <what you want to build>
---

# Fiber AI Python SDK

Help the user write Python code using the `fiberai` package.

## When to Use

- User wants to BUILD something with Fiber AI in Python
- User says "python", "script", "automation", "data pipeline", "backend"
- User wants a custom integration, ETL pipeline, or automation

## Do Not Use When

- User just wants to search or enrich via chat — use `/fiber:search` or `/fiber:enrich` instead
- User wants to write TypeScript code — use `/fiber:sdk-ts` instead

## Quick Start

```python
import os
from fiberai import Client
from fiberai.api.search.company_search import sync as company_search_sync
from fiberai.models.company_search_body import CompanySearchBody

client = Client(base_url="https://api.fiber.ai")

result = company_search_sync(
    client=client,
    body=CompanySearchBody(
        api_key=os.environ["FIBER_API_KEY"],
        search_params={},  # Check https://api.fiber.ai/docs/ for filter schema
        page_size=25,
    ),
)
```

## Key Concepts

- The SDK provides typed functions for every API endpoint
- API functions are **standalone module functions**, not methods on the client — import them from `fiberai.api.{domain}.{operation}`
- Each module exports 4 variants: `sync`, `sync_detailed`, `asyncio`, `asyncio_detailed`
- Request bodies are **typed model classes** (not raw dicts) — import from `fiberai.models.{model_name}`
- `api_key` is a field on every body model (for POST) or query parameter (for GET) — not a header
- Search filters go inside `search_params` (not `filters`)
- Pagination uses `cursor` (not `page`)
- The `Client` and `AuthenticatedClient` are the two exported client classes

## Schema & Type Discovery

Fiber's request/response schemas are large and evolve across versions. The SDK is the best source of truth:

1. **From the installed package**: inspect `fiberai.models.<ModelName>` for every field. Use `help(fiberai.models.CompanySearchBody)` or IDE autocomplete to discover available fields for `search_params`, `enrichment_type`, etc. Model classes enforce correct field names at construction time.
2. **From online docs**: per-operation pages at `https://api.fiber.ai/ai-docs/<operationId>.md` describe every field with examples. Start with `https://api.fiber.ai/llms.txt` for routing.
3. **From MCP at runtime**: call `get_endpoint_details_full("<operationId>")` on the Core MCP to get the full current schema.
4. **Open-source examples**: `https://github.com/fiber-ai/open-fiber` has working code samples.

## Async Support

The same `Client` instance supports async via the `asyncio` function variant:

```python
import os
from fiberai import Client
from fiberai.api.search.company_search import asyncio as company_search_async
from fiberai.models.company_search_body import CompanySearchBody

client = Client(base_url="https://api.fiber.ai")

result = await company_search_async(
    client=client,
    body=CompanySearchBody(
        api_key=os.environ["FIBER_API_KEY"],
        search_params={},
        page_size=25,
    ),
)
```

There is no separate `AsyncClient` class. Use the `asyncio` or `asyncio_detailed` function variants with the same `Client`.

## Important Rules

- Always use environment variables for API keys — never hardcode secrets
- `api_key` goes in the body model (POST) or query params (GET), not as a header
- Body parameters must be constructed as typed model instances, not raw dicts
- The `Client` supports both sync and async via context managers
- Error responses are typed unions — check the response type or use `raise_on_unexpected_status=True` on the `Client` for automatic error raising (raises `errors.UnexpectedStatus`)
- Check https://api.fiber.ai/docs/ for current API schemas — parameters and response shapes may change between versions

## Detailed Examples

See the `references/` folder for:
- Full client setup with error handling
- Search, enrichment, and async patterns

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> — routing policy + critical rules (read before generating code).
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> — every public operation, grouped by tag. Use it to discover the right `operationId` for a task.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. Drop this straight into an LLM prompt — it describes request/response shapes, credit costs, and routing hints for that one operation.
- **Full corpus (RAG):** <https://api.fiber.ai/llms-full.txt> — every per-operation page concatenated for one-shot indexing.
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.
