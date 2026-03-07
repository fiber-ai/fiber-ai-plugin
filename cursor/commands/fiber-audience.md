---
name: fiber-audience
description: Build a prospecting list with bulk search, enrichment, and export using Fiber AI audiences
---

Walk the user through the Fiber AI audience workflow for bulk operations.

All audience operations use the Core MCP via `call_operation`. Call `get_endpoint_details_full` for each operationId before constructing parameters.

The 8-step lifecycle (do not skip steps):

1. **Create**: `call_operation("createAudience", {"body": {"apiKey": "...", "name": "..."}})` — save the audience ID
2. **Set filters**: `call_operation("updateAudienceSearchParams", {"body": {...}, "path": {"audienceId": "..."}})` — uses `companySearchParams` and `prospectSearchParams`
3. **Build**: `call_operation("buildAudience", ...)` — charges credits, CONFIRM with user first
4. **Poll build status**: check audience status until `NORMAL` (poll every 10-30s)
5. **Estimate cost**: `call_operation("estimateEnrichmentCost", ...)` — free, show estimate to user
6. **Enrich**: `call_operation("triggerEnrichment", ...)` — charges credits, CONFIRM with user first
7. **Poll enrichment**: `call_operation("getEnrichmentStatus", {"query": {"apiKey": "..."}, "path": {"audienceId": "..."}})` — poll every 30s until complete
8. **Export**: `call_operation("exportCompanies", ...)` or `call_operation("exportProspects", ...)`

NEVER skip the cost estimate. NEVER proceed without user confirmation on credit-charging steps.
