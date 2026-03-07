---
name: fiber-enrich
description: Reveal contact details (emails, phones) for a person or enrich a company profile using Fiber AI
---

Enrich a contact or company using Fiber AI.

For individual contact enrichment:
- operationId: `syncContactEnrichment`
- Endpoint: `POST /v1/contact-details/sync`
- Use `call_operation("syncContactEnrichment", {"body": {...}})` via Core MCP
- Primary identifier: `linkedinUrl`
- The `enrichmentType` object controls what data to fetch

For company enrichment:
- operationId: `companyLiveEnrich` or `kitchenSinkCompany`
- Use `call_operation` via Core MCP

Always call `get_endpoint_details_full` for the exact parameter schema before making calls. Check https://api.fiber.ai/docs/ for current enrichment options and credit costs.

Warn the user about credit costs before enriching. For bulk enrichment (more than 5 contacts), suggest using the audience workflow instead.
