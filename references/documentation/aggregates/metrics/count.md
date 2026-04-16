> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Count

> Count the number of values in a field

The following query counts the number of values in a field:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"value_count": {"field": "rating"}}') FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"value_count": {"field": "rating"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.value_count(field="rating")))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: ParadeDB::Aggregations.value_count(:rating))
  ```
</CodeGroup>

```ini Expected Response theme={null}
       agg
-----------------
 {"value": 41.0}
(1 row)
```

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/metric/struct.CountAggregation.html) for all available options.

## SQL Count Syntax

SQL's `COUNT` syntax is supported in beta. To enable it, first run

```sql theme={null}
SET paradedb.enable_aggregate_custom_scan TO on;
```

With this feature enabled, the following query is equivalent to the above and is executed in the same way.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT COUNT(rating) FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from django.db.models import Count
  from paradedb import All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(count=Count('rating'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(func.count(MockItem.rating))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id).match_all.count(:rating)
  ```
</CodeGroup>

To count all rows, including rows with null values, use `COUNT(*)`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT COUNT(*) FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import All, ParadeDB

  MockItem.objects.filter(id=ParadeDB(All())).count()
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(func.count())
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id).match_all.count
  ```
</CodeGroup>
