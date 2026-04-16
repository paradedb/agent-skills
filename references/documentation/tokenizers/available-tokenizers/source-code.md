> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Source Code

> Tokenizes text that is actually code

The source code tokenizer is intended for tokenizing code. In addition to splitting on whitespace,
punctuation, and symbols, it also splits on common casing conventions like camel case and snake case. For instance, text like
`my_variable` or `myVariable` would get split into `my` and `variable`.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.source_code))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'let my_variable = 2;'::pdb.source_code::text[];
```

```ini Expected Response theme={null}
        text
---------------------
 {let,my,variable,2}
(1 row)
```
