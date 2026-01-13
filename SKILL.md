---
name: paradedb-search
description: Expert guidance on ParadeDB full-text search, BM25 indexing, aggregations, and analytics in Postgres. Use when writing ParadeDB queries, creating BM25 indexes, configuring tokenizers, or implementing Elasticsearch-like search in PostgreSQL.
---

# ParadeDB Search Skill

ParadeDB is a Postgres extension (`pg_search`) that brings Elasticsearch-like full-text search and analytics to PostgreSQL with BM25 scoring, ACID compliance, and real-time indexing.

## Quick Reference

### Search Operators

| Operator | Type | Description | Example |
|----------|------|-------------|---------|
| `\|\|\|` | Match disjunction | Matches ANY token | `WHERE description \|\|\| 'running shoes'` |
| `&&&` | Match conjunction | Matches ALL tokens | `WHERE description &&& 'running shoes'` |
| `###` | Phrase | Exact sequence | `WHERE description ### 'running shoes'` |
| `===` | Term | Exact token match | `WHERE description === 'running'` |
| `@@@` | Query builder | Advanced queries | `WHERE description @@@ pdb.regex('key.*')` |
| `##` | Proximity | Token distance | `WHERE description @@@ ('sleek' ## 1 ## 'shoes')` |

### Creating a BM25 Index

```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, description, category, rating, created_at, metadata)
WITH (key_field='id');
```

- `key_field` is required and must be a UNIQUE column (usually PRIMARY KEY)
- Include all columns used in search, filtering, ORDER BY, GROUP BY, or aggregations
- Only one BM25 index per table

### Tokenizers

| Tokenizer | Use Case | Syntax |
|-----------|----------|--------|
| `pdb.unicode_words` | Default, Unicode word boundaries | `(col::pdb.unicode_words)` |
| `pdb.simple` | Whitespace + lowercase | `(col::pdb.simple)` |
| `pdb.literal` | Exact string match, no tokenization | `(col::pdb.literal)` |
| `pdb.ngram(min,max)` | Partial/substring matching | `(col::pdb.ngram(3,3))` |
| `pdb.icu` | Multi-language Unicode | `(col::pdb.icu)` |
| `pdb.whitespace` | Whitespace only | `(col::pdb.whitespace)` |
| `pdb.literal_normalized` | Single token, allows filters | `(col::pdb.literal_normalized)` |

### Token Filters

```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.simple('stemmer=english', 'ascii_folding=true')))
WITH (key_field='id');
```

Available filters: `stemmer=<lang>`, `ascii_folding=true`, `remove_long=<n>`, `remove_short=<n>`

### BM25 Scoring & Highlighting

```sql
SELECT description, pdb.score(id), pdb.snippet(description)
FROM my_table
WHERE description ||| 'search query'
ORDER BY score DESC
LIMIT 10;
```

### Fuzzy Search (Typo Tolerance)

```sql
-- Edit distance of 2
SELECT * FROM my_table WHERE description ||| 'runing shose'::pdb.fuzzy(2);

-- Fuzzy prefix matching
SELECT * FROM my_table WHERE description === 'rann'::pdb.fuzzy(1, t);
```

### Phrase with Slop

```sql
-- Allow 2 word positions of flexibility
SELECT * FROM my_table WHERE description ### 'shoes running'::pdb.slop(2);
```

### Query Builder Functions

```sql
-- Regex
WHERE description @@@ pdb.regex('key.*rd')

-- Phrase prefix (autocomplete)
WHERE description @@@ pdb.phrase_prefix(ARRAY['running', 'sh'])

-- Parse (Tantivy query syntax)
WHERE id @@@ pdb.parse('description:shoes AND rating:>3')

-- All (force ParadeDB index usage)
WHERE id @@@ pdb.all()

-- More Like This
WHERE id @@@ pdb.more_like_this(3)

-- Range term
WHERE weight_range @@@ pdb.range_term('(10, 12]'::int4range, 'Intersects')
```

### Aggregations (Elasticsearch-compatible JSON)

```sql
-- Count
SELECT pdb.agg('{"value_count": {"field": "id"}}') FROM my_table WHERE id @@@ pdb.all();

-- Stats (count, sum, min, max, avg)
SELECT pdb.agg('{"stats": {"field": "rating"}}') FROM my_table WHERE id @@@ pdb.all();

-- Histogram
SELECT pdb.agg('{"histogram": {"field": "rating", "interval": "1"}}') FROM my_table WHERE id @@@ pdb.all();

-- Date histogram
SELECT pdb.agg('{"date_histogram": {"field": "created_at", "fixed_interval": "30d"}}') FROM my_table WHERE id @@@ pdb.all();

-- Percentiles
SELECT pdb.agg('{"percentiles": {"field": "rating", "percents": [50, 95]}}') FROM my_table WHERE id @@@ pdb.all();

-- Cardinality (distinct count estimate)
SELECT pdb.agg('{"cardinality": {"field": "rating"}}') FROM my_table WHERE id @@@ pdb.all();
```

### Faceted Queries (Top N + Aggregate)

```sql
SELECT description, rating,
       pdb.agg('{"value_count": {"field": "id"}}') OVER ()
FROM my_table
WHERE description ||| 'shoes'
ORDER BY rating DESC
LIMIT 3;
```

### Terms Aggregation (GROUP BY)

```sql
SELECT rating, pdb.agg('{"value_count": {"field": "id"}}')
FROM my_table
WHERE id @@@ pdb.all()
GROUP BY rating
LIMIT 10;
```

### Filter Aggregations

```sql
SELECT
    pdb.agg('{"value_count": {"field": "id"}}') FILTER (WHERE category === 'electronics') AS electronics_count,
    pdb.agg('{"value_count": {"field": "id"}}') FILTER (WHERE category === 'footwear') AS footwear_count
FROM my_table;
```

### Boosting (Relevance Tuning)

```sql
SELECT id, pdb.score(id), description
FROM my_table
WHERE description ||| 'shoes'::pdb.boost(2.0)
   OR category === 'footwear'::pdb.boost(0.5);
```

## Key Concepts

### Token Matching vs Substring Matching
ParadeDB uses token matching (like Elasticsearch), not substring matching. Text is tokenized at index time, and queries match against tokens. Use regex queries for substring matching.

### Filter Pushdown
Include non-text columns in the BM25 index for faster filtering:
```sql
CREATE INDEX search_idx ON my_table
USING bm25(id, description, rating, created_at)
WITH (key_field = 'id');
```

For text field exact matching, use the `literal` tokenizer:
```sql
CREATE INDEX search_idx ON my_table
USING bm25(id, description, (category::pdb.literal))
WITH (key_field = 'id');
```

### JSON Indexing
JSON fields are automatically indexed with all sub-fields:
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, metadata)
WITH (key_field='id');

-- Query JSON sub-fields
SELECT * FROM my_table WHERE metadata.color === 'Silver';
```

### Multiple Tokenizers Per Field
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (
  id,
  (description::pdb.literal),
  (description::pdb.simple('alias=description_simple'))
) WITH (key_field='id');

-- Query against alias
WHERE description::pdb.alias('description_simple') ||| 'Sleek running shoes'
```

## Performance Tuning

### Parallel Workers
```sql
SET max_parallel_workers_per_gather = 4;
SET max_parallel_workers = 64;
```

### Shared Buffers
Allocate up to 40% of RAM to `shared_buffers` in postgresql.conf.

### Vacuum
Run `VACUUM` regularly or configure autovacuum for frequently updated tables.

### Index Prewarming
```sql
CREATE EXTENSION pg_prewarm;
SELECT pg_prewarm('search_idx');
```

### Mutable Segment Size (Write Performance)
```sql
ALTER INDEX search_idx SET (mutable_segment_rows = 1000);
```

## Reference Documentation

For detailed documentation on specific topics, see:
- `reference/aggregations.md` - Full aggregation syntax and examples
- `reference/tokenizers.md` - All tokenizer configurations
- `reference/query-builder.md` - Advanced query functions
