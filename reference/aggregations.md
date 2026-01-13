# ParadeDB Aggregations Reference

ParadeDB aggregations use `pdb.agg()` with Elasticsearch-compatible JSON syntax. They execute on the columnar portion of the BM25 index for high performance.

## Metrics Aggregations

### Count
```sql
SELECT pdb.agg('{"value_count": {"field": "id"}}')
FROM my_table WHERE id @@@ pdb.all();
-- Returns: {"value": 41.0}
```

### Sum
```sql
SELECT pdb.agg('{"sum": {"field": "rating"}}')
FROM my_table WHERE id @@@ pdb.all();
-- Returns: {"value": 158.0}
```

### Average
```sql
SELECT pdb.agg('{"avg": {"field": "rating"}}')
FROM my_table WHERE id @@@ pdb.all();
-- Returns: {"value": 3.8536585365853657}
```

### Min/Max
```sql
SELECT pdb.agg('{"min": {"field": "rating"}}') FROM my_table WHERE id @@@ pdb.all();
SELECT pdb.agg('{"max": {"field": "rating"}}') FROM my_table WHERE id @@@ pdb.all();
```

### Stats (all at once)
```sql
SELECT pdb.agg('{"stats": {"field": "rating"}}')
FROM my_table WHERE id @@@ pdb.all();
-- Returns: {"avg": 3.85, "max": 5.0, "min": 1.0, "sum": 158.0, "count": 41}
```

### Percentiles
```sql
SELECT pdb.agg('{"percentiles": {"field": "rating", "percents": [50, 95]}}')
FROM my_table WHERE id @@@ pdb.all();
-- Returns: {"values": {"50.0": 4.01, "95.0": 5.00}}
```

### Cardinality (Distinct Count Estimate)
Uses HyperLogLog++ for fast approximation.
```sql
SELECT pdb.agg('{"cardinality": {"field": "rating"}}')
FROM my_table WHERE id @@@ pdb.all();
-- Returns: {"value": 5.0}
```

## Bucket Aggregations

### Histogram
```sql
SELECT pdb.agg('{"histogram": {"field": "rating", "interval": "1"}}')
FROM my_table WHERE id @@@ pdb.all();
-- Returns: {"buckets": [{"key": 1.0, "doc_count": 1}, {"key": 2.0, "doc_count": 3}, ...]}
```

### Date Histogram
```sql
SELECT pdb.agg('{"date_histogram": {"field": "created_at", "fixed_interval": "30d"}}')
FROM my_table WHERE id @@@ pdb.all();
```

### Range
```sql
SELECT pdb.agg('{"range": {"field": "rating", "ranges": [{"to": 3.0}, {"from": 3.0, "to": 6.0}]}}')
FROM my_table WHERE id @@@ pdb.all();
```

### Terms (GROUP BY equivalent)
```sql
SELECT rating, pdb.agg('{"value_count": {"field": "id"}}')
FROM my_table
WHERE id @@@ pdb.all()
GROUP BY rating
ORDER BY rating
LIMIT 10;
```

**Important:** Text/JSON fields in GROUP BY must use the `literal` tokenizer.

### Top Hits
Get top documents for each bucket:
```sql
SELECT pdb.agg('{"top_hits": {"size": 3, "sort": [{"created_at": "desc"}], "docvalue_fields": ["id", "created_at"]}}')
FROM my_table
WHERE id @@@ pdb.all()
GROUP BY rating;
```

## Faceted Queries

Combine Top N results with aggregates in one query:
```sql
SELECT
  id, description, rating,
  pdb.agg('{"value_count": {"field": "id"}}') OVER ()
FROM my_table
WHERE category === 'electronics'
ORDER BY rating DESC
LIMIT 3;
```

### Performance Optimization
Disable visibility checks for approximate but faster results:
```sql
SELECT description, pdb.agg('{"value_count": {"field": "id"}}', false) OVER ()
FROM my_table WHERE description ||| 'shoes'
LIMIT 5;
```

## Filter Aggregations

Multiple aggregates with different filters:
```sql
SELECT
    pdb.agg('{"value_count": {"field": "id"}}') FILTER (WHERE category === 'electronics') AS electronics_count,
    pdb.agg('{"value_count": {"field": "id"}}') FILTER (WHERE category === 'footwear') AS footwear_count
FROM my_table;
```

## Multiple Aggregations

Compute multiple aggregations at once:
```sql
SELECT
  pdb.agg('{"avg": {"field": "rating"}}') AS avg_rating,
  pdb.agg('{"value_count": {"field": "id"}}') AS count
FROM my_table WHERE category === 'electronics';
```

## JSON Fields

Use dot notation for JSON sub-fields:
```sql
SELECT pdb.agg('{"terms": {"field": "metadata.color"}}')
FROM my_table WHERE id @@@ pdb.all();
```

**Note:** Text/JSON fields inside `pdb.agg` must use the `literal` tokenizer.

## SQL Syntax (Beta)

Enable with:
```sql
SET paradedb.enable_aggregate_custom_scan TO on;
```

Then use standard SQL:
```sql
SELECT COUNT(*), AVG(rating), SUM(rating), MIN(rating), MAX(rating)
FROM my_table WHERE id @@@ pdb.all();
```

## Limitations

1. A ParadeDB operator must be present for aggregate pushdown. Use `id @@@ pdb.all()` to force it.
2. JOINs are not yet pushed down (on roadmap).
