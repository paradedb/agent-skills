> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# ASCII Folding

> Strips away diacritical marks like accents

The ASCII folding filter strips away diacritical marks (accents, umlauts, tildes, etc.) while leaving the base character intact.
It is supported for all tokenizers besides the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer.

To enable, append `ascii_folding=true` to the tokenizer's arguments.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('ascii_folding=true')))
WITH (key_field='id');
```

To demonstrate this token filter, let's compare the output of the following two statements:

```sql theme={null}
SELECT
  'Café naïve coöperate'::pdb.simple::text[],
  'Café naïve coöperate'::pdb.simple('ascii_folding=true')::text[];
```

```ini Expected Response theme={null}
          text          |          text
------------------------+------------------------
 {café,naïve,coöperate} | {cafe,naive,cooperate}
(1 row)
```
