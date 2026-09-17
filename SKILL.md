---
name: paradedb-skill
description: >
  Expert guidance on ParadeDB text and vector search, hybrid search
  (BM25 + semantic), filters, facets, joins, and aggregations in Postgres. Use when writing
  ParadeDB queries, creating ParadeDB indexes, indexing vectors, configuring
  tokenizers, or implementing Elasticsearch-quality search in Postgres.
---

# ParadeDB Skill

ParadeDB makes text and vector search, filters, facets, and joins fast in Postgres with the `pg_search` extension.

Use this skill when users ask about:

- ParadeDB indexes, BM25 scoring, and relevance ranking
- Vector search and hybrid search (keyword + semantic, fused with reciprocal rank fusion)
- Tokenizers, token filters, fuzzy matching, and phrase queries
- Facets, aggregations, snippets/highlighting, joins, and query tuning

For up-to-date ParadeDB documentation, always fetch the documentation index
(`llms.txt`) using the bundled script at `scripts/paradedb-docs`.
Resolve that path relative to the directory containing this `SKILL.md`, not
relative to the current working directory or repo root.

```bash
scripts/paradedb-docs llms.txt
```

Once you have the index, fetch only the pages relevant to the user's question.
Pass the path after `/docs/` from an index URL, including the `.md` suffix.
Common commands include:

```bash
# Getting started and application integrations
scripts/paradedb-docs start/connect-your-app.md
scripts/paradedb-docs reference/indexing/create-index.md
scripts/paradedb-docs reference/full-text/match.md

# Filters, facets, and joins
scripts/paradedb-docs reference/filtering/overview.md
scripts/paradedb-docs reference/filtering/external-indexes.md
scripts/paradedb-docs reference/aggregates/facets.md
scripts/paradedb-docs reference/joins/overview.md

# Vector and hybrid search
scripts/paradedb-docs reference/indexing/indexing-vectors.md
scripts/paradedb-docs reference/vector/querying.md
scripts/paradedb-docs reference/vector/tuning.md
scripts/paradedb-docs reference/hybrid/rrf.md

# SQL APIs and runtime settings
scripts/paradedb-docs reference/operators-and-functions.md
scripts/paradedb-docs reference/sql-functions.md
scripts/paradedb-docs reference/configuration.md
```

Use the operator reference to choose search predicates, the SQL function reference
for callable APIs and index inspection, and the configuration reference for runtime
settings. Consult the relevant `operate/` pages in the index for deployment,
maintenance, upgrades, and performance tuning.

After a successful fetch, treat that content as cached session context and
reuse it for later ParadeDB questions in the same session if applicable.
Do not refetch on every turn when the previously fetched docs are still
available and relevant.

The tool uses curl internally and requires network access. Make sure you run it with network access.
If you have to ask the user for permission to run the tool, make sure to ask them to allow you to run
the command for all arguments so you can fetch every page.

Do **not** use any tool other than `scripts/paradedb-docs` to fetch documentation.

## Response Guidelines

1. Prefer runnable SQL examples over prose-only answers.
2. State ParadeDB/Postgres version assumptions when syntax may differ. Some features are only
   available in newer versions, so when you have database access and the answer depends on
   one, check first with `SELECT extversion FROM pg_extension WHERE extname = 'pg_search';`.
3. If behavior is uncertain, call it out explicitly instead of guessing.
4. Prefer current search operators and `pdb.*` query builders, scoring, and highlighting
   functions over deprecated syntax unless the user requests compatibility with an older
   version. Do not replace every `paradedb` occurrence: `USING paradedb`, runtime settings
   such as `paradedb.enable_custom_scan`, and documented operational functions in the
   `paradedb` schema are current. Check the SQL function and configuration references
   before changing those names.
5. In version 0.25.0, the BM25 index was renamed to the ParadeDB index, because it now
   powers vector search, aggregates, top K and filtering as well as BM25 scoring. Write
   `CREATE INDEX ... USING paradedb`, not `USING bm25`, which survives only as a
   backwards-compatible alias, and call it the ParadeDB index. Reserve "BM25" for the
   scoring function itself.
6. Vector search runs inside the ParadeDB index as of version 0.25.0, where it is a beta
   feature. ParadeDB indexes pgvector's `vector` type, but does not use pgvector's HNSW or
   IVFFlat indexes — do not suggest them for a vector column that is in a ParadeDB index.
   Fetch `reference/indexing/indexing-vectors.md` and `reference/vector/querying.md`
   before writing vector queries, and `reference/hybrid/rrf.md` before writing hybrid ones.

## Network Failure Rules (Mandatory)

If any documentation cannot be fetched due to DNS/network/access errors:

1. State clearly that live docs could not be accessed and include the actual error.
2. If you have cached session docs from an earlier successful fetch, say that
   you can continue from that cached copy unless the user wants to stop.
3. If you do not have cached session docs, ask whether to proceed with
   local/repo-only context or to retry later.
4. Do **not** invent or infer doc URLs, page paths, or feature availability.
5. Do **not** present unverified links as real.
6. Label any fallback statements as assumptions and keep them minimal.

Never silently switch to guessed documentation structure when network access fails.
