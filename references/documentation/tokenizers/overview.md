> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# How Tokenizers Work

> Tokenizers split large chunks of text into small, searchable units called tokens

Before text is indexed, it is first split into searchable units called tokens.

The default tokenizer in ParadeDB is the [unicode\_words tokenizer](/documentation/tokenizers/available-tokenizers/unicode). It splits text according to word boundaries defined by the Unicode Standard Annex #29 rules. All characters are lowercased by default. To visualize how this tokenizer works, you can cast a text string to the tokenizer type, and then to `text[]`:

```sql theme={null}
SELECT 'Hello world!'::pdb.unicode_words::text[];
```

```ini Expected Response theme={null}
     text
---------------
 {hello,world}
(1 row)
```

On the other hand, the [ngrams](/documentation/tokenizers/available-tokenizers/ngrams) tokenizer splits text into "grams" of size `n`. In this example, `n = 3`:

```sql theme={null}
SELECT 'Hello world!'::pdb.ngram(3,3)::text[];
```

```ini Expected Response theme={null}
                      text
-------------------------------------------------
 {hel,ell,llo,"lo ","o w"," wo",wor,orl,rld,ld!}
(1 row)
```

Choosing the right tokenizer is crucial to getting the search results you want. For instance, the simple tokenizer works best for whole-word matching like "hello" or "world", while the ngram tokenizer enables partial matching.

To configure a tokenizer for a column in the index, simply cast it to the desired tokenizer type:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.ngram(3,3)))
WITH (key_field='id');
```
