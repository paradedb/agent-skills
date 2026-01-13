# ParadeDB Search Skill

An AI agent skill that provides expert guidance on [ParadeDB](https://paradedb.com) — a Postgres extension for Elasticsearch-like full-text search and analytics with BM25 scoring.

This skill is derived from the official [ParadeDB LLM documentation](https://docs.paradedb.com/llms-full.txt).

## What's Included

- **SKILL.md** — Quick reference for operators, tokenizers, aggregations, and common patterns
- **reference/aggregations.md** — Complete aggregation syntax and examples
- **reference/tokenizers.md** — All tokenizer configurations and token filters
- **reference/query-builder.md** — Advanced query functions (fuzzy, proximity, regex, MLT, etc.)
- **reference/performance.md** — Performance tuning for reads, writes, and JOINs

## Installation

### Amp

Copy the skill to your global skills directory:

```bash
# macOS/Linux
mkdir -p ~/.config/agents/skills/paradedb-search
cp -r SKILL.md reference ~/.config/agents/skills/paradedb-search/

# Or for a specific project
mkdir -p /path/to/your/project/.agents/skills/paradedb-search
cp -r SKILL.md reference /path/to/your/project/.agents/skills/paradedb-search/
```

The skill will automatically load when you ask about ParadeDB, BM25 indexing, or full-text search in Postgres.

### Claude Code

Copy the skill to your project's `.claude/skills` directory:

```bash
mkdir -p /path/to/your/project/.claude/skills/paradedb-search
cp -r SKILL.md reference /path/to/your/project/.claude/skills/paradedb-search/
```

### Cursor

Add the skill content to your project's `.cursor/rules` or `.cursorrules` file:

```bash
# Option 1: Copy SKILL.md content to .cursorrules
cat SKILL.md >> /path/to/your/project/.cursorrules

# Option 2: Create a rules directory
mkdir -p /path/to/your/project/.cursor/rules
cp SKILL.md /path/to/your/project/.cursor/rules/paradedb.md
```

### VS Code (Copilot)

Add the skill as a custom instruction file:

```bash
# Create a .github directory for Copilot instructions
mkdir -p /path/to/your/project/.github
cp SKILL.md /path/to/your/project/.github/copilot-instructions.md

# Or append to existing instructions
cat SKILL.md >> /path/to/your/project/.github/copilot-instructions.md
```

Alternatively, add to VS Code workspace settings (`.vscode/settings.json`):
```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    { "file": "SKILL.md" }
  ]
}
```

### Windsurf

Add to your project's `.windsurfrules` file:

```bash
cat SKILL.md >> /path/to/your/project/.windsurfrules
```

### OpenCode

Copy the skill to your project directory and reference it in your config:

```bash
# Copy skill files to your project
cp -r SKILL.md reference /path/to/your/project/

# Or add to OpenCode's context files
mkdir -p /path/to/your/project/.opencode
cp SKILL.md /path/to/your/project/.opencode/paradedb.md
```

### Other AI Coding Assistants

Most AI coding tools support custom instructions or rules files. You can:

1. **Copy SKILL.md content** directly into your tool's custom instructions/system prompt
2. **Include as a file** in your project that the AI can read when needed
3. **Reference as context** by mentioning "use the ParadeDB skill" in your prompts

## Usage

Once installed, your AI assistant will automatically have knowledge of:

- ParadeDB search operators (`|||`, `&&&`, `###`, `===`, `@@@`)
- BM25 index creation and configuration
- Tokenizer selection (unicode, simple, literal, ngram, icu)
- Fuzzy search, phrase matching, and proximity queries
- Aggregations and faceted search
- Performance tuning best practices

### Example Prompts

**Index Creation:**
- "Use the ParadeDB skill to create a BM25 index for my products table with full-text search on name and description"
- "Help me set up a ParadeDB index with the ngram tokenizer for autocomplete on my articles table"

**Search Queries:**
- "Using the ParadeDB skill, write a fuzzy search query that tolerates typos in product names"
- "How do I search for an exact phrase 'running shoes' in ParadeDB?"
- "Write a ParadeDB query to find documents where 'machine' appears within 2 words of 'learning'"

**Aggregations & Analytics:**
- "Use ParadeDB skill to write a faceted query that returns top 10 results and the total count"
- "How do I get a histogram of ratings using ParadeDB aggregations?"
- "Write a ParadeDB query to count products by category"

**Scoring & Relevance:**
- "Using ParadeDB, how do I boost matches in the title field over the description field?"
- "Show me how to get BM25 relevance scores and highlighted snippets in ParadeDB"

**Performance:**
- "Use the ParadeDB skill to help me optimize my slow full-text search queries"
- "What's the best tokenizer to use for multi-language content in ParadeDB?"

**General:**
- "Explain the difference between ParadeDB's ||| and &&& operators"
- "Use the ParadeDB skill to help me migrate from Elasticsearch to ParadeDB"

## Learn More

- [ParadeDB Documentation](https://docs.paradedb.com)
- [ParadeDB LLM-optimized Docs](https://docs.paradedb.com/llms-full.txt) — Full documentation in a single text file
- [ParadeDB GitHub](https://github.com/paradedb/paradedb)
- [pg_search Extension](https://github.com/paradedb/paradedb/tree/main/pg_search)

## License

MIT
