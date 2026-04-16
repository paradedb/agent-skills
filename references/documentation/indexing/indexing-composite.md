> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Indexing 32+ Columns

> Use composite types to index more than 32 columns

<Note>This is a beta feature available in versions `0.22.0` and above.</Note>

Postgres allows a maximum of 32 columns in an index definition, but because ParadeDB benefits from pushing filters and ranking signals into the BM25 index this can become a limitation.

To index more than 32 columns in a single BM25 index,
wrap columns in a `ROW()` expression cast to a composite type. ParadeDB will unpack the composite type and index each
field individually.

## Creating a Composite Type

First, define a composite type whose field names and types match the columns you want to index:

```sql theme={null}
CREATE TYPE item_fields AS (description TEXT, category TEXT, rating INTEGER);
```

Then reference the columns in a `ROW()` expression cast to the composite type:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (ROW(description, category, rating)::item_fields))
WITH (key_field='id');
```

Each field in the composite type is indexed as if it were a standalone column. Queries use the field names
directly with the standard operators:

```sql theme={null}
SELECT description, category FROM mock_items
WHERE description &&& 'running shoes';
```

## Configuring Tokenizers

Fields in the composite type can use [tokenizers](/documentation/tokenizers/overview) and
[token filters](/documentation/token-filters/overview) by specifying them as the field type:

```sql theme={null}
CREATE TYPE item_fields AS (
    description pdb.simple('stemmer=english'),
    category pdb.literal,
    in_stock BOOLEAN
);

CREATE INDEX search_idx ON mock_items
USING bm25 (id, (ROW(description, category, in_stock)::item_fields))
WITH (key_field='id');
```

## Constraints

The following are not supported and will produce an error:

* **Anonymous ROW expressions**: `ROW(a, b)` without a type cast is not allowed. Always cast to a named composite type.
* **Nested composites**: A composite type cannot contain another composite type as a field.
* **Duplicate field names**: Field names must be unique across all composite types and regular columns in the index.
