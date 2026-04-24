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

## Happy path

### Step 1: pre-register the benchmark (MANDATORY - do not skip)

Output a benchmark plan and get explicit user sign-off BEFORE making any API call. Template:

```
Benchmark plan
--------------
Sample: <what rows, from where, size, stratification>
Competitors: Fiber AI vs <vendor-name> (<competitor endpoint>)
Metrics:
  - Match rate: fraction of sample where the provider returned a non-empty identity record
  - Email presence: fraction of sample where a work email (or personal email, if the sample is recruiting) is returned
  - Email validity: fraction of returned emails that pass SMTP-verifiable checks (use a bounce-detection service the user already has, or mark as "not measured")
  - Phone presence: fraction where at least one phone number is returned
  - Data freshness: median days since last update (use the provider's `lastUpdated` field where available; mark as "not measured" where not)
  - Latency: p50 and p95 round-trip time
  - Cost per successful match: list-price credits per match (use the provider's published price list)
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
- **Emails (reverse lookup):** loop [`reverseEmailLookup`](https://api.fiber.ai/ai-docs/reverseEmailLookup.md).
- **Company domains:** loop [`kitchenSinkCompany`](https://api.fiber.ai/ai-docs/kitchenSinkCompany.md).
- **Profile freshness tests:** [`profileLiveEnrich`](https://api.fiber.ai/ai-docs/profileLiveEnrich.md) for a live LinkedIn snapshot.

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

| Metric                | Fiber              | <vendor>          |
| --------------------- | ------------------ | ----------------- |
| Match rate            | X.X% [CI]          | Y.Y% [CI]         |
| Email presence        | X.X% [CI]          | Y.Y% [CI]         |
| Phone presence        | X.X% [CI]          | Y.Y% [CI]         |
| Freshness (med. days) | N                  | M                 |
| Latency p50 / p95     | N / M ms           | X / Y ms          |
| Cost per match        | $N                 | $M                |

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
  - <https://api.fiber.ai/ai-docs/kitchenSinkCompany.md>
  - <https://api.fiber.ai/ai-docs/profileLiveEnrich.md>
  - <https://api.fiber.ai/ai-docs/getOrgCredits.md>
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.

## SDK usage (optional)

The Fiber side can be driven from TypeScript via `@fiberai/sdk` (see [`/fiber:sdk-ts`](../sdk-ts/SKILL.md)) or Python via direct `httpx` against the operation endpoints (see [`/fiber:sdk-py`](../sdk-py/SKILL.md)). Competitor wrappers live in [`./competitors/`](./competitors/). This skill is MCP-first for chat-time benchmarks; use the SDKs only when embedding benchmarks into a product.
