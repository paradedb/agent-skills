> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Stats

> Compute several metrics at once

The stats aggregation returns the count, sum, min, max, and average all at once.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"stats": {"field": "rating"}}') FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"stats": {"field": "rating"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.stats(field="rating")))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: ParadeDB::Aggregations.stats(:rating))
  ```
</CodeGroup>

```ini Expected Response theme={null}
                                      agg
--------------------------------------------------------------------------------
 {"avg": 3.8536585365853657, "max": 5.0, "min": 1.0, "sum": 158.0, "count": 41}
(1 row)
```

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/metric/struct.StatsAggregation.html) for all available options.
