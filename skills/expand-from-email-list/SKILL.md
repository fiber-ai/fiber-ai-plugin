---
name: expand-from-email-list
description: Turn a list of email addresses into full people + company records using Fiber AI reverse email lookup, then optionally pull fresh LinkedIn data and extra contact fields. Use this when the user says "I have emails, give me more info", "reverse lookup these emails", "I have a list of emails from our CRM", "decorate emails with LinkedIn/company", "who are these people (by email)?", "unknown customers enrichment", or otherwise starts from raw emails and wants identity + firmographic data back.
user-invocable: true
argument-hint: <one or more email addresses - paste or CSV path>
---

# Fiber AI: Expand From Email List

Start from raw emails (CRM dump, signups, support tickets) and resolve them into people - LinkedIn URL, name, title, company, location - then optionally layer on fresh profile data or extra contact fields.

## When to use

- User pastes or attaches emails and asks "who are these people?"
- User wants to decorate a CRM export with LinkedIn URLs and titles
- User wants to identify anonymous customers who signed up with an email
- User says "reverse lookup", "email to LinkedIn", "unknown customers enrichment"

## Do not use when

- User already has LinkedIn URLs and needs contact data - use `/fiber:enrich-linkedin-csv`
- User wants to find new people matching a role - use `/fiber:find-and-enrich-by-role`
- User wants a saved, exportable audience - use `/fiber:audience` or `/fiber:build-recruiting-audience`
- User wants code - use `/fiber:sdk-ts` or `/fiber:sdk-py`

## Happy path

Route by list size, then layer optional follow-up enrichment.

1. Loop [`reverseEmailLookup`](https://api.fiber.ai/ai-docs/reverseEmailLookup.md) row by row with a small concurrency cap (3-5 parallel). Surface progress as matches arrive. The public API currently only exposes the single-row endpoint; no bulk variant is registered.
2. For each returned LinkedIn URL, pick one follow-up based on what the user actually needs:
   - Canonical profile snapshot (cheap, fast): [`KitchenSinkProfile`](https://api.fiber.ai/ai-docs/KitchenSinkProfile.md) - preserve the PascalCase on this one.
   - Freshest LinkedIn data (current role, tenure, recent posts-derived signals): [`profileLiveEnrich`](https://api.fiber.ai/ai-docs/profileLiveEnrich.md). Charges credits.
3. If the user also needs phones or alternative emails on the now-identified people, pipe them into [`syncQuickContactReveal`](https://api.fiber.ai/ai-docs/syncQuickContactReveal.md) (for <=5) or hand off to [`/fiber:enrich-linkedin-csv`](../enrich-linkedin-csv/SKILL.md) or [`/fiber:build-recruiting-audience`](../build-recruiting-audience/SKILL.md) for larger lists.
4. Always call out unmatched emails explicitly - reverse email match rates vary significantly by vintage and data source. Do not silently drop misses.

Call `get_endpoint_details_full("<operationId>")` on the Core MCP before constructing the body - the fields evolve.

## Cost & consent gates

- `reverseEmailLookup`: charges credits per successful match. Before running: "Reverse-lookup these N emails? Charges apply only to matches (expected hit rate: 40-70% depending on data source). Proceed?"
- `KitchenSinkProfile`: charges per resolved profile. Cheap; still confirm on larger fan-outs.
- `profileLiveEnrich`: charges per call. Always confirm before running on more than a handful.
- `syncQuickContactReveal`: charges per reveal. Confirm scope before looping.
- Check [`getOrgCredits`](https://api.fiber.ai/ai-docs/getOrgCredits.md) before any multi-step fan-out.

Never chain all four steps silently. After reverse lookup, summarize ("matched 42 of 60 emails") and ask whether to follow up with profile enrichment or contact reveal.

## Error handling

- Email is a personal address (gmail, outlook) with no professional footprint: `reverseEmailLookup` often misses. Flag as unresolved rather than retrying.
- Role-based email (info@, support@, hello@): these cannot be resolved to an individual. Skip automatically and tell the user.
- 402 insufficient credits mid-batch: surface balance from `getOrgCredits` and how many rows were charged before the failure.
- Match returned a low-confidence LinkedIn URL: surface the confidence score and ask the user to confirm before burning credits on `profileLiveEnrich`.
- Partial success across the loop (some rows error, others succeed): display both - do not retry the whole list.
- The same email resolves to two people (rare): show both matches and ask the user to pick.
- Malformed emails in the input (missing `@`, trailing whitespace): strip and validate before submitting; the API will 400 on bad inputs.
- User pasted a mix of work and personal emails: do not split unless the user asks. Match rates differ, and the output should preserve row order.

## Hit rate expectations

Reverse email match rates vary by source. Set user expectations before running:

- Work emails at established companies: typically 50-75% match.
- Personal emails (gmail, outlook, yahoo): typically 20-40% match.
- Old emails (>5 years): coverage drops significantly as LinkedIn records churn.
- Role-based addresses: 0% - always skip.

After the reverse lookup step, always surface "matched X of Y, unmatched Z" before proposing any follow-up enrichment. Do not silently budget the follow-up cost off the full input size - budget it off the match count.

If the user cares about the unmatched rows, suggest they route those through [`/fiber:enrich-linkedin-csv`](../enrich-linkedin-csv/SKILL.md) only if they can supply LinkedIn URLs, or into [`/fiber:build-recruiting-audience`](../build-recruiting-audience/SKILL.md) when they need a different identifier strategy at scale.

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> - routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> - every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. For this skill:
  - <https://api.fiber.ai/ai-docs/reverseEmailLookup.md>
  - <https://api.fiber.ai/ai-docs/KitchenSinkProfile.md>
  - <https://api.fiber.ai/ai-docs/profileLiveEnrich.md>
  - <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md>
  - <https://api.fiber.ai/ai-docs/getOrgCredits.md>
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## SDK usage (optional)

This skill is primarily MCP-driven. When embedding into a product, the right SDK calls are `reverseEmailLookup` (loop with a small concurrency cap) followed by `KitchenSinkProfile` or `profileLiveEnrich`. See [`/fiber:sdk-ts`](../sdk-ts/SKILL.md) and [`/fiber:sdk-py`](../sdk-py/SKILL.md) for client setup and error handling patterns - the call shapes follow the same body-with-`apiKey` pattern used elsewhere.
