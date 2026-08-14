<h1 align="center">
  <a href="https://paradedb.com">
    <picture align=center>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/paradedb/paradedb/raw/main/docs/logo/paradedb-logo-dark-large.svg">
      <source media="(prefers-color-scheme: light)" srcset="https://github.com/paradedb/paradedb/raw/main/docs/logo/paradedb-logo-light-large.svg">
      <img alt="The ParadeDB logo." src="https://github.com/paradedb/paradedb/raw/main/docs/logo/paradedb-logo-light-large.svg">
    </picture>
  </a>
  <br>
</h1>

<p align="center">
  <b>Search without a second system.</b><br/>
  One Postgres for your application data, full-text search, vector retrieval, and aggregations.
</p>

<h3 align="center">
  <a href="https://paradedb.com">Website</a> &bull;
  <a href="https://docs.paradedb.com">Docs</a> &bull;
  <a href="https://paradedb.com/slack">Community</a> &bull;
  <a href="https://paradedb.com/blog/">Blog</a> &bull;
  <a href="https://docs.paradedb.com/changelog/">Changelog</a>
</h3>

---

# ParadeDB Agent Skill

An AI agent skill for [ParadeDB](https://paradedb.com) - One Postgres for your application data, full-text search, vector retrieval, and aggregations.. Once installed, the skill activates when you ask your agent about:

- ParadeDB
- ParadeDB indexing and BM25 scoring
- Full-text search in Postgres
- Vector and hybrid search in Postgres
- Elasticsearch alternatives for Postgres

> [!NOTE]
> ParadeDB also supports MCP integrations. For setup instructions, use
> [https://docs.paradedb.com/documentation/getting-started/ai-agents](https://docs.paradedb.com/documentation/getting-started/ai-agents).
> The `/mcp` route is a protocol endpoint, not a human-readable docs page.

## Installation

### One-Line Install (Recommended)

```bash
npx skills add paradedb/agent-skills
```

`npx skills add` is the most stable installation path because the installer keeps up with agent-specific directory conventions.

### Manual Installation (Fallback)

Use this path when `npx skills add` is unavailable.

Most agents now read the cross-agent `.agents/skills` convention, so a single install covers them:

| Directory          | Scope                      | Read by                                                                           |
| ------------------ | -------------------------- | --------------------------------------------------------------------------------- |
| `.agents/skills`   | This project               | Codex, Cursor, Copilot, Gemini CLI, Amp, OpenCode, Devin Desktop, and many others |
| `~/.agents/skills` | All projects, current user | The same set, minus Amp (see below)                                               |

Agents that also, or only, read their own directory:

| Agent                   | Global directory             | Project directory  |
| ----------------------- | ---------------------------- | ------------------ |
| Claude Code             | `~/.claude/skills`           | `.claude/skills`   |
| Cursor                  | `~/.cursor/skills`           | `.cursor/skills`   |
| OpenCode                | `~/.config/opencode/skills`  | `.opencode/skills` |
| Amp                     | `~/.config/agents/skills`    | `.agents/skills`   |
| Codex                   | `~/.agents/skills`           | `.agents/skills`   |
| Devin CLI               | `~/.config/devin/skills`     | `.devin/skills`    |
| Windsurf, Devin Desktop | `~/.codeium/windsurf/skills` | `.windsurf/skills` |

> [!TIP]
> Directory conventions above were verified on **August 14, 2026**. `npx skills add`
> supports 76 agents; see [vercel-labs/skills](https://github.com/vercel-labs/skills#supported-agents)
> for the full, maintained list.

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
directory (for example, `.agents/skills/paradedb-skill` or `.claude/skills/paradedb-skill`).

## Implementation

Instead of bundling static docs that can become stale, this skill instructs agents to fetch the latest ParadeDB docs to answer your questions.
The skill includes a tiny script called `scripts/paradedb-docs` that allows the agent to fetch only the documentation using `curl`. This approach ensures the agent sees the
full content of docs instead of a summarized view and makes it easy to allow the agent to fetch the docs freely without also granting it unrestricted access to `curl`.

This is the [script](./scripts/paradedb-docs):

```bash
#!/bin/bash

set -euo pipefail

DOC_PATH=${1:-}

if [[ -z "$DOC_PATH" ]]; then
  echo "Usage: paradedb-docs <doc-path>    e.g. paradedb-docs documentation/full-text/match.md" >&2
  exit 1
fi

# The docs are authored as .mdx in paradedb/paradedb, but docs.paradedb.com serves
# each page as .md and 404s on .mdx. Requesting a page with no extension returns the
# rendered HTML page, which is far larger and harder to read. So: .md or .txt only.
if [[ "$DOC_PATH" != *.md && "$DOC_PATH" != *.txt ]]; then
  echo "Error: doc path must end in .md or .txt (the docs site serves .md, not .mdx)" >&2
  exit 1
fi

curl -fsSL --max-time 30 --retry 2 "https://docs.paradedb.com/$DOC_PATH"
```

### Example Prompts

See [EXAMPLES.md](EXAMPLES.md) for categorized prompt examples.

## Links

- [ParadeDB Documentation](https://docs.paradedb.com)
- [ParadeDB AI Agents Guide](https://docs.paradedb.com/documentation/getting-started/ai-agents)
- [LLM-Optimized Docs](https://docs.paradedb.com/llms-full.txt)
- [ParadeDB GitHub](https://github.com/paradedb/paradedb)

## License

MIT License. See [LICENSE](LICENSE) for details.
