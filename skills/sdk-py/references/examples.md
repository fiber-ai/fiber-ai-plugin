# Python SDK — Usage Examples

## Company Search

```python
import os
from fiberai import Client
from fiberai.api.search.company_search import sync as company_search_sync
from fiberai.models.company_search_body import CompanySearchBody

client = Client(base_url="https://api.fiber.ai")

result = company_search_sync(
    client=client,
    body=CompanySearchBody(
        api_key=os.environ["FIBER_API_KEY"],
        search_params={
            # Check https://api.fiber.ai/docs/ for the current filter schema
            # Common filters: location, employee count, industry, tech stack, funding, etc.
        },
        page_size=25,
    ),
)
```

## People Search

```python
from fiberai.api.search.people_search import sync as people_search_sync
from fiberai.models.people_search_body import PeopleSearchBody

result = people_search_sync(
    client=client,
    body=PeopleSearchBody(
        api_key=os.environ["FIBER_API_KEY"],
        search_params={
            # Check https://api.fiber.ai/docs/ for the current filter schema
            # Common filters: job title, seniority, department, current company, location, etc.
        },
        page_size=25,
    ),
)
```

## Contact Enrichment

The primary endpoint is `syncContactEnrichment` at `/v1/contact-details/sync`:

```python
from fiberai.api.contact_details.sync_contact_enrichment import (
    sync as contact_enrich_sync,
)
from fiberai.models.sync_contact_enrichment_body import SyncContactEnrichmentBody

contact = contact_enrich_sync(
    client=client,
    body=SyncContactEnrichmentBody(
        api_key=os.environ["FIBER_API_KEY"],
        linkedin_url="https://www.linkedin.com/in/example-profile",
        enrichment_type={
            # Check https://api.fiber.ai/docs/ for current enrichment type options
            # Common fields: get_work_emails, get_personal_emails, get_phone_numbers
        },
    ),
)
```

## Check Credits

```python
from fiberai.api.account.get_org_credits import sync as get_credits_sync

credits = get_credits_sync(
    client=client,
    api_key=os.environ["FIBER_API_KEY"],
)
print(f"Credits: {credits}")
```

## Async Usage

Use the `asyncio` function variant with the same `Client` instance:

```python
import asyncio as aio
import os
from fiberai import Client
from fiberai.api.search.company_search import asyncio as company_search_async
from fiberai.models.company_search_body import CompanySearchBody

client = Client(base_url="https://api.fiber.ai")


async def main():
    result = await company_search_async(
        client=client,
        body=CompanySearchBody(
            api_key=os.environ["FIBER_API_KEY"],
            search_params={},
            page_size=25,
        ),
    )
    print(result)


aio.run(main())
```

## Async Batch Enrichment

```python
import asyncio as aio
import os
from fiberai import Client
from fiberai.api.contact_details.sync_contact_enrichment import (
    asyncio as contact_enrich_async,
)
from fiberai.models.sync_contact_enrichment_body import SyncContactEnrichmentBody

client = Client(base_url="https://api.fiber.ai")
api_key = os.environ["FIBER_API_KEY"]


async def enrich_batch(linkedin_urls: list[str], delay: float = 0.2):
    results = []
    for url in linkedin_urls:
        try:
            result = await contact_enrich_async(
                client=client,
                body=SyncContactEnrichmentBody(
                    api_key=api_key,
                    linkedin_url=url,
                    enrichment_type={},  # Specify types per https://api.fiber.ai/docs/
                ),
            )
            results.append({"url": url, "data": result, "error": None})
        except Exception as e:
            results.append({"url": url, "data": None, "error": str(e)})
        await aio.sleep(delay)  # Respect rate limits
    return results
```

## Important Notes

- API functions are standalone imports from `fiberai.api.{domain}.{operation}`, not client methods
- Bodies are `attrs` classes from `fiberai.models.{model_name}` — not raw dicts
- `api_key` is a field on every body model (POST) or keyword argument (GET)
- There is no `AsyncClient` — use `asyncio` function variants with the regular `Client`
- Python model fields use `snake_case` (e.g., `linkedin_url`, `api_key`, `search_params`, `page_size`)
- Check https://api.fiber.ai/docs/ for current schemas — parameters change between versions
