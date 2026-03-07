---
name: fiber-search
description: Search for companies or people using Fiber AI MCP tools
---

Search for companies or people matching the user's criteria using Fiber AI.

Use the Fiber AI MCP tools to execute the search:
- For company search: use `companySearch_tool` (V2) or `call_operation("companySearch", ...)` (Core)
- For people search: use `peopleSearch_tool` (V2) or `call_operation("peopleSearch", ...)` (Core)

Before constructing parameters, call `get_endpoint_details_full("companySearch")` or `get_endpoint_details_full("peopleSearch")` via the Core MCP to get the exact parameter schema.

Key structural notes:
- `apiKey` is required in the request body
- Search filters go inside `searchParams` (not `filters`)
- Pagination uses `cursor` and `pageSize`

Present results in a clean table. Suggest next steps: enrich contacts or build an audience.
