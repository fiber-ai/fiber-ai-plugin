---
name: fiber-enrich
description: Reveal contact details (emails, phones) for a person or enrich a company profile using Fiber AI
---

Enrich a contact or company using Fiber AI.

For individual contact enrichment, pick the tier by latency vs cost:
- Standard (default): operationId `syncQuickContactReveal` — `POST /v1/contact-details/single`
- Premium (fastest): operationId `syncTurboContactEnrichment` — `POST /v1/contact-details/turbo/sync`
- Async waterfall (maximum coverage): `triggerExhaustiveContactEnrichment` + `pollExhaustiveContactEnrichmentResult`
- Use `call_operation("syncQuickContactReveal", {"body": {...}})` via Core MCP.
- Primary identifier: `linkedinUrl`.
- The `enrichmentType` object controls what data to fetch.

For company enrichment:
- operationId: `companyLiveEnrich` or `kitchenSinkCompany`
- Use `call_operation` via Core MCP.

Always call `get_endpoint_details_full` for the exact parameter schema before making calls. Prefer the per-operation page (e.g. <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md>) over the full OpenAPI spec when building context.

Warn the user about credit costs before enriching — trust `response.chargeInfo` as authoritative. For bulk enrichment (10–2,000 identifiers) use `startBatchContactDetails` + `pollBatchContactDetails`; for more than 2,000 suggest the audience workflow instead.
