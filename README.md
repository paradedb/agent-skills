# ParadeDB Agent Skill

An AI agent skill for [ParadeDB](https://paradedb.com) - Elasticsearch-quality full-text search in Postgres.

This skill uses a pointer-based approach. Instead of bundling static docs that can become stale, it instructs agents to fetch current ParadeDB docs from [https://docs.paradedb.com/llms-full.txt](https://docs.paradedb.com/llms-full.txt) at runtime and reuse the first successful fetch for the rest of the session.

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

### Sync Across Agents

> **Easiest way to sync across agents:** Use
> [dotagents](https://github.com/iannuttall/dotagents) to manage your skills in
> one place.

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

### VS Code (GitHub Copilot) Repository Instructions

GitHub Copilot supports repository-wide instructions via
`.github/copilot-instructions.md`.

```bash
mkdir -p .github
curl -fsSL \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md \
  | awk 'NR == 1 && $0 == "---" { in_frontmatter = 1; next } in_frontmatter && $0 == "---" { in_frontmatter = 0; next } !in_frontmatter { if (!started && $0 == "") { next } started = 1; print }' \
  > .github/copilot-instructions.md
printf '\n\n' >> .github/copilot-instructions.md
curl -fsSL \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md \
  >> .github/copilot-instructions.md
```

This keeps the file in the location Copilot looks for repository instructions
and strips the YAML frontmatter from `SKILL.md` before appending the examples.

## Usage

Once installed, the skill activates when you ask your AI agent about:

- ParadeDB
- BM25 indexing
- Full-text search in Postgres
- Elasticsearch alternatives for Postgres

On the first ParadeDB question in a session, the agent should fetch live docs
before answering. After a successful fetch, it should reuse that session copy
for later ParadeDB questions and only refetch when the user asks for a refresh,
the answer depends on newer/current changes, the earlier fetch was incomplete,
or the session context is no longer available.

If docs are unavailable due to network or access errors, the skill requires the
agent to report the error. When a cached session copy exists, the agent should
say it can continue from that cached copy; otherwise it should ask whether to
continue with local context only.

### Example Prompts

See [EXAMPLES.md](EXAMPLES.md) for categorized prompt examples.

## Links

- [ParadeDB Documentation](https://docs.paradedb.com)
- [ParadeDB AI Agents Guide](https://docs.paradedb.com/welcome/ai-agents)
- [LLM-Optimized Docs](https://docs.paradedb.com/llms-full.txt)
- [ParadeDB GitHub](https://github.com/paradedb/paradedb)

## License

MIT License. See [LICENSE](LICENSE) for details.
