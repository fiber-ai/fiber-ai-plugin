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

Fiber exposes three tiers for single-profile contact reveal:

| operationId | Endpoint | When to use |
| --- | --- | --- |
| `syncQuickContactReveal` | `POST /v1/contact-details/single` | Default. Balanced speed and cost. |
| `syncTurboContactEnrichment` | `POST /v1/contact-details/turbo/sync` | Fastest sync tier (premium cost). |
| `triggerExhaustiveContactEnrichment` + `pollExhaustiveContactEnrichmentResult` | `POST /v1/contact-details/exhaustive/start` → `GET /v1/contact-details/exhaustive/poll` | Async waterfall for maximum coverage. Use as a fallback. |

See <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md> for the canonical schema.

```python
from fiberai.api.contact_details.sync_quick_contact_reveal import (
    sync as quick_reveal_sync,
)
from fiberai.models.sync_quick_contact_reveal_body import SyncQuickContactRevealBody

contact = quick_reveal_sync(
    client=client,
    body=SyncQuickContactRevealBody(
        api_key=os.environ["FIBER_API_KEY"],
        linkedin_url="https://www.linkedin.com/in/example-profile",
        enrichment_type={
            # Check https://api.fiber.ai/ai-docs/syncQuickContactReveal.md for current options
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

## Batch Enrichment (10–2,000 identifiers)

For larger sets of identifiers, prefer the dedicated batch endpoint over a loop of sync calls:

```python
import asyncio as aio
import os
from fiberai import Client
from fiberai.api.contact_details.start_batch_contact_details import (
    asyncio as start_batch_async,
)
from fiberai.api.contact_details.poll_batch_contact_details import (
    asyncio as poll_batch_async,
)
from fiberai.models.start_batch_contact_details_body import (
    StartBatchContactDetailsBody,
)

client = Client(base_url="https://api.fiber.ai")
api_key = os.environ["FIBER_API_KEY"]


async def enrich_batch(linkedin_urls: list[str]):
    start = await start_batch_async(
        client=client,
        body=StartBatchContactDetailsBody(
            api_key=api_key,
            linkedin_urls=linkedin_urls,
        ),
    )
    task_id: str = start.task_id

    while True:
        poll = await poll_batch_async(client=client, api_key=api_key, task_id=task_id)
        if poll.status == "DONE":
            return poll
        await aio.sleep(30)  # 30s cadence — never tighter
```

## Important Notes

- API functions are standalone imports from `fiberai.api.{domain}.{operation}`, not client methods
- Bodies are typed model classes from `fiberai.models.{model_name}` — not raw dicts
- `api_key` is a field on every body model (POST) or keyword argument (GET)
- There is no `AsyncClient` — use `asyncio` function variants with the regular `Client`
- Python model fields use `snake_case` (e.g., `linkedin_url`, `api_key`, `search_params`, `page_size`)
- Check https://api.fiber.ai/docs/ for current schemas — parameters change between versions
