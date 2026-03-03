# ParadeDB Example Prompts

This document contains example prompts you can use with the ParadeDB skill when working with your AI agent.

## Ask For Structured Answers

For more reviewable answers, prepend this instruction to any prompt:

```text
Use ParadeDB docs from https://docs.paradedb.com/llms-full.txt.
Return:
1) runnable SQL,
2) a short explanation,
3) version assumptions (ParadeDB/Postgres),
4) edge cases and tradeoffs.
```

## Network-Aware Prompt

Use this when you want strict behavior if docs cannot be fetched:

```text
If you cannot fetch live ParadeDB docs, show the exact error and ask whether to continue with local assumptions only.
```

## Getting Started & Setup

```text
What are the ways to index large datasets for search using ParadeDB?

What's the quickest way to create a full-text searchable table?

How do I generate embeddings for my documents and store them with pgvector?

```

## Basic Full-Text Search

```text
Create a BM25 index for full-text search on my products table

How do I implement fuzzy search with ParadeDB?

Write a ParadeDB query to search across multiple text fields

How do I add phrase queries to my BM25 search?

```

## Handling No Results & Fallback Strategies

```text
What should I do to get documents for related terms when my primary search returns 0 results?

How do I implement a fallback from BM25 to vector search when there are no matches?

How do I configure fuzzy matching as a fallback when exact queries fail?

```

## Advanced Search Features

```text
Write a ParadeDB query with faceted search and aggregations

How do I run nearest neighbor search and combine with text search for hybrid results?

How do I set up hybrid search that fuses BM25 and vector scores?

How do I add boost fields to prioritize certain matches?

What tokenizers are available in ParadeDB and how do I configure them?

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

Can ParadeDB coexist with other PostgreSQL extensions?

```

## Performance & Optimization

```text
How do I configure field weights in BM25 to prioritize title matches over description?

How do I set up ngram tokenization for partial matching and autocomplete?

What are the best practices for scaling ParadeDB in production?

How do I monitor and tune ParadeDB performance?

```

## Analytics & Aggregations

```text
How do I implement category facets with counts for my e-commerce search results?

Write a ParadeDB query that returns faceted counts for brand, price range, and category

How do I build a filter sidebar with dynamic facet counts that update as users apply filters?

How do I add range aggregations for numeric fields like price?

```
