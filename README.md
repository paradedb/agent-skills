# ParadeDB Agent Skill

An AI agent skill for [ParadeDB](https://paradedb.com) - Elasticsearch-quality full-text search in Postgres.

Once installed, the skill activates when you ask your agent about:

- ParadeDB
- BM25 indexing
- Full-text search in Postgres
- Elasticsearch alternatives for Postgres

> [!NOTE]
> ParadeDB also supports MCP integrations. For setup instructions, use
> [https://docs.paradedb.com/welcome/ai-agents](https://docs.paradedb.com/welcome/ai-agents).
> The `/mcp` route is a protocol endpoint, not a human-readable docs page.

## Installation

### One-Line Install (Recommended)

```bash
npx skills add paradedb/agent-skills
```

`npx skills add` is the most stable installation path because the installer keeps up with agent-specific directory conventions.

### Manual Installation (Fallback)

Use this path when `npx skills add` is unavailable.

> [!TIP]
> Directory conventions below were verified on **March 3, 2026**.

| Agent       | Global directory                                      | Project directory                        |
| ----------- | ----------------------------------------------------- | ---------------------------------------- |
| Claude Code | `~/.claude/skills`                                    | `.claude/skills`                         |
| OpenCode    | `~/.config/opencode/skills` (or `~/.opencode/skills`) | `.opencode/skills`                       |
| Cursor      | `~/.cursor/skills`                                    | `.cursor/skills`                         |
| Amp         | `~/.config/agents/skills`                             | `.agents/skills`                         |
| Windsurf    | `~/.codeium/windsurf/skills`                          | `.windsurf/skills`                       |
| Codex       | `$CODEX_HOME/skills`                                  | Set `CODEX_HOME` to a project-local path |

Install the skill in the directory that matches your agent. For example, for Claude:

```bash
TARGET_DIR="$HOME/.claude/skills/paradedb-skill"

mkdir -p "$TARGET_DIR"
curl -fsSL \
  "https://github.com/paradedb/agent-skills/archive/main.tar.gz" \
  | tar -xzf - -C "$TARGET_DIR" --strip-components=1
chmod +x "$TARGET_DIR/scripts/paradedb-docs"
```

For project-local installs, change `TARGET_DIR` to the corresponding project
directory (for example, `.claude/skills/paradedb-skill`).

## Implementation

Instead of bundling static docs that can become stale, this skill instructs agents to fetch the latest ParadeDB docs to answer your questions.
The skill includes a tiny script wrapping `curl` that allows the agent to fetch only the documentation. This approach ensures the agent sees the
full content of docs instead of a summarized view and makes it easy to allow fetching the docs freely without also granting full access to `curl`.
This is the script:
```bash
#!/bin/bash

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <doc-path>" >&2
  echo "Example: $0 welcome/introduction.md" >&2
  exit
fi

DOC_PATH=$1

if [[ "$DOC_PATH" != *.md && "$DOC_PATH" != *.txt ]]; then
  echo "Error: doc path must end in .md or .txt" >&2
  exit 1
fi

curl -fsSL "https://docs.paradedb.com/$DOC_PATH"
``` 

### Example Prompts

See [EXAMPLES.md](EXAMPLES.md) for categorized prompt examples.

## Links

- [ParadeDB Documentation](https://docs.paradedb.com)
- [ParadeDB AI Agents Guide](https://docs.paradedb.com/welcome/ai-agents)
- [LLM-Optimized Docs](https://docs.paradedb.com/llms-full.txt)
- [ParadeDB GitHub](https://github.com/paradedb/paradedb)

## License

MIT License. See [LICENSE](LICENSE) for details.
