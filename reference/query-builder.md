# ParadeDB Query Builder Reference

Advanced query functions use the `@@@` operator with `pdb.*` functions.

## Basic Query Types

### Match Disjunction (`|||`)
Matches documents containing ANY of the query tokens.
```sql
SELECT * FROM my_table WHERE description ||| 'running shoes';
-- Matches: "Sleek running shoes", "Generic shoes", "White jogging shoes"
```

### Match Conjunction (`&&&`)
Matches documents containing ALL query tokens.
```sql
SELECT * FROM my_table WHERE description &&& 'running shoes';
-- Matches only: "Sleek running shoes"
```

### Phrase (`###`)
Matches exact token sequence.
```sql
SELECT * FROM my_table WHERE description ### 'running shoes';
-- Matches "running shoes" but NOT "shoes running" or "running sleek shoes"
```

### Term (`===`)
Exact token match (case-sensitive to indexed tokens).
```sql
SELECT * FROM my_table WHERE description === 'running';
-- Note: Most tokenizers lowercase, so 'RUNNING' won't match
```

### Term Set
Match any of multiple exact tokens:
```sql
SELECT * FROM my_table WHERE description === ARRAY['shoes', 'running'];
```

## Fuzzy Search

Allow typos using Levenshtein edit distance (max 2).

```sql
-- Edit distance 2
SELECT * FROM my_table WHERE description ||| 'runing shose'::pdb.fuzzy(2);

-- Fuzzy prefix matching
SELECT * FROM my_table WHERE description === 'rann'::pdb.fuzzy(1, t);

-- Transposition cost = 1 (default is 2)
SELECT * FROM my_table WHERE description === 'shose'::pdb.fuzzy(1, f, t);
```

Parameters: `fuzzy(distance, prefix?, transpose_cost_1?)`

## Phrase with Slop

Allow flexibility in token positions:
```sql
-- Slop of 2 allows transpositions or extra words
SELECT * FROM my_table WHERE description ### 'shoes running'::pdb.slop(2);
```

## Proximity Queries

Match tokens within a certain distance:
```sql
-- 'sleek' within 1 token of 'shoes' (any order)
SELECT * FROM my_table WHERE description @@@ ('sleek' ## 1 ## 'shoes');

-- Ordered: 'sleek' must come before 'shoes'
SELECT * FROM my_table WHERE description @@@ ('sleek' ##> 1 ##> 'shoes');
```

### Proximity with Regex
```sql
SELECT * FROM my_table
WHERE description @@@ (pdb.prox_regex('sl.*') ## 1 ## 'shoes');

-- Limit regex expansions
SELECT * FROM my_table
WHERE description @@@ (pdb.prox_regex('sl.*', 100) ## 1 ## 'shoes');
```

### Proximity with Array
```sql
SELECT * FROM my_table
WHERE description @@@ (pdb.prox_array('sleek', 'white') ## 1 ## 'shoes');
```

## Regex Queries

Rust regex syntax (no lazy quantifiers or `\b`).
```sql
SELECT * FROM my_table WHERE description @@@ pdb.regex('key.*rd');
```

Supports:
- Named/numbered capture groups
- Case insensitivity: `(?i)pattern`
- Multi-line mode: `(?m)pattern`

## Regex Phrase

Match sequence of regex patterns:
```sql
SELECT * FROM my_table WHERE description @@@ pdb.regex_phrase(ARRAY['ru.*', 'shoes']);
-- Matches "running shoes" but not "shoes running"
```

Parameters:
- `slop` - flexibility in positions (default 0)
- `max_expansions` - limit regex expansions

## Phrase Prefix (Autocomplete)

```sql
SELECT * FROM my_table WHERE description @@@ pdb.phrase_prefix(ARRAY['running', 'sh']);
-- Matches "running shoes", "running shorts", etc.
```

Parameters:
- `max_expansions` - limit prefix expansions

## Range Term Queries

For Postgres range types (`int4range`, `daterange`, etc.):
```sql
-- Contains value
SELECT * FROM my_table WHERE weight_range @@@ pdb.range_term(1);

-- Range intersects
SELECT * FROM my_table WHERE weight_range @@@ pdb.range_term('(10, 12]'::int4range, 'Intersects');

-- Range contains
SELECT * FROM my_table WHERE weight_range @@@ pdb.range_term('(3, 9]'::int4range, 'Contains');

-- Range within
SELECT * FROM my_table WHERE weight_range @@@ pdb.range_term('(2, 11]'::int4range, 'Within');
```

## More Like This (MLT)

Find similar documents:
```sql
-- Find documents like document with id=3
SELECT * FROM my_table WHERE id @@@ pdb.more_like_this(3);

-- Limit to specific fields
SELECT * FROM my_table WHERE id @@@ pdb.more_like_this(3, ARRAY['description']);

-- Custom document as JSON
SELECT * FROM my_table WHERE id @@@ pdb.more_like_this('{"description": "Sleek running shoes"}');
```

Options:
- `min_term_frequency` / `max_term_frequency`
- `min_doc_frequency` / `max_doc_frequency`
- `max_query_terms` (default 25)
- `min_word_length` / `max_word_length`
- `stopwords => ARRAY['the', 'a']`

## Query Parser (Tantivy Syntax)

Accept raw user query strings:
```sql
SELECT * FROM my_table WHERE id @@@ pdb.parse('description:(sleek shoes) AND rating:>3');

-- Lenient mode (best-effort parsing)
SELECT * FROM my_table WHERE id @@@ pdb.parse('sleek shoes', lenient => true);

-- Conjunction mode (AND terms by default)
SELECT * FROM my_table WHERE id @@@ pdb.parse('description:(sleek shoes)', conjunction_mode => true);
```

Tantivy query syntax:
- `field:term` - field-specific search
- `field:(term1 term2)` - multiple terms
- `field:>value` - range queries
- `AND`, `OR`, `NOT` - boolean operators
- `"phrase query"` - exact phrase

## All Query

Force ParadeDB index usage:
```sql
SELECT * FROM my_table WHERE id @@@ pdb.all() ORDER BY rating LIMIT 10;
```

## Boosting (Relevance Tuning)

Increase/decrease query weight:
```sql
SELECT id, pdb.score(id), description FROM my_table
WHERE description ||| 'shoes'::pdb.boost(2.0)
   OR category === 'footwear'::pdb.boost(0.5);
```

## Highlighting

### Single Best Snippet
```sql
SELECT pdb.snippet(description) FROM my_table WHERE description ||| 'shoes';

-- Custom tags
SELECT pdb.snippet(description, start_tag => '*', end_tag => '*') FROM my_table WHERE description ||| 'shoes';
```

### Multiple Snippets
```sql
SELECT pdb.snippets(description, max_num_chars => 15) FROM my_table WHERE description ||| 'artistic vase';
```

Options: `limit`, `offset`, `sort_by` ('score' or 'position')

### Byte Offsets
```sql
SELECT pdb.snippet_positions(description) FROM my_table WHERE description ||| 'shoes';
-- Returns: {"{14,19}"}
```

## BM25 Scoring

```sql
SELECT description, pdb.score(id) FROM my_table
WHERE description ||| 'running shoes'
ORDER BY score DESC;
```

Note: Include fields in the BM25 index for them to contribute to the score.
