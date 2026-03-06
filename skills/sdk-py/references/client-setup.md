# Python SDK — Client Setup

## Installation

```bash
pip install fiberai
```

## Client Initialization

The SDK exports two client classes: `Client` (unauthenticated) and `AuthenticatedClient` (token-based auth). For Fiber AI's API key model, use `Client` and pass `api_key` per-request in the body or query.

```python
import os
from fiberai import Client

client = Client(base_url="https://api.fiber.ai")
```

## Making API Calls

API functions are standalone module functions, not methods on the client. Import them from `fiberai.api.{domain}.{operation}`:

```python
from fiberai.api.account.get_org_credits import sync as get_credits_sync

# GET endpoint — api_key as a keyword argument (mapped to query string)
credits = get_credits_sync(client=client, api_key=os.environ["FIBER_API_KEY"])
```

Each module exports 4 function variants:

| Function | Returns | Usage |
|----------|---------|-------|
| `sync(*, client, body)` | Parsed response or `None` | Simple sync calls |
| `sync_detailed(*, client, body)` | `Response` object with `.parsed`, `.status_code`, `.headers` | When you need status codes |
| `asyncio(*, client, body)` | Parsed response or `None` | Async calls |
| `asyncio_detailed(*, client, body)` | `Response` object | Async with full response |

## Request Bodies

Bodies are `attrs` classes. Import from `fiberai.models.{model_name}`:

```python
from fiberai.models.company_search_body import CompanySearchBody

body = CompanySearchBody(
    api_key=os.environ["FIBER_API_KEY"],
    search_params={},  # Check https://api.fiber.ai/docs/ for filter schema
    page_size=25,
)
```

## Error Handling

```python
from fiberai import Client
from fiberai.errors import UnexpectedStatus

# Option 1: Auto-raise on non-2xx responses
client = Client(
    base_url="https://api.fiber.ai",
    raise_on_unexpected_status=True,
)

try:
    result = some_api_call(client=client, body=body)
except UnexpectedStatus as e:
    # e.status_code, e.content available
    if e.status_code == 401:
        print("Invalid API key. Check FIBER_API_KEY.")
    elif e.status_code == 402:
        print("Insufficient credits. Top up at https://www.fiber.ai/app/subscription")
    elif e.status_code == 429:
        print("Rate limit exceeded. Retry after a moment.")

# Option 2: Check response manually using sync_detailed
from fiberai.api.search.company_search import sync_detailed

response = sync_detailed(client=client, body=body)
if response.status_code == 200:
    data = response.parsed
else:
    print(f"Error {response.status_code}: {response.content}")
```

## Environment Variable Validation

```python
import os


def get_fiber_api_key() -> str:
    key = os.environ.get("FIBER_API_KEY")
    if not key:
        raise RuntimeError(
            "FIBER_API_KEY environment variable is required. "
            "Get your key at https://fiber.ai/app/api"
        )
    return key
```

## API Reference

For the full list of available operations, parameter schemas, and response types, see:
- Interactive API docs: https://api.fiber.ai/docs/
- SDK source: check `site-packages/fiberai/api/` and `site-packages/fiberai/models/` after installation
