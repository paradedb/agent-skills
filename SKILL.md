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
scripts/paradedb-docs start/configure-your-environment.md
scripts/paradedb-docs reference/indexing/create-index.md
scripts/paradedb-docs reference/indexing/columnar.md
scripts/paradedb-docs reference/indexing/partition-by.md
scripts/paradedb-docs reference/indexing/faster-bm25-queries.md
scripts/paradedb-docs reference/full-text/match.md

# Filters, facets, and joins
scripts/paradedb-docs reference/filtering/overview.md
scripts/paradedb-docs reference/filtering/external-indexes.md
scripts/paradedb-docs reference/aggregates/overview.md
scripts/paradedb-docs reference/aggregates/facets.md
scripts/paradedb-docs reference/aggregates/limitations.md
scripts/paradedb-docs reference/joins/overview.md

# Vector and hybrid search
scripts/paradedb-docs reference/indexing/indexing-vectors.md
scripts/paradedb-docs reference/vector/querying.md
scripts/paradedb-docs reference/vector/tuning.md
scripts/paradedb-docs reference/hybrid/rrf.md

# Tokenizer options
scripts/paradedb-docs reference/tokenizers/available-tokenizers/jieba.md
scripts/paradedb-docs reference/tokenizers/available-tokenizers/chinese-compatible.md

# Upgrades and index maintenance
scripts/paradedb-docs operate/deploy/upgrading.md
scripts/paradedb-docs operate/index-maintenance/reindexing.md

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
   feature. Install the `vector` extension in the same database before installing or
   upgrading `pg_search`. ParadeDB indexes pgvector's `vector` type, but does not use
   pgvector's HNSW or IVFFlat indexes — do not suggest them for a vector column that
   is in a ParadeDB index.
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

## Guidance for 0.26.0 and Later

Check the installed version before applying these rules to an older database.
Fetch the relevant live references above for complete syntax and current defaults.

- Index definitions do not require a primary key, a unique first column, or an
  identifier option in `WITH`. Include columns needed for search, filtering,
  ordering, and returned values. Avoid copying obsolete identifier options from
  historical release examples.
- Vector queries need a ParadeDB search predicate at the same query level as
  `ORDER BY <distance> LIMIT k`. Use `WHERE id @@@ pdb.all()` for an unfiltered
  query when `id` is indexed. Match `<->`, `<=>`, or `<#>` to `vector_l2_ops`,
  `vector_cosine_ops`, or `vector_ip_ops`, respectively. Confirm pushdown with
  `EXPLAIN` and `Exec Method: TopKScanExecState`.
- Vector build options are `training_sample_ratio` (default `0.32`) and
  `max_leaf_size` (default `100`). They replace `centroid_ratio` and
  `training_samples_per_centroid`, which are no longer accepted. Recreate indexes
  storing those old options; `REINDEX` alone does not remove obsolete options.
- Quantization is enabled by default for vector fields with at least 64
  dimensions. Field-level `vector_fields` settings, including
  `"quantization": false`, take effect on `CREATE INDEX` or `REINDEX`; changing
  them with `ALTER INDEX ... SET` requires a rebuild. Use
  `paradedb.vector_cluster_max_probe` to tune recall against latency, and fetch
  the tuning and configuration references before changing other settings.
- After upgrading to 0.26.0, rebuild every index containing vectors with
  `REINDEX`, including unquantized indexes. Vector queries fail until rebuilt;
  `REINDEX CONCURRENTLY` allows writes to continue. Fetch the upgrade and
  reindexing guides before planning an upgrade.
- For vector diagnostics, consult the SQL function reference for
  `paradedb.vector_info`, `paradedb.vector_config`, and
  `paradedb.vector_estimator_info`. Stored segment metadata and configured build
  targets may differ until a rebuild; estimator diagnostics do not tune the index.
- `partition_by` is a beta index option introduced in 0.26.0. Fetch
  `reference/indexing/partition-by.md` before recommending it. Choose columns
  used in selective equality/range filters, or equi-join keys on both tables.
  Partition columns must be single-valued and columnar indexed; text requires
  `pdb.literal`. Arrays and JSON/JSONB cannot be partition columns. Multiple
  columns use a comma-separated string, and their order does not matter.
  Start with 1–2 columns and `target_segment_count` at 2–4 times CPU cores or
  parallel workers. Boundaries are set on `CREATE INDEX`/`REINDEX` and are not
  rebalanced as writes accumulate; rebuild when needed to restore pruning.
- For faster BM25 scoring, fetch `reference/indexing/faster-bm25-queries.md`.
  Rebuilding existing indexes enables the new text-search improvements; enabling
  `pnorms=true` on scoring text fields' tokenizer casts during the rebuild enables
  the posting-norm improvements.
- For analytics, consult the aggregate and join references before implementing
  application-side workarounds: 0.26.0 adds eligible `SELECT DISTINCT` pushdown,
  global window aggregates with empty `OVER ()` over joins, and grouping by
  `DATE(timestamp)` for columnar timestamps without time zone. Preserve MVCC
  correctness with aggregate `visibility='transaction'` (the default); `raw`
  skips visibility checks and `threshold` applies them conditionally.
- Fetch tokenizer references for Jieba `search_mode` and
  `chinese_compatible`'s `chinese_convert` options before configuring them.
