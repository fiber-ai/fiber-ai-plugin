# Fiber AI — OpenCode install instructions

You are an AI agent running inside OpenCode. The user asked you to install the Fiber AI plugin. Follow these steps in order. Do not skip steps.

## 1. Confirm the user has a Fiber API key

Ask the user if they already have `FIBER_API_KEY` set in their shell. If they do not:

- Direct them to <https://fiber.ai/app/api> to create one.
- Show them how to persist it:

  ```bash
  echo 'export FIBER_API_KEY=sk_live_your_key_here' >> ~/.zshrc
  source ~/.zshrc
  ```

Do not proceed until the user confirms they have `FIBER_API_KEY` set.

## 2. Register the Fiber MCP servers

OpenCode reads MCP config from one of:

- `./opencode.json` (project-level, preferred for team sharing)
- `~/.config/opencode/opencode.json` (user-global)

Decide with the user which scope they want. Default to project-level.

Add the following entries to the chosen config file's `mcp` object. V3 uses OAuth (browser-based SSO login) instead of an API key - ask the user whether they want to register it; skip it if they only want the API-key path.

```json
{
  "mcp": {
    "fiber-ai-v2": {
      "type": "remote",
      "url": "https://mcp.fiber.ai/mcp/v2",
      "headers": {
        "x-api-key": "{env:FIBER_API_KEY}"
      },
      "enabled": true
    },
    "fiber-ai-v3": {
      "type": "remote",
      "url": "https://mcp.fiber.ai/mcp/v3",
      "enabled": true
    },
    "fiber-ai-core": {
      "type": "remote",
      "url": "https://mcp.fiber.ai/mcp",
      "headers": {
        "x-api-key": "{env:FIBER_API_KEY}"
      },
      "enabled": true
    }
  }
}
```

If the file already has an `mcp` object, merge — do not overwrite existing servers.

If the file does not exist, create it with the full structure above.

## 3. Install the agent skills

OpenCode agents read skill-style instructions from `AGENTS.md` and/or `.opencode/AGENTS.md`. Do the following:

1. Fetch the list of skills from <https://github.com/fiber-ai/fiber-ai-plugin/tree/main/skills>.
2. Clone the plugin repo into a sibling directory, or fetch the skill Markdown files directly:

   ```bash
   git clone --depth 1 https://github.com/fiber-ai/fiber-ai-plugin .fiber-ai-plugin
   ```

3. Append a "Fiber AI skills" section to the user's project `AGENTS.md` (create it if missing) that points to the cloned skills directory and the canonical Fiber docs:

   ```markdown
   ## Fiber AI skills

   Workflow skills for Fiber AI are in `.fiber-ai-plugin/skills/`. When the user expresses one of these intents, load the matching SKILL.md:

   - "find companies like X" → `.fiber-ai-plugin/skills/find-similar-companies/SKILL.md`
   - "enrich these LinkedIn URLs" → `.fiber-ai-plugin/skills/enrich-linkedin-csv/SKILL.md`
   - "build a recruiting list" → `.fiber-ai-plugin/skills/build-recruiting-audience/SKILL.md`
   - "reverse lookup these emails" → `.fiber-ai-plugin/skills/expand-from-email-list/SKILL.md`
   - "enrich these GitHub handles" → `.fiber-ai-plugin/skills/enrich-github-handles/SKILL.md`
   - "find VPs/CMOs/CTOs at ..." → `.fiber-ai-plugin/skills/find-and-enrich-by-role/SKILL.md`

   Canonical API docs: <https://api.fiber.ai/llms.txt>, <https://api.fiber.ai/ai-docs/index.md>.
   Per-operation docs: <https://api.fiber.ai/ai-docs/{operationId}.md>.
   ```

## 4. Verify

Restart OpenCode (or ask the user to) so the new MCP servers load. Then confirm with the user:

- "Ask me: 'find 5 fintech companies in NYC under 200 employees'"
- The agent should route to the `find-similar-companies` or `find-and-enrich-by-role` skill and call `companySearch` via the `fiber-ai-v2` MCP.

If the MCP connection fails:

- Confirm `FIBER_API_KEY` is exported (`echo $FIBER_API_KEY`).
- Confirm the URL reaches the server: `curl -sSI https://mcp.fiber.ai/mcp/v2`.
- Direct the user to <https://docs.fiber.ai/article/using-mcp-in-llms> for debugging.

## 5. Summary to print to the user

"Fiber AI is installed. Try: 'search for Series B fintech in NYC' or 'enrich this LinkedIn URL'. I will route those through the Fiber MCP and the matching skill. Docs: <https://api.fiber.ai/llms.txt>."
