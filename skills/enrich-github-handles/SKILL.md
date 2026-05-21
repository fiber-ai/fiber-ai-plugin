---
name: enrich-github-handles
description: Resolve GitHub handles or profile URLs into LinkedIn profiles and full contact enrichment using Fiber AI. Use this when the user says "I have GitHub handles", "enrich these engineers by GitHub", "find LinkedIn for these GitHub users", "developer enrichment", "OSS contributors list", "dev candidate enrichment", or otherwise starts from GitHub identifiers and wants LinkedIn or contact data.
user-invocable: true
argument-hint: <one or more GitHub handles or github.com/USER URLs>
---

# Fiber AI: Enrich GitHub Handles

Developer-sourcing skill. Start from GitHub handles or profile URLs, resolve to LinkedIn, then optionally layer on email / phone / live profile enrichment. All GitHub resolution is async.

## When to use

- User pastes a list of GitHub handles and wants LinkedIn URLs
- User is sourcing developers from OSS contributor lists, top-repos, or a CSV export
- User says "find LinkedIn for these GitHub users", "dev candidate enrichment", "OSS contributors to LinkedIn"
- User wants contact details for a list of engineers identified via GitHub

## Do not use when

- User starts from LinkedIn URLs - use `/fiber:enrich-linkedin-csv`
- User wants to find engineers by role description (not GitHub) - use `/fiber:find-and-enrich-by-role`
- User wants an exportable audience of thousands of engineers - use `/fiber:build-recruiting-audience`
- User wants to write a pipeline - use `/fiber:sdk-ts` or `/fiber:sdk-py`

## Happy path

Route by what the user actually needs back. Both GitHub operations are async - expect to poll.

1. **Input is a GitHub handle / profile URL; user only wants the LinkedIn URL** - call [`githubToLinkedInTrigger`](https://api.fiber.ai/ai-docs/githubToLinkedInTrigger.md), save the returned task id, then poll [`githubToLinkedInPolling`](https://api.fiber.ai/ai-docs/githubToLinkedInPolling.md) no more often than every 5 seconds until done. This is the cheapest path and returns just the matched LinkedIn URL.
2. **Input is a GitHub handle / profile URL; user wants full person enrichment** - call [`githubLookupTrigger`](https://api.fiber.ai/ai-docs/githubLookupTrigger.md), save the returned task id, then poll [`githubLookupPoll`](https://api.fiber.ai/ai-docs/githubLookupPoll.md) no more often than every 5 seconds until done. This returns a resolved person record (LinkedIn, name, title, company, location).
3. Once a LinkedIn URL is resolved (path 1 or 2), hand off to the relevant downstream enrichment:
   - Contact details (email / phone): [`syncQuickContactReveal`](https://api.fiber.ai/ai-docs/syncQuickContactReveal.md) per row, or [`startBatchContactDetails`](https://api.fiber.ai/ai-docs/startBatchContactDetails.md) + [`pollBatchContactDetails`](https://api.fiber.ai/ai-docs/pollBatchContactDetails.md) for batches of 10-2000.
   - Freshest LinkedIn profile data: [`profileLiveEnrich`](https://api.fiber.ai/ai-docs/profileLiveEnrich.md).
4. Unresolved handles are expected - GitHub to LinkedIn match rates are not 100%. Skip gracefully and flag misses in the output table.

For batches of 20+ handles, loop triggers sequentially but batch your polling - poll once per 15 seconds across all outstanding task ids.

Always call `get_endpoint_details_full("<operationId>")` on the Core MCP before constructing bodies. GitHub handle normalization (case, leading `@`, full URL vs bare handle) matters - check the schema.

## Cost & consent gates

- `githubToLinkedInTrigger` / `githubToLinkedInPolling`: charges credits only on a successful match. Polling is free. Before triggering: "Resolve these N GitHub handles to LinkedIn URLs? Charges apply only to matches."
- `githubLookupTrigger` / `githubLookupPoll`: charges per successful resolution (more than the LinkedIn-only path because it returns a full person record). Only use when the user explicitly needs more than the LinkedIn URL.
- Downstream `syncQuickContactReveal` / `startBatchContactDetails`: charge per reveal. Confirm scope before running - see [`/fiber:enrich-linkedin-csv`](../enrich-linkedin-csv/SKILL.md) for the exact gates.
- `profileLiveEnrich`: charges per call. Confirm on larger fan-outs.
- Check [`getOrgCredits`](https://api.fiber.ai/ai-docs/getOrgCredits.md) before starting a large batch.

Never silently escalate from path 1 to path 2 - if the user asked for "LinkedIn URLs for these handles", do not also pull contact reveals without asking.

## Error handling

- Handle does not resolve (no public LinkedIn signal): flag as unresolved. Do not retry automatically - the answer will be the same.
- Poll returns `PENDING` for > 5 minutes on a single task: keep polling but tell the user and offer to cancel. Never re-trigger an in-flight task; you will double-charge on success.
- Poll returns 404 (task id expired or invalid): re-trigger from scratch for that handle.
- User supplies handles with mixed formats (`torvalds`, `@torvalds`, `https://github.com/torvalds`): normalize before triggering. The API accepts full URLs; bare handles may need the `https://github.com/` prefix.
- 429 rate limited on polling: back off to 15s intervals, then 30s.
- Downstream contact reveal misses on a resolved LinkedIn URL: offer [`triggerExhaustiveContactEnrichment`](https://api.fiber.ai/ai-docs/triggerExhaustiveContactEnrichment.md) as the waterfall fallback.
- Private GitHub profile (email hidden, no linked sites): resolution will usually fail. Skip.
- GitHub org handles (not user handles): not supported by these operations. Filter them out before triggering.

## Hit rate expectations

Set user expectations up front - GitHub-to-LinkedIn match rates are structurally bounded by what the engineer has exposed publicly:

- Profiles with a linked personal site or Twitter/X: typically high match rate.
- Profiles with real-name commits visible in public repos: moderate match rate.
- Throwaway handles, pseudonymous accounts, or minimal profiles: typically miss.

For developer-sourcing workflows, expect to lose 30-50% of the input list on the GitHub-to-LinkedIn hop alone. Plan the contact-reveal budget off the resolved count, not the input count. If the user needs every handle resolved, no amount of retries will help - gracefully surface the misses and move on.

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> - routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md> - every public operation, grouped by tag.
- **Per-operation pages:** <https://api.fiber.ai/ai-docs/{operationId}.md>. For this skill:
  - <https://api.fiber.ai/ai-docs/githubToLinkedInTrigger.md>
  - <https://api.fiber.ai/ai-docs/githubToLinkedInPolling.md>
  - <https://api.fiber.ai/ai-docs/githubLookupTrigger.md>
  - <https://api.fiber.ai/ai-docs/githubLookupPoll.md>
  - <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md>
  - <https://api.fiber.ai/ai-docs/startBatchContactDetails.md>
  - <https://api.fiber.ai/ai-docs/pollBatchContactDetails.md>
  - <https://api.fiber.ai/ai-docs/profileLiveEnrich.md>
  - <https://api.fiber.ai/ai-docs/getOrgCredits.md>
- **Content negotiation:** send `Accept: text/markdown` to <https://api.fiber.ai/openapi.json> to get the agent-friendly index at the same URL (Stripe pattern).
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## SDK usage (optional)

This skill is primarily MCP-driven because polling logic fits naturally into an agent loop. When embedding into a product, both trigger/poll pairs follow the same shape as other async Fiber operations. See [`/fiber:sdk-ts`](../sdk-ts/SKILL.md) and [`/fiber:sdk-py`](../sdk-py/SKILL.md) for client setup, and reuse the polling cadence rules above - never poll faster than every 5 seconds.
