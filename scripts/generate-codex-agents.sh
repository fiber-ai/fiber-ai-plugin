#!/usr/bin/env bash
# Regenerates .codex/agents/*.toml from the canonical agents/*.md files.
#
# The canonical source for every persona is agents/<name>.md (Claude Code /
# Cursor format). This script translates each of those to the TOML schema
# Codex CLI expects:
#     name = "<agent>"
#     description = "<single-line description>"
#     model_reasoning_effort = "medium" | "high"
#     sandbox_mode = "workspace-write"
#     mcp_servers = ["fiber-ai-v2", "fiber-ai-core"]
#     developer_instructions = """<markdown body>"""
#
# Run from the plugin root: bash scripts/generate-codex-agents.sh

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$here"

mkdir -p .codex/agents

for src in agents/*.md; do
  agent="$(basename "$src" .md)"
  desc=$(awk '/^description: /{ sub(/^description: /, ""); print; exit }' "$src")

  body_tmp="$(mktemp)"
  awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2{print}' "$src" > "$body_tmp"

  if grep -q '"""' "$body_tmp"; then
    echo "ERROR: triple-quote collision inside body of $src; aborting" >&2
    rm -f "$body_tmp"
    exit 1
  fi

  desc_escaped=${desc//\\/\\\\}
  desc_escaped=${desc_escaped//\"/\\\"}

  case "$agent" in
    gtm-strategist|data-quality-auditor) effort=high ;;
    *)                                   effort=medium ;;
  esac

  out=".codex/agents/${agent}.toml"
  {
    echo "# Fiber AI persona subagent for Codex CLI."
    echo "# Source of truth: fiber-ai-plugin/agents/${agent}.md (Claude Code / Cursor / OpenCode)."
    echo "# This TOML is a format translation, not a re-authoring. Regenerate via:"
    echo "#     bash scripts/generate-codex-agents.sh"
    echo
    echo "name = \"${agent}\""
    echo "description = \"${desc_escaped}\""
    echo "model_reasoning_effort = \"${effort}\""
    echo "sandbox_mode = \"workspace-write\""
    echo "mcp_servers = [\"fiber-ai-v2\", \"fiber-ai-core\"]"
    echo
    echo "developer_instructions = \"\"\""
    cat "$body_tmp"
    echo "\"\"\""
  } > "$out"

  rm -f "$body_tmp"
  echo "wrote ${out} ($(wc -l < "$out") lines)"
done
