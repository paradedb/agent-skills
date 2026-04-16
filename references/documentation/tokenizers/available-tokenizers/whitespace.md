> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Whitespace

> Tokenizes text by splitting on whitespace

The whitespace tokenizer splits only on whitespace. It also [lowercases](/documentation/token-filters/lowercase) characters by default.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.whitespace))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Tokenize me!'::pdb.whitespace::text[];
```

```ini Expected Response theme={null}
      text
----------------
 {tokenize,me!}
(1 row)
```
