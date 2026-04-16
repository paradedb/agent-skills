> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Cardinality

> Compute the number of distinct values in a field

The cardinality aggregation estimates the number of distinct values in a field.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"cardinality": {"field": "rating"}}') FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"cardinality": {"field": "rating"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(pdb.agg({"cardinality": {"field": "rating"}}))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: { cardinality: { field: "rating" } })
  ```
</CodeGroup>

```ini Expected Response theme={null}
      agg
----------------
 {"value": 5.0}
(1 row)
```

Unlike SQL's `DISTINCT` clause, which returns an exact value but is very computationally expensive, the cardinality aggregation uses the HyperLogLog++ algorithm to
closely approximate the number of distinct values.

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/metric/struct.CardinalityAggregationReq.html) for all available options.
