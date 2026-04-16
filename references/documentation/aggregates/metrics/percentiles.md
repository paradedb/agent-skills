> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Percentiles

> Analyze the distribution of a field

The percentiles aggregation computes the values below which a given percentage of the data falls.
In this example, the aggregation will return the 50th and 95th percentiles for `rating`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"percentiles": {"field": "rating", "percents": [50, 95]}}') FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"percentiles": {"field": "rating", "percents": [50, 95]}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.percentiles(field="rating", percents=[50, 95])))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: ParadeDB::Aggregations.percentiles(:rating, percents: [50, 95]))
  ```
</CodeGroup>

```ini Expected Response theme={null}
                                 agg
---------------------------------------------------------------------
 {"values": {"50.0": 4.014835333028612, "95.0": 5.0028295751107414}}
(1 row)
```

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/metric/struct.PercentilesAggregationReq.html) for all available options.
