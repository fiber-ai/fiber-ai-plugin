---
name: fiber-setup
description: Configure Fiber AI API key and verify MCP connection
---

Help the user set up Fiber AI in their environment.

1. Check if `FIBER_API_KEY` environment variable is set
2. If not set, instruct user to get their key from https://fiber.ai/app/api and set it:
   ```bash
   export FIBER_API_KEY=sk_live_...
   ```
   Add to shell profile for persistence.
3. Verify MCP connection by calling any tool (e.g., check credits via Core MCP)
4. If user needs the SDK: `npm install @fiberai/sdk` (TypeScript) or `pip install fiberai` (Python)
