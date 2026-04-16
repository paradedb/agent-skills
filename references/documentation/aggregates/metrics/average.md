> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Average

> Compute the average value of a field

The following query computes the average value over a specific field:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"avg": {"field": "rating"}}') FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"avg": {"field": "rating"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.avg(field="rating")))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: ParadeDB::Aggregations.avg(:rating))
  ```
</CodeGroup>

```ini Expected Response theme={null}
              agg
-------------------------------
 {"value": 3.8536585365853657}
(1 row)
```

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/metric/struct.AverageAggregation.html) for all available options.

## SQL Average Syntax

SQL's `AVERAGE` syntax is supported in beta. To enable it, first run

```sql theme={null}
SET paradedb.enable_aggregate_custom_scan TO on;
```

With this feature enabled, the following query is equivalent to the above and is executed in the same way.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT AVG(rating) FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from django.db.models import Avg
  from paradedb import All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(avg_rating=Avg('rating'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(func.avg(MockItem.rating))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id).match_all.average(:rating)
  ```
</CodeGroup>

By default, `AVG` ignores null values. Use `COALESCE` to include them in the final average:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT AVG(COALESCE(rating, 0)) FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from django.db.models import Avg, Value
  from django.db.models.functions import Coalesce
  from paradedb import All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(avg_rating=Avg(Coalesce('rating', Value(0))))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(func.avg(func.coalesce(MockItem.rating, 0)))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  rating = MockItem.arel_table[:rating]
  coalesced_rating = Arel::Nodes::NamedFunction.new("COALESCE", [rating, Arel::Nodes.build_quoted(0)])

  MockItem.search(:id).match_all.average(coalesced_rating)
  ```
</CodeGroup>
