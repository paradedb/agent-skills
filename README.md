# ParadeDB Agent Skill

An AI agent skill for [ParadeDB](https://paradedb.com): Elasticsearch-quality full-text search in Postgres.

This skill uses a pointer-based approach. Instead of bundling static docs that can become stale, it instructs agents to fetch current ParadeDB docs from [https://docs.paradedb.com/llms-full.txt](https://docs.paradedb.com/llms-full.txt) at runtime.

> [!NOTE]
> ParadeDB also supports MCP integrations. For setup instructions, use
> [https://docs.paradedb.com/welcome/ai-agents](https://docs.paradedb.com/welcome/ai-agents).
> The `/mcp` route is a protocol endpoint, not a human-readable docs page.

## Installation

### One-Line Install (Recommended)

```bash
npx skills add paradedb/agent-skills
```

`npx skills add` is the most stable installation path because the installer
keeps up with agent-specific directory conventions.

### Sync Across Agents

> **Easiest way to sync across agents:** Use
> [dotagents](https://github.com/iannuttall/dotagents) to manage your skills in
> one place.

### Manual Installation (Fallback)

Use this path when `npx skills add` is unavailable.

> [!TIP]
> Directory conventions below were verified on **March 3, 2026**.

| Agent | Global directory | Project directory |
| --- | --- | --- |
| Claude Code | `~/.claude/skills` | `.claude/skills` |
| OpenCode | `~/.config/opencode/skills` (or `~/.opencode/skills`) | `.opencode/skills` |
| Cursor | `~/.cursor/skills` | `.cursor/skills` |
| Amp | `~/.config/agents/skills` | `.agents/skills` |
| Windsurf | `~/.codeium/windsurf/skills` | `.windsurf/skills` |
| Codex | `$CODEX_HOME/skills` | Set `CODEX_HOME` to a project-local path |

Install the skill in the directory that matches your agent:

```bash
SKILL_REF="main"  # Replace with a tag or commit SHA to pin a specific version.
TARGET_DIR="$HOME/.claude/skills/paradedb-skill"  # Change for your agent.

mkdir -p "$TARGET_DIR"
curl -fsSL \
  "https://raw.githubusercontent.com/paradedb/agent-skills/${SKILL_REF}/SKILL.md" \
  -o "$TARGET_DIR/SKILL.md"
curl -fsSL \
  "https://raw.githubusercontent.com/paradedb/agent-skills/${SKILL_REF}/EXAMPLES.md" \
  -o "$TARGET_DIR/EXAMPLES.md"
```

For project-local installs, change `TARGET_DIR` to the corresponding project
directory (for example, `.claude/skills/paradedb-skill`).

### VS Code (GitHub Copilot) Workspace Setup

Copilot does not currently use the same `skills` folder conventions as other
agents. A stable project-local option is to reference `SKILL.md` from workspace
settings.

```bash
curl -fsSL -o SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -fsSL -o EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

Then add this to `.vscode/settings.json`:

```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    {
      "file": "SKILL.md"
    }
  ]
}
```

If your repo already has `.vscode/settings.json`, merge this key instead of
overwriting existing settings.

## Usage

Once installed, the skill activates when you ask your AI agent about:

- ParadeDB
- BM25 indexing
- Full-text search in Postgres
- Elasticsearch alternatives for Postgres

The agent should fetch live docs before answering. If docs are unavailable due
to network or access errors, the skill requires the agent to report the error
and ask whether to continue with local context only.

### Example Prompts

See [EXAMPLES.md](EXAMPLES.md) for categorized prompt examples.

## Links

- [ParadeDB Documentation](https://docs.paradedb.com)
- [ParadeDB AI Agents Guide](https://docs.paradedb.com/welcome/ai-agents)
- [LLM-Optimized Docs](https://docs.paradedb.com/llms-full.txt)
- [ParadeDB GitHub](https://github.com/paradedb/paradedb)

## License

MIT License. See [LICENSE](LICENSE) for details.
