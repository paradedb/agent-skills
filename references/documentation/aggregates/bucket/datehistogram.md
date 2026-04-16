> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Date Histogram

> Count the number of occurrences over fixed time intervals

The date histogram aggregation constructs a histogram for date fields.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"date_histogram": {"field": "created_at", "fixed_interval": "30d"}}')
  FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"date_histogram": {"field": "created_at", "fixed_interval": "30d"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.date_histogram(field="created_at", fixed_interval="30d")))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: ParadeDB::Aggregations.date_histogram(:created_at, fixed_interval: "30d"))
  ```
</CodeGroup>

```ini Expected Response theme={null}

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 {"buckets": [{"key": 1679616000000.0, "doc_count": 14, "key_as_string": "2023-03-24T00:00:00Z"}, {"key": 1682208000000.0, "doc_count": 27, "key_as_string": "2023-04-23T00:00:00Z"}]}
(1 row)
```

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/bucket/struct.DateHistogramAggregationReq.html)
for all available options.
