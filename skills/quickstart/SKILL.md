---
name: quickstart
description: Guided first-run experience that proves Fiber AI value in under 60 seconds. Verifies the API key, searches for companies in the user's industry, and reveals one contact - all in one flow. Use this when the user says "quickstart", "get started", "first run", "try Fiber", "show me what Fiber can do", "demo", "test Fiber", or has just installed the plugin and does not know where to start.
user-invocable: true
argument-hint: <optional industry or company name - e.g. "fintech" or "Stripe">
---

# Fiber AI: Quickstart

Prove Fiber's value in under 60 seconds. This skill chains three operations into a single guided flow: verify credentials, search for relevant companies, and reveal one real contact with verified email. Designed for the moment right after installation when the user is deciding whether to keep using Fiber.

## When to use

- User just installed the Fiber plugin and wants to see it work
- User says "quickstart", "get started", "demo", "try Fiber", "show me what Fiber can do"
- User seems uncertain about what Fiber does or how to use it
- User has not yet run any Fiber operation in this session

## Do not use when

- User already knows what they want (a specific search, enrichment, or audience) - route to the relevant skill directly
- User wants to set up API key only without running anything - use `/fiber:setup`
- User wants a full benchmark or data-quality test - use `/fiber:benchmark-vs-competitor`

## Happy path

### Step 1: verify credentials (5 seconds)

1. Check if `FIBER_API_KEY` is set in the environment.
2. If not set, tell the user: "Set your API key first: `export FIBER_API_KEY=sk_live_...` (get one free at https://fiber.ai/app/api)." Stop here until the key is set.
3. Call [`getOrgCredits`](https://api.fiber.ai/ai-docs/getOrgCredits.md) to verify the key works. Show: "Connected. You have N credits available."

### Step 2: find relevant companies (15 seconds)

1. Ask ONE question: "What industry or type of company are you interested in?" If the user provided an argument (e.g. `/fiber:quickstart fintech`), skip the question and use that.
2. Call [`companySearch`](https://api.fiber.ai/ai-docs/companySearch.md) with a tight filter based on the user's answer. Set `pageSize: 5`.
3. Display the 5 results as a compact table: company name, domain, industry, headcount, location. Example:

```
Found 5 companies matching "fintech, Series B+":

| Company       | Domain          | Industry  | Headcount | Location    |
| ------------- | --------------- | --------- | --------- | ----------- |
| Acme Pay      | acmepay.com     | Fintech   | 200       | San Francisco |
| ...           | ...             | ...       | ...       | ...         |
```

4. Ask: "Pick one - I will find a real contact with verified email. (This uses ~1 credit.)"

### Step 3: reveal one contact (20 seconds)

1. For the chosen company, call [`peopleSearch`](https://api.fiber.ai/ai-docs/peopleSearch.md) with `currentCompanies` set to that company and `seniority` set to a reasonable default (Director+). Set `pageSize: 3`.
2. Show the top 3 people (name, title, LinkedIn URL).
3. Ask: "Want me to reveal contact details for one of these? (~1 credit for verified work + personal email.)"
4. On confirmation, call [`syncQuickContactReveal`](https://api.fiber.ai/ai-docs/syncQuickContactReveal.md) on the chosen profile.
5. Display the result: name, title, company, work email, personal email (if found), phone (if found).

### Step 4: what next (5 seconds)

Surface the natural next steps based on what just happened:

```
You are set up. Here is what you can do next:

- /fiber:search          - Search for more companies or people
- /fiber:enrich          - Reveal contacts for profiles you already have
- /fiber:find-similar-companies - Find companies like the one above
- /fiber:help            - See all 16 available skills

Or just describe what you need in plain English - the Fiber plugin will route you.
```

## Cost & consent gates

This flow uses at most 2-3 credits total:
- `getOrgCredits`: free
- `companySearch` (5 results): charges per result
- `peopleSearch` (3 results): charges per result
- `syncQuickContactReveal` (1 profile): charges per reveal

Always confirm before the reveal step (step 3.3). Never auto-reveal.

## Error handling

- API key invalid (401): "Your API key is not valid. Get a new one at https://fiber.ai/app/api or run `/fiber:setup`."
- Zero credits: "Your account has 0 credits. Top up at https://www.fiber.ai/app/subscription to continue."
- Company search returns 0: relax the filters (drop region or headcount constraint) and retry once. If still 0, suggest the user try a different industry.
- People search returns 0 for the chosen company: try a broader seniority filter (Manager+). If still 0, try the next company from step 2.
- Reveal returns no email: "Fiber did not find a verified email for this profile. This happens for ~15-25% of profiles. Try another person from the list above."

## For AI agents: machine-readable docs

- **Start here:** <https://api.fiber.ai/llms.txt> - routing policy + critical rules.
- **Operation index:** <https://api.fiber.ai/ai-docs/index.md>.
- **Per-operation pages used by this skill:**
  - <https://api.fiber.ai/ai-docs/getOrgCredits.md>
  - <https://api.fiber.ai/ai-docs/companySearch.md>
  - <https://api.fiber.ai/ai-docs/peopleSearch.md>
  - <https://api.fiber.ai/ai-docs/syncQuickContactReveal.md>
- **MCP:** <https://mcp.fiber.ai/mcp/v2> (API key) or <https://mcp.fiber.ai/mcp/v3> (OAuth via Clerk).
- **MCP quickstart:** <https://docs.fiber.ai/article/using-mcp-in-llms>.
