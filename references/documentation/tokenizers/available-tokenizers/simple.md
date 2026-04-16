> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Simple

> Splits on any non-alphanumeric character

The simple tokenizer splits on any non-alphanumeric character (e.g. whitespace, punctuation, symbols). All characters are
[lowercased](/documentation/token-filters/lowercase) by default.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Tokenize me!'::pdb.simple::text[];
```

```ini Expected Response theme={null}
     text
---------------
 {tokenize,me}
(1 row)
```
