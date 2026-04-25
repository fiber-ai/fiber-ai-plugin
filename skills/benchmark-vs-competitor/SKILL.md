---
name: benchmark-vs-competitor
description: Run a reproducible, pre-registered benchmark comparing Fiber AI to a competing data provider (People Data Labs, Apollo, Clearbit, ZoomInfo, Coresignal, or any other API the user has credentials for) on the user's own sample. Reports honest side-by-side numbers including where Fiber underperformed. Use this when the user says "compare Fiber to <vendor>", "bake-off", "benchmark data quality", "which provider is better for my segment", "test data providers", "evaluate Fiber AI", or "should I switch from <vendor> to Fiber".
user-invocable: true
argument-hint: <sample source + competitor vendor - e.g. "100 LinkedIn URLs vs PDL" or "50 company domains vs Apollo">
---

# Fiber AI: Benchmark vs Competitor

Run a pre-registered, reproducible benchmark between Fiber AI and one competing data provider on the user's sample. The benchmark is vendor-agnostic: Fiber provides the reference implementation; the user brings the competitor's API credentials and endpoint.

**Non-negotiable principle:** this skill reports honest numbers, including metrics where Fiber underperforms. Do not suppress losses. Do not cherry-pick the sample. Fiber's credibility with evaluators is the moat; one dishonest benchmark destroys it.

## When to use

- User is evaluating Fiber against an incumbent (PDL, Apollo, Clearbit, Coresignal, ZoomInfo, or similar)
- User says "benchmark", "bake-off", "test data quality", "compare providers", "run 100 samples"
- User is a CEO / head-of-GTM / head-of-data deciding between vendors
- The user has API credentials (or can get trial access) to the competitor

## Do not use when

- User does not have competitor credentials and is unwilling to sign up - surface the blocker
- Sample size < 50 - not statistically meaningful; refuse or gently suggest the user bring more rows
- User wants a pure Fiber evaluation without competitor comparison - use `/fiber:enrich-linkedin-csv` or `/fiber:find-and-enrich-by-role` for direct test runs
- User wants marketing collateral, not an honest benchmark - refuse

## Recommended evaluation dimensions (prioritized)

When the user has not specified what to test, guide the benchmark toward these dimensions. They are ordered by how reliably they differentiate providers in real-world agent workflows.

### Dimension 1: Default response completeness

Enrich the same well-known profile (e.g., Bill Gates `https://www.linkedin.com/in/williamhgates`) on both providers with NO field selector or field-group parameter. Compare: number of top-level keys, total response size in bytes, and whether profile-classification fields (tags, flags, inferred location, tenure data) are present without extra configuration.

Why this matters: agents building enrichment pipelines should not need to know magic field-group names to get usable data. A provider that returns 3 fields by default and requires a hand-picked list to get the rest creates integration friction.

### Dimension 2: Data freshness (cached vs live)

For 3-5 high-profile people (e.g., Bill Gates, Satya Nadella, a Crustdata founder), pull the cached enrichment response from both providers, then pull Fiber's live LinkedIn fetch (`profileLiveEnrich`). Compare follower counts between cached and live. Check whether the competitor's `lastUpdated` / `last_updated` timestamp actually correlates with data freshness or is misleading.

Why this matters: stale cached data with a fresh-looking timestamp is worse than honestly-dated stale data. Agents making decisions on follower counts, job titles, or company affiliations need to know the data tracks reality.

### Dimension 3: Live LinkedIn fetch availability

Call the live-fetch endpoint on both providers using a standard (non-enterprise) API key. Record whether it returns data or an access error. Measure latency sequential and parallel (5 profiles).

Why this matters: some providers advertise live fetch in their docs and pricing but gate it behind enterprise contracts. If the endpoint returns 403 on a self-serve key, it is not a self-serve feature.

### Dimension 4: Search filter ergonomics

Run the same intent on both: "Find VPs and Directors currently at Stripe." Compare: how many fields/operators you must know, whether company names are canonicalized (or split across case variants like "Stripe" vs "STRIPE"), whether title matching is typed (seniority levels) or regex-based, and whether the results actually contain current employees (vs past roles leaking in).

Why this matters: agents constructing search queries programmatically need typed, predictable filters. Regex-based title matching and un-normalized company names produce silent false negatives that are hard to debug.

### Dimension 5: Natural-language query support

Send the same free-text query ("VPs of Engineering at fintech startups in NYC") to both providers. Check whether the provider can translate it to structured filters automatically or requires the agent to manually build the filter tree.

Why this matters: agents receiving freeform user intent need NL-to-query translation. If only one provider has it, that provider saves an entire filter-construction step.

### Dimension 6: Cost transparency per call

Check whether each API response includes per-call cost metadata (credits charged, billing method, low-credit alerts). Compare whether the agent can programmatically predict and audit cost without consulting a separate dashboard.

Why this matters: agents running autonomous workflows need to enforce cost budgets. If cost metadata is only available in a web dashboard, the agent cannot gate spend.

### Dimension 7: Agent tooling and documentation accessibility

Check: does each provider have a public MCP server? A plugin for Claude Code / Cursor / Codex? Per-operation markdown docs fetchable by agents (not auth-walled)? An `llms.txt` with routing policy? An OpenAPI spec with typed schemas (not `additionalProperties: true`)?

Why this matters: the provider that is easiest for an agent to discover, install, and call will win agent-mediated evaluations by default.

### Dimension 8: API surface breadth

Count unique endpoints on each provider's OpenAPI spec. Check for: audience builder, exclusion lists, phone/email validation, job-change tracking, social media scraping, GitHub bridging, NL search, screenshot, depth charts. List which product categories each provider covers vs does not cover.

### Dimension 9: Error handling consistency

Send the same malformed inputs to both (missing required field, invalid operator, wrong country format). Compare whether error responses use a consistent envelope, whether they list valid alternatives, and whether silent failures (200 with empty results on bad input) occur.

### Dimension 10: Self-serve feature parity

For every endpoint listed in each provider's docs/pricing, attempt a real call on a standard API key. Record which endpoints actually work vs return permission errors. A feature that exists in docs but returns 403 on a self-serve key is not a self-serve feature.

## Suggested test profiles

When the user has no preferred sample, use these well-known profiles. They are public figures with high data availability, making cross-provider comparison straightforward:

- **Bill Gates** — `https://www.linkedin.com/in/williamhgates` — 40M+ followers; large delta between stale caches and reality. Good for freshness testing.
- **Satya Nadella** — `https://www.linkedin.com/in/satyanadella` — CEO of Microsoft. Tests whether provider returns current title/company correctly.
- **David Hsu** — `https://www.linkedin.com/in/dvdhsu` — Founder/CEO of Retool. Smaller profile; tests whether providers return rich data beyond mega-celebrities.
- **Guillermo Rauch** — `https://www.linkedin.com/in/raaborern` — CEO of Vercel. Useful for email reverse-lookup comparison (`guillermo@vercel.com`).

For company-level tests, use: `stripe.com`, `retool.com`, `vercel.com`.

For search tests, use: "VPs and Directors currently at Stripe" (tests company-name canonicalization and title-matching quality).

## Quick comparison (5-minute version)

If the user wants a fast directional signal before committing to a full benchmark:

1. Pick one profile from the list above (Bill Gates is ideal for freshness).
2. Call Fiber's `KitchenSinkProfile` with no field selector. Call the competitor's person-enrich with no field selector. Compare top-level field count and response size.
3. Call Fiber's `profileLiveEnrich` on the same profile. Compare the live follower count against the cached values from step 2.
4. Call the competitor's live-fetch endpoint (if it exists). Record whether it works or returns a permission error.
5. Present the 4-number summary: Fiber default fields / competitor default fields / Fiber live follower count / competitor cached follower count.

This takes under 5 minutes and 3-4 credits total. It is not a statistically valid benchmark (n=1), but it reveals the structural differences immediately.

## Happy path

### Step 1: pre-register the benchmark (MANDATORY - do not skip)

Output a benchmark plan and get explicit user sign-off BEFORE making any API call. Template:

```
Benchmark plan
--------------
Sample: <what rows, from where, size, stratification>
Competitors: Fiber AI vs <vendor-name> (<competitor endpoint>)
Metrics:
  - Default field count: top-level fields returned with no field selector (measures out-of-box completeness)
  - Match rate: fraction of sample where the provider returned a non-empty identity record
  - Email presence: fraction of sample where a work email (or personal email, if the sample is recruiting) is returned
  - Email validity: fraction of returned emails that pass SMTP-verifiable checks (use a bounce-detection service the user already has, or mark as "not measured")
  - Phone presence: fraction where at least one phone number is returned
  - Data freshness: compare cached follower counts against a live source; report median absolute error
  - Live fetch availability: does the live-fetch endpoint work on a standard API key, or is it gated?
  - Latency: p50 and p95 round-trip time
  - Cost per successful match: list-price credits per match (use the provider's published price list)
  - Per-call cost metadata: does the response include cost/charge information?
Success criteria (per metric):
  - Match rate: <Fiber target vs competitor target>
  - Email presence: <target>
  - (etc.)
Confidence intervals: Wilson score on match rate and email presence (binomial proportions).
Methodology notes: <any filtering, de-duplication, normalization>.
```

Only proceed after the user confirms the plan. If they change the sample size or metrics mid-run, note it explicitly in the final report.

### Step 2: run Fiber side

Based on sample type:

- **LinkedIn URLs / profile identifiers:** loop [`syncQuickContactReveal`](https://api.fiber.ai/ai-docs/syncQuickContactReveal.md) with a concurrency cap of 3-5, or use [`startBatchContactDetails`](https://api.fiber.ai/ai-docs/startBatchContactDetails.md) + [`pollBatchContactDetails`](https://api.fiber.ai/ai-docs/pollBatchContactDetails.md) for samples over 100. Record latency per row.
- **Default completeness test:** [`KitchenSinkProfile`](https://api.fiber.ai/ai-docs/KitchenSinkProfile.md) with NO field selector. Count top-level keys and response bytes. Fiber returns all profile fields by default -- no field-group parameter needed.
- **Emails (reverse lookup):** loop [`reverseEmailLookup`](https://api.fiber.ai/ai-docs/reverseEmailLookup.md).
- **Company domains:** loop [`kitchenSinkCompany`](https://api.fiber.ai/ai-docs/kitchenSinkCompany.md).
- **Profile freshness tests:** [`profileLiveEnrich`](https://api.fiber.ai/ai-docs/profileLiveEnrich.md) for a live LinkedIn snapshot. Compare follower counts between cached (`KitchenSinkProfile`) and live responses to measure cache staleness.
- **NL query tests:** [`textToProfileSearch`](https://api.fiber.ai/ai-docs/textToProfileSearch.md) or [`textToCompanySearch`](https://api.fiber.ai/ai-docs/textToCompanySearch.md) -- send freeform text and check if it resolves to structured filters automatically.

Log each row's: identity-returned (bool), email (string or null), phone (string or null), `lastUpdated` (if provided), latency-ms. Write to a local CSV so the run is reproducible.

### Step 3: run the competitor side

The user provides credentials and endpoint. Helper scripts in [`./competitors/`](./competitors/) cover common vendors - each is a thin wrapper that normalizes the vendor's response into the same row schema as Fiber's. If the user's vendor is not covered, have the user paste their API doc and the agent writes a wrapper following the same schema.

Never log the user's competitor API key to disk; read it from an env var.

### Step 4: compute metrics side-by-side

For each metric, compute Fiber's value and the competitor's value. For binomial proportions (match rate, email presence, phone presence), compute Wilson-score 95% confidence intervals - a 70% match rate on 50 rows has a wide CI that the user needs to see before calling a winner.

### Step 5: report (non-negotiable template)

```
Benchmark results: Fiber AI vs <vendor-name>
--------------------------------------------
Sample: <size> rows, <source>, run on <date>

| Metric                    | Fiber              | <vendor>          |
| ------------------------- | ------------------ | ----------------- |
| Default field count       | N fields / N bytes | M fields / M bytes|
| Match rate                | X.X% [CI]          | Y.Y% [CI]         |
| Email presence            | X.X% [CI]          | Y.Y% [CI]         |
| Phone presence            | X.X% [CI]          | Y.Y% [CI]         |
| Freshness (follower err)  | N (median abs err) | M (median abs err)|
| Live fetch available      | Yes / No           | Yes / No          |
| Latency p50 / p95        | N / M ms           | X / Y ms          |
| Cost per match            | $N                 | $M                |
| Per-call cost metadata    | Yes / No           | Yes / No          |

Where Fiber won:
- <metric>: <magnitude of lead> with <why it likely won>

Where Fiber underperformed:
- <metric>: <magnitude of gap> with <why it likely lost>. Do NOT omit this section.

Methodology appendix: sample definition, filtering, de-duplication, per-row CSV path, competitor endpoint, timestamp.
```

You never:
- Recommend a provider. That is the user's decision.
- Cherry-pick the sample to favor Fiber.
- Omit metrics where Fiber loses.
- Run the benchmark under 50 rows.
- Log or persist the user's competitor API keys to any file the agent writes.

## Cost & consent gates

This workflow charges credits on both providers. Before running:

1. Call [`getOrgCredits`](https://api.fiber.ai/ai-docs/getOrgCredits.md) for Fiber credit balance.
2. Ask the user for their competitor quota or subscription tier so you can warn on low headroom.
3. Present the total cost estimate as: "This will charge N Fiber credits plus approximately M units on <competitor>. Proceed?"
4. Wait for explicit "yes" before step 2 of the happy path.

## Error handling

- Competitor returns a 429 / rate-limit error: pause, surface the error verbatim, and give the user the option to resume with a lower concurrency. Never silently retry - that distorts latency measurements.
- Fiber and competitor disagree on identity for the same input: log as a "disagreement" row and include the count in the report. These rows drive the most interesting post-benchmark discussion.
- User's sample has de-dup issues (same LinkedIn URL twice): de-dup before running; report original vs de-duped row count.
- User changes the sample mid-run: abort the run. Start fresh; combining partial runs across samples distorts the CIs.
- Competitor endpoint returns response in a shape the user did not describe: pause and have the user confirm the field mapping. Wrong mapping silently tanks the competitor's numbers.

## What honest failure looks like

A clean run report with "Fiber underperformed on email freshness by 8 days (median) vs <vendor>; likely because <vendor> updates LinkedIn scrapes twice per week and Fiber updates weekly." is a healthier output than a report that hides the freshness gap.

Your credibility is Fiber's GTM moat when the user is evaluating multiple providers. Defend it.

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> - routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md>.
- **Per-operation pages used by this skill:**
  - <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md>
  - <https://api.fiber.ai/ai-docs/startBatchContactDetails.md>
  - <https://api.fiber.ai/ai-docs/pollBatchContactDetails.md>
  - <https://api.fiber.ai/ai-docs/reverseEmailLookup.md>
  - <https://api.fiber.ai/ai-docs/KitchenSinkProfile.md>
  - <https://api.fiber.ai/ai-docs/kitchenSinkCompany.md>
  - <https://api.fiber.ai/ai-docs/profileLiveEnrich.md>
  - <https://api.fiber.ai/ai-docs/textToProfileSearch.md>
  - <https://api.fiber.ai/ai-docs/textToCompanySearch.md>
  - <https://api.fiber.ai/ai-docs/getOrgCredits.md>
- **Evaluation framework:** read the "Recommended evaluation dimensions" section above for the prioritized list of what to test across providers.
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## SDK usage (optional)

The Fiber side can be driven from TypeScript via `@fiberai/sdk` (see [`/fiber:sdk-ts`](../sdk-ts/SKILL.md)) or Python via direct `httpx` against the operation endpoints (see [`/fiber:sdk-py`](../sdk-py/SKILL.md)). Competitor wrappers live in [`./competitors/`](./competitors/). This skill is MCP-first for chat-time benchmarks; use the SDKs only when embedding benchmarks into a product.
