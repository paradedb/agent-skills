# ParadeDB Tokenizers Reference

Tokenizers split text into searchable units (tokens). Configure them during index creation.

## Available Tokenizers

### Unicode (Default)
Splits text according to Unicode Standard Annex #29 word boundaries. Lowercases by default.
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, description)  -- uses unicode by default
WITH (key_field='id');

-- Or explicitly:
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.unicode_words))
WITH (key_field='id');
```

Test tokenization:
```sql
SELECT 'Tokenize me!'::pdb.unicode_words::text[];
-- Returns: {tokenize,me}
```

### Simple
Splits on whitespace and punctuation, lowercases.
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.simple))
WITH (key_field='id');
```

### Whitespace
Splits only on whitespace, preserves case.
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.whitespace))
WITH (key_field='id');
```

### Literal
No tokenization - entire text is a single token. Required for:
- Exact string matching
- Text fields in ORDER BY
- Text fields in GROUP BY
- Text fields in aggregations

```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (category::pdb.literal))
WITH (key_field='id');
```

### Literal Normalized
Like literal but allows token filters (lowercases by default).
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (category::pdb.literal_normalized))
WITH (key_field='id');

SELECT 'Tokenize me!'::pdb.literal_normalized::text[];
-- Returns: {"tokenize me!"}
```

### Ngram
Creates character n-grams for partial/substring matching.
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.ngram(3,3)))  -- trigrams only
WITH (key_field='id');

-- Variable length grams (2-5 characters)
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.ngram(2,5)))
WITH (key_field='id');
```

Test:
```sql
SELECT 'Hello world!'::pdb.ngram(3,3)::text[];
-- Returns: {hel,ell,llo,"lo ",o w," wo",wor,orl,rld,"ld!"}
```

### ICU (International Components for Unicode)
Best for multi-language text. Handles nuances in word boundaries across languages.
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.icu))
WITH (key_field='id');

SELECT 'Hello world! 你好!'::pdb.icu::text[];
```

## Token Filters

Apply additional processing after tokenization. Add as arguments to the tokenizer.

### Stemming
Reduce words to root form.
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.simple('stemmer=english')))
WITH (key_field='id');
```

Supported languages: `arabic`, `danish`, `dutch`, `english`, `finnish`, `french`, `german`, `greek`, `hungarian`, `italian`, `norwegian`, `portuguese`, `romanian`, `russian`, `spanish`, `swedish`, `tamil`, `turkish`

### ASCII Folding
Convert accented characters to ASCII equivalents.
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.simple('ascii_folding=true')))
WITH (key_field='id');
```

### Token Length Filtering
Remove tokens that are too short or too long.
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.simple('remove_long=100', 'remove_short=2')))
WITH (key_field='id');
```

### Combining Filters
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (description::pdb.simple('stemmer=english', 'ascii_folding=true', 'remove_short=2')))
WITH (key_field='id');
```

## Multiple Tokenizers Per Field

Index the same field with different tokenizers using aliases:
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (
  id,
  (description::pdb.literal),
  (description::pdb.simple('alias=description_simple'))
) WITH (key_field='id');
```

Query against the aliased field:
```sql
SELECT * FROM my_table
WHERE description::pdb.alias('description_simple') ||| 'Sleek running shoes';
```

**Recommendation:** If using multiple tokenizers including `literal`, leave `literal` un-aliased for ORDER BY/GROUP BY compatibility.

## Custom Query Tokenization

Override the default query tokenizer:
```sql
-- Use whitespace tokenizer for this query only
SELECT * FROM my_table
WHERE description ||| 'running shoes'::pdb.whitespace;

-- Use pretokenized array (no further processing)
SELECT * FROM my_table
WHERE description &&& ARRAY['running', 'shoes'];
```

## Indexing Expressions

### Text Expressions
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, ((description || ' ' || category)::pdb.simple('alias=combined_text')))
WITH (key_field='id');
```

### Non-Text Expressions
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, description, ((rating + 1)::pdb.alias('adjusted_rating')))
WITH (key_field='id');
```

## Indexing JSON

JSON fields are automatically indexed with all sub-fields:
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, metadata)
WITH (key_field='id');
```

Configure tokenizer for all JSON text fields:
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, (metadata::pdb.ngram(2,3)))
WITH (key_field='id');
```

Index specific JSON sub-fields:
```sql
CREATE INDEX search_idx ON my_table
USING bm25 (id, ((metadata->>'color')::pdb.ngram(2,3)))
WITH (key_field='id');
```

## Indexing Text Arrays

```sql
CREATE TABLE array_demo (id SERIAL PRIMARY KEY, categories TEXT[]);
CREATE INDEX ON array_demo USING bm25 (id, categories) WITH (key_field = 'id');

-- Matches if ANY array element matches
SELECT * FROM array_demo WHERE categories === 'food';
```
