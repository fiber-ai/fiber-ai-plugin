---
name: track-signals
description: Track buying and hiring signals on a seed list of people and companies - job changes (Journeyman), hiring intent (job postings), social activity (LinkedIn posts), and funding rounds - using Fiber AI. Use this when the user says "track signals", "watch these accounts for hiring intent", "alert me when these people change jobs", "monitor my ABM list", "job-change alerts", "who is hiring for <role> at <companies>", "recent posts from this exec", "recent funding at my targets", or otherwise wants to turn a static list into a live intent feed.
user-invocable: true
argument-hint: <signal type + seed list - e.g. "job-change alerts for these 200 LinkedIn URLs" or "hiring signals for these 50 companies">
---

# Fiber AI: Track Signals

Turn a static list of people or companies into a live intent feed. Fiber exposes four orthogonal signal surfaces; this skill composes them based on what the user is trying to trigger on.

## When to use

- User has a seed list of people or companies and wants ongoing alerts, not a one-shot enrichment
- User asks to "track job changes", "monitor these accounts", "set up hiring alerts", "watch for funding rounds", "alert me when X happens at these companies"
- User wants to build a signal-driven outbound cadence ("reach out whenever someone changes jobs")
- User wants a recruiting pipeline driven by "open to work" / recent-title-change signals

## Do not use when

- User wants a one-shot contact reveal - use `/fiber:enrich` or `/fiber:enrich-linkedin-csv`
- User wants to discover new accounts, not monitor known ones - use `/fiber:find-similar-companies` or `/fiber:search`
- User needs a persistent exportable audience of 100+ prospects - use `/fiber:audience` or `/fiber:build-recruiting-audience` (those are build-then-export flows, not monitor-over-time)

## Happy path

Pick the signal type based on what the user is trying to trigger on. Do not bundle all four by default - each carries its own cost and cadence.

### A. Job-change signals (native, recommended default)

Fiber exposes a first-class Journeyman / job-change list. Run it once, poll forever.

1. Create a list with [`createJobChangeList`](https://api.fiber.ai/ai-docs/createJobChangeList.md). Free.
2. Add profiles in one pass with [`addProfilesToList`](https://api.fiber.ai/ai-docs/addProfilesToList.md). The list transitions to `BUILDING`, then `NORMAL`.
3. Poll [`getJourneymanList`](https://api.fiber.ai/ai-docs/getJourneymanList.md) until `status === "NORMAL"`. For large lists wait, don't busy-loop.
4. Read current state with [`listAllProfilesFromJourneymanList`](https://api.fiber.ai/ai-docs/listAllProfilesFromJourneymanList.md). Each row carries the last observed company / title plus any change detected since the last poll.
5. On an ongoing basis, the user re-polls (step 4) on whatever cadence they want. Flag each row where company or title changed since last known state.

Housekeeping: [`listAllJourneymanLists`](https://api.fiber.ai/ai-docs/listAllJourneymanLists.md) to inventory, [`updateJobChangeList`](https://api.fiber.ai/ai-docs/updateJobChangeList.md) to rename or pause, [`deleteProfilesFromJobChangeList`](https://api.fiber.ai/ai-docs/deleteProfilesFromJobChangeList.md) to drop rows, [`deleteJobChangeList`](https://api.fiber.ai/ai-docs/deleteJobChangeList.md) to remove the list entirely.

### B. Hiring intent signals (company-level, budget proxy)

Use when the user wants to know which target accounts are actively hiring a specific role (often a proxy for budget / team expansion / sales readiness).

1. For each target company, call [`jobPostingSearchCount`](https://api.fiber.ai/ai-docs/jobPostingSearchCount.md) with `companyName` + role keywords. Free, use it to gate cost.
2. When the count is non-zero, call [`jobPostingSearch`](https://api.fiber.ai/ai-docs/jobPostingSearch.md) to pull the postings themselves. Surface posting date, title, location, seniority band. Posting age matters - a 3-month-old unfilled posting is a stronger signal than a 2-day-old one.

### C. Social / activity signals (person or company posts)

Use when the user wants to reference something a target said publicly in their outreach.

1. For a person: [`profilePostsLiveFetch`](https://api.fiber.ai/ai-docs/profilePostsLiveFetch.md). Charges credits; limit to high-priority profiles.
2. For a company: [`companyPostsLiveFetch`](https://api.fiber.ai/ai-docs/companyPostsLiveFetch.md). Charges credits; one call per account.
3. For Twitter: [`twitterUserTweets`](https://api.fiber.ai/ai-docs/twitterUserTweets.md) when the target operates mostly on Twitter.

### D. Funding signals (company-level)

Use when the user is selling into "companies that just raised".

1. [`investmentSearch`](https://api.fiber.ai/ai-docs/investmentSearch.md) - filter by round type, amount, date range, industry. Returns the funded companies.
2. Optionally [`investorSearch`](https://api.fiber.ai/ai-docs/investorSearch.md) to find who the investors are; useful for "who else did this investor back" lateral expansion.

### E. Compose (the common real-world ask)

Most signal workflows are a composition. Example: "alert me when someone in my top-100 accounts changes jobs AND the new company is hiring for our persona".

1. Run pattern A on the 100 accounts' execs (job-change list).
2. When a change fires, trigger pattern B on the NEW company.
3. If pattern B returns hiring for the persona, surface it. Else skip.

Walk the user through each step; do not silently chain.

## Cost & consent gates

- List setup in pattern A (`createJobChangeList` / `addProfilesToList` / `getJourneymanList` / `listAllProfilesFromJourneymanList` / `listAllJourneymanLists` / `updateJobChangeList` / `deleteProfilesFromJobChangeList` / `deleteJobChangeList`): all free.
- `jobPostingSearchCount`: free. Always use it to gate `jobPostingSearch`.
- `jobPostingSearch`: charges credits per posting returned. Required script before paginating: "Pull N job postings for {company}. Estimated cost ~N credits. Proceed?"
- `profilePostsLiveFetch` / `companyPostsLiveFetch`: charges credits per call. Never loop across a whole list without gating - ask the user which N profiles to fetch posts for.
- `twitterUserTweets`: charges credits. Same rule.
- `investmentSearch` / `investorSearch`: charges credits per result. Gate with `investmentSearch` + date range before opening up.

Always check [`getOrgCredits`](https://api.fiber.ai/ai-docs/getOrgCredits.md) before any charged batch.

## Error handling

- Journeyman list stuck in `BUILDING` for > 15 minutes on a large input: keep polling but tell the user; if > 1 hour, surface a support contact rather than re-creating (which drops history).
- Journeyman list in `ERROR`: the list is broken; create a fresh list rather than mutating.
- `addProfilesToList` partially succeeds: the response carries warnings - surface the failures verbatim so the user knows which rows did not join the list.
- `jobPostingSearch` returns 0 while `jobPostingSearchCount` was > 0: usually a filter mismatch between count and search params - re-run both with identical params.
- `profilePostsLiveFetch` returns empty: profile may have private / zero public posts. Do not retry - that just charges again.
- Funding searches miss recent rounds: Fiber's investment data lags by days in some markets. Do not guarantee "real-time" on funding alerts.

## Cadence and data-freshness tips

- Job-change detection in Journeyman is event-driven from the upstream source. Polling once per day is usually sufficient; faster polling does not make changes appear faster.
- Hiring-intent postings refresh daily. Polling hourly is wasteful.
- Social posts are live (`*LiveFetch`) - each call hits LinkedIn / Twitter fresh. Batch them and cache locally.
- Funding data lags reality by several days in most markets. Use it as a pipeline-routing signal, not a real-time trigger.

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> - routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md>.
- **Per-operation pages used by this skill:**
  - <https://api.fiber.ai/ai-docs/createJobChangeList.md>
  - <https://api.fiber.ai/ai-docs/addProfilesToList.md>
  - <https://api.fiber.ai/ai-docs/getJourneymanList.md>
  - <https://api.fiber.ai/ai-docs/listAllProfilesFromJourneymanList.md>
  - <https://api.fiber.ai/ai-docs/listAllJourneymanLists.md>
  - <https://api.fiber.ai/ai-docs/updateJobChangeList.md>
  - <https://api.fiber.ai/ai-docs/deleteProfilesFromJobChangeList.md>
  - <https://api.fiber.ai/ai-docs/deleteJobChangeList.md>
  - <https://api.fiber.ai/ai-docs/jobPostingSearch.md>
  - <https://api.fiber.ai/ai-docs/jobPostingSearchCount.md>
  - <https://api.fiber.ai/ai-docs/profilePostsLiveFetch.md>
  - <https://api.fiber.ai/ai-docs/companyPostsLiveFetch.md>
  - <https://api.fiber.ai/ai-docs/investmentSearch.md>
  - <https://api.fiber.ai/ai-docs/investorSearch.md>
  - <https://api.fiber.ai/ai-docs/twitterUserTweets.md>
  - <https://api.fiber.ai/ai-docs/getOrgCredits.md>
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## SDK usage (optional)

The Journeyman lifecycle is available in `@fiberai/sdk` as individual function exports (`createJobChangeList`, `addProfilesToList`, `listAllProfilesFromJourneymanList`, etc.); see [`/fiber:sdk-ts`](../sdk-ts/SKILL.md). For Python, call the endpoints directly via `httpx` against `https://api.fiber.ai/v1/job-changes/*` until the SDK regenerates. The agent path (MCP `call_operation`) is primary for chat-time signal tracking; use the SDK only when embedding this flow into a product.
