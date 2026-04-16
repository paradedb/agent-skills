> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Indexing Text Arrays

> Add text arrays to the index

The BM25 index accepts arrays of type `text[]` or `varchar[]`.

```sql theme={null}
CREATE TABLE array_demo (id SERIAL PRIMARY KEY, categories TEXT[]);
INSERT INTO array_demo (categories) VALUES
    ('{"food","groceries and produce"}'),
    ('{"electronics","computers"}'),
    ('{"books","fiction","mystery"}');

CREATE INDEX ON array_demo USING bm25 (id, categories)
WITH (key_field = 'id');
```

Under the hood, each element in the array is indexed as a separate entry. This means that an array is considered a
match if **any** of its entries is a match.

```sql theme={null}
SELECT * FROM array_demo WHERE categories === 'food';
```

```ini Expected Response theme={null}
 id |           categories
----+--------------------------------
  1 | {food,"groceries and produce"}
(1 row)
```

Text arrays can be [tokenized](/documentation/tokenizers/overview) and [filtered](/documentation/token-filters/overview) in the same way as text fields:

```sql theme={null}
CREATE INDEX ON array_demo USING bm25 (id, (categories::pdb.literal))
WITH (key_field = 'id');
```
