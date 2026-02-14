# ParadeDB Agent Skill

An AI agent skill for [ParadeDB](https://paradedb.com) — Elasticsearch-quality full-text search in Postgres.

This skill uses a **pointer-based approach**: instead of bundling static documentation that can go stale, it instructs agents to fetch the latest ParadeDB docs from [https://docs.paradedb.com/llms-full.txt](https://docs.paradedb.com/llms-full.txt) in real-time.

> [!NOTE]
> **For users who prefer MCP:** ParadeDB documentation is also available via the Model Context Protocol at [https://docs.paradedb.com/mcp](https://docs.paradedb.com/mcp) for direct integration with MCP-compatible agents.

## Installation

### One-Line Install (Recommended)

`npx skills add` supports almost all the known agents: Amp, Antigravity, Claude Code, OpenClaw, Codex, Cursor\*, Droid, Gemini CLI, GitHub Copilot, OpenCode, Pi, Roo Code, Trae, and others.

```bash
npx skills add paradedb/agent-skills
```

- With Cursor you may have to choose non-symlink version when asked by the installer.

### Sync Across Agents

> **Easiest way to sync across all agents:** Use [dotagents](https://github.com/iannuttall/dotagents) to manage and sync your skills automatically across Claude Code, OpenCode, Cursor, VS Code, and other AI agents. This saves you from manually installing the same skill in multiple locations.

### Manual Tool-Specific Instructions

<details>
<summary><strong>Claude Code</strong></summary>

#### Global Installation (Recommended)

Available in all projects:

```bash
mkdir -p ~/.claude/skills/paradedb-skill
curl -o ~/.claude/skills/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -o ~/.claude/skills/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

#### Project-Specific Installation

Available only in the current project:

```bash
mkdir -p .claude/skills/paradedb-skill
curl -o .claude/skills/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -o .claude/skills/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

The skill will auto-load when you mention ParadeDB in your prompts.

</details>

<details>
<summary><strong>OpenCode</strong></summary>

#### Global Installation (Recommended)

Available in all projects:

```bash
mkdir -p ~/.config/opencode/skill/paradedb-skill
curl -o ~/.config/opencode/skill/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -o ~/.config/opencode/skill/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

#### Project-Specific Installation

Available only in the current project:

```bash
mkdir -p .opencode/skill/paradedb-skill
curl -o .opencode/skill/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -o .opencode/skill/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

Verify the skill is loaded:

```bash
opencode
# Then in the TUI, the skill will appear in available skills
```

</details>

<details>
<summary><strong>Cursor</strong></summary>

#### Global Installation (Recommended)

Available in all projects:

```bash
mkdir -p ~/.cursor/skills/paradedb-skill
curl -o ~/.cursor/skills/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -o ~/.cursor/skills/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

#### Project-Specific Installation

Available only in the current project:

```bash
mkdir -p .cursor/skills/paradedb-skill
curl -o .cursor/skills/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -o .cursor/skills/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

The skill will auto-load when you mention ParadeDB in your prompts.

</details>

<details>
<summary><strong>VS Code (GitHub Copilot)</strong></summary>

#### Global Installation (Recommended)

Available in all projects:

```bash
mkdir -p ~/.copilot/skills/paradedb-skill
curl -o ~/.copilot/skills/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -o ~/.copilot/skills/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

#### Project-Specific Installation

Add to your project's Copilot instructions:

```bash
mkdir -p .github
curl https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md >> .github/copilot-instructions.md
curl https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md >> .github/copilot-instructions.md
```

#### Via Workspace Settings

Alternatively, add to `.vscode/settings.json`:

```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    {
      "file": "SKILL.md"
    }
  ]
}
```

Then download `SKILL.md` to your project root:

```bash
curl -O https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -O https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

**Note:** Remove the YAML frontmatter (the lines between `---`) from `SKILL.md` after downloading.

</details>

<details>
<summary><strong>Amp</strong></summary>

#### Global Installation (Recommended)

Available in all projects:

```bash
mkdir -p ~/.config/agents/skills/paradedb-skill
curl -o ~/.config/agents/skills/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -o ~/.config/agents/skills/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

#### Project-Specific Installation

Available only in the current project:

```bash
mkdir -p .agents/skills/paradedb-skill
curl -o .agents/skills/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
curl -o .agents/skills/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
```

The skill will auto-load when you mention ParadeDB in your prompts.

</details>

<details>
<summary><strong>Windsurf</strong></summary>

Windsurf uses `.windsurfrules`. Append the skill content:

```bash
curl https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md >> .windsurfrules
curl https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md >> .windsurfrules
```

**Note:** Remove the YAML frontmatter (the lines between `---`) from `SKILL.md` when appending to `.windsurfrules`.

</details>

## Usage

Once installed, the skill activates automatically when you ask your AI agent about:

- ParadeDB
- BM25 indexing
- Full-text search in Postgres
- Elasticsearch alternatives for Postgres

The agent will fetch the latest documentation from ParadeDB and provide accurate, up-to-date guidance.

### Example Prompts

See [EXAMPLES.md](EXAMPLES.md) for a comprehensive list of example prompts organized by category.

## Links

- [ParadeDB Documentation](https://docs.paradedb.com)
- [LLM-Optimized Docs](https://docs.paradedb.com/llms-full.txt) (what this skill points to)
- [ParadeDB GitHub](https://github.com/paradedb/paradedb)

## License

MIT License - see [LICENSE](LICENSE) for details.
