# Competitor wrappers

The benchmark skill is vendor-agnostic by design. This directory is the place to drop thin wrappers that normalize a competing provider's response into the same row schema as Fiber, so side-by-side metrics can be computed.

No vendor-specific wrappers ship by default. There are two reasons:

1. Competitor APIs change. A wrapper frozen in this repo rots the moment the vendor ships a breaking change, and an out-of-date wrapper produces misleading benchmark numbers. Authoring the wrapper against the user's current vendor docs, at benchmark time, is more reliable.
2. Shipping competitor SDKs in this repo creates a false sense that one wrapper fits every account plan at that vendor. Field availability and response shape vary by tier; the user's wrapper should be authored against their own tier.

## Schema every wrapper must normalize to

```typescript
type BenchmarkRow = {
  input: string;                    // the identifier the user provided (LinkedIn URL, email, domain, etc.)
  identityReturned: boolean;        // did the provider return any record at all
  workEmail: string | null;
  personalEmail: string | null;
  phone: string | null;
  lastUpdated: string | null;       // ISO 8601 timestamp if the provider supplies one
  latencyMs: number;                // round-trip time for this row
  rawResponseBytes: number | null;  // optional, for debugging
  providerError: string | null;     // provider's error code / message if this row failed
};
```

Fiber rows come from `syncQuickContactReveal` / `startBatchContactDetails` / `reverseEmailLookup` / `kitchenSinkCompany`. The competitor wrapper should return the same shape so the reporting step can diff them directly.

## Authoring a wrapper at benchmark time

Ask the user to paste the relevant section of their competitor's API doc (the request shape and response shape for the enrichment endpoint they have access to). The agent then writes a small wrapper module in this folder that:

- Reads the competitor's API key from an environment variable (`PDL_API_KEY`, `APOLLO_API_KEY`, `CLEARBIT_API_KEY`, etc.) - never hard-coded.
- Exposes a single function that takes a sample row and returns a `BenchmarkRow`.
- Logs latency with `performance.now()` / `time.monotonic()`, not wall-clock.
- Catches rate-limit errors distinctly so the benchmark run does not silently retry through 429s.

## What NOT to put in this directory

- Vendor API keys (they belong in env vars).
- Large response fixtures (they bloat the repo and leak PII).
- Wrappers that call multiple endpoints per sample row without the user's explicit sign-off (that silently changes the cost-per-match math).
