---
name: paradedb-skill
description: >
  Expert guidance on ParadeDB full-text search, hybrid search (BM25 + semantic),
  aggregations, and analytics in Postgres. Use when writing ParadeDB queries,
  creating BM25 indexes, configuring tokenizers, or implementing
  Elasticsearch-quality search in Postgres.
---

# ParadeDB Skill

ParadeDB brings Elasticsearch-quality full-text search and analytics to
Postgres via the `pg_search` extension.

Use this skill when users ask about:

- BM25 indexes and relevance ranking
- Hybrid search (keyword + semantic vectors via `pgvector`)
- Tokenizers, analyzers, fuzzy matching, and phrase queries
- Facets, aggregations, snippets/highlighting, and query tuning

For complete and up-to-date ParadeDB documentation, always fetch:

**[https://docs.paradedb.com/llms-full.txt](https://docs.paradedb.com/llms-full.txt)**

Use your web-fetching tool to retrieve current docs before answering ParadeDB
questions. Treat behavior claims as version-dependent until verified.

## Response Guidelines

1. Prefer runnable SQL examples over prose-only answers.
2. State ParadeDB/Postgres version assumptions when syntax may differ.
3. If behavior is uncertain, call it out explicitly instead of guessing.

## Network Failure Rules (Mandatory)

If `llms-full.txt` (or any required docs URL) cannot be fetched due to DNS/network/access errors:

1. State clearly that live docs could not be accessed and include the actual error.
2. Ask the user whether to proceed with local/repo-only context or to retry later.
3. Do **not** invent or infer doc URLs, page paths, or feature availability.
4. Do **not** present unverified links as real.
5. Label any fallback statements as assumptions and keep them minimal.

Never silently switch to guessed documentation structure when network access fails.
