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

For up-to-date ParadeDB documentation, always fetch the documentation index
(`llms.txt`) using the bundled script at `scripts/paradedb-docs`.
Resolve that path relative to the directory containing this `SKILL.md`, not
relative to the current working directory or repo root.

```bash
scripts/paradedb-docs llms.txt
```

Once you have the list of urls, load the pages necessary to answer the user's question. For example:
```bash
scripts/paradedb-docs documentation/getting-started/environment.md
scripts/paradedb-docs documentation/full-text/match.md
scripts/paradedb-docs documentation/indexing/create-index.md
# etc
```

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
2. State ParadeDB/Postgres version assumptions when syntax may differ.
3. If behavior is uncertain, call it out explicitly instead of guessing.
4. Do not generate any of the deprecated syntax. The new syntax was released in
   version 0.20.0 and should be used exclusively unless the user requests the old syntax.
   If a query contains `paradedb`, it is using the old syntax. Use `pdb` instead.

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
