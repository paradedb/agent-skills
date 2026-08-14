# ParadeDB Example Prompts

This document contains example prompts you can use with the ParadeDB skill when working with your AI agent.

## Getting Started & Setup

```text
What are the ways to index large datasets for search using ParadeDB?

What's the quickest way to create a full-text searchable table?

How do I load an existing Postgres table into ParadeDB and keep it in sync?

Which Postgres settings should I change before running ParadeDB in production?
```

## Indexing

```text
Create a ParadeDB index for full-text search on my products table

How do I index a JSON column so I can search and filter on nested fields?

How do I index a text array column?

How do I index the output of an expression, like lower(title) or a concatenation of two columns?

My table has more than 32 columns I want to search. How do I index them?

How do I create a partial index that only covers rows where status = 'published'?

When should I enable columnar storage on a field?

How do I reindex without taking search offline, and how do I verify index integrity afterwards?
```

## Basic Full-Text Search

```text
How do I implement fuzzy search with ParadeDB?

Write a ParadeDB query to search across multiple text fields

How do I add phrase queries to my full-text search?

What's the difference between a match query and a term query, and when should I use each?

How do I highlight the matching part of a document in my search results?
```

## Advanced Query Types

```text
How do I run a regex query over a text field, and can I do regex inside a phrase?

How do I build a "more like this" query to find documents similar to a given row?

How do I write a proximity query that matches two terms within N tokens of each other?

How do I implement search-as-you-type with a phrase prefix query?

How do I search a range column, e.g. find all rows whose validity range contains a given date?

Can I accept raw user query strings with AND/OR/NOT syntax, and what are the risks?

How do I combine several ParadeDB queries with boolean logic?
```

## Filtering

```text
How do I combine a full-text search with filters on numeric, boolean, and timestamp columns?

Why is my filter not being pushed down into the ParadeDB index, and how do I confirm with EXPLAIN?

How do I filter on a field whose values are case-sensitive when the default tokenizer lowercases everything?
```

## Vector Search

> Native vector search inside the ParadeDB index is a beta feature in `0.25.0` and above.
> ParadeDB uses pgvector's `vector` type, but its own SPANN-style index — not pgvector's HNSW or IVFFlat.

```text
How do I add a vector column to my ParadeDB index and run nearest-neighbour search?

Which distance operator do I use, and how does it have to match the operator class I indexed with?

How do I run a nearest-neighbour search restricted to rows that match a filter, in a single index scan?

How do I check with EXPLAIN that my vector query is using TopKScanExecState instead of a brute-force sort?

My vector results change between runs. How do I make the ordering deterministic?

How do I tune Paradedb to trade recall against latency?

What do centroid_ratio, training_samples_per_centroid, and cluster_replication do at index build time?

Should I migrate off pgvector's HNSW index, and what do I gain for filtered queries?

How do I generate embeddings for my documents and store them in a column ParadeDB can index?
```

## Hybrid Search

```text
How do I set up a hybrid search that fuses BM25 and vector results with reciprocal rank fusion?

Why can't I just add the BM25 score and the vector distance together?

How do I weight the text branch more heavily than the vector branch in my RRF query?

What rank constant (k) should I use for RRF, and how does it change the results?

How do I run nearest-neighbour search and combine it with text search for hybrid results?
```

## Joins

```text
How do I search across a joined table and still get the search pushed into the index?

What are the requirements for join pushdown in ParadeDB?

How do I write a semi join that returns parent rows having at least one matching child row?

How do I score a query that spans two tables?
```

## Analytics & Aggregations

```text
How do I implement category facets with counts for my e-commerce search results?

Write a ParadeDB query that returns faceted counts for brand, price range, and category

How do I build a filter sidebar with dynamic facet counts that update as users apply filters?

How do I add range aggregations for numeric fields, such as price?

How do I bucket search results into a date histogram by month?

How do I compute percentiles, cardinality, and stats over the rows matching a search?

How do I return the top hits within each bucket of a terms aggregation?

What are the limitations of ParadeDB aggregations, and how do I make them faster?
```

## Ranking & Relevance Tuning

```text
How do I configure BM25 field weights to prioritize title matches over description matches?

How do I add boost fields to prioritize certain matches?

How do I read pdb.score() and sort by relevance alongside another column?

How do I keep the Top K optimization when I sort by score and then by a tiebreaker column?
```

## Tokenizers & Token Filters

```text
What tokenizers are available in ParadeDB, and how do I configure them?

How do I set up ngram tokenization for partial matching and autocomplete?

How do I index Chinese, Japanese, or Korean text?

How do I apply stemming and stopword removal to one field but not another?

How do I make accented text match unaccented queries?

How do I index identifiers and code with a tokenizer that keeps snake_case and camelCase parts searchable?

Can one field have several tokenizers, and how do I choose which one a query uses?
```

## Handling No Results & Fallback Strategies

```text
What should I do to get documents for related terms when my primary search returns 0 results?

How do I implement a fallback from BM25 to vector search when there are no matches?

How do I configure fuzzy matching as a fallback when exact queries fail?
```

## Application & ORM Integration

```text
How do I define a ParadeDB index and run searches from Drizzle?

How do I use ParadeDB from Django without dropping to raw SQL?

Show me the SQLAlchemy equivalent of this ParadeDB query

How do I add ParadeDB search to an ActiveRecord model in Rails?

How do I call ParadeDB search and vector search from EF Core?

How do I paginate search results without the offset getting slow?
```

## Migration & Integration

```text
Translate this Elasticsearch query to ParadeDB SQL:
{
  "query": {
    "bool": {
      "must": [ { "match": { "description": "running shoes" } } ],
      "filter": [ { "term": { "brand": "nike" } } ]
    }
  }
}

Which Elasticsearch features have a ParadeDB equivalent, and which don't?

Can ParadeDB coexist with other PostgreSQL extensions?

How do I run ParadeDB alongside Citus?
```

## Performance & Optimization

```text
What are the best practices for scaling ParadeDB in production?

How do I monitor and tune ParadeDB performance?

How do I speed up index creation on a large table?

My write throughput dropped after adding a ParadeDB index. What should I tune?

How do I increase read throughput for a search-heavy workload?
```

## Operations & Deployment

```text
How do I deploy ParadeDB on Kubernetes with high availability?

How do I set up logical replication from my primary Postgres into ParadeDB?

How do I handle schema changes on the publisher once logical replication is running?

How do I upgrade ParadeDB safely, and what do I need to do to my indexes?

How do I run ParadeDB in CI with GitHub Actions or GitLab CI?
```
