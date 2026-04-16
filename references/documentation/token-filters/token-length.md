> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Token Length

> Remove tokens that are above or below a certain byte length from the index

The token length filter automatically removes tokens that are above or below a certain length in bytes.
To remove all tokens longer than a certain length, append a `remove_long` configuration to the tokenizer:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('remove_long=100')))
WITH (key_field='id');
```

To remove all tokens shorter than a length, use `remove_short`:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('remove_short=3')))
WITH (key_field='id');
```

All tokenizers besides the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer accept these configurations.

To demonstrate this token filter, let's compare the output of the following two statements:

```sql theme={null}
SELECT
  'A supersupersuperlong token'::pdb.simple::text[],
  'A supersupersuperlong token'::pdb.simple('remove_short=2', 'remove_long=10')::text[];
```

```ini Expected Response theme={null}
             text              |  text
-------------------------------+---------
 {a,supersupersuperlong,token} | {token}
(1 row)
```
