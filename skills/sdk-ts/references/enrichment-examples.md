# TypeScript SDK — Enrichment Examples

## Individual Contact Enrichment

Fiber exposes three tiers of single-profile contact reveal. Start with the **standard** tier (`syncQuickContactReveal`) and escalate as needed:

| operationId | Endpoint | When to use |
| --- | --- | --- |
| `syncQuickContactReveal` | `POST /v1/contact-details/single` | Default. Balanced speed and cost. |
| `syncTurboContactEnrichment` | `POST /v1/contact-details/turbo/sync` | Fastest sync tier (premium cost). |
| `triggerExhaustiveContactEnrichment` + `pollExhaustiveContactEnrichmentResult` | `POST /v1/contact-details/exhaustive/start` → `GET /v1/contact-details/exhaustive/poll` | Async waterfall for maximum coverage. Use as a fallback when both sync tiers return nothing. |

See <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md> for the full canonical schema before writing code.

```typescript
import { createClient, syncQuickContactReveal } from "@fiberai/sdk";

const client = createClient({ baseUrl: "https://api.fiber.ai" });

const contact = await syncQuickContactReveal({
  client,
  body: {
    apiKey: process.env.FIBER_API_KEY!,
    linkedinUrl: "https://www.linkedin.com/in/example-profile",
    enrichmentType: {
      // Check https://api.fiber.ai/ai-docs/syncQuickContactReveal.md for current options
      // Common fields: getWorkEmails, getPersonalEmails, getPhoneNumbers
    },
  },
});
```

## Company Live Enrichment

```typescript
import { createClient, companyLiveEnrich } from "@fiberai/sdk";

const client = createClient({ baseUrl: "https://api.fiber.ai" });

const company = await companyLiveEnrich({
  client,
  body: {
    apiKey: process.env.FIBER_API_KEY!,
    // Check https://api.fiber.ai/ai-docs/companyLiveEnrich.md for required parameters
  },
});
```

## Check Credits Before Enrichment

```typescript
import { createClient, getOrgCredits, syncQuickContactReveal } from "@fiberai/sdk";

const client = createClient({ baseUrl: "https://api.fiber.ai" });
const apiKey = process.env.FIBER_API_KEY!;

async function enrichWithCreditCheck(linkedinUrl: string) {
  const credits = await getOrgCredits({
    client,
    query: { apiKey },
  });

  // Trust response.chargeInfo on the enrichment call itself for the authoritative cost.
  console.log("Current credits:", credits.data);

  return syncQuickContactReveal({
    client,
    body: {
      apiKey,
      linkedinUrl,
      enrichmentType: {
        // Specify which data types to fetch
      },
    },
  });
}
```

## Batch Enrichment with Rate Limiting

For 10–2,000 identifiers, prefer the dedicated batch endpoint over a loop of sync calls:

```typescript
import {
  createClient,
  startBatchContactDetails,
  pollBatchContactDetails,
} from "@fiberai/sdk";

const client = createClient({ baseUrl: "https://api.fiber.ai" });
const apiKey = process.env.FIBER_API_KEY!;

async function enrichBatch(linkedinUrls: string[]) {
  const start = await startBatchContactDetails({
    client,
    body: { apiKey, linkedinUrls },
  });
  const taskId: string = start.data.taskId;

  for (;;) {
    const poll = await pollBatchContactDetails({ client, query: { apiKey, taskId } });
    if (poll.data.status === "DONE") return poll.data;
    await new Promise((resolve) => setTimeout(resolve, 30_000));
  }
}
```

If a small loop is unavoidable, keep a 30-second cadence between `syncQuickContactReveal` calls to stay well inside the rate limit.

## Important Notes

- Tier selection: `syncQuickContactReveal` (standard) → `syncTurboContactEnrichment` (fastest) → exhaustive async as last resort.
- `linkedinUrl` is the primary identifier for contact enrichment.
- The `enrichmentType` object controls what data to fetch — check the per-operation markdown at <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md>.
- Credit costs vary by enrichment type — the authoritative value is on the response's `chargeInfo`.
- For 10–2,000 identifiers, use `startBatchContactDetails` / `pollBatchContactDetails`. For larger jobs, use the audience workflow via `/fiber:audience`.
