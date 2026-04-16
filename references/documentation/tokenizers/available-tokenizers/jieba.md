> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Jieba

> The most advanced Chinese tokenizer that leverages both a dictionary and statistical models

The Jieba tokenizer is a tokenizer for Chinese text that leverages both a dictionary and statistical models. It is generally considered to be better at identifying ambiguous Chinese word boundaries
compared to the [Chinese Lindera](/documentation/tokenizers/available-tokenizers/lindera) and [Chinese compatible](/documentation/tokenizers/available-tokenizers/chinese-compatible) tokenizers, but
the tradeoff is that it is slower.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.jieba))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Hello world! 你好!'::pdb.jieba::text[];
```

```ini Expected Response theme={null}
              text
--------------------------------
 {hello," ",world,!," ",你好,!}
(1 row)
```
