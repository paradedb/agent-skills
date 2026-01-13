# ParadeDB Performance Tuning Reference

## Index Creation

### Parallel Indexing Workers
```sql
SET max_parallel_maintenance_workers = 8;
```
Must be ≤ `max_parallel_workers` and `max_worker_processes`.

### Indexing Memory
```sql
SET maintenance_work_mem = '2GB';
```
Minimum 15MB per parallel worker.

### Defer Index Creation
Create index AFTER populating the table for better performance:
```sql
CREATE TABLE test (id SERIAL, data text);
INSERT INTO test (data) VALUES ('hello world'), ('many more values');
CREATE INDEX ON test USING bm25 (id, data) WITH (key_field = 'id');
```

### Track Progress
```sql
SELECT pid, phase, blocks_done, blocks_total FROM pg_stat_progress_create_index;
```

## Read Performance

### Parallel Workers
```ini
# postgresql.conf
max_worker_processes = 72
max_parallel_workers = 64
max_parallel_workers_per_gather = 4
```

### Shared Buffers
Allocate up to 40% of RAM:
```ini
shared_buffers = 8GB
```

### Index Prewarming
```sql
CREATE EXTENSION pg_prewarm;
SELECT pg_prewarm('search_idx');
```

### Autovacuum
Configure for frequently updated tables:
```sql
ALTER TABLE my_table SET (autovacuum_vacuum_threshold = 500);
```

Or globally:
```ini
autovacuum_vacuum_scale_factor = 0
autovacuum_vacuum_threshold = 100000
```

### Target Segment Count
Match to `max_parallel_workers_per_gather`:
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, description)
WITH (key_field = 'id', target_segment_count = 8);

-- Or alter existing index
ALTER INDEX search_idx SET (target_segment_count = 8);
REINDEX INDEX search_idx;
```

## Write Performance

### Background Merging
Configure layer sizes for background segment merging:
```sql
ALTER INDEX search_idx SET (background_layer_sizes = '100MB, 1GB');
```

Disable background merging:
```sql
ALTER INDEX search_idx SET (background_layer_sizes = '0');
```

### Foreground Merging (Apply Backpressure)
```sql
ALTER INDEX search_idx SET (layer_sizes = '100KB, 1MB');
```

### Work Memory for Bulk Updates
```sql
SET work_mem = '64MB';
```

### Mutable Segment Size
Buffer writes before flushing (improves write throughput, may slow reads):
```sql
-- Per index
ALTER INDEX search_idx SET (mutable_segment_rows = 1000);

-- Global
SET paradedb.global_mutable_segment_rows = 1000;
```

## Aggregate Performance

### Parallel Workers
Increase for faster aggregates:
```sql
SET max_parallel_workers_per_gather = 4;
```

### Vacuum
```sql
VACUUM my_table;
```

### Prewarming
```sql
SELECT pg_prewarm('search_idx');
```

### Faceted Query Optimization
Disable visibility checks for approximate but faster results:
```sql
SELECT description, pdb.agg('{"value_count": {"field": "id"}}', false) OVER ()
FROM my_table WHERE description ||| 'shoes' LIMIT 5;
```

## JOIN Performance

### Fast Cases
Each table filtered independently before JOIN:
```sql
SELECT a.name, b.title
FROM authors a JOIN books b ON a.id = b.author_id
WHERE a.bio ||| 'science fiction' AND b.content ||| 'space travel';
```

### Slow Cases (Cross-table OR)
Avoid OR conditions spanning tables:
```sql
-- SLOW: OR prevents pushdown
WHERE a.bio ||| 'science' OR b.content ||| 'artificial'
```

### Optimization: Use UNION Instead
```sql
SELECT a.name, b.title FROM authors a JOIN books b ON a.id = b.author_id
WHERE a.bio ||| 'science'
UNION
SELECT a.name, b.title FROM authors a JOIN books b ON a.id = b.author_id
WHERE b.content ||| 'artificial';
```

### Optimization: Use CTEs
```sql
WITH matching_authors AS (
  SELECT id, name FROM authors WHERE bio ||| 'science' LIMIT 100
),
matching_books AS (
  SELECT id, title, author_id FROM books WHERE content ||| 'artificial' LIMIT 100
)
SELECT ma.name, mb.title
FROM matching_authors ma
JOIN matching_books mb ON ma.id = mb.author_id;
```

## Diagnosing Performance

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM my_table WHERE description ||| 'running shoes' LIMIT 10;
```

Watch for:
- `Custom Scan` with large row counts
- `Tantivy Query: all` (full index scan)
- Large `Heap Fetches` (run VACUUM)
- ParadeDB operators in JOIN conditions (slow)

## Reindexing

```sql
-- Exclusive lock (blocks writes)
REINDEX INDEX search_idx;

-- Concurrent (allows writes, slower)
REINDEX INDEX CONCURRENTLY search_idx;
```

**Note:** If `REINDEX CONCURRENTLY` fails, drop invalid `*_ccnew` indexes manually.
