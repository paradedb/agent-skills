> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Regex Patterns

> Tokenizes text using a regular expression

The `regex_pattern` tokenizer tokenizes text using a regular expression. The regular expression can be specified with the pattern parameter.
For instance, the following tokenizer creates tokens only for words starting with the letter `h`:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.regex_pattern('(?i)\bh\w*')))
WITH (key_field='id');
```

The regex tokenizer uses the Rust [regex](https://docs.rs/regex/latest/regex/) crate, which supports all regex constructs with the following
exceptions:

1. Lazy quantifiers such as `+?`
2. Word boundaries such as `\b`

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Hello world!'::pdb.regex_pattern('(?i)\bh\w*')::text[];
```

```ini Expected Response theme={null}
  text
---------
 {hello}
(1 row)
```
