> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Phrase Prefix

> Finds documents containing a phrase followed by a term prefix

Phrase prefix identifies documents containing a phrase followed by a term prefix.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ pdb.phrase_prefix(ARRAY['running', 'sh']);
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, PhrasePrefix

  MockItem.objects.filter(
      description=ParadeDB(PhrasePrefix('running', 'sh'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.phrase_prefix(MockItem.description, ["running", "sh"]))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .phrase_prefix("running", "sh")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

<div className="mt-8" />

<ParamField body="phrases" required>
  An `ARRAY` of tokens that the search is looking to match, followed by a term
  prefix rather than a complete term.
</ParamField>

<ParamField body="max_expansions" default={50}>
  Limits the number of term variations that the prefix can expand to during the
  search. This helps in controlling the breadth of the search by setting a cap
  on how many different terms the prefix can match.
</ParamField>

## Performance Considerations

Expanding a prefix might lead to thousands of matching terms, which impacts search times.

With `max_expansions`, the prefix term is expanded to at most `max_expansions` terms
in lexicographic order. For instance, if `sh` matches `shall`, `share`, `shoe`, and `shore` but `max_expansions` is set to 3,
`sh` will only be expanded to `shall`, `share`, and `shoe`.
