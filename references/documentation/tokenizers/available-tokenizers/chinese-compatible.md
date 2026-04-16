> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Chinese Compatible

> A simple tokenizer for Chinese, Japanese, and Korean characters

The Chinese compatible tokenizer is like the [simple](/documentation/tokenizers/available-tokenizers/simple) tokenizer -- it lowercases non-CJK characters and splits on
any non-alphanumeric character. Additionally, it treats each CJK character as its own token.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.chinese_compatible))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Hello world! 你好!'::pdb.chinese_compatible::text[];
```

```ini Expected Response theme={null}
        text
---------------------
 {hello,world,你,好}
(1 row)
```
