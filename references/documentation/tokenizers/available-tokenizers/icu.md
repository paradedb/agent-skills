> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# ICU

> Splits text according to the Unicode standard

The ICU (International Components for Unicode) tokenizer breaks down text according to the Unicode standard. It can be used to tokenize most languages and recognizes the nuances in word boundaries across different languages.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.icu))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Hello world! 你好!'::pdb.icu::text[];
```

```ini Expected Response theme={null}
        text
--------------------
 {hello,world,你好}
(1 row)
```
