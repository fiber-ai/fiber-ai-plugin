# TypeScript SDK — Enrichment Examples

## Individual Contact Enrichment

The primary endpoint for contact enrichment is `syncContactEnrichment` (`POST /v1/contact-details/sync`).

```typescript
import { createClient, syncContactEnrichment } from "@fiberai/sdk";

const client = createClient({ baseUrl: "https://api.fiber.ai" });

const contact = await syncContactEnrichment({
  client,
  body: {
    apiKey: process.env.FIBER_API_KEY!,
    linkedinUrl: "https://www.linkedin.com/in/example-profile",
    enrichmentType: {
      // Check https://api.fiber.ai/docs/ for current enrichment type options
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
    // Check https://api.fiber.ai/docs/ for required parameters (e.g., LinkedIn company URL or domain)
  },
});
```

## Check Credits Before Enrichment

```typescript
import { createClient, getOrgCredits, syncContactEnrichment } from "@fiberai/sdk";

const client = createClient({ baseUrl: "https://api.fiber.ai" });
const apiKey = process.env.FIBER_API_KEY!;

async function enrichWithCreditCheck(linkedinUrl: string) {
  // Check credits (GET endpoint — apiKey in query)
  const credits = await getOrgCredits({
    client,
    query: { apiKey },
  });

  // Verify sufficient credits before proceeding
  // Check https://api.fiber.ai/docs/ for current enrichment credit costs
  console.log("Current credits:", credits.data);

  return syncContactEnrichment({
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

```typescript
import { createClient, syncContactEnrichment } from "@fiberai/sdk";

const client = createClient({ baseUrl: "https://api.fiber.ai" });
const apiKey = process.env.FIBER_API_KEY!;

async function enrichBatch(linkedinUrls: string[], delayMs = 200) {
  const results = [];

  for (const url of linkedinUrls) {
    try {
      const result = await syncContactEnrichment({
        client,
        body: {
          apiKey,
          linkedinUrl: url,
          enrichmentType: {
            // Specify enrichment types
          },
        },
      });
      results.push({ url, data: result.data, error: null });
    } catch (error) {
      results.push({ url, data: null, error: String(error) });
    }

    // Respect rate limits
    await new Promise((resolve) => setTimeout(resolve, delayMs));
  }

  return results;
}
```

## Important Notes

- The contact enrichment endpoint is `syncContactEnrichment` at `/v1/contact-details/sync`
- `linkedinUrl` is the primary identifier for contact enrichment
- The `enrichmentType` object controls what data to fetch — check https://api.fiber.ai/docs/ for current options
- Credit costs vary by enrichment type — check current pricing before bulk operations
- For large batches (10+ contacts), consider using `startBatchContactEnrichment` for async processing, or the audience workflow via `/fiber:audience`
