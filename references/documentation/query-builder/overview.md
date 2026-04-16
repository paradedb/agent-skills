> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# How Advanced Query Functions Work

> ParadeDB's query builder functions provide advanced query types

In addition to basic [match](/documentation/full-text/match), [phrase](/documentation/full-text/phrase), and
[term](/documentation/full-text/term) queries, additional advanced query types are exposed as query builder functions.

Query builder functions use the `@@@` operator. `@@@` takes a column on the left-hand side and a query builder function on the
right-hand side. It means "find all rows where the column matches the given query."

For example:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ pdb.regex('key.*rd');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Regex

  MockItem.objects.filter(
      description=ParadeDB(Regex('key.*rd'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.regex(MockItem.description, "key.*rd"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .regex("key.*rd")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

```ini Expected Response theme={null}
       description        | rating |  category
--------------------------+--------+-------------
 Ergonomic metal keyboard |      4 | Electronics
 Plastic Keyboard         |      4 | Electronics
(2 rows)
```

This uses the [regex](/documentation/query-builder/term/regex) builder function to match all rows where `description` matches the regex expression `key.*rd`.
