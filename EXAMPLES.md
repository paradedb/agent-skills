# ParadeDB Example Prompts

This document contains example prompts you can use with the ParadeDB skill when working with your AI agent.

## Getting Started & Setup

```text
What are the ways to index large datasets for search using ParadeDB?

What's the quickest way to create a full-text searchable table?

How do I generate embeddings for my documents and store them as pgvector columns?
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

How do I run nearest neighbour search and combine it with text search for hybrid results?

How do I set up a hybrid search that fuses BM25 and vector scores?

How do I add boost fields to prioritize certain matches?

What tokenizers are available in ParadeDB, and how do I configure them?
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
How do I configure BM25 field weights to prioritize title matches over description matches?

How do I set up ngram tokenization for partial matching and autocomplete?

What are the best practices for scaling ParadeDB in production?

How do I monitor and tune ParadeDB performance?
```

## Analytics & Aggregations

```text
How do I implement category facets with counts for my e-commerce search results?

Write a ParadeDB query that returns faceted counts for brand, price range, and category

How do I build a filter sidebar with dynamic facet counts that update as users apply filters?

How do I add range aggregations for numeric fields, such as price?
```
