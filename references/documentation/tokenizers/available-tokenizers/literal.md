> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Literal

> Indexes the text in its raw form, without any splitting or processing

<Note>
  The literal tokenizer is not ideal for text search queries like
  [match](/documentation/full-text/match) or
  [phrase](/documentation/full-text/phrase). If you need to do text search over
  a field that is literal tokenized, consider using [multiple
  tokenizers](/documentation/tokenizers/multiple-per-field).
</Note>

<Note>
  Because the literal tokenizer preserves the source text exactly, [token
  filters](/documentation/token-filters/overview) cannot be configured for this
  tokenizer.
</Note>

The literal tokenizer applies no tokenization to the text, preserving it as-is. It is the default for `uuid` fields (since
exact UUID matching is a common use case), and is useful for doing exact string matching over text fields.

It is also required if the text field is used as a sort field in a [Top K](/documentation/sorting/topk) query,
or as part of an [aggregate](/documentation/aggregates/overview).

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.literal))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Tokenize me!'::pdb.literal::text[];
```

```ini Expected Response theme={null}
       text
------------------
 {"Tokenize me!"}
(1 row)
```
