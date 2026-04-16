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

This skill contains the ParadeDB documentation in `references/docs.md`. Always read the relevant documentation
before answering a user's question.

## Response Guidelines

1. Always read the documentation before answering.
2. Prefer runnable SQL examples over prose-only answers.
3. State ParadeDB/Postgres version assumptions when syntax may differ.
4. If behavior is uncertain, call it out explicitly instead of guessing.
5. Do not generate any of the deprecated syntax. The new syntax was released in
   version 0.20.0 and should be used exclusively unless the user requests the old syntax.
   If a query contains `paradedb` it is using the old syntax. use `pdb` instead.
