> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Lowercase

> Converts all characters to lowercase

The lowercase filter converts all characters to lowercase, allowing for case-insensitive queries. It is enabled by default but can be
configured for all tokenizers besides the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer.

To disable, append `lowercase=false` to the tokenizer's arguments:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('lowercase=false')))
WITH (key_field='id');
```

To demonstrate this token filter, let's compare the output of the following two statements:

```sql theme={null}
SELECT
  'Tokenize me!'::pdb.simple::text[],
  'Tokenize me!'::pdb.simple('lowercase=false')::text[];
```

```ini Expected Response theme={null}
     text      |     text
---------------+---------------
 {tokenize,me} | {Tokenize,me}
(1 row)
```
