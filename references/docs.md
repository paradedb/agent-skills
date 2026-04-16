# Date Histogram
Source: https://docs.paradedb.com/documentation/aggregates/bucket/datehistogram

Count the number of occurrences over fixed time intervals

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


# Filters
Source: https://docs.paradedb.com/documentation/aggregates/bucket/filters

Compute aggregations over multiple filters in one query

The filters aggregation allows a single query to return aggregations for multiple search queries at a time.
To use this aggregation, pass `pdb.agg` to the left-hand side of `FILTER` and a search query to the right-hand side.
For example:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT
      pdb.agg('{"value_count": {"field": "id"}}')
      FILTER (WHERE category === 'electronics') AS electronics_count,
      pdb.agg('{"value_count": {"field": "id"}}')
      FILTER (WHERE category === 'footwear') AS footwear_count
  FROM mock_items;
  ```

  ```python Django theme={null}
  from django.db.models import Q
  from paradedb import Agg, ParadeDB, Term

  MockItem.objects.aggregate(
      electronics_count=Agg(
          '{"value_count": {"field": "id"}}',
          filter=Q(category=ParadeDB(Term('electronics'))),
      ),
      footwear_count=Agg(
          '{"value_count": {"field": "id"}}',
          filter=Q(category=ParadeDB(Term('footwear'))),
      ),
  )
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = select(
      pdb.agg(facets.value_count(field="id"))
      .filter(search.term(MockItem.category, "electronics"))
      .label("electronics_count"),
      pdb.agg(facets.value_count(field="id"))
      .filter(search.term(MockItem.category, "footwear"))
      .label("footwear_count"),
  ).select_from(MockItem)

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  result = MockItem.facets_agg(
    electronics_count: ParadeDB::Aggregations.filtered(
      ParadeDB::Aggregations.value_count(:id),
      field: :category,
      term: "electronics"
    ),
    footwear_count: ParadeDB::Aggregations.filtered(
      ParadeDB::Aggregations.value_count(:id),
      field: :category,
      term: "footwear"
    )
  )
  ```
</CodeGroup>

<Note>
  Use lowercase `electronics` and `footwear`. The default BM25 tokenizer
  lowercases terms, so `Electronics` and `Footwear` would not match here.
</Note>

```ini Expected Response theme={null}
 electronics_count | footwear_count
-------------------+----------------
 {"value": 5.0}    | {"value": 6.0}
(1 row)
```


# Histogram
Source: https://docs.paradedb.com/documentation/aggregates/bucket/histogram

Count the number of occurrences over some interval

The histogram aggregation dynamically creates buckets for a given `interval` and counts the number of occurrences
in each bucket.

Each value is rounded down to its bucket. For instance, a rating of `18` with an interval of `5` rounds down to a bucket
with key `15`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"histogram": {"field": "rating", "interval": "1"}}')
  FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"histogram": {"field": "rating", "interval": "1"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.histogram(field="rating", interval=1)))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: ParadeDB::Aggregations.histogram(:rating, interval: 1))
  ```
</CodeGroup>

```ini Expected Response theme={null}
                                                                                  agg
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
 {"buckets": [{"key": 1.0, "doc_count": 1}, {"key": 2.0, "doc_count": 3}, {"key": 3.0, "doc_count": 9}, {"key": 4.0, "doc_count": 16}, {"key": 5.0, "doc_count": 12}]}
(1 row)
```

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/bucket/struct.HistogramAggregation.html)
for all available options.


# Range
Source: https://docs.paradedb.com/documentation/aggregates/bucket/range

Count the number of occurrences over user-defined buckets

The range aggregation counts the number of occurrences over user-defined buckets. The buckets must be continuous and cannot overlap.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"range": {"field": "rating", "ranges": [{"to": 3.0 }, {"from": 3.0, "to": 6.0} ]}}')
  FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"range": {"field": "rating", "ranges": [{"to": 3.0}, {"from": 3.0, "to": 6.0}]}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(
          pdb.agg(
              facets.range(
                  field="rating",
                  ranges=[{"to": 3.0}, {"from": 3.0, "to": 6.0}],
              )
          )
      )
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(
            agg: ParadeDB::Aggregations.range(
              :rating,
              ranges: [{ to: 3.0 }, { from: 3.0, to: 6.0 }]
            )
          )
  ```
</CodeGroup>

```ini Expected Response theme={null}
                                                                              agg
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 {"buckets": [{"to": 3.0, "key": "*-3", "doc_count": 4}, {"to": 6.0, "key": "3-6", "from": 3.0, "doc_count": 37}, {"key": "6-*", "from": 6.0, "doc_count": 0}]}
(1 row)
```

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/bucket/struct.RangeAggregation.html)
for all available options.


# Terms
Source: https://docs.paradedb.com/documentation/aggregates/bucket/terms

Count the number of occurrences for each value in a result set

<Note>
  If a text or JSON field is in the `GROUP BY` or `ORDER BY` clause, it must use
  the [literal](/documentation/tokenizers/available-tokenizers/literal)
  tokenizer.
</Note>

A terms aggregation counts the number of occurrences for every unique value in a field. For example, the following query
groups the `mock_items` table by `rating`, and calculates the number of items for each unique `rating`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT rating, pdb.agg('{"value_count": {"field": "id"}}') FROM mock_items
  WHERE id @@@ pdb.all()
  GROUP BY rating
  LIMIT 10;
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).values('rating').annotate(
      agg=Agg('{"value_count": {"field": "id"}}')
  )[:10]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(MockItem.rating, pdb.agg(facets.value_count(field="id")).label("agg"))
      .where(search.all(MockItem.id))
      .group_by(MockItem.rating)
      .limit(10)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .aggregate_by(
            :rating,
            agg: ParadeDB::Aggregations.value_count(:id)
          )
          .limit(10)
  ```
</CodeGroup>

```ini Expected Response theme={null}
 rating |       agg
--------+-----------------
      4 | {"value": 16.0}
      5 | {"value": 12.0}
      3 | {"value": 9.0}
      2 | {"value": 3.0}
      1 | {"value": 1.0}
(5 rows)
```

Ordering by the bucketing field is supported:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT rating, pdb.agg('{"value_count": {"field": "id"}}') FROM mock_items
  WHERE id @@@ pdb.all()
  GROUP BY rating
  ORDER BY rating
  LIMIT 10;
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).values('rating').annotate(
      agg=Agg('{"value_count": {"field": "id"}}')
  ).order_by('rating')[:10]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(MockItem.rating, pdb.agg(facets.value_count(field="id")).label("agg"))
      .where(search.all(MockItem.id))
      .group_by(MockItem.rating)
      .order_by(MockItem.rating)
      .limit(10)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .aggregate_by(
            :rating,
            agg: ParadeDB::Aggregations.value_count(:id)
          )
          .order(:rating)
          .limit(10)
  ```
</CodeGroup>

<Note>Ordering by the aggregate value is not yet supported.</Note>

For performance reasons, we strongly recommend adding a `LIMIT` to the `GROUP BY`. Terms aggregations without a `LIMIT` consume more memory and
are slower to execute. If a query does not have a limit and more than `65000` unique values are found in a field, an error will be returned.


# Facets
Source: https://docs.paradedb.com/documentation/aggregates/facets

Compute a Top K and aggregate in one query

A common pattern in search is to query for both an aggregate and a set of search results. For example, "find the top 10
results, and also count the total number of results."

Instead of issuing two separate queries -- one for the search results, and another for the aggregate -- `pdb.agg` allows for
these results to be returned in a single "faceted" query. This can significantly improve read throughput, since issuing a single
query uses less CPU and disk I/O.

For example, this query returns the top 3 search results alongside the total number of results found.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT
    id, description, rating,
    pdb.agg('{"value_count": {"field": "id"}}') OVER ()
  FROM mock_items
  WHERE category === 'electronics'
  ORDER BY rating DESC
  LIMIT 3;
  ```

  ```python Django theme={null}
  from django.db.models import Window
  from paradedb import Agg, ParadeDB, Term

  MockItem.objects.filter(
      category=ParadeDB(Term('electronics'))
  ).values(
      'id', 'description', 'rating'
  ).annotate(
      agg=Window(expression=Agg('{"value_count": {"field": "id"}}'))
  ).order_by('-rating')[:3]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, search

  base = (
      select(MockItem.id, MockItem.description, MockItem.rating)
      .where(
          search.all(MockItem.id),
          search.term(MockItem.category, "electronics"),
      )
      .order_by(MockItem.rating.desc())
      .limit(3)
  )

  stmt = facets.with_rows(base, agg=facets.value_count(field="id"), key_field=MockItem.id)

  with Session(engine) as session:
      rows = session.execute(stmt).all()
      facets.extract(rows)

  ```

  ```ruby Rails theme={null}
  relation = MockItem.search(:category)
                     .term("electronics")
                     .with_agg(agg: ParadeDB::Aggregations.value_count(:id))
                     .select(:id, :description, :rating)
                     .order(rating: :desc)
                     .limit(3)

  rows = relation.to_a
  aggregates = relation.aggregates
  ```
</CodeGroup>

```ini Expected Response theme={null}
 id |         description         | rating |      agg
----+-----------------------------+--------+----------------
 12 | Innovative wireless earbuds |      5 | {"value": 5.0}
  1 | Ergonomic metal keyboard    |      4 | {"value": 5.0}
  2 | Plastic Keyboard            |      4 | {"value": 5.0}
(3 rows)
```

<Note>
  Faceted queries require that `pdb.agg` be used as a window function:
  `pdb.agg() OVER ()`.
</Note>


# Limitations
Source: https://docs.paradedb.com/documentation/aggregates/limitations

Caveats for aggregate support

## ParadeDB Operator

In order for ParadeDB to push down an aggregate, a ParadeDB text search operator must be present in the query.

<CodeGroup>
  ```sql SQL theme={null}
  -- Not pushed down
  SELECT COUNT(id) FROM mock_items
  WHERE rating = 5;

  -- Pushed down
  SELECT COUNT(id) FROM mock_items
  WHERE rating = 5
  AND id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import All, ParadeDB

  # Not pushed down — no ParadeDB operator
  MockItem.objects.filter(rating=5).count()

  # Pushed down — ParadeDB operator triggers aggregate pushdown
  MockItem.objects.filter(rating=5, id=ParadeDB(All())).count()
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  # Not pushed down.
  count_without_operator_stmt = select(func.count(MockItem.id)).where(MockItem.rating == 5)

  # Pushed down.
  count_with_operator_stmt = select(func.count(MockItem.id)).where(
      MockItem.rating == 5,
      search.all(MockItem.id),
  )

  with Session(engine) as session:
      {
          "count_without_operator": session.execute(count_without_operator_stmt).scalar_one(),
          "count_with_operator": session.execute(count_with_operator_stmt).scalar_one(),
      }
  ```

  ```ruby Rails theme={null}
  # Not pushed down — no ParadeDB operator
  MockItem.where(rating: 5).count

  # Pushed down — ParadeDB operator triggers aggregate pushdown
  MockItem.search(:id).match_all.where(rating: 5).count
  ```
</CodeGroup>

If your query does not contain a ParadeDB operator, a way to "force" aggregate pushdown is to append the [all query](/documentation/query-builder/compound/all) to the query's
`WHERE` clause.

## Join Support

ParadeDB is currently only able to push down aggregates over a single table. JOINs are not yet pushed down but are on the [roadmap](/welcome/roadmap).

## NUMERIC Columns

`NUMERIC` columns do not support aggregate pushdown. Queries with aggregates on `NUMERIC` columns will automatically fall back to PostgreSQL for aggregation.

For numeric data that requires aggregate pushdown, use `FLOAT` or `DOUBLE PRECISION` instead:

```sql theme={null}
-- Aggregates can be pushed down
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    price DOUBLE PRECISION
);

-- Aggregates fall back to PostgreSQL
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    price NUMERIC(10,2)
);
```

<Note>
  Filter pushdown (equality and range queries) is fully supported for all
  `NUMERIC` columns. Only aggregate pushdown is not supported.
</Note>


# Average
Source: https://docs.paradedb.com/documentation/aggregates/metrics/average

Compute the average value of a field

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


# Cardinality
Source: https://docs.paradedb.com/documentation/aggregates/metrics/cardinality

Compute the number of distinct values in a field

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


# Count
Source: https://docs.paradedb.com/documentation/aggregates/metrics/count

Count the number of values in a field

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


# Min/Max
Source: https://docs.paradedb.com/documentation/aggregates/metrics/minmax

Compute the min/max value of a field

`min` and `max` return the smallest and largest values of a column, respectively.

SQL's `MIN`/`MAX` syntax is supported in beta. To enable it, first run:

```sql SQL theme={null}
SET paradedb.enable_aggregate_custom_scan TO on;
```

## Min

The `min` aggregation returns the smallest value in a field.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"min": {"field": "rating"}}') FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"min": {"field": "rating"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.min(field="rating")))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: ParadeDB::Aggregations.min(:rating))
  ```
</CodeGroup>

```ini Expected Response theme={null}
      agg
----------------
 {"value": 1.0}
(1 row)
```

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/metric/struct.MinAggregation.html) for all available options.

### SQL Min Syntax

With `paradedb.enable_aggregate_custom_scan` enabled, the following query is equivalent to the above and is executed in the same way.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT MIN(rating) FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from django.db.models import Min
  from paradedb import All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(min_rating=Min('rating'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(func.min(MockItem.rating))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id).match_all.minimum(:rating)
  ```
</CodeGroup>

By default, `MIN` ignores null values. Use `COALESCE` to include them in the final result:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT MIN(COALESCE(rating, 0)) FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from django.db.models import Min, Value
  from django.db.models.functions import Coalesce
  from paradedb import All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(min_rating=Min(Coalesce('rating', Value(0))))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(func.min(func.coalesce(MockItem.rating, 0)))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  rating = MockItem.arel_table[:rating]
  coalesced_rating = Arel::Nodes::NamedFunction.new("COALESCE", [rating, Arel::Nodes.build_quoted(0)])

  MockItem.search(:id).match_all.minimum(coalesced_rating)
  ```
</CodeGroup>

## Max

The `max` aggregation returns the largest value in a field.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"max": {"field": "rating"}}') FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"max": {"field": "rating"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.max(field="rating")))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: ParadeDB::Aggregations.max(:rating))
  ```
</CodeGroup>

```ini Expected Response theme={null}
      agg
----------------
 {"value": 5.0}
(1 row)
```

### SQL Max Syntax

With `paradedb.enable_aggregate_custom_scan` enabled, the following query is equivalent to the above and is executed in the same way.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT MAX(rating) FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from django.db.models import Max
  from paradedb import All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(max_rating=Max('rating'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(func.max(MockItem.rating))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id).match_all.maximum(:rating)
  ```
</CodeGroup>

By default, `MAX` ignores null values. Use `COALESCE` to include them in the final result:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT MAX(COALESCE(rating, 0)) FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from django.db.models import Max, Value
  from django.db.models.functions import Coalesce
  from paradedb import All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(max_rating=Max(Coalesce('rating', Value(0))))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(func.max(func.coalesce(MockItem.rating, 0)))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  rating = MockItem.arel_table[:rating]
  coalesced_rating = Arel::Nodes::NamedFunction.new("COALESCE", [rating, Arel::Nodes.build_quoted(0)])

  MockItem.search(:id).match_all.maximum(coalesced_rating)
  ```
</CodeGroup>


# Percentiles
Source: https://docs.paradedb.com/documentation/aggregates/metrics/percentiles

Analyze the distribution of a field

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


# Stats
Source: https://docs.paradedb.com/documentation/aggregates/metrics/stats

Compute several metrics at once

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


# Sum
Source: https://docs.paradedb.com/documentation/aggregates/metrics/sum

Compute the sum of a field

The sum aggregation computes the sum of a field.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"sum": {"field": "rating"}}') FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"sum": {"field": "rating"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.sum(field="rating")))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: ParadeDB::Aggregations.sum(:rating))
  ```
</CodeGroup>

```ini Expected Response theme={null}
       agg
------------------
 {"value": 158.0}
(1 row)
```

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/metric/struct.SumAggregation.html) for all available options.

## SQL Sum Syntax

SQL's `SUM` syntax is supported in beta. To enable it, first run

```sql theme={null}
SET paradedb.enable_aggregate_custom_scan TO on;
```

With this feature enabled, the following query is equivalent to the above and is executed in the same way.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT SUM(rating) FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from django.db.models import Sum
  from paradedb import All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(total=Sum('rating'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(func.sum(MockItem.rating))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id).match_all.sum(:rating)
  ```
</CodeGroup>

By default, `SUM` ignores null values. Use `COALESCE` to include them in the final sum:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT SUM(COALESCE(rating, 0)) FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from django.db.models import Sum, Value
  from django.db.models.functions import Coalesce
  from paradedb import All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(total=Sum(Coalesce('rating', Value(0))))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(func.sum(func.coalesce(MockItem.rating, 0)))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  rating = MockItem.arel_table[:rating]
  coalesced_rating = Arel::Nodes::NamedFunction.new("COALESCE", [rating, Arel::Nodes.build_quoted(0)])

  MockItem.search(:id).match_all.sum(coalesced_rating)
  ```
</CodeGroup>


# Top Hits
Source: https://docs.paradedb.com/documentation/aggregates/metrics/tophits

Compute the top hits for each bucket in a terms aggregation

The top hits aggregation is meant to be used in conjunction with the [terms](/documentation/aggregates/bucket/terms)
aggregation. It returns the top documents for each bucket of a terms aggregation.

For example, the following query answers "what are top 3 results sorted by `created_at` for each
`rating` category?"

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"top_hits": {"size": 3, "sort": [{"created_at": "desc"}], "docvalue_fields": ["id", "created_at"]}}')
  FROM mock_items
  WHERE id @@@ pdb.all()
  GROUP BY rating;
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).values('rating').annotate(
      agg=Agg('{"top_hits": {"size": 3, "sort": [{"created_at": "desc"}], "docvalue_fields": ["id", "created_at"]}}')
  ).values('agg')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(
          pdb.agg(
              facets.top_hits(
                  size=3,
                  sort=[{"created_at": "desc"}],
                  docvalue_fields=["id", "created_at"],
              )
          )
      )
      .select_from(MockItem)
      .where(search.all(MockItem.id))
      .group_by(MockItem.rating)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .aggregate_by(
            :rating,
            agg: ParadeDB::Aggregations.top_hits(
              size: 3,
              sort: [{ created_at: "desc" }],
              docvalue_fields: %w[id created_at]
            )
          )
  ```
</CodeGroup>

```ini Expected Response theme={null}
      agg
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 {"hits": [{"sort": [10907000251854775808], "docvalue_fields": {"id": [25], "created_at": ["2023-05-09T10:30:15Z"]}}, {"sort": [10906844884854775808], "docvalue_fields": {"id": [26], "created_at": ["2023-05-07T15:20:48Z"]}}, {"sort": [10906666358854775808], "docvalue_fields": {"id": [13], "created_at": ["2023-05-05T13:45:22Z"]}}]}
 {"hits": [{"sort": [10906756363854775808], "docvalue_fields": {"id": [24], "created_at": ["2023-05-06T14:45:27Z"]}}, {"sort": [10906385295854775808], "docvalue_fields": {"id": [28], "created_at": ["2023-05-02T07:40:59Z"]}}, {"sort": [10906236353854775808], "docvalue_fields": {"id": [29], "created_at": ["2023-04-30T14:18:37Z"]}}]}
 {"hits": [{"sort": [10906480573854775808], "docvalue_fields": {"id": [17], "created_at": ["2023-05-03T10:08:57Z"]}}, {"sort": [10906315942854775808], "docvalue_fields": {"id": [20], "created_at": ["2023-05-01T12:25:06Z"]}}, {"sort": [10906218361854775808], "docvalue_fields": {"id": [8], "created_at": ["2023-04-30T09:18:45Z"]}}]}
 {"hits": [{"sort": [10906573359854775808], "docvalue_fields": {"id": [27], "created_at": ["2023-05-04T11:55:23Z"]}}, {"sort": [10905961160854775808], "docvalue_fields": {"id": [15], "created_at": ["2023-04-27T09:52:04Z"]}}, {"sort": [10905202003854775808], "docvalue_fields": {"id": [7], "created_at": ["2023-04-18T14:59:27Z"]}}]}
 {"hits": [{"sort": [10906586188854775808], "docvalue_fields": {"id": [10], "created_at": ["2023-05-04T15:29:12Z"]}}]}
(5 rows)
```

The `sort` value returned by the aggregation is Tantivy's internal sort ID and should be ignored.
To get the actual fields, pass a list of fields to `docvalue_fields`.

If a text or JSON field is passed to `docvalue_fields`, it must be indexed with the [literal](/documentation/tokenizers/available-tokenizers/literal)
or [literal normalized](/documentation/tokenizers/available-tokenizers/literal-normalized) tokenizer.

To specify an offset, use `from`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"top_hits": {"size": 3, "from": 1, "sort": [{"created_at": "desc"}], "docvalue_fields": ["id", "created_at"]}}')
  FROM mock_items
  WHERE id @@@ pdb.all()
  GROUP BY rating;
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).values('rating').annotate(
      agg=Agg('{"top_hits": {"size": 3, "from": 1, "sort": [{"created_at": "desc"}], "docvalue_fields": ["id", "created_at"]}}')
  ).values('agg')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(
          pdb.agg(
              facets.top_hits(
                  size=3,
                  from_=1,
                  sort=[{"created_at": "desc"}],
                  docvalue_fields=["id", "created_at"],
              )
          )
      )
      .select_from(MockItem)
      .where(search.all(MockItem.id))
      .group_by(MockItem.rating)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .aggregate_by(
            :rating,
            agg: ParadeDB::Aggregations.top_hits(
              size: 3,
              from: 1,
              sort: [{ created_at: "desc" }],
              docvalue_fields: %w[id created_at]
            )
          )
  ```
</CodeGroup>

If multiple fields are passed into `sort`, the additional fields are used as tiebreakers:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"top_hits": {"size": 3, "sort": [{"created_at": "desc"}, {"id": "asc"}], "docvalue_fields": ["id", "created_at"]}}')
  FROM mock_items
  WHERE id @@@ pdb.all()
  GROUP BY rating;
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).values('rating').annotate(
      agg=Agg('{"top_hits": {"size": 3, "sort": [{"created_at": "desc"}, {"id": "asc"}], "docvalue_fields": ["id", "created_at"]}}')
  ).values('agg')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(
          pdb.agg(
              facets.top_hits(
                  size=3,
                  sort=[{"created_at": "desc"}, {"id": "asc"}],
                  docvalue_fields=["id", "created_at"],
              )
          )
      )
      .select_from(MockItem)
      .where(search.all(MockItem.id))
      .group_by(MockItem.rating)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .aggregate_by(
            :rating,
            agg: ParadeDB::Aggregations.top_hits(
              size: 3,
              sort: [{ created_at: "desc" }, { id: "asc" }],
              docvalue_fields: %w[id created_at]
            )
          )
  ```
</CodeGroup>

See the [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/aggregation/metric/struct.TopHitsAggregationReq.html) for all available options.


# Aggregate Syntax
Source: https://docs.paradedb.com/documentation/aggregates/overview

Accelerate aggregates with the ParadeDB index

The `pdb.agg` function accepts an Elasticsearch-compatible JSON aggregate query string. It executes the aggregate using the
[columnar](/welcome/architecture#columnar-index) portion of the ParadeDB index, which can significantly accelerate performance compared to vanilla Postgres.

For example, the following query counts the total number of results for a search query.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"value_count": {"field": "id"}}')
  FROM mock_items
  WHERE category === 'electronics';
  ```

  ```python Django theme={null}
  from paradedb import Agg, ParadeDB, Term

  MockItem.objects.filter(
      category=ParadeDB(Term('electronics'))
  ).aggregate(agg=Agg('{"value_count": {"field": "id"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.value_count(field="id")))
      .select_from(MockItem)
      .where(search.term(MockItem.category, "electronics"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:category)
          .term("electronics")
          .facets_agg(agg: ParadeDB::Aggregations.value_count(:id))
  ```
</CodeGroup>

```ini Expected Response theme={null}
      agg
----------------
 {"value": 5.0}
(1 row)
```

This query counts the number of results for every distinct group:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT rating, pdb.agg('{"value_count": {"field": "id"}}')
  FROM mock_items
  WHERE category === 'electronics'
  GROUP BY rating
  ORDER BY rating
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Agg, ParadeDB, Term

  MockItem.objects.filter(
      category=ParadeDB(Term('electronics'))
  ).values('rating').annotate(
      agg=Agg('{"value_count": {"field": "id"}}')
  ).order_by('rating')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(MockItem.rating, pdb.agg(facets.value_count(field="id")).label("agg"))
      .where(search.term(MockItem.category, "electronics"))
      .group_by(MockItem.rating)
      .order_by(MockItem.rating)
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:category)
          .term("electronics")
          .aggregate_by(
            :rating,
            agg: ParadeDB::Aggregations.value_count(:id)
          )
          .order(:rating)
          .limit(5)
  ```
</CodeGroup>

```ini Expected Response theme={null}
 rating |      agg
--------+----------------
      3 | {"value": 1.0}
      4 | {"value": 3.0}
      5 | {"value": 1.0}
(3 rows)
```

## Multiple Aggregations

To compute multiple aggregations at once, simply include multiple `pdb.agg` functions in the target list:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT
    pdb.agg('{"avg": {"field": "rating"}}') AS avg_rating,
    pdb.agg('{"value_count": {"field": "id"}}') AS count
  FROM mock_items
  WHERE category === 'electronics';
  ```

  ```python Django theme={null}
  from paradedb import Agg, ParadeDB, Term

  MockItem.objects.filter(
      category=ParadeDB(Term('electronics'))
  ).aggregate(
      avg_rating=Agg('{"avg": {"field": "rating"}}'),
      count=Agg('{"value_count": {"field": "id"}}'),
  )
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(
          pdb.agg(facets.avg(field="rating")).label("avg_rating"),
          pdb.agg(facets.value_count(field="id")).label("count"),
      )
      .select_from(MockItem)
      .where(search.term(MockItem.category, "electronics"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:category)
          .term("electronics")
          .facets_agg(
            avg_rating: ParadeDB::Aggregations.avg(:rating),
            count: ParadeDB::Aggregations.value_count(:id)
          )
  ```
</CodeGroup>

```ini Expected Response theme={null}
   avg_rating   |     count
----------------+----------------
 {"value": 4.0} | {"value": 5.0}
(1 row)
```

## Performance Optimization

On every query, ParadeDB runs checks to ensure that deleted or updated-away rows are not factored into the result set.

If your table is not frequently updated or you can tolerate an approximate result, the performance of aggregate queries can be improved by disabling these visibility checks.
To do so, set the second argument of `pdb.agg` to `false`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"value_count": {"field": "id"}}', false)
  FROM mock_items
  WHERE description ||| 'running shoes';
  ```

  ```python Django theme={null}
  from paradedb import Agg, Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='OR'))
  ).aggregate(
      agg=Agg('{"value_count": {"field": "id"}}', exact=False)
  )
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.value_count(field="id"), approximate=True).label("agg"))
      .where(search.match_any(MockItem.description, "running shoes"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running shoes")
          .facets_agg(exact: false, agg: ParadeDB::Aggregations.value_count(:id))
  ```
</CodeGroup>

Disabling this check can improve query times by 2-4x in some cases (at the expense of correctness).

<Note>
  If a single query contains multiple `pdb.agg` calls, all of them must use the same visibility setting (either all `true` or all `false`).
</Note>

## JSON Fields

If `metadata` is a JSON field with key `color`, use `metadata.color` as the field name:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT pdb.agg('{"terms": {"field": "metadata.color"}}')
  FROM mock_items
  WHERE id @@@ pdb.all();
  ```

  ```python Django theme={null}
  from paradedb import Agg, All, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(All())
  ).aggregate(agg=Agg('{"terms": {"field": "metadata.color"}}'))
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, pdb, search

  stmt = (
      select(pdb.agg(facets.terms(field="metadata.color")))
      .select_from(MockItem)
      .where(search.all(MockItem.id))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .match_all
          .facets_agg(agg: ParadeDB::Aggregations.terms("metadata.color"))
  ```
</CodeGroup>

<Note>
  If a text or JSON field is used inside `pdb.agg`, it must use the [literal](/documentation/tokenizers/available-tokenizers/literal) or
  [literal normalized](/documentation/tokenizers/available-tokenizers/literal-normalized) tokenizer.
</Note>


# Performance Tuning
Source: https://docs.paradedb.com/documentation/aggregates/tuning

Several settings can be tuned to improve the performance of aggregates in ParadeDB

### Configure Parallel Workers

ParadeDB uses Postgres parallel workers. By default, Postgres allows two workers per parallel query.
Increasing the number of [parallel workers](/documentation/performance-tuning/reads) allows parallel queries to use all of the available hardware on the host machine and can deliver significant
speedups.

### Run `VACUUM`

`VACUUM` updates the table's [visibility map](https://www.postgresql.org/docs/current/storage-vm.html),
which speeds up Postgres' visibility checks.

```sql theme={null}
VACUUM mock_items;
```

If the table experiences frequent updates, we recommend configuring [autovacuum](https://www.postgresql.org/docs/current/routine-vacuuming.html).

### Run `pg_prewarm`

The `pg_prewarm` extension can be used to preload data from the index into the Postgres buffer cache, which
improves the response times of "cold" queries (i.e. the first search query after Postgres has restarted).

```sql theme={null}
CREATE EXTENSION pg_prewarm;
SELECT pg_prewarm('search_idx');
```


# Filtering
Source: https://docs.paradedb.com/documentation/filtering

Filter search results based on metadata from other fields

Adding filters to text search is as simple as using PostgreSQL's built-in `WHERE` clauses and operators.
For instance, the following query filters out results that do not meet `rating > 2`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ||| 'running shoes' AND rating > 2;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='OR')),
      rating__gt=2
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(MockItem.description, "running shoes"), MockItem.rating > 2)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running shoes")
          .where(rating: 3..)
          .select(:description, :rating, :category)
  ```
</CodeGroup>

## Filter Pushdown

### Non-Text Fields

While not required, filtering performance over non-text columns can be improved by including them in the BM25 index.
When these columns are part of the index, `WHERE` clauses that reference them can be pushed down into the index scan itself.
This can result in faster query execution over large datasets.

For example, if `rating` and `created_at` are frequently used in filters, they can be added to the BM25 index during index creation:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25(id, description, rating, created_at)
WITH (key_field = 'id');
```

Filter pushdown is currently supported for the following combinations of types and operators:

| Operator                                   | Left Operand Type | Right Operand Type | Example                    |
| ------------------------------------------ | ----------------- | ------------------ | -------------------------- |
| `=`, `<`, `>`, `<=`, `>=`, `<>`, `BETWEEN` | `int2`            | `int2`             | `WHERE rating = 2`         |
|                                            | `int4`            | `int4`             |                            |
|                                            | `int8`            | `int8`             |                            |
|                                            | `int2`            | `int4`             |                            |
|                                            | `int2`            | `int8`             |                            |
|                                            | `int4`            | `int8`             |                            |
|                                            | `float4`          | `float4`           |                            |
|                                            | `float8`          | `float8`           |                            |
|                                            | `float4`          | `float8`           |                            |
|                                            | `numeric`         | `numeric`          | `WHERE price = 99.99`      |
|                                            | `date`            | `date`             |                            |
|                                            | `time`            | `time`             |                            |
|                                            | `timetz`          | `timetz`           |                            |
|                                            | `timestamp`       | `timestamp`        |                            |
|                                            | `timestamptz`     | `timestamptz`      |                            |
|                                            | `uuid`            | `uuid`             |                            |
| `=`                                        | `bool`            | `bool`             | `WHERE in_stock = true`    |
| `IN`, `ANY`, `ALL`                         | `bool`            | `bool[]`           | `WHERE rating IN (1,2,3)`  |
|                                            | `int2`            | `int2[]`           |                            |
|                                            | `int4`            | `int4[]`           |                            |
|                                            | `int8`            | `int8[]`           |                            |
|                                            | `int2`            | `int4[]`           |                            |
|                                            | `int2`            | `int8[]`           |                            |
|                                            | `int4`            | `int8[]`           |                            |
|                                            | `float4`          | `float4[]`         |                            |
|                                            | `float8`          | `float8[]`         |                            |
|                                            | `float4`          | `float8[]`         |                            |
|                                            | `date`            | `date[]`           |                            |
|                                            | `timetz`          | `timetz[]`         |                            |
|                                            | `timestamp`       | `timestamp[]`      |                            |
|                                            | `timestamptz`     | `timestamptz[]`    |                            |
|                                            | `uuid`            | `uuid[]`           |                            |
| `IS`, `IS NOT`                             | `bool`            | `bool`             | `WHERE in_stock IS true`   |
| `IS NULL`, `IS NOT NULL`                   | `bool`            |                    | `WHERE rating IS NOT NULL` |
|                                            | `int2`            |                    |                            |
|                                            | `int4`            |                    |                            |
|                                            | `int8`            |                    |                            |
|                                            | `int2`            |                    |                            |
|                                            | `int2`            |                    |                            |
|                                            | `int4`            |                    |                            |
|                                            | `float4`          |                    |                            |
|                                            | `float8`          |                    |                            |
|                                            | `float4`          |                    |                            |
|                                            | `date`            |                    |                            |
|                                            | `time`            |                    |                            |
|                                            | `timetz`          |                    |                            |
|                                            | `timestamp`       |                    |                            |
|                                            | `timestamptz`     |                    |                            |
|                                            | `uuid`            |                    |                            |

### Text Fields

Suppose we have a text filter that looks for an exact string match like `category = 'Footwear'`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ 'shoes' AND category = 'Footwear';
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Term

  MockItem.objects.filter(
      description=ParadeDB(Term('shoes')),
      category='Footwear'
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.term(MockItem.description, "shoes"), MockItem.category == "Footwear")
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .term("shoes")
          .where(category: "Footwear")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

To push down the `category = 'Footwear'` filter, `category` must be indexed using the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25(id, description, (category::pdb.literal))
WITH (key_field = 'id');
```

Pushdown of set filters over text fields also requires the literal tokenizer:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ 'shoes' AND category IN ('Footwear', 'Apparel');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Term

  MockItem.objects.filter(
      description=ParadeDB(Term('shoes')),
      category__in=['Footwear', 'Apparel']
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.term(MockItem.description, "shoes"), MockItem.category.in_(["Footwear", "Apparel"]))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .term("shoes")
          .where(category: ["Footwear", "Apparel"])
          .select(:description, :rating, :category)
  ```
</CodeGroup>


# Fuzzy
Source: https://docs.paradedb.com/documentation/full-text/fuzzy

Allow for typos in the query string

Fuzziness allows for tokens to be considered a match even if they are not identical, allowing for typos
in the query string.

<Warning>
  While fuzzy matching will work for non-latin characters (Chinese, Japanese, Korean, etc..), it may not
  give expected results (with large result sets returned) as Levenshtein distance relies on individual character difference.

  If you need this functionality then please thumbs-up this [issue](https://github.com/paradedb/paradedb/issues/3782), and leave
  a comment with your use case.
</Warning>

## Overview

To add fuzziness to a query, cast it to the `fuzzy(n)` type, where `n` is the [edit distance](#how-it-works).
Fuzziness is supported for [match](/documentation/full-text/match) and [term](/documentation/full-text/term) queries.

<CodeGroup>
  ```sql SQL theme={null}
  -- Fuzzy match disjunction
  SELECT id, description
  FROM mock_items
  WHERE description ||| 'runing shose'::pdb.fuzzy(2)
  LIMIT 5;

  -- Fuzzy match conjunction
  SELECT id, description
  FROM mock_items
  WHERE description &&& 'runing shose'::pdb.fuzzy(2)
  LIMIT 5;

  -- Fuzzy Term
  SELECT id, description
  FROM mock_items
  WHERE description === 'shose'::pdb.fuzzy(2)
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Term

  # Fuzzy match disjunction
  MockItem.objects.filter(
      description=ParadeDB(Match('runing shose', operator='OR', distance=2))
  ).values('id', 'description')[:5]

  # Fuzzy match conjunction
  MockItem.objects.filter(
      description=ParadeDB(Match('runing shose', operator='AND', distance=2))
  ).values('id', 'description')[:5]

  # Fuzzy term
  MockItem.objects.filter(
      description=ParadeDB(Term('shose', distance=2))
  ).values('id', 'description')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  fuzzy_or_stmt = (
      select(MockItem.id, MockItem.description)
      .where(search.match_any(MockItem.description, "runing shose", distance=2))
      .limit(5)
  )

  fuzzy_and_stmt = (
      select(MockItem.id, MockItem.description)
      .where(search.match_all(MockItem.description, "runing shose", distance=2))
      .limit(5)
  )

  fuzzy_term_stmt = (
      select(MockItem.id, MockItem.description)
      .where(search.term(MockItem.description, "shose", distance=2))
      .limit(5)
  )

  with Session(engine) as session:
      {
          "or_rows": session.execute(fuzzy_or_stmt).all(),
          "and_rows": session.execute(fuzzy_and_stmt).all(),
          "term_rows": session.execute(fuzzy_term_stmt).all(),
      }
  ```

  ```ruby Rails theme={null}
  # Fuzzy match disjunction
  MockItem.search(:description)
          .matching_any('runing shose', distance: 2)
          .select(:id, :description)
          .limit(5)

  # Fuzzy match conjunction
  MockItem.search(:description)
          .matching_all('runing shose', distance: 2)
          .select(:id, :description)
          .limit(5)

  # Fuzzy term
  MockItem.search(:description)
          .term("shose", distance: 2)
          .select(:id, :description)
          .limit(5)
  ```
</CodeGroup>

## How It Works

By default, the [match](/documentation/full-text/match) and [term](/documentation/full-text/term) queries require exact token matches between the query and indexed text. When a query is cast to `fuzzy(n)`, this requirement is relaxed -- tokens are matched if their Levenshtein distance, or edit distance, is less than or equal to `n`.

Edit distance is a measure of how many single-character operations are needed to turn one string into another. The allowed operations are:

* **Insertion** adds a character e.g., "shoe" → "shoes" (insert "s") has an edit distance of `1`
* **Deletion** removes a character e.g. "runnning" → "running" (delete one "n") has an edit distance of `1`
* **Transposition** replaces on character with another e.g., "shose" → "shoes" (transpose "s" → "e") has an edit distance of `2`

<Note>For performance reasons, the maximum allowed edit distance is `2`.</Note>

<Note>Casting a query to `fuzzy(0)` is the same as an exact token match.</Note>

## Fuzzy Prefix

`fuzzy` also supports prefix matching.
For instance, "runn" is a prefix of "running" because it matches the beginning of the token exactly. "rann" is a **fuzzy prefix** of "running" because it matches the
beginning within an edit distance of `1`.

To treat the query string as a prefix, set the second argument of `fuzzy` to either `t` or `"true"`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description
  FROM mock_items
  WHERE description === 'rann'::pdb.fuzzy(1, t)
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Term

  MockItem.objects.filter(
      description=ParadeDB(Term('rann', distance=1, prefix=True))
  ).values('id', 'description')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description)
      .where(search.term(MockItem.description, "rann", distance=1, prefix=True))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .term("rann", distance: 1, prefix: true)
          .select(:id, :description)
          .limit(5)
  ```
</CodeGroup>

<Note>
  Postgres requires that `true` be double-quoted, i.e. `fuzzy(1, "true")`.
</Note>

When used with [match](/documentation/full-text/match) queries, fuzzy prefix treats all tokens in the query string as prefixes.
For instance, the following query means "find all documents containing the fuzzy prefix `rann` AND the fuzzy prefix `slee`":

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description
  FROM mock_items
  WHERE description &&& 'slee rann'::pdb.fuzzy(1, t)
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('slee rann', operator='AND', distance=1, prefix=True))
  ).values('id', 'description')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description)
      .where(search.match_all(MockItem.description, "slee rann", distance=1, prefix=True))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_all("slee rann", distance: 1, prefix: true)
          .select(:id, :description)
          .limit(5)
  ```
</CodeGroup>

## Transposition Cost

By default, the cost of a transposition (i.e. "shose" → "shoes") is `2`. Setting the third argument of `fuzzy` to `t` lowers the
cost of a transposition to `1`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description
  FROM mock_items
  WHERE description === 'shose'::pdb.fuzzy(1, f, t)
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Term

  MockItem.objects.filter(
      description=ParadeDB(Term('shose', distance=1, transposition_cost_one=True))
  ).values('id', 'description')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description)
      .where(search.term(MockItem.description, "shose", distance=1, transpose_cost_one=True))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .term("shose", distance: 1, transposition_cost_one: true)
          .select(:id, :description)
          .limit(5)
  ```
</CodeGroup>

<Note>
  The default value for the second and third arguments of `fuzzy` is `f`, which
  means `fuzzy(1)` is equivalent to `fuzzy(1, f, f)`.
</Note>


# Highlighting
Source: https://docs.paradedb.com/documentation/full-text/highlight

Generate snippets for portions of the source text that match the query string

<Note>
  Highlighting is an expensive process and can slow down query times. We
  recommend passing a `LIMIT` to any query where `pdb.snippet` or `pdb.snippets`
  is called to restrict the number of snippets that need to be generated.
</Note>

<Note>Highlighting is not supported for fuzzy search.</Note>

Highlighting refers to the practice of visually emphasizing the portions of a document that match a user's
search query.

## Basic Usage

`pdb.snippet(<column>)` can be added to any query where a ParadeDB operator is present. `pdb.snippet` returns the single best snippet, sorted by relevance score.
The following query generates highlighted snippets against the `description` field.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.snippet(description)
  FROM mock_items
  WHERE description ||| 'shoes'
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Snippet

  MockItem.objects.filter(
      description=ParadeDB(Match('shoes', operator='OR'))
  ).annotate(
      snippet=Snippet('description')
  ).values('id', 'snippet')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(MockItem.id, pdb.snippet(MockItem.description).label("snippet"))
      .where(search.match_any(MockItem.description, "shoes"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("shoes")
          .with_snippet(:description)
          .select(:id)
          .limit(5)
  ```
</CodeGroup>

<ParamField>
  The leading indicator around the highlighted region.
</ParamField>

<ParamField>
  The trailing indicator around the highlighted region.
</ParamField>

<ParamField>
  Max number of characters for a highlighted snippet. A snippet may contain
  multiple matches if they are close to each other.
</ParamField>

By default, `<b></b>` encloses the snippet. This can be configured with `start_tag` and `end_tag`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.snippet(description, start_tag => '<i>', end_tag => '</i>')
  FROM mock_items
  WHERE description ||| 'shoes'
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Snippet

  MockItem.objects.filter(
      description=ParadeDB(Match('shoes', operator='OR'))
  ).annotate(
      snippet=Snippet('description', start_sel='<i>', stop_sel='</i>')
  ).values('id', 'snippet')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(
          MockItem.id,
          pdb.snippet(
              MockItem.description,
              start_tag="<i>",
              end_tag="</i>",
          ).label("snippet"),
      )
      .where(search.match_any(MockItem.description, "shoes"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("shoes")
          .with_snippet(:description, start_tag: "<i>", end_tag: "</i>")
          .select(:id)
          .limit(5)
  ```
</CodeGroup>

## Multiple Snippets

`pdb.snippets(<column>)` returns an array of snippets, allowing you to retrieve multiple highlighted matches from a document. This is particularly useful when a document has several relevant matches spread throughout its content.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.snippets(description, max_num_chars => 15)
  FROM mock_items
  WHERE description ||| 'artistic vase'
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Snippets

  MockItem.objects.filter(
      description=ParadeDB(Match('artistic vase', operator='OR'))
  ).annotate(
      snippets=Snippets('description', max_num_chars=15)
  ).values('id', 'snippets')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(MockItem.id, pdb.snippets(MockItem.description, max_num_chars=15).label("snippets"))
      .where(search.match_any(MockItem.description, "artistic vase"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("artistic vase")
          .with_snippets(:description, max_chars: 15)
          .select(:id)
          .limit(5)
  ```
</CodeGroup>

```ini Expected Response theme={null}
 id |                snippets
----+-----------------------------------------
 19 | {<b>Artistic</b>,"ceramic <b>vase</b>"}
(1 row)

```

<ParamField>
  The leading indicator around the highlighted region.
</ParamField>

<ParamField>
  The trailing indicator around the highlighted region.
</ParamField>

<ParamField>
  Max number of characters for a highlighted snippet. When `max_num_chars` is
  small, multiple snippets may be generated for a single document.
</ParamField>

<ParamField>
  The maximum number of snippets to return per document.
</ParamField>

<ParamField>
  The number of snippets to skip before returning results. Use with `limit` for
  pagination.
</ParamField>

<ParamField>
  The order in which to sort the snippets. Can be `'score'` (default, sorts by
  relevance) or `'position'` (sorts by appearance in the document).
</ParamField>

### Limiting and Offsetting Snippets

You can control the number and order of snippets returned using the `limit`, `offset`, and `sort_by` parameters.

For example, to get only the first snippet:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.snippets(description, max_num_chars => 15, "limit" => 1)
  FROM mock_items
  WHERE description ||| 'running'
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Snippets

  MockItem.objects.filter(
      description=ParadeDB(Match('running', operator='OR'))
  ).annotate(
      snippets=Snippets('description', max_num_chars=15, limit=1)
  ).values('id', 'snippets')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(MockItem.id, pdb.snippets(MockItem.description, max_num_chars=15, limit=1).label("snippets"))
      .where(search.match_any(MockItem.description, "running"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running")
          .with_snippets(:description, max_chars: 15, limit: 1)
          .select(:id)
          .limit(5)
  ```
</CodeGroup>

To get the second snippet (by skipping the first one):

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.snippets(description, max_num_chars => 15, "limit" => 1, "offset" => 1)
  FROM mock_items
  WHERE description ||| 'running'
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Snippets

  MockItem.objects.filter(
      description=ParadeDB(Match('running', operator='OR'))
  ).annotate(
      snippets=Snippets('description', max_num_chars=15, limit=1, offset=1)
  ).values('id', 'snippets')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(
          MockItem.id,
          pdb.snippets(MockItem.description, max_num_chars=15, limit=1, offset=1).label("snippets"),
      )
      .where(search.match_any(MockItem.description, "running"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running")
          .with_snippets(:description, max_chars: 15, limit: 1, offset: 1)
          .select(:id)
          .limit(5)
  ```
</CodeGroup>

### Sorting Snippets

Snippets can be sorted either by their relevance score (`'score'`) or their position within the document (`'position'`).

To sort snippets by their appearance in the document:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.snippets(description, max_num_chars => 15, sort_by => 'position')
  FROM mock_items
  WHERE description ||| 'artistic vase'
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Snippets

  MockItem.objects.filter(
      description=ParadeDB(Match('artistic vase', operator='OR'))
  ).annotate(
      snippets=Snippets('description', max_num_chars=15, sort_by='position')
  ).values('id', 'snippets')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(
          MockItem.id,
          pdb.snippets(MockItem.description, max_num_chars=15, sort_by="position").label("snippets"),
      )
      .where(search.match_any(MockItem.description, "artistic vase"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("artistic vase")
          .with_snippets(:description, max_chars: 15, sort_by: :position)
          .select(:id)
          .limit(5)
  ```
</CodeGroup>

## Byte Offsets

`pdb.snippet_positions(<column>)` returns the byte offsets in the original text where the snippets would appear. It returns a two-dimensional integer array where each nested pair is `[start, end)`: the first value is the byte index of the first highlighted byte, and the second value is the byte index immediately after the last highlighted byte.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.snippet(description), pdb.snippet_positions(description)
  FROM mock_items
  WHERE description ||| 'shoes'
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Snippet, SnippetPositions

  MockItem.objects.filter(
      description=ParadeDB(Match('shoes', operator='OR'))
  ).annotate(
      snippet=Snippet('description'),
      snippet_positions=SnippetPositions('description')
  ).values('id', 'snippet', 'snippet_positions')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(
          MockItem.id,
          pdb.snippet(MockItem.description).label("snippet"),
          pdb.snippet_positions(MockItem.description).label("snippet_positions"),
      )
      .where(search.match_any(MockItem.description, "shoes"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("shoes")
          .with_snippet(:description)
          .with_snippet_positions(:description)
          .select(:id)
          .limit(5)
  ```
</CodeGroup>

```ini Expected Response theme={null}
 id |          snippet           | snippet_positions
----+----------------------------+-------------------
  4 | White jogging <b>shoes</b> | {{14,19}}
  3 | Sleek running <b>shoes</b> | {{14,19}}
  5 | Generic <b>shoes</b>       | {{8,13}}
(3 rows)
```


# Match
Source: https://docs.paradedb.com/documentation/full-text/match

Returns documents that match the provided query string, which is tokenized before matching

Match queries are the go-to query type for text search in ParadeDB. There are two types of match queries:
[match disjunction](#match-disjunction) and [match conjunction](#match-conjunction).

## Match Disjunction

Match disjunction uses the `|||` operator and means "find all documents that contain one or more of the terms tokenized from this text input."

To understand what this looks like in practice, let's consider the following query:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ||| 'running shoes';
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='OR'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(MockItem.description, "running shoes"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running shoes")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

This query returns:

```csv theme={null}
     description     | rating | category
---------------------+--------+----------
 Sleek running shoes |      5 | Footwear
 White jogging shoes |      3 | Footwear
 Generic shoes       |      4 | Footwear
(3 rows)
```

### How It Works

Let's look at what the `|||` operator does:

1. Retrieves the tokenizer configuration of the `description` column. In this example,
   let's assume `description` uses the [unicode](/documentation/tokenizers/available-tokenizers/unicode) tokenizer.
2. Tokenizes the query string with the same tokenizer. This means `running shoes` becomes two tokens: `running` and `shoes`.
3. Finds all rows where `description` contains **any one** of the tokens, `running` or `shoes`.

This is why all results have either `running` or `shoes` tokens in `description`.

### Examples

Let's consider a few more hypothetical documents to see whether they would be returned by match disjunction.
These examples assume that the index uses the default tokenizer and token filters, and that the query is
`running shoes`.

| Original Text       | Tokens                    | Match | Reason                                  | Related                                                               |
| ------------------- | ------------------------- | ----- | --------------------------------------- | --------------------------------------------------------------------- |
| Sleek running shoes | `sleek` `running` `shoes` | ✅     | Contains both `running` and `shoes`.    |                                                                       |
| Running shoes sleek | `sleek` `running` `shoes` | ✅     | Contains both `running` and `shoes`.    | [Phrase](/documentation/full-text/phrase)                             |
| SLeeK RUNNING ShOeS | `sleek` `running` `shoes` | ✅     | Contains both `running` and `shoes`.    | [Lowercasing](/documentation/indexing/create-index)                   |
| Sleek run shoe      | `sleek` `run` `shoe`      | ❌     | Contains neither `running` nor `shoes`. | [Stemming](/documentation/indexing/create-index)                      |
| Sleke ruining shoez | `sleke` `ruining` `shoez` | ❌     | Contains neither `running` nor `shoes`. | [Fuzzy](/documentation/full-text/fuzzy)                               |
| White jogging shoes | `white` `jogging` `shoes` | ✅     | Contains `shoes`.                       | [Match conjunction](/documentation/full-text/match#match-conjunction) |

## Match Conjunction

Suppose we want to find rows that contain both `running` **and** `shoes`. This is where the `&&&` match conjunction operator comes in.
`&&&` means "find all documents that contain all terms tokenized from this text input."

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description &&& 'running shoes';
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='AND'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_all(MockItem.description, "running shoes"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_all("running shoes")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

This query returns:

```csv theme={null}
     description     | rating | category
---------------------+--------+----------
 Sleek running shoes |      5 | Footwear
(1 row)
```

Note that `White jogging shoes` and `Generic shoes` are no longer returned because they do not have the token `running`.

### How It Works

Match conjunction works exactly like match disjunction, except for one key distinction. Instead of finding documents containing
at least one matching token from the query, it finds documents where **all tokens** from the query are a match.

### Examples

Let’s consider a few more hypothetical documents to see whether they would be returned by match conjunction.
These examples assume that the index uses the default tokenizer and token filters, and that the query is
`running shoes`.

| Original Text       | Tokens                    | Match | Reason                                       | Related                                                               |
| ------------------- | ------------------------- | ----- | -------------------------------------------- | --------------------------------------------------------------------- |
| Sleek running shoes | `sleek` `running` `shoes` | ✅     | Contains both `running` and `shoes`.         |                                                                       |
| Running shoes sleek | `sleek` `running` `shoes` | ✅     | Contains both `running` and `shoes`.         | [Phrase](/documentation/full-text/phrase)                             |
| SLeeK RUNNING ShOeS | `sleek` `running` `shoes` | ✅     | Contains both `running` and `shoes`.         | [Lowercasing](/documentation/indexing/create-index)                   |
| Sleek run shoe      | `sleek` `run` `shoe`      | ❌     | Does not contain both `running` and `shoes`. | [Stemming](/documentation/indexing/create-index)                      |
| Sleke ruining shoez | `sleke` `ruining` `shoez` | ❌     | Does not contain both `running` and `shoes`. | [Fuzzy](/documentation/full-text/fuzzy)                               |
| White jogging shoes | `white` `jogging` `shoes` | ❌     | Does not contain both `running` and `shoes`. | [Match conjunction](/documentation/full-text/match#match-conjunction) |

<Note>
  If the query string only contains one token, then `|||` and `&&&` are effectively the same:

  ```sql theme={null}
  -- These two queries produce the same results
  SELECT description, rating, category
  FROM mock_items
  WHERE description ||| 'shoes';

  SELECT description, rating, category
  FROM mock_items
  WHERE description &&& 'shoes';
  ```
</Note>

## Using a Custom Tokenizer

By default, the match query automatically tokenizes the query string with the same tokenizer used by the field it's being searched against.
This behavior can be overridden by explicitly casting the query to a different tokenizer.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ||| 'running shoes'::pdb.whitespace;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='OR', tokenizer='whitespace'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(MockItem.description, "running shoes", tokenizer="whitespace"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running shoes", tokenizer: "whitespace")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

## Using Pretokenized Text

The match operators also accept text arrays. If a text array is provided, each element of the array is treated as an exact token,
which means that no further processing is done.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description &&& ARRAY['running', 'shoes'];
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running', 'shoes', operator='AND'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_all(MockItem.description, "running", "shoes"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_all("running", "shoes")
          .select(:description, :rating, :category)
  ```
</CodeGroup>


# How Text Search Works
Source: https://docs.paradedb.com/documentation/full-text/overview

Understand how ParadeDB uses token matching to efficiently search large corpuses of text

Text search in ParadeDB, like Elasticsearch and most search engines, is centered around the concept of **token matching**.

Token matching consists of two steps. First, at indexing time, text is processed by a tokenizer, which breaks input into discrete units called **tokens** or
**terms**. For example, the [default](/documentation/indexing/create-index) tokenizer splits the text `Sleek running shoes` into the tokens `sleek`, `running`, and `shoes`.

Second, at query time, the query engine looks for token matches based on the specified query and query type. Some common query types include:

* [Match](/documentation/full-text/match): Matches documents containing any or all query tokens
* [Phrase](/documentation/full-text/phrase): Matches documents where all tokens appear in the same order as the query
* [Term](/documentation/full-text/term): Matches documents containing an exact token
* ...and many more [advanced](/documentation/query-builder/overview) query types

## Not Substring Matching

While ParadeDB supports substring matching via [regex](/documentation/query-builder/term/regex) queries, it's important to note that token matching is **not** the
same as substring matching.

Token matching is a much more versatile and powerful technique. It enables relevance scoring, language-specific analysis, typo tolerance, and more expressive query types — capabilities that go far beyond simply looking for a sequence of characters.

## Similarity Search

Text search is different from similarity search, also known as vector search. Whereas text search matches based on token matches, similarity search
matches based on semantic meaning.

Today, most ParadeDB users install [pgvector](https://github.com/pgvector/pgvector) alongside ParadeDB for vector search and hybrid search.
That remains our recommended setup when you need embeddings in Postgres right now.

We are also actively working on a native vector search experience inside ParadeDB indexes that is intended to improve on the current `pgvector`
workflow, especially for filtered and hybrid search. You can follow that work in our [roadmap](/welcome/roadmap#vector-search-improvements) or
[reach out](mailto:support@paradedb.com) if it is important for your use case.


# Phrase
Source: https://docs.paradedb.com/documentation/full-text/phrase

Phrase queries are like match queries, but with order and position of matching tokens enforced

Phrase queries work exactly like [match conjunction](/documentation/full-text/match#match-conjunction), but are more strict in that they require the
order and position of tokens to be the same.

Suppose our query is `running shoes`, and we want to omit results like
`running sleek shoes` or `shoes running` — these results contain the right tokens, but not in the exact order and position
that the query specifies.

Enter the `###` phrase operator:

```sql theme={null}
INSERT INTO mock_items (description, rating, category) VALUES
('running sleek shoes', 5, 'Footwear'),
('shoes running', 5, 'Footwear');
```

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ### 'running shoes';
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Phrase

  MockItem.objects.filter(
      description=ParadeDB(Phrase('running shoes'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.phrase(MockItem.description, "running shoes"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .phrase("running shoes")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

This query returns:

```csv theme={null}
     description     | rating | category
---------------------+--------+----------
 Sleek running shoes |      5 | Footwear
(1 row)
```

Note that `running sleek shoes` and `shoes running` did not match the phrase `running shoes` despite having the tokens `running` and
`shoes` because they appear in the wrong order or with other words in between.

## How It Works

Let's look at what happens under the hood for the above phrase query:

1. Retrieves the tokenizer configuration of the `description` column. In this example,
   let's assume `description` uses the [unicode](/documentation/tokenizers/available-tokenizers/unicode) tokenizer.
2. Tokenizes the query string with the same tokenizer. This means `running shoes` becomes two tokens: `running` and `shoes`.
3. Finds all rows where `description` contains `running` immediately followed by `shoes`.

## Examples

Let’s consider a few more hypothetical documents to see whether they would be returned by the phrase query.
These examples assume that index uses the default tokenizer and token filters, and that the query is
`running shoes`.

| Original Text       | Tokens                    | Match | Reason                                         | Related                                                               |
| ------------------- | ------------------------- | ----- | ---------------------------------------------- | --------------------------------------------------------------------- |
| Sleek running shoes | `sleek` `running` `shoes` | ✅     | Contains `running` and `shoes`, in that order. |                                                                       |
| Sleek shoes running | `sleek` `shoes` `running` | ❌     | `running` and `shoes` not in the right order.  | [Match conjunction](/documentation/full-text/match#match-conjunction) |
| SLeeK RUNNING ShOeS | `sleek` `running` `shoes` | ✅     | Contains `running` and `shoes`, in that order. | [Lowercasing](/documentation/indexing/create-index)                   |
| Sleek run shoe      | `sleek` `run` `shoe`      | ❌     | Does not contain both `running` and `shoes`.   | [Stemming](/documentation/indexing/create-index)                      |
| Sleke ruining shoez | `sleke` `ruining` `shoez` | ❌     | Does not contain both `running` and `shoes`.   |                                                                       |
| White jogging shoes | `white` `jogging` `shoes` | ❌     | Does not contain both `running` and `shoes`.   |                                                                       |

## Adding Slop

Slop allows the token ordering requirement of phrase queries to be relaxed. It specifies how many changes — like extra words in between or transposed word positions — are allowed while still considering the phrase a match:

* An extra word in between (e.g. `sleek shoes` vs. `sleek running shoes`) has a slop of `1`
* A transposition (e.g. `running shoes` vs. `shoes running`) has a slop of `2`

To apply slop to a phrase query, cast the query to `slop(n)`, where `n` is the maximum allowed slop.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ### 'shoes running'::pdb.slop(2);
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Phrase

  MockItem.objects.filter(
      description=ParadeDB(Phrase('shoes running', slop=2))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.phrase(MockItem.description, "shoes running", slop=2))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .phrase("shoes running", slop: 2)
          .select(:description, :rating, :category)
  ```
</CodeGroup>

## Using a Custom Tokenizer

The phrase query supports custom query tokenization.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ### 'running shoes'::pdb.whitespace;
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Phrase

  MockItem.objects.filter(
      description=ParadeDB(Phrase('running shoes', tokenizer='whitespace'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.phrase(MockItem.description, "running shoes", tokenizer="whitespace"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .phrase("running shoes", tokenizer: "whitespace")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

## Using Pretokenized Text

The phrase operator also accepts a text array as the right-hand side argument. If a text array is provided, each element of the array is treated as an exact token,
which means that no further processing is done.

The following query matches documents containing the token `shoes` immediately followed by `running`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ### ARRAY['running', 'shoes'];
  ```

  ```python Django theme={null}
  MockItem.objects.extra(
      where=["description ### ARRAY['running', 'shoes']"]
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.phrase(MockItem.description, ["running", "shoes"]))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .phrase(%w[running shoes])
          .select(:description, :rating, :category)
  ```
</CodeGroup>

Adding slop is supported:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ### ARRAY['shoes', 'running']::pdb.slop(2);
  ```

  ```python Django theme={null}
  MockItem.objects.extra(
      where=["description ### ARRAY['shoes', 'running']::pdb.slop(2)"]
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.phrase(MockItem.description, ["shoes", "running"], slop=2))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .phrase(%w[shoes running], slop: 2)
          .select(:description, :rating, :category)
  ```
</CodeGroup>


# Proximity
Source: https://docs.paradedb.com/documentation/full-text/proximity

Match documents based on token proximity within the source document

Proximity queries are used to match documents containing tokens that are within a certain token distance of one another.

## Overview

The following query finds all documents where the token `sleek` is at most `1` token away from `shoes`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ ('sleek' ## 1 ## 'shoes');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Proximity

  MockItem.objects.filter(
      description=ParadeDB(Proximity('sleek').within(1, 'shoes'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = select(MockItem.description, MockItem.rating, MockItem.category).where(
      search.proximity(MockItem.description, search.prox_str("sleek").within(1, "shoes"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .near(ParadeDB.proximity("sleek").within(1, "shoes"))
          .select(:description, :rating, :category)
  ```
</CodeGroup>

<Note>
  Like the [term](/documentation/full-text/term) query, the query string in a
  proximity query is treated as a finalized token.
</Note>

`##` does not care about order -- the term on the left-hand side may appear before or after the term on the right-hand side.
To ensure that the left-hand term appears before the right-hand term, use `##>`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ ('sleek' ##> 1 ##> 'shoes');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Proximity

  MockItem.objects.filter(
      description=ParadeDB(Proximity('sleek').within(1, 'shoes', ordered=True))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.proximity(MockItem.description, search.prox_str("sleek").within(1, "shoes", ordered=True)))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .near(ParadeDB.proximity("sleek").within(1, "shoes", ordered: true))
          .select(:description, :rating, :category)
  ```
</CodeGroup>

## Proximity Regex

In addition to exact tokens, proximity queries can also match against regex expressions.

The following query finds all documents where any token matching the regex query `sl.*` is at most `1` token away
from the token `shoes`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ (pdb.prox_regex('sl.*') ## 1 ## 'shoes');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, ProxRegex, Proximity

  MockItem.objects.filter(
      description=ParadeDB(Proximity('shoes').within(1, ProxRegex('sl.*')))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.proximity(MockItem.description, search.prox_regex("sl.*").within(1, "shoes")))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .near(ParadeDB.proximity(ParadeDB.regex_term("sl.*")).within(1, "shoes"))
          .select(:description, :rating, :category)
  ```
</CodeGroup>

By default, `pdb.prox_regex` will expand to the first `50` regex matches in each document. This limit can be overridden
by providing a second argument:

<CodeGroup>
  ```sql SQL theme={null}
  -- Expand up to 100 regex matches
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ (pdb.prox_regex('sl.*', 100) ## 1 ## 'shoes');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, ProxRegex, Proximity

  MockItem.objects.filter(
      description=ParadeDB(Proximity('shoes').within(1, ProxRegex('sl.*', max_expansions=100)))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.proximity(MockItem.description, search.prox_regex("sl.*", 100).within(1, "shoes")))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .near(ParadeDB.proximity(ParadeDB.regex_term("sl.*", max_expansions: 100)).within(1, "shoes"))
          .select(:description, :rating, :category)
  ```
</CodeGroup>

## Proximity Array

`pdb.prox_array` matches against an array of tokens instead of a single token. For example, the following query finds all
documents where any of the tokens `sleek` or `white` is within `1` token of `shoes`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ (pdb.prox_array('sleek', 'white') ## 1 ## 'shoes');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Proximity

  MockItem.objects.filter(
      description=ParadeDB(Proximity(['sleek', 'white']).within(1, 'shoes'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.proximity(MockItem.description, search.prox_array("sleek", "white").within(1, "shoes")))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .near(ParadeDB.proximity("sleek", "white").within(1, "shoes"))
          .select(:description, :rating, :category)
  ```
</CodeGroup>

`pdb.prox_array` can also take regex:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ (pdb.prox_array(pdb.prox_regex('sl.*'), 'white') ## 1 ## 'shoes');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, ProxRegex, Proximity

  MockItem.objects.filter(
      description=ParadeDB(Proximity([ProxRegex('sl.*'), 'white']).within(1, 'shoes'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.proximity(MockItem.description, search.prox_array(search.prox_regex("sl.*"), "white").within(1, "shoes")))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .near(ParadeDB.proximity(ParadeDB.regex_term("sl.*"), "white").within(1, "shoes"))
          .select(:description, :rating, :category)
  ```
</CodeGroup>

## Proximity Chaining

Multiple proximity clauses can be chained together:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ ('sleek' ## 1 ## 'running' ## 2 ## pdb.prox_array('sneakers', pdb.prox_regex('sho.*')));
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, ProxRegex, Proximity

  MockItem.objects.filter(
      description=ParadeDB(Proximity('sleek').within(1, 'running').within(2, ['sneakers', ProxRegex('sho.*')]))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.proximity(MockItem.description, search.prox_str("sleek").within(1, "running").within(2, search.prox_array('sneakers', search.prox_regex('sho.*')))))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .near(ParadeDB.proximity("sleek").within(1, "running").within(2, ['sneakers', ParadeDB.regex_term('sho.*')]))
          .select(:description, :rating, :category)
  ```
</CodeGroup>


# Term
Source: https://docs.paradedb.com/documentation/full-text/term

Look for exact token matches in the source document, without any further processing of the query string

Term queries look for exact token matches. A term query is like an exact string match, but at the
token level.

Unlike [match](/documentation/full-text/match) or [phrase](/documentation/full-text/phrase) queries, term queries treat the query
string as a **finalized token**. This means that the query string is taken as-is, without any further tokenization or filtering.

Term queries use the `===` operator. To understand exactly how it works, let's consider the following two term queries:

<CodeGroup>
  ```sql SQL theme={null}
  -- Term query 1
  SELECT description, rating, category
  FROM mock_items
  WHERE description === 'running';

  -- Term query 2
  SELECT description, rating, category
  FROM mock_items
  WHERE description === 'RUNNING';
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Term

  # Term query 1
  MockItem.objects.filter(
      description=ParadeDB(Term('running'))
  ).values('description', 'rating', 'category')

  # Term query 2
  MockItem.objects.filter(
      description=ParadeDB(Term('RUNNING'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  term_query_1 = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.term(MockItem.description, "running"))
  )

  term_query_2 = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.term(MockItem.description, "RUNNING"))
  )

  with Session(engine) as session:
      {
          "rows_query_1": session.execute(term_query_1).all(),
          "rows_query_2": session.execute(term_query_2).all(),
      }
  ```

  ```ruby Rails theme={null}
  # Term query 1
  MockItem.search(:description)
          .term("running")
          .select(:description, :rating, :category)

  # Term query 2
  MockItem.search(:description)
          .term("RUNNING")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

The first query returns:

```csv theme={null}
     description     | rating | category
---------------------+--------+----------
 Sleek running shoes |      5 | Footwear
(1 row)
```

However, the second query returns no results. This is because term queries look for exact matches, which includes
case sensitivity, and there are no documents in the example dataset containing the token `RUNNING`.

<Note>
  All tokenizers besides the literal tokenizer
  [lowercase](/documentation/token-filters/lowercase) tokens by default. Make
  sure to account for this when searching for a term.
</Note>

<Note>
  If you are using `===` to do an exact string match on the original text, make
  sure that the text uses the
  [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer.
</Note>

## How It Works

Under the hood, `===` simply finds all documents where any of their tokens are an exact string match against the query token.
A document's tokens are determined by the field's tokenizer and token filters, configured at index creation time.

## Examples

Let’s consider a few more hypothetical documents to see whether they would be returned by the term query.
These examples assume that index uses the default tokenizer and token filters, and that the term query is
`running`.

| Original Text       | Tokens                    | Match | Reason                                | Related                                             |
| ------------------- | ------------------------- | ----- | ------------------------------------- | --------------------------------------------------- |
| Sleek running shoes | `sleek` `running` `shoes` | ✅     | Contains the token `running`.         |                                                     |
| Running shoes sleek | `sleek` `running` `shoes` | ✅     | Contains the token `running`.         |                                                     |
| SLeeK RUNNING ShOeS | `sleek` `running` `shoes` | ✅     | Contains the token `running`.         | [Lowercasing](/documentation/indexing/create-index) |
| Sleek run shoe      | `sleek` `run` `shoe`      | ❌     | Does not contain the token `running`. | [Stemming](/documentation/indexing/create-index)    |
| Sleke ruining shoez | `sleke` `ruining` `shoez` | ❌     | Does not contain the token `running`. | [Fuzzy](/documentation/full-text/fuzzy)             |
| White jogging shoes | `white` `jogging` `shoes` | ❌     | Does not contain the token `running`. |                                                     |

## Term Set

Passing a text array to the right-hand side of `===` means "find all documents containing any one of these tokens."

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description === ARRAY['shoes', 'running'];
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, TermSet

  MockItem.objects.filter(
      description=ParadeDB(TermSet('shoes', 'running'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import or_, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(
          or_(
              search.term(MockItem.description, "shoes"),
              search.term(MockItem.description, "running"),
          )
      )
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .term_set("shoes", "running")
          .select(:description, :rating, :category)
  ```
</CodeGroup>


# Configure your Environment
Source: https://docs.paradedb.com/documentation/getting-started/environment

Configure your environment for querying ParadeDB

This guide will walk you through setting up your environment to run queries against ParadeDB. Choose your preferred tool below:

<Accordion title="SQL">
  ParadeDB comes with a helpful procedure that creates a table populated with mock data to help
  you get started. Run the following command to create this table.

  ```sql theme={null}
  CALL paradedb.create_bm25_test_table(
    schema_name => 'public',
    table_name => 'mock_items'
  );
  ```

  Then, inspect the first 3 rows:

  ```sql theme={null}
  SELECT description, rating, category
  FROM mock_items
  LIMIT 3;
  ```

  ```ini Expected Response theme={null}
         description        | rating |  category
  --------------------------+--------+-------------
   Ergonomic metal keyboard |      4 | Electronics
   Plastic Keyboard         |      4 | Electronics
   Sleek running shoes      |      5 | Footwear
  (3 rows)
  ```

  Next, let's create a BM25 index called `search_idx` on this table. A BM25 index is a covering index, which means that multiple columns can be included in the same index.

  ```sql theme={null}
  CREATE INDEX search_idx ON mock_items
  USING bm25 (id, description, category, rating, in_stock, created_at, metadata, weight_range)
  WITH (key_field='id');
  ```

  <Note>
    As a general rule of thumb, any columns that you want to filter, `GROUP BY`,
    `ORDER BY`, or aggregate as part of a full text query should be added to the
    index for faster performance.
  </Note>

  <Note>
    Note the mandatory `key_field` option. See [choosing a key
    field](/documentation/indexing/create-index#choosing-a-key-field) for more
    details.
  </Note>

  You're all set! Try [running some queries](/documentation/getting-started/queries).
</Accordion>

<Accordion title="Django">
  To start you'll need a [Django](https://www.djangoproject.com/) project with [Psycopg](https://www.psycopg.org/) and [django-paradedb](https://pypi.org/project/django-paradedb/) installed. Run the following to create one:

  ```bash theme={null}
  python3 -m venv .venv
  source .venv/bin/activate
  pip install django psycopg django-paradedb
  python3 -m django startproject myproject .
  python3 manage.py startapp myapp
  ```

  In `myproject/settings.py`, add `'django.contrib.postgres'` and `'myapp'` to `INSTALLED_APPS`. Then, configure `DATABASES["default"]` to point to Postgres:

  ```python myproject/settings.py theme={null}
  INSTALLED_APPS = [
      ...,
      'django.contrib.postgres',
      'myapp',
  ]

  DATABASES = {
      "default": {
          "ENGINE": "django.db.backends.postgresql",
          "NAME": "mydatabase",
          "USER": "myuser",
          "PASSWORD": "mypassword",
          "HOST": "localhost",
          "PORT": "5432",
      }
  }
  ```

  We can now add a model for ParadeDB's built-in test table and BM25 index:

  ```python models.py theme={null}
  from django.db import models

  from django.contrib.postgres.fields import IntegerRangeField
  from paradedb.indexes import BM25Index
  from paradedb.queryset import ParadeDBManager


  class MockItem(models.Model):
      description = models.TextField(null=True, blank=True)
      rating = models.IntegerField(null=True, blank=True)
      category = models.CharField(max_length=255, null=True, blank=True)
      in_stock = models.BooleanField(null=True, blank=True)
      metadata = models.JSONField(null=True, blank=True)
      created_at = models.DateTimeField(null=True, blank=True)
      last_updated_date = models.DateField(null=True, blank=True)
      latest_available_time = models.TimeField(null=True, blank=True)
      weight_range = IntegerRangeField(null=True, blank=True)

      objects = ParadeDBManager()

      class Meta:
          db_table = "mock_items"
          indexes = [
              BM25Index(
                  fields={
                      "id": {},
                      "description": {"tokenizer": "unicode_words"},
                      "category": {"tokenizer": "literal"},
                      "rating": {},
                      "in_stock": {},
                      "metadata": {"json_fields": {"fast": True}},
                      "created_at": {},
                      "last_updated_date": {},
                      "latest_available_time": {},
                      "weight_range": {},
                  },
                  key_field="id",
                  name="search_idx",
              ),
          ]
  ```

  <Note>
    As a general rule of thumb, any columns that you want to filter, `GROUP BY`,
    `ORDER BY`, or aggregate as part of a full text query should be added to the
    index for faster performance.
  </Note>

  <Note>
    Note the mandatory `key_field` option. See [choosing a key
    field](/documentation/indexing/create-index#choosing-a-key-field) for more
    details.
  </Note>

  Run the migrations to create the table and index:

  ```bash theme={null}
  python3 manage.py makemigrations
  python3 manage.py migrate
  ```

  Now, open a Python shell with `python3 manage.py shell` and run the following command to populate `mock_items`.

  ```python theme={null}
  from django.db import connection

  with connection.cursor() as cursor:
      cursor.execute("""
          CALL paradedb.create_bm25_test_table(
            schema_name => 'public',
            table_name  => 'mock_items_tmp'
          );
          INSERT INTO public.mock_items
          SELECT * FROM public.mock_items_tmp;
          DROP TABLE public.mock_items_tmp;
      """)
  ```

  You're all set! Try [running some queries](/documentation/getting-started/queries) in your Python shell.
</Accordion>

<Accordion title="SQLAlchemy">
  To get started, install [SQLAlchemy](https://www.sqlalchemy.org/), [Alembic](https://alembic.sqlalchemy.org/en/latest/), [Psycopg](https://www.psycopg.org/), and [sqlalchemy-paradedb](https://pypi.org/project/sqlalchemy-paradedb/).

  ```bash theme={null}
  python3 -m venv .venv
  source .venv/bin/activate
  pip install sqlalchemy psycopg alembic sqlalchemy-paradedb
  ```

  Initialize Alembic:

  ```bash theme={null}
  alembic init migrations
  ```

  Then update the Alembic configuration to point to your database:

  ```ini alembic.ini theme={null}
  sqlalchemy.url = postgresql+psycopg://myuser:mypassword@localhost:5432/mydatabase
  ```

  ParadeDB comes with a built-in test table that we'll run our queries against. Create a `models.py` file with a model and search index for that table:

  ```python theme={null}
  from __future__ import annotations

  from datetime import date, datetime, time
  from typing import Any

  from sqlalchemy import Boolean, Date, DateTime, Index, Integer, String, Text, Time
  from sqlalchemy.dialects.postgresql import INT4RANGE, JSONB, Range
  from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

  from paradedb.sqlalchemy import indexing


  class Base(DeclarativeBase):
      pass


  class MockItem(Base):
      __tablename__ = "mock_items"

      id: Mapped[int] = mapped_column(Integer, primary_key=True)
      description: Mapped[str | None] = mapped_column(Text, nullable=True)
      rating: Mapped[int | None] = mapped_column(Integer, nullable=True)
      category: Mapped[str | None] = mapped_column(String(255), nullable=True)
      in_stock: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
      metadata_: Mapped[dict[str, Any] | None] = mapped_column("metadata", JSONB, nullable=True)
      created_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
      last_updated_date: Mapped[date | None] = mapped_column(Date, nullable=True)
      latest_available_time: Mapped[time | None] = mapped_column(Time, nullable=True)
      weight_range: Mapped[Range[int] | None] = mapped_column(INT4RANGE, nullable=True)


  Index(
      "search_idx",
      indexing.BM25Field(MockItem.id),
      indexing.BM25Field(MockItem.description),
      indexing.BM25Field(MockItem.category),
      indexing.BM25Field(MockItem.rating),
      indexing.BM25Field(MockItem.in_stock),
      indexing.BM25Field(MockItem.metadata_),
      indexing.BM25Field(MockItem.created_at),
      indexing.BM25Field(MockItem.last_updated_date),
      indexing.BM25Field(MockItem.latest_available_time),
      indexing.BM25Field(MockItem.weight_range),
      postgresql_using="bm25",
      postgresql_with={"key_field": "id"},
  )
  ```

  <Note>
    As a general rule of thumb, any columns that you want to filter, `GROUP BY`,
    `ORDER BY`, or aggregate as part of a full text query should be added to the
    index for faster performance.
  </Note>

  <Note>
    Note the mandatory `key_field` option. See [choosing a key
    field](/documentation/indexing/create-index#choosing-a-key-field) for more
    details.
  </Note>

  Copy this configuration into your `migrations/env.py`:

  ```python migrations/env.py theme={null}
  from logging.config import fileConfig

  from sqlalchemy import engine_from_config, text
  from sqlalchemy import pool

  from alembic import context

  # This import is required for autogenerated ParadeDB migrations
  # to work properly.
  import paradedb.sqlalchemy.alembic  # noqa: F401
  from models import Base

  config = context.config

  if config.config_file_name is not None:
      fileConfig(config.config_file_name)

  target_metadata = Base.metadata

  # The ParadeDB Docker image comes pre-bundled with some popular
  # extensions like PostGIS. PostGIS automatically creates a table
  # called `spatial_ref_sys`. This tells Alembic not to drop it even
  # though it isn't tracked in Alembic's metadata.
  IGNORED_TABLES = {"spatial_ref_sys"}


  def include_object(object, name, type_, reflected, compare_to):
      if type_ == "table" and reflected and name in IGNORED_TABLES:
          return False
      return True


  def run_migrations_offline() -> None:
      url = config.get_main_option("sqlalchemy.url")
      context.configure(
          url=url,
          target_metadata=target_metadata,
          literal_binds=True,
          dialect_opts={"paramstyle": "named"},
      )

      with context.begin_transaction():
          context.run_migrations()


  def run_migrations_online() -> None:
      connectable = engine_from_config(
          config.get_section(config.config_ini_section, {}),
          prefix="sqlalchemy.",
          poolclass=pool.NullPool,
      )

      with connectable.connect() as connection:
          # This prevents Alembic from modifying tables outside
          # of the `public` schema.
          connection.execute(text("SET search_path TO public"))
          connection.commit()
          context.configure(
              connection=connection,
              target_metadata=target_metadata,
              include_object=include_object,
          )

          with context.begin_transaction():
              context.run_migrations()


  if context.is_offline_mode():
      run_migrations_offline()
  else:
      run_migrations_online()
  ```

  Next, add a migration to create the `mock_items` test table. Create a blank migration in `0001_create_mock_items_table.py` by running the following command:

  ```bash theme={null}
  alembic revision --rev-id 0001 -m "Create mock_items table"
  ```

  Update the generated migration to create the table:

  ```python theme={null}
  def upgrade() -> None:
      """Upgrade schema."""
      op.execute(
          """
          CALL paradedb.create_bm25_test_table(
            schema_name => 'public',
            table_name => 'mock_items'
          )
          """
      )


  def downgrade() -> None:
      """Downgrade schema."""
      op.execute("DROP TABLE IF EXISTS public.mock_items")
  ```

  Then, run it with:

  ```bash theme={null}
  alembic upgrade head
  ```

  Next, autogenerate a new migration to create the search index.

  ```bash theme={null}
  alembic revision --rev-id 0002 --autogenerate -m "Create search index on mock_items"
  ```

  The generated migration should look like this:

  ```python 0002_add_mock_items_search_index.py theme={null}
  """add mock_items search index

  Revision ID: 0002
  Revises: 0001
  Create Date: 2026-04-07 13:56:45.304941

  """
  from typing import Sequence, Union

  from alembic import op
  import sqlalchemy as sa


  # revision identifiers, used by Alembic.
  revision: str = '0002'
  down_revision: Union[str, Sequence[str], None] = '0001'
  branch_labels: Union[str, Sequence[str], None] = None
  depends_on: Union[str, Sequence[str], None] = None


  def upgrade() -> None:
      """Upgrade schema."""
      # ### commands auto generated by Alembic - please adjust! ###
      op.create_bm25_index('search_idx', 'mock_items', ['id', 'description', 'category', 'rating', 'in_stock', 'metadata', 'created_at', 'last_updated_date', 'latest_available_time', 'weight_range'], key_field='id', table_schema='public')
      # ### end Alembic commands ###


  def downgrade() -> None:
      """Downgrade schema."""
      # ### commands auto generated by Alembic - please adjust! ###
      op.drop_bm25_index('search_idx', if_exists=True, schema='public')
      # ### end Alembic commands ###
  ```

  Then run it with:

  ```bash theme={null}
  alembic upgrade head
  ```

  Finally, run `python` and execute the following:

  ```python theme={null}
  from models import MockItem
  from sqlalchemy import create_engine
  engine = create_engine('postgresql+psycopg://myuser:mypassword@localhost:5432/mydatabase')
  ```

  You're all set! Try [running some queries](/documentation/getting-started/queries) in your shell.
</Accordion>

<Accordion title="Rails">
  To get started, create a [Rails](https://rubyonrails.org/) app that uses PostgreSQL.

  ```bash theme={null}
  rails new paradedb -d postgresql
  cd paradedb
  ```

  Add the [rails-paradedb](https://rubygems.org/gems/rails-paradedb) gem to your `Gemfile`:

  ```ruby Gemfile theme={null}
  gem "rails-paradedb", require: "parade_db"
  ```

  Then install it:

  ```bash theme={null}
  bundle install
  ```

  Update `config/database.yml` to point to your ParadeDB database:

  ```yml config/database.yml theme={null}
  development:
    adapter: postgresql
    encoding: unicode
    database: mydatabase
    username: myuser
    password: mypassword
    host: localhost
    port: 5432
  ```

  ParadeDB comes with a built-in test table that we'll run our queries against. Generate a migration to create it:

  ```bash theme={null}
  rails generate migration CreateMockItemsTable
  ```

  Update the generated migration to create `mock_items`:

  ```ruby db/migrate/*_create_mock_items_table.rb theme={null}
  def up
    execute <<~SQL
      CALL paradedb.create_bm25_test_table(
        schema_name => 'public',
        table_name => 'mock_items'
      );
    SQL
  end

  def down
    drop_table :mock_items, if_exists: true
  end
  ```

  Next, create a model for the `mock_items` table in `app/models/mock_item.rb`:

  ```ruby app/models/mock_item.rb theme={null}
  class MockItem < ApplicationRecord
    include ParadeDB::Model

    self.table_name = "mock_items"
    self.primary_key = "id"
  end
  ```

  Then, create a search index for that table in `app/models/mock_item_index.rb`:

  ```ruby app/models/mock_item_index.rb theme={null}
  class MockItemIndex < ParadeDB::Index
    self.table_name = :mock_items
    self.key_field = :id
    self.index_name = :search_idx
    self.fields = {
      id: nil,
      description: nil,
      category: nil,
      rating: nil,
      in_stock: nil,
      metadata: nil,
      created_at: nil,
      last_updated_date: nil,
      latest_available_time: nil,
      weight_range: nil
    }
  end
  ```

  <Note>
    As a general rule of thumb, any columns that you want to filter, `GROUP BY`,
    `ORDER BY`, or aggregate as part of a full text query should be added to the
    index for faster performance.
  </Note>

  <Note>
    Note the mandatory `key_field` option. See [choosing a key
    field](/documentation/indexing/create-index#choosing-a-key-field) for more
    details.
  </Note>

  Generate a migration for the search index:

  ```bash theme={null}
  rails generate migration CreateMockItemsIndex
  ```

  Update the generated migration to create the index:

  ```ruby db/migrate/*_create_mock_items_index.rb theme={null}
  def up
    create_paradedb_index(MockItemIndex, if_not_exists: true)
  end

  def down
    remove_bm25_index :mock_items, name: :search_idx, if_exists: true
  end
  ```

  Run the migrations:

  ```bash theme={null}
  rails db:migrate
  ```

  You're all set! Open the Rails console and [run some queries](/documentation/getting-started/queries).

  ```bash theme={null}
  rails console
  ```
</Accordion>


# Install ParadeDB
Source: https://docs.paradedb.com/documentation/getting-started/install

How to run the ParadeDB Docker image

The fastest way to install ParadeDB is by pulling the ParadeDB Docker image and running it locally. If
your primary Postgres is in a virtual private cloud (VPC), we recommend deploying ParadeDB on a compute
instance within your VPC to avoid exposing public IP addresses and needing to provision traffic routing
rules.

**Note**: ParadeDB supports Postgres 15+, and the `latest` tag ships with Postgres 18. To specify a different Postgres version, please refer to the available tags on [Docker Hub](https://hub.docker.com/r/paradedb/paradedb/tags).

```bash theme={null}
docker run \
  --name paradedb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=mydatabase \
  -v paradedb_data:/var/lib/postgresql/ \
  -p 5432:5432 \
  -d \
  paradedb/paradedb:latest
```

You may replace `myuser`, `mypassword`, and `mydatabase` with whatever values you want. These will be your database
connection credentials.

To connect to ParadeDB, run

```bash theme={null}
docker exec -it paradedb psql -U myuser -d mydatabase -W
```

To see all the ways in which you can install ParadeDB, please refer to our [deployment documentation](/deploy/overview).

That's it! Next, let's [set up your environment](/documentation/getting-started/environment) so we can run a few queries.


# Load Data from Postgres
Source: https://docs.paradedb.com/documentation/getting-started/load

Dump data from an existing Postgres and load into ParadeDB

The easiest way to copy data from another Postgres into ParadeDB is with the `pg_dump` and `pg_restore` utilities. These are
installed by default when you install `psql`.

This approach is ideal for quickly testing ParadeDB. See the [deployment guide](/deploy/overview) for how to deploy ParadeDB into production.

## Create a Dump

Run `pg_dump` to create a copy of your database. The `pg_dump` version needs be greater than or equal to that of your Postgres database. You can check the version with `pg_dump --version`.

Below, we use the "custom" format (`-Fc`) for both `pg_dump` and `pg_restore`. Please review the [Postgres `pg_dump` documentation](https://www.postgresql.org/docs/current/app-pgdump.html) for other options that may be more appropriate for your environment.

<Note>
  Replace `host`, `username`, and `dbname` with your existing Postgres database
  credentials. If you deployed ParadeDB within your VPC, the `host` will be the
  private IP address of your existing Postgres database.
</Note>

```bash theme={null}
pg_dump -Fc --no-acl --no-owner \
    -h <host> \
    -U <username> \
    <dbname> > old_db.dump
```

If your database is large, this can take some time. You can speed this up by dumping specific tables.

```bash theme={null}
pg_dump -Fc --no-acl --no-owner \
    -h <host> \
    -U <username> \
    -t <table_name_1> -t <table_name_2> \
    <dbname> > old_db.dump
```

## Restore the Dump

Run `pg_restore` to load this data into ParadeDB. The `pg_restore` version needs be greater than or equal to that of your `pg_dump`. You can check the version with `pg_restore --version`.

<Note>
  Replace `host`, `username`, and `dbname` with your ParadeDB credentials.
</Note>

```bash theme={null}
pg_restore --verbose --clean --no-acl --no-owner \
    -h <host> \
    -U <username> \
    -d <dbname> \
    -Fc \
    old_db.dump
```

Congratulations! You are now ready to run real queries over your data. To get started, refer to our [full text search documentation](https://docs.paradedb.com/documentation/full-text/overview).


# Run Queries
Source: https://docs.paradedb.com/documentation/getting-started/queries

Run your first queries on ParadeDB

Now that your [environment is configured](/documentation/getting-started/environment), select the codetab for your tool and run some queries.

## Match Query

We're now ready to execute a basic text search query. We'll look for matches where `description` matches `running shoes` where `rating` is greater than `2`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ||| 'running shoes' AND rating > 2
  ORDER BY rating
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='OR')),
      rating__gt=2
  ).values('description', 'rating', 'category').order_by('rating')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(MockItem.description, "running shoes"), MockItem.rating > 2)
      .order_by(MockItem.rating)
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running shoes")
          .where(rating: 3..)
          .select(:description, :rating, :category)
          .order(:rating)
          .limit(5)
  ```
</CodeGroup>

```ini Expected Response theme={null}
     description     | rating | category
---------------------+--------+----------
 White jogging shoes |      3 | Footwear
 Generic shoes       |      4 | Footwear
 Sleek running shoes |      5 | Footwear
(3 rows)
```

`|||` is ParadeDB's custom [match disjunction](/documentation/full-text/match#disjunction) operator, which means "find me all documents containing
`running OR shoes`.

If we want all documents containing `running AND shoes`, we can use ParadeDB's `&&&` [match conjunction](/documentation/full-text/match#conjunction) operator.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description &&& 'running shoes' AND rating > 2
  ORDER BY rating
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='AND')),
      rating__gt=2
  ).values('description', 'rating', 'category').order_by('rating')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_all(MockItem.description, "running shoes"), MockItem.rating > 2)
      .order_by(MockItem.rating)
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_all("running shoes")
          .where(rating: 3..)
          .select(:description, :rating, :category)
          .order(:rating)
          .limit(5)
  ```
</CodeGroup>

```ini Expected Response theme={null}
     description     | rating | category
---------------------+--------+----------
 Sleek running shoes |      5 | Footwear
(1 row)
```

## BM25 Scoring

Next, let's add [BM25 scoring](/documentation/sorting/score) to the results, which sorts matches by relevance. To do this, we'll use `pdb.score`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, pdb.score(id)
  FROM mock_items
  WHERE description ||| 'running shoes' AND rating > 2
  ORDER BY score DESC
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Score

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='OR')),
      rating__gt=2
  ).annotate(
      score=Score()
  ).values('description', 'score').order_by('-score')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import desc, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(MockItem.description, pdb.score(MockItem.id).label("score"))
      .where(search.match_any(MockItem.description, "running shoes"), MockItem.rating > 2)
      .order_by(desc("score"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running shoes")
          .where(rating: 3..)
          .with_score
          .select(:description)
          .order(search_score: :desc)
          .limit(5)
  ```
</CodeGroup>

```ini Expected Response theme={null}
     description     |   score
---------------------+-----------
 Sleek running shoes |  6.817111
 Generic shoes       | 3.8772602
 White jogging shoes | 3.4849067
(3 rows)
```

## Highlighting

Finally, let's also [highlight](/documentation/full-text/highlight) the relevant portions of the documents that were matched.
To do this, we'll use `pdb.snippet`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, pdb.snippet(description), pdb.score(id)
  FROM mock_items
  WHERE description ||| 'running shoes' AND rating > 2
  ORDER BY score DESC
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Score, Snippet

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='OR')),
      rating__gt=2
  ).annotate(
      snippet=Snippet('description'),
      score=Score()
  ).values('description', 'snippet', 'score').order_by('-score')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import desc, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(
          MockItem.description,
          pdb.snippet(MockItem.description).label("snippet"),
          pdb.score(MockItem.id).label("score"),
      )
      .where(search.match_any(MockItem.description, "running shoes"), MockItem.rating > 2)
      .order_by(desc("score"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running shoes")
          .where(rating: 3..)
          .with_snippet(:description)
          .with_score
          .select(:description)
          .order(search_score: :desc)
          .limit(5)
  ```
</CodeGroup>

```ini Expected Response theme={null}
     description     |              snippet              |   score
---------------------+-----------------------------------+-----------
 Sleek running shoes | Sleek <b>running</b> <b>shoes</b> |  6.817111
 Generic shoes       | Generic <b>shoes</b>              | 3.8772602
 White jogging shoes | White jogging <b>shoes</b>        | 3.4849067
(3 rows)
```

## Top K

ParadeDB is highly optimized for quickly returning the [Top K](/documentation/sorting/topk) results out of the index. In SQL, this means queries that contain an `ORDER BY...LIMIT`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ||| 'running shoes'
  ORDER BY rating
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='OR'))
  ).values('description', 'rating', 'category').order_by('rating')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(MockItem.description, "running shoes"))
      .order_by(MockItem.rating)
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running shoes")
          .select(:description, :rating, :category)
          .order(:rating)
          .limit(5)
  ```
</CodeGroup>

```ini Expected Response theme={null}
     description     | rating | category
---------------------+--------+----------
 White jogging shoes |      3 | Footwear
 Generic shoes       |      4 | Footwear
 Sleek running shoes |      5 | Footwear
(3 rows)
```

## Facets

[Faceted queries](/documentation/aggregates/facets) allow a single query to return both the Top K results and an aggregate value,
which is more CPU-efficient than issuing two separate queries.

For example, the following query returns the top 3 results as well as the total number of results matched.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT
       description, rating, category,
       pdb.agg('{"value_count": {"field": "id"}}') OVER ()
  FROM mock_items
  WHERE description ||| 'running shoes'
  ORDER BY rating
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  (
      MockItem.objects
      .filter(description=ParadeDB(Match('running shoes', operator='OR')))
      .order_by('rating')
      .values('description', 'rating', 'category')[:5]
      .facets(agg='{"value_count": {"field": "id"}}')
  )
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import facets, search

  base = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(MockItem.description, "running shoes"))
      .order_by(MockItem.rating)
      .limit(5)
  )

  stmt = facets.with_rows(base, agg=facets.value_count(field="id"), key_field=MockItem.id)

  with Session(engine) as session:
      rows = session.execute(stmt).all()
      facets.extract(rows)
  ```

  ```ruby Rails theme={null}
  relation = MockItem.search(:description)
                     .matching_any("running shoes")
                     .with_agg(agg: ParadeDB::Aggregations.value_count(:id))
                     .order(:rating)
                     .select(:description, :rating, :category)
                     .limit(5)

  rows = relation.to_a
  facets = relation.aggregates
  ```
</CodeGroup>

```ini Expected Response theme={null}
     description     | rating | category |      agg
---------------------+--------+----------+----------------
 White jogging shoes |      3 | Footwear | {"value": 3.0}
 Generic shoes       |      4 | Footwear | {"value": 3.0}
 Sleek running shoes |      5 | Footwear | {"value": 3.0}
(3 rows)
```

That's it! Next, let's [load your data](/documentation/getting-started/load) to start running real queries.


# Columnar Storage
Source: https://docs.paradedb.com/documentation/indexing/columnar

Column-oriented indexing for fast filtering, sorting, and aggregates

By default, all non-text and non-JSON fields are indexed using ParadeDB's columnar format.
This enables fast [filtering pushdown](/documentation/filtering#filter-pushdown), [Top K ordering](/documentation/sorting/topk), and
[aggregates](/documentation/aggregates/overview) over these fields. For example, in the following index definition, `rating` and `id` are columnar indexed
because they are integers, whereas `description` is not because it is text.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, description, rating)
WITH (key_field = 'id');
```

To enable columnar indexing for text and JSON fields, cast the field to a [tokenizer](/documentation/tokenizers/overview) with `columnar` set to `true`.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.unicode_words('columnar=true')), rating)
WITH (key_field = 'id');
```

<Note>
  The `columnar` option for tokenizers is available in versions `0.22.0` and
  above.
</Note>

Columnar defaults to `false` for all tokenizers besides [literal](/documentation/tokenizers/available-tokenizers/literal) and
[literal normalized](/documentation/tokenizers/available-tokenizers/literal-normalized), which default to
`true` and do not require an explicit setting.

The reason is that tokenized fields can represent large documents and would be expensive to store column-wise,
whereas literal and literal normalized fields are typically single-value and much more compact.

<Note>
  The columnar field stores the raw text value regardless of the tokenizer. For example, if `Hello world` is
  split into tokens `hello` and `world`, the columnar value remains `Hello world`.

  This is important because operations like filtering and sorting require the original field value, not the tokens.
</Note>

<Note>
  Internally, Tantivy refers to columnar fields as fast fields. Our [legacy
  docs](/legacy/indexing/create-index) also refer to these fields as fast.
</Note>


# Create an Index
Source: https://docs.paradedb.com/documentation/indexing/create-index

Index a Postgres table for full text search

Before a table can be searched, it must be indexed. ParadeDB uses a custom index type called the BM25 index.
The following code block creates a BM25 index over several columns in the `mock_items` table.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, description, category)
WITH (key_field='id');
```

By default, text columns are tokenized using the [unicode](/documentation/tokenizers/available-tokenizers/unicode) tokenizer, which splits text according to the
Unicode segmentation standard. Because index creation is a time-consuming operation, we recommend experimenting with the [available tokenizers](/documentation/tokenizers/overview)
to find the most suitable one before running `CREATE INDEX`.

For instance, if a column contains multiple languages, the ICU tokenizer may be more appropriate.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.icu), category)
WITH (key_field='id');
```

Only one BM25 index can exist per table. We recommend indexing all columns in a table that may be present in a search query,
including columns used for sorting, grouping, filtering, and aggregations.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, description, category, rating, in_stock, created_at, metadata, weight_range)
WITH (key_field='id');
```

Most Postgres types, including text, JSON, numeric, timestamp, range, boolean, and arrays, can be indexed.

## Track Create Index Progress

To monitor the progress of a long-running `CREATE INDEX`, open a separate Postgres connection and query `pg_stat_progress_create_index`:

```sql theme={null}
SELECT pid, phase, blocks_done, blocks_total
FROM pg_stat_progress_create_index;
```

Comparing `blocks_done` to `blocks_total` will provide a good approximation of the progress so far. If `blocks_done` equals
`blocks_total`, that means that all rows have been indexed and the index is being flushed to disk.

## Choosing a Key Field

In the `CREATE INDEX` statement above, note the mandatory `key_field` option.
Every BM25 index needs a `key_field`, which is the name of a column that will function as a row’s unique identifier within the index.

The `key_field` must:

1. Have a `UNIQUE` constraint. Usually this means the table's `PRIMARY KEY`.
2. Be the first column in the column list.
3. Be untokenized, if it is a text field.

## Token Filters

After tokens are created, [token filters](/documentation/token-filters/overview) can be configured to apply further processing like lowercasing, stemming, or unaccenting.
For example, the following code block adds English stemming to `description`:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('stemmer=english')), category)
WITH (key_field='id');
```


# Indexing Text Arrays
Source: https://docs.paradedb.com/documentation/indexing/indexing-arrays

Add text arrays to the index

The BM25 index accepts arrays of type `text[]` or `varchar[]`.

```sql theme={null}
CREATE TABLE array_demo (id SERIAL PRIMARY KEY, categories TEXT[]);
INSERT INTO array_demo (categories) VALUES
    ('{"food","groceries and produce"}'),
    ('{"electronics","computers"}'),
    ('{"books","fiction","mystery"}');

CREATE INDEX ON array_demo USING bm25 (id, categories)
WITH (key_field = 'id');
```

Under the hood, each element in the array is indexed as a separate entry. This means that an array is considered a
match if **any** of its entries is a match.

```sql theme={null}
SELECT * FROM array_demo WHERE categories === 'food';
```

```ini Expected Response theme={null}
 id |           categories
----+--------------------------------
  1 | {food,"groceries and produce"}
(1 row)
```

Text arrays can be [tokenized](/documentation/tokenizers/overview) and [filtered](/documentation/token-filters/overview) in the same way as text fields:

```sql theme={null}
CREATE INDEX ON array_demo USING bm25 (id, (categories::pdb.literal))
WITH (key_field = 'id');
```


# Indexing 32+ Columns
Source: https://docs.paradedb.com/documentation/indexing/indexing-composite

Use composite types to index more than 32 columns

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


# Indexing Expressions
Source: https://docs.paradedb.com/documentation/indexing/indexing-expressions

Add Postgres expressions to the index

In addition to indexing columns, Postgres expressions can also be indexed.

## Indexing Text/JSON Expressions

The following statement indexes an expression which concatenates `description` and `category`, which are both text fields:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, ((description || ' ' || category)::pdb.simple('alias=description_concat')))
WITH (key_field='id');
```

To index a text/JSON expression:

1. Add the expression to the column list. In this example, the expression is `description || ' ' || category`.
2. Cast it to a [tokenizer](/documentation/tokenizers/overview), in this example `pdb.simple`.
3. ParadeDB will try and infer a field name based on the field used in the expression. However,
   if the field name cannot be inferred (e.g. because the expression involves more than one field), you will be required
   to add an `alias=<alias_name>` to the tokenizer.

Querying against the expression is the same as querying a regular field:

```sql theme={null}
SELECT description, rating, category
FROM mock_items
WHERE (description || ' ' || category) &&& 'running shoes';
```

<Note>
  The expression on the left-hand side of the operator must exactly match the
  expression that was indexed.
</Note>

## Indexing Non-Text Expressions

To index a non-text expression, cast the expression to `pdb.alias`. For example, the following statement indexes
the expression `rating + 1`, which returns an integer:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, description, ((rating + 1)::pdb.alias('rating')))
WITH (key_field='id');
```

With the expression indexed, queries containing the expression can be pushed down to the ParadeDB index:

```sql theme={null}
SELECT description, rating, category
FROM mock_items
WHERE description &&& 'running shoes'
AND rating + 1 > 3;
```


# Indexing JSON
Source: https://docs.paradedb.com/documentation/indexing/indexing-json

Add JSON and JSONB types to the index

When indexing JSON, ParadeDB automatically indexes all sub-fields of the JSON object. The type of each sub-field is also inferred automatically.
For example, consider the following statement where `metadata` is `JSONB`:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, metadata)
WITH (key_field='id');
```

A single `metadata` JSON may look like:

```json theme={null}
{ "color": "Silver", "location": "United States" }
```

ParadeDB will automatically index both `metadata.color` and `metadata.location` as text.

By default, all text sub-fields of a JSON object use the same tokenizer. The tokenizer can be configured the same way as text fields:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (metadata::pdb.ngram(2,3)))
WITH (key_field='id');
```

Instead of indexing the entire JSON, sub-fields of the JSON can be indexed individually. This allows for configuring separate tokenizers
within a larger JSON:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, ((metadata->>'color')::pdb.ngram(2,3)))
WITH (key_field='id');
```


# Partial Indexes
Source: https://docs.paradedb.com/documentation/indexing/indexing-partial

Add row filters to the BM25 index

A partial index is an index that only includes rows that satisfy a `WHERE` condition.
Instead of indexing every row in a table, Postgres evaluates the predicate and only indexes rows that match it.
This can reduce index size and improve performance when you only query a subset of a table.

The BM25 index supports partial indexes using the same syntax as PostgreSQL.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, description, category)
WITH (key_field='id')
WHERE description IS NOT NULL;
```

An important note: if the BM25 index has a `WHERE` condition, queries **must have the same `WHERE` condition** in order for the index to be used.
A query that does not contain the `WHERE` condition will fall back to a sequential scan, which does not support all of
ParadeDB's query types and has poor performance.

For example, the following query will not use the partial BM25 index defined above because it does not contain the
`description IS NOT NULL` predicate:

```sql theme={null}
SELECT * FROM mock_items
WHERE description ||| 'running shoes';
```

However, this query will use the BM25 index because it contains the predicate:

```sql theme={null}
SELECT * FROM mock_items
WHERE description ||| 'running shoes'
AND description IS NOT NULL;
```

This behavior is consistent with other Postgres indexes and is necessary to ensure that the index returns correct results.


# Reindexing
Source: https://docs.paradedb.com/documentation/indexing/reindexing

Rebuild an existing index with zero downtime

## Changing the Schema

If an index's schema is changed, it must be rebuilt. This includes:

1. Adding a field to the index
2. Removing a field from the index
3. Renaming an indexed column in the underlying table
4. Changing a field's tokenizer

Let's assume the existing index is called `search_idx`, and we want to create a new index called `search_idx_v2`.
First, use `CREATE INDEX CONCURRENTLY` to build a new index in the background.

```sql theme={null}
CREATE INDEX CONCURRENTLY search_idx_v2
ON mock_items USING bm25 (id, description, category)
WITH (key_field = 'id');
```

<Note>
  The `CONCURRENTLY` clause is required. `CONCURRENTLY` allows the existing
  index to continue serving queries while the new index is being built.
</Note>

From another session, you can use `pg_stat_progress_create_index` to [track the progress](/documentation/indexing/create-index#track-create-index-progress) of the new index.

Once the new index is done building, confirm that it is valid:

```sql theme={null}
SELECT ix.indisvalid, ix.indisready, ix.indislive
FROM pg_class i
JOIN pg_index ix ON ix.indexrelid = i.oid
WHERE i.relname = 'search_idx_v2';
```

```csv Expected Response theme={null}
 indisvalid | indisready | indislive
------------+------------+-----------
 t          | t          | t
(1 row)
```

If all three columns are `true`, the original index can safely be dropped, which will redirect queries to the new index.

```sql theme={null}
DROP INDEX search_idx;
```

## Rebuilding the Index

`REINDEX` is used to rebuild an index without changing the schema.
The basic syntax for `REINDEX` is:

```sql theme={null}
REINDEX INDEX search_idx;
```

This operation takes an exclusive lock on the table, which blocks incoming writes (but not reads) while the new index is being built.

To allow for concurrent writes during a reindex, use `REINDEX CONCURRENTLY`:

```sql theme={null}
REINDEX INDEX CONCURRENTLY search_idx;
```

The tradeoff is that `REINDEX CONCURRENTLY` is slower than a plain `REINDEX`. Generally speaking, `REINDEX CONCURRENTLY` is recommended for
production systems that cannot tolerate temporarily blocked writes.

## Important Caveats

Although `CREATE INDEX CONCURRENTLY` and `REINDEX CONURRENTLY` run in the background, Postgres requires that the
session that is executing the command remain open. If the session is closed,
Postgres will cancel the operation. This is relevant if you are using a
connection pooler like `pgbouncer`, which may terminate
sessions after a certain idle timeout is reached.

If `REINDEX CONCURRENTLY` fails or is cancelled, an invalid transient index will be left behind that must be dropped manually.
To check for invalid indexes in `psql`, run `\d <table_name>` and look for `INVALID` indexes.


# Verify Index Integrity
Source: https://docs.paradedb.com/documentation/indexing/verify-index

Check BM25 indexes for corruption and structural issues

ParadeDB provides `amcheck`-style index verification functions to detect corruption and validate the structural integrity of BM25 indexes.
These functions are useful for:

* Proactive corruption detection before issues become critical
* Validating index health after hardware failures or unexpected shutdowns
* Verifying backup integrity
* Debugging index-related issues

## Basic Verification

The `pdb.verify_index` function performs structural integrity checks on a BM25 index:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT * FROM pdb.verify_index('search_idx');
  ```

  ```python Django theme={null}
  from paradedb import paradedb_verify_index

  paradedb_verify_index("search_idx")
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  diagnostics.paradedb_verify_index(engine, "search_idx")
  ```

  ```ruby Rails theme={null}
  ParadeDB.paradedb_verify_index("search_idx")
  ```
</CodeGroup>

This returns a table with three columns:

| Column       | Type    | Description                                   |
| ------------ | ------- | --------------------------------------------- |
| `check_name` | text    | Name of the verification check                |
| `passed`     | boolean | Whether the check passed                      |
| `details`    | text    | Additional information about the check result |

### Example Output

```
               check_name               | passed |                    details
----------------------------------------+--------+-----------------------------------------------
 search_idx: schema_valid               | t      | Index schema loaded successfully
 search_idx: index_readable             | t      | Index reader opened successfully
 search_idx: checksums_valid            | t      | All segment checksums validated successfully
 search_idx: segment_metadata_valid     | t      | 3 segments validated successfully
```

## Heap Reference Validation

To verify that all indexed entries still exist in the heap table, use the `heapallindexed` option:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT * FROM pdb.verify_index('search_idx', heapallindexed := true);
  ```

  ```python Django theme={null}
  from paradedb import paradedb_verify_index

  paradedb_verify_index("search_idx", heapallindexed=True)
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  diagnostics.paradedb_verify_index(
      engine,
      "search_idx",
      heapallindexed=True,
  )
  ```

  ```ruby Rails theme={null}
  ParadeDB.paradedb_verify_index(
    "search_idx",
    heapallindexed: true
  )
  ```
</CodeGroup>

This adds an additional check that validates every indexed `ctid` (tuple identifier) references a valid row in the table.
This is particularly useful for detecting index entries that reference deleted or non-existent rows.

<Warning>
  The `heapallindexed` option can be slow on large indexes as it must verify
  every document. Consider using `sample_rate` for quick spot checks on large
  indexes.
</Warning>

## Options

### Sampling for Large Indexes

For large indexes, you can check a random sample of documents instead of all documents:

<CodeGroup>
  ```sql SQL theme={null}
  -- Check 10% of documents
  SELECT * FROM pdb.verify_index('search_idx',
      heapallindexed := true,
      sample_rate := 0.1
  );
  ```

  ```python Django theme={null}
  from paradedb import paradedb_verify_index

  paradedb_verify_index(
      "search_idx",
      heapallindexed=True,
      sample_rate=0.1,
  )
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  diagnostics.paradedb_verify_index(
      engine,
      "search_idx",
      heapallindexed=True,
      sample_rate=0.1,
  )
  ```

  ```ruby Rails theme={null}
  ParadeDB.paradedb_verify_index(
    "search_idx",
    heapallindexed: true,
    sample_rate: 0.1
  )
  ```
</CodeGroup>

### Progress Reporting

For long-running verifications, enable progress reporting to see status updates:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT * FROM pdb.verify_index('search_idx',
      heapallindexed := true,
      report_progress := true
  );
  ```

  ```python Django theme={null}
  from paradedb import paradedb_verify_index

  paradedb_verify_index(
      "search_idx",
      heapallindexed=True,
      report_progress=True,
  )
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  diagnostics.paradedb_verify_index(
      engine,
      "search_idx",
      heapallindexed=True,
      report_progress=True,
  )
  ```

  ```ruby Rails theme={null}
  ParadeDB.paradedb_verify_index(
    "search_idx",
    heapallindexed: true,
    report_progress: true
  )
  ```
</CodeGroup>

Progress messages are emitted via PostgreSQL's `NOTICE` channel.

### Verbose Mode

For detailed logging including segment-by-segment progress and resume hints, enable verbose mode:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT * FROM pdb.verify_index('search_idx',
      heapallindexed := true,
      report_progress := true,
      verbose := true
  );
  ```

  ```python Django theme={null}
  from paradedb import paradedb_verify_index

  paradedb_verify_index(
      "search_idx",
      heapallindexed=True,
      report_progress=True,
      verbose=True,
  )
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  diagnostics.paradedb_verify_index(
      engine,
      "search_idx",
      heapallindexed=True,
      report_progress=True,
      verbose=True,
  )
  ```

  ```ruby Rails theme={null}
  ParadeDB.paradedb_verify_index(
    "search_idx",
    heapallindexed: true,
    report_progress: true,
    verbose: true
  )
  ```
</CodeGroup>

### Stop on First Error

To stop verification immediately when the first error is found (similar to `pg_amcheck --on-error-stop`):

<CodeGroup>
  ```sql SQL theme={null}
  SELECT * FROM pdb.verify_index('search_idx', on_error_stop := true);
  ```

  ```python Django theme={null}
  from paradedb import paradedb_verify_index

  paradedb_verify_index("search_idx", on_error_stop=True)
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  diagnostics.paradedb_verify_index(
      engine,
      "search_idx",
      on_error_stop=True,
  )
  ```

  ```ruby Rails theme={null}
  ParadeDB.paradedb_verify_index(
    "search_idx",
    on_error_stop: true
  )
  ```
</CodeGroup>

## Parallel Verification

A single `verify_index` call processes segments sequentially within one PostgreSQL backend.
For very large indexes, you can distribute verification across multiple database connections
by specifying which segments each connection should check using the `segment_ids` parameter.
This allows you to utilize multiple CPU cores by running verification in parallel processes.

### Listing Segments

First, list all segments in the index:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT * FROM pdb.index_segments('search_idx');
  ```

  ```python Django theme={null}
  from paradedb import paradedb_index_segments

  paradedb_index_segments("search_idx")
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  diagnostics.paradedb_index_segments(engine, "search_idx")
  ```

  ```ruby Rails theme={null}
  ParadeDB.paradedb_index_segments("search_idx")
  ```
</CodeGroup>

```
 partition_name | segment_idx | segment_id | num_docs | num_deleted | max_doc
----------------+-------------+------------+----------+-------------+---------
 search_idx     |           0 | b7e661af   |    10000 |           0 |   10000
 search_idx     |           1 | b4fc1b40   |    10000 |           0 |   10000
 search_idx     |           2 | 9894b412   |    10000 |           0 |   10000
 search_idx     |           3 | 4d0168d6   |     5000 |           0 |    5000
```

### Verifying Specific Segments

Then verify specific segments using the `segment_ids` parameter:

<CodeGroup>
  ```sql SQL theme={null}
  -- Worker 1: Verify even segments
  SELECT * FROM pdb.verify_index('search_idx',
      heapallindexed := true,
      segment_ids := ARRAY[0, 2]
  );

  -- Worker 2: Verify odd segments
  SELECT * FROM pdb.verify_index('search_idx',
      heapallindexed := true,
      segment_ids := ARRAY[1, 3]
  );

  ```

  ```python Django theme={null}
  from paradedb import paradedb_verify_index

  # Worker 1: Verify even segments
  paradedb_verify_index(
      "search_idx",
      heapallindexed=True,
      segment_ids=[0, 2],
  )

  # Worker 2: Verify odd segments
  paradedb_verify_index(
      "search_idx",
      heapallindexed=True,
      segment_ids=[1, 3],
  )
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  # Worker 1: Verify even segments
  diagnostics.paradedb_verify_index(
      engine,
      "search_idx",
      heapallindexed=True,
      segment_ids=[0, 2],
  )

  # Worker 2: Verify odd segments
  diagnostics.paradedb_verify_index(
      engine,
      "search_idx",
      heapallindexed=True,
      segment_ids=[1, 3],
  )
  ```

  ```ruby Rails theme={null}
  # Worker 1: Verify even segments
  ParadeDB.paradedb_verify_index(
    "search_idx",
    heapallindexed: true,
    segment_ids: [0, 2]
  )

  # Worker 2: Verify odd segments
  ParadeDB.paradedb_verify_index(
    "search_idx",
    heapallindexed: true,
    segment_ids: [1, 3]
  )
  ```
</CodeGroup>

### Automation Example

Distribute verification across N workers:

<CodeGroup>
  ```sql SQL theme={null}
  -- Get segments for worker 0 (of 4 workers)
  SELECT array_agg(segment_idx) AS segments
  FROM pdb.index_segments('search_idx')
  WHERE segment_idx % 4 = 0;

  -- Run verification with those segments
  SELECT * FROM pdb.verify_index('search_idx',
      heapallindexed := true,
      segment_ids := (
          SELECT array_agg(segment_idx)
          FROM pdb.index_segments('search_idx')
          WHERE segment_idx % 4 = 0
      )
  );

  ```

  ```python Django theme={null}
  from paradedb import paradedb_index_segments, paradedb_verify_index

  paradedb_verify_index(
      "search_idx",
      heapallindexed=True,
      segment_ids=[
          row["segment_idx"]
          for row in paradedb_index_segments("search_idx")
          if row["segment_idx"] % 4 == 0
      ],
  )
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  diagnostics.paradedb_verify_index(
      engine,
      "search_idx",
      heapallindexed=True,
      segment_ids=[
          row["segment_idx"]
          for row in diagnostics.paradedb_index_segments(engine, "search_idx")
          if row["segment_idx"] % 4 == 0
      ],
  )
  ```

  ```ruby Rails theme={null}
  ParadeDB.paradedb_verify_index(
    "search_idx",
    heapallindexed: true,
    segment_ids: ParadeDB.paradedb_index_segments("search_idx").filter_map { |row|
      row["segment_idx"] if row["segment_idx"] % 4 == 0
    })
  ```
</CodeGroup>

## Verifying All BM25 Indexes

To verify all BM25 indexes in the database at once:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT * FROM pdb.verify_all_indexes();
  ```

  ```python Django theme={null}
  from paradedb import paradedb_verify_all_indexes

  paradedb_verify_all_indexes()
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  diagnostics.paradedb_verify_all_indexes(engine)
  ```

  ```ruby Rails theme={null}
  ParadeDB.paradedb_verify_all_indexes()
  ```
</CodeGroup>

### Filtering by Pattern

Filter indexes by schema or name pattern (using SQL `LIKE` syntax):

<CodeGroup>
  ```sql SQL theme={null}
  -- Verify indexes in the 'public' schema only
  SELECT * FROM pdb.verify_all_indexes(schema_pattern := 'public');

  -- Verify indexes matching a name pattern
  SELECT * FROM pdb.verify_all_indexes(index_pattern := 'search_%');

  -- Combine filters
  SELECT * FROM pdb.verify_all_indexes(
      schema_pattern := 'app_%',
      index_pattern := '%_idx',
      heapallindexed := true
  );
  ```

  ```python Django theme={null}
  from paradedb import paradedb_verify_all_indexes

  # Verify indexes in the 'public' schema only
  paradedb_verify_all_indexes(schema_pattern="public")

  # Verify indexes matching a name pattern
  paradedb_verify_all_indexes(index_pattern="search_%")

  # Combine filters
  paradedb_verify_all_indexes(
      schema_pattern="app_%",
      index_pattern="%_idx",
      heapallindexed=True,
  )
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  # Verify indexes in the 'public' schema only
  diagnostics.paradedb_verify_all_indexes(
      engine,
      schema_pattern="public",
  )

  # Verify indexes matching a name pattern
  diagnostics.paradedb_verify_all_indexes(
      engine,
      index_pattern="search_%",
  )

  # Combine filters
  diagnostics.paradedb_verify_all_indexes(
      engine,
      schema_pattern="app_%",
      index_pattern="%_idx",
      heapallindexed=True,
  )
  ```

  ```ruby Rails theme={null}
  # Verify indexes in the 'public' schema only
  ParadeDB.paradedb_verify_all_indexes(schema_pattern: "public")

  # Verify indexes matching a name pattern
  ParadeDB.paradedb_verify_all_indexes(index_pattern: "search_%")

  # Combine filters
  ParadeDB.paradedb_verify_all_indexes(
    schema_pattern: "app_%",
    index_pattern: "%_idx",
    heapallindexed: true
  )
  ```
</CodeGroup>

## Listing All BM25 Indexes

To see all BM25 indexes in the database with summary statistics:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT * FROM pdb.indexes();
  ```

  ```python Django theme={null}
  from paradedb import paradedb_indexes

  paradedb_indexes()
  ```

  ```python SQLAlchemy theme={null}
  from paradedb.sqlalchemy import diagnostics

  diagnostics.paradedb_indexes(engine)
  ```

  ```ruby Rails theme={null}
  ParadeDB.paradedb_indexes()
  ```
</CodeGroup>

```
 schemaname |  tablename  |   indexname   | indexrelid | num_segments | total_docs
------------+-------------+---------------+------------+--------------+------------
 public     | products    | products_idx  |      16421 |            3 |      50000
 public     | documents   | documents_idx |      16435 |            5 |     125000
 app        | articles    | articles_idx  |      16448 |            2 |      10000
```

## Function Reference

### `pdb.verify_index`

Verifies a single BM25 index.

| Parameter         | Type     | Default    | Description                                                |
| ----------------- | -------- | ---------- | ---------------------------------------------------------- |
| `index`           | regclass | (required) | The index to verify                                        |
| `heapallindexed`  | boolean  | `false`    | Check that all indexed ctids exist in the heap             |
| `sample_rate`     | float    | `NULL`     | Fraction of documents to check (0.0-1.0). NULL = check all |
| `report_progress` | boolean  | `false`    | Emit progress messages                                     |
| `verbose`         | boolean  | `false`    | Emit detailed segment-level progress and resume hints      |
| `on_error_stop`   | boolean  | `false`    | Stop on first error found                                  |
| `segment_ids`     | int\[]   | `NULL`     | Specific segment indices to check. NULL = all segments     |

### `pdb.verify_all_indexes`

Verifies all BM25 indexes in the database.

| Parameter         | Type    | Default | Description                                                |
| ----------------- | ------- | ------- | ---------------------------------------------------------- |
| `schema_pattern`  | text    | `NULL`  | Filter by schema name (SQL LIKE pattern). NULL = all       |
| `index_pattern`   | text    | `NULL`  | Filter by index name (SQL LIKE pattern). NULL = all        |
| `heapallindexed`  | boolean | `false` | Check that all indexed ctids exist in the heap             |
| `sample_rate`     | float   | `NULL`  | Fraction of documents to check (0.0-1.0). NULL = check all |
| `report_progress` | boolean | `false` | Emit progress messages                                     |
| `on_error_stop`   | boolean | `false` | Stop on first error found                                  |

### `pdb.index_segments`

Lists all segments in a BM25 index.

| Parameter | Type     | Default    | Description          |
| --------- | -------- | ---------- | -------------------- |
| `index`   | regclass | (required) | The index to inspect |

Returns:

| Column           | Type   | Description                                      |
| ---------------- | ------ | ------------------------------------------------ |
| `partition_name` | text   | Name of the index partition                      |
| `segment_idx`    | int    | Segment index (use with `segment_ids` parameter) |
| `segment_id`     | text   | Tantivy segment UUID                             |
| `num_docs`       | bigint | Number of live documents                         |
| `num_deleted`    | bigint | Number of deleted documents                      |
| `max_doc`        | bigint | Maximum document ID                              |

### `pdb.indexes`

Lists all BM25 indexes in the database.

Returns:

| Column         | Type   | Description                         |
| -------------- | ------ | ----------------------------------- |
| `schemaname`   | text   | Schema containing the index         |
| `tablename`    | text   | Table the index is on               |
| `indexname`    | text   | Name of the index                   |
| `indexrelid`   | oid    | OID of the index                    |
| `num_segments` | int    | Number of Tantivy segments          |
| `total_docs`   | bigint | Total documents across all segments |


# Joins Overview
Source: https://docs.paradedb.com/documentation/joins/overview

Optimize JOIN queries in ParadeDB

ParadeDB supports all standard PostgreSQL `JOIN` types, including:

* `INNER JOIN`
* `LEFT JOIN`
* `RIGHT JOIN`
* `FULL JOIN`
* `SEMI JOIN`
* `ANTI JOIN`

In most cases, join queries run using PostgreSQL’s native execution exactly as they would in a vanilla Postgres database.
However, ParadeDB also includes a beta optimization called **join pushdown** that can significantly accelerate `INNER`, `SEMI`, and `ANTI`
joins when they involve ParadeDB search queries.

## Join Pushdown (Beta)

<Note>
  Join pushdown is in beta and is available on versions `0.22.0` and up.
</Note>

Join pushdown is an optimization that allows ParadeDB to execute parts of a `JOIN` directly inside
the ParadeDB executor instead of in Postgres' row-based executor.

This can dramatically reduce latency for certain queries because ParadeDB tries to answer as much
of the query as possible using the index before touching the underlying table.

To enable join pushdown, first enable the feature:

```sql theme={null}
SET paradedb.enable_join_custom_scan TO on;
```

## Requirements for Join Pushdown

Join pushdown is automatically used when a query meets several conditions. If any of these are not satisfied, PostgreSQL will simply execute the join normally.

| Requirement         | Description                                                                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Supported join type | The query must use an `INNER`, `SEMI`, or `ANTI` join. Pushdown for other join types is coming soon.                                                         |
| BM25 indexes        | All tables participating in the join must have a ParadeDB BM25 index.                                                                                        |
| Search predicate    | The query must contain a ParadeDB operator such as `&&&`, `===`, etc.                                                                                        |
| Equi-join key       | The join must contain at least one equality condition such as `a.id = b.id`.                                                                                 |
| Indexed fields      | All join keys, filters, and `ORDER BY` columns must be present in the BM25 index. Text and JSON fields must be [columnar](/documentation/indexing/columnar). |
| LIMIT clause        | The query must include a `LIMIT`.                                                                                                                            |
| No aggregates       | Queries containing aggregates (`GROUP BY`, `COUNT`, etc.) are not currently supported.                                                                       |

If any checks fail, ParadeDB will emit a `NOTICE` explaining why and fall back to Postgres' native join execution.

To demonstrate, let's create a second table called `orders` that can be joined with `mock_items`:

```sql theme={null}
CALL paradedb.create_bm25_test_table(
  schema_name => 'public',
  table_name => 'orders',
  table_type => 'Orders'
);

ALTER TABLE orders
ADD CONSTRAINT foreign_key_product_id
FOREIGN KEY (product_id)
REFERENCES mock_items(id);

CREATE INDEX orders_idx ON orders
USING bm25 (order_id, product_id, order_quantity, order_total, customer_name)
WITH (key_field = 'order_id');
```

```sql theme={null}
SELECT * FROM orders ORDER BY order_id LIMIT 3;
```

```csv Expected Response theme={null}
 order_id | product_id | order_quantity | order_total | customer_name
----------+------------+----------------+-------------+---------------
        1 |          1 |              3 |       99.99 | John Doe
        2 |          2 |              1 |       49.99 | Jane Smith
        3 |          3 |              5 |      249.95 | Alice Johnson
(3 rows)
```

## Inner Join

An inner join returns rows where a matching row exists in both tables according to the join condition.

```sql theme={null}
SELECT o.order_id, o.customer_name, o.order_total, m.description
FROM orders o
INNER JOIN mock_items m
  ON o.product_id = m.id
WHERE m.description ||| 'keyboard'
AND o.customer_name ||| 'John'
ORDER BY o.order_total DESC
LIMIT 5;
```

```csv Expected Response theme={null}
 order_id | customer_name | order_total |       description
----------+---------------+-------------+--------------------------
        4 | John Doe      |      501.87 | Plastic Keyboard
        1 | John Doe      |       99.99 | Ergonomic metal keyboard
(2 rows)
```

To verify join pushdown, run `EXPLAIN` on the query and look for a `ParadeDB Join Scan` in the output.

```csv Expected Response theme={null}
                                                                                                                         QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=10.00..11.00 rows=5 width=55)
   ->  Custom Scan (ParadeDB Join Scan)  (cost=10.00..11.00 rows=5 width=55)
         Relation Tree: m INNER o
         Join Cond: o.product_id = m.id
         Limit: 5
         Order By: o.order_total desc
         DataFusion Physical Plan:
           : ProjectionExec: expr=[NULL as col_1, NULL as col_2, order_total@2 as col_3, NULL as col_4, ctid_0@0 as ctid_0, ctid_1@1 as ctid_1]
           :   SortExec: TopK(fetch=5), expr=[order_total@2 DESC], preserve_partitioning=[false]
           :     HashJoinExec: mode=CollectLeft, join_type=Inner, on=[(id@1, product_id@1)], projection=[ctid_0@0, ctid_1@2, order_total@4]
           :       ProjectionExec: expr=[ctid@0 as ctid_0, id@1 as id]
           :         CooperativeExec
           :           PgSearchScan: segments=1, query={"with_index":{"query":{"match":{"field":"description","value":"keyboard","tokenizer":null,"distance":null,"transposition_cost_one":null,"prefix":null,"conjunction_mode":false}}}}
           :       ProjectionExec: expr=[ctid@0 as ctid_1, product_id@1 as product_id, order_total@2 as order_total]
           :         CooperativeExec
           :           PgSearchScan: segments=1, dynamic_filters=2, query={"with_index":{"query":{"match":{"field":"customer_name","value":"John","tokenizer":null,"distance":null,"transposition_cost_one":null,"prefix":null,"conjunction_mode":false}}}}
(16 rows)
```

## Semi Join

A semi join returns rows from the left table when a matching row exists in the right table.
In SQL, this usually appears as an `IN` or `EXISTS` query:

```sql theme={null}
SELECT o.order_id, o.order_total FROM orders o
WHERE o.product_id IN (
  SELECT m.id
  FROM mock_items m
  WHERE m.description ||| 'keyboard'
)
ORDER BY o.order_total DESC
LIMIT 5;
```

```csv Expected Response theme={null}
 order_id | order_total
----------+-------------
       27 |      676.15
       57 |      676.15
       11 |      633.94
       41 |      633.94
        4 |      501.87
(5 rows)
```

To verify join pushdown, run `EXPLAIN` on the query and look for a `ParadeDB Join Scan` in the output.

```csv Expected Response theme={null}
                                                                                                                QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=10.00..11.00 rows=5 width=11)
   ->  Custom Scan (ParadeDB Join Scan)  (cost=10.00..11.00 rows=5 width=11)
         Relation Tree: m INNER o
         Join Cond: o.product_id = m.id
         Limit: 5
         Order By: o.order_total desc
         DataFusion Physical Plan:
           : ProjectionExec: expr=[NULL as col_1, order_total@2 as col_2, ctid_0@0 as ctid_0, ctid_1@1 as ctid_1]
           :   SortExec: TopK(fetch=5), expr=[order_total@2 DESC], preserve_partitioning=[false]
           :     HashJoinExec: mode=CollectLeft, join_type=Inner, on=[(id@1, product_id@1)], projection=[ctid_0@0, ctid_1@2, order_total@4]
           :       ProjectionExec: expr=[ctid@0 as ctid_0, id@1 as id]
           :         CooperativeExec
           :           PgSearchScan: segments=1, query={"with_index":{"query":{"match":{"field":"description","value":"keyboard","tokenizer":null,"distance":null,"transposition_cost_one":null,"prefix":null,"conjunction_mode":false}}}}
           :       ProjectionExec: expr=[ctid@0 as ctid_1, product_id@1 as product_id, order_total@2 as order_total]
           :         CooperativeExec
           :           PgSearchScan: segments=1, dynamic_filters=2, query="all"
(16 rows)
```

## Anti Join

An anti join returns rows from the left table when no matching row exists in the right table. This typically appears as NOT EXISTS or NOT IN.

```sql theme={null}
SELECT o.order_id, o.order_total FROM orders o
WHERE NOT EXISTS (
  SELECT 1
  FROM mock_items m
  WHERE m.id = o.product_id
    AND m.description ||| 'keyboard'
)
ORDER BY o.order_total DESC
LIMIT 5;
```

```csv Expected Response theme={null}
 order_id | order_total
----------+-------------
       10 |      638.73
       40 |      638.73
       21 |      632.08
       51 |      632.08
       22 |      605.18
(5 rows)
```

To verify join pushdown, run `EXPLAIN` on the query and look for a `ParadeDB Join Scan` in the output.

```csv Expected Response theme={null}
                                                                                                               QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=10.00..11.00 rows=5 width=11)
   ->  Custom Scan (ParadeDB Join Scan)  (cost=10.00..11.00 rows=5 width=11)
         Relation Tree: o ANTI m
         Join Cond: m.id = o.product_id
         Limit: 5
         Order By: o.order_total desc
         DataFusion Physical Plan:
           : ProjectionExec: expr=[NULL as col_1, order_total@1 as col_2, ctid_0@0 as ctid_0]
           :   SortExec: TopK(fetch=5), expr=[order_total@1 DESC], preserve_partitioning=[false]
           :     HashJoinExec: mode=CollectLeft, join_type=RightAnti, on=[(id@0, product_id@1)], projection=[ctid_0@0, order_total@2]
           :       CooperativeExec
           :         PgSearchScan: segments=1, query={"with_index":{"query":{"match":{"field":"description","value":"keyboard","tokenizer":null,"distance":null,"transposition_cost_one":null,"prefix":null,"conjunction_mode":false}}}}
           :       ProjectionExec: expr=[ctid@0 as ctid_0, product_id@1 as product_id, order_total@2 as order_total]
           :         CooperativeExec
           :           PgSearchScan: segments=1, dynamic_filters=1, query="all"
(15 rows)
```

## Future Work

We are actively improving join pushdown, specifically when it comes to pushing down more shapes of joins.
If your join query is not currently supported by join pushdown (or isn't as fast as you'd like!), we invite you to [open a Github issue](https://github.com/paradedb/paradedb/issues).


# Migrating from Elasticsearch
Source: https://docs.paradedb.com/documentation/migration/elasticsearch-feature-comparison

Feature comparison and migration guide for Elasticsearch users moving to ParadeDB

This page is for developers who are evaluating or actively migrating from Elasticsearch (or OpenSearch) to ParadeDB.
ParadeDB delivers Elastic-quality full-text search as a Postgres extension, so your data, queries, and infrastructure
all live inside Postgres — no ETL pipelines, no separate cluster to manage.

## Key Differences

|                     | Elasticsearch                                | ParadeDB                                       |
| ------------------- | -------------------------------------------- | ---------------------------------------------- |
| **Query language**  | JSON DSL                                     | Standard SQL with search operators             |
| **Data model**      | Denormalized documents                       | Normalized relational tables with JOINs        |
| **Transactions**    | Per-document atomicity, eventual consistency | Full ACID transactions                         |
| **Index storage**   | Separate cluster                             | Inside Postgres (same database)                |
| **Schema changes**  | Dynamic mapping or reindex                   | Defined at index creation; `REINDEX` to change |
| **Updates/deletes** | Expensive (reindex internally)               | Native Postgres operations                     |

## Migration Tips

* **Start with your most common queries.** Map your highest-traffic Elasticsearch queries using the
  [full-text search reference](/documentation/full-text/overview).
* **Use SQL JOINs instead of denormalization.** Elasticsearch requires denormalized documents, but ParadeDB supports
  full SQL JOINs. You can normalize your schema and simplify your data model.
* **Continue to use Postgres tooling.** Backups, replication, monitoring, and CI/CD integrate with standard Postgres tools
  you already use.

## Feature Comparison

## Query Capabilities

| Feature                     | Elasticsearch | ParadeDB | Notes                                                                                                                                                                      |
| --------------------------- | :-----------: | :------: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Full-text search (BM25)     |       ✅       |     ✅    | [Match and phrase operators](/documentation/full-text/overview)                                                                                                            |
| Fuzzy matching              |       ✅       |     ✅    | Max edit distance of 2 via [`pdb.fuzzy()`](/documentation/full-text/fuzzy)                                                                                                 |
| Phrase matching             |       ✅       |     ✅    | [`###` operator](/documentation/full-text/phrase)                                                                                                                          |
| Phrase prefix               |       ✅       |     ✅    | [`pdb.phrase_prefix()`](/documentation/query-builder/phrase/phrase-prefix)                                                                                                 |
| Regular expressions         |       ✅       |     ✅    | [`pdb.regex()`](/documentation/query-builder/term/regex)                                                                                                                   |
| Wildcard queries            |       ✅       |     ✅    | Via [regex](/documentation/query-builder/term/regex)                                                                                                                       |
| Boolean queries             |       ✅       |     ✅    | Via SQL `AND`/`OR`/`NOT` or [`paradedb.boolean`](/documentation/query-builder/overview)                                                                                    |
| Proximity search            |       ✅       |     ✅    | [`##` operator](/documentation/full-text/proximity)                                                                                                                        |
| More Like This              |       ✅       |     ✅    | [`paradedb.more_like_this`](/documentation/query-builder/specialized/more-like-this)                                                                                       |
| Nested queries              |       ✅       |     ✅    | Via SQL [`JOIN`s](/documentation/joins/overview)                                                                                                                           |
| Parent-child queries        |       ✅       |     ✅    | Via SQL [`JOIN`s](/documentation/joins/overview)                                                                                                                           |
| Geo queries                 |       ✅       |     ❌    | Use [PostGIS](https://postgis.net/)                                                                                                                                        |
| Percolator (reverse search) |       ✅       |     ❌    |                                                                                                                                                                            |
| Script-based scoring        |       ✅       |     ❌    |                                                                                                                                                                            |
| Suggesters (autocomplete)   |       ✅       |     ✅    | Via [search\_tokenizer](/documentation/tokenizers/search-tokenizer) (index with ngram, search with unicode) or [fuzzy prefix](/documentation/full-text/fuzzy#fuzzy-prefix) |

## Text Analysis

| Feature                        | Elasticsearch | ParadeDB | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ------------------------------ | :-----------: | :------: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Custom tokenizers              |       ✅       |     ✅    | 12+ built-in [tokenizers](/documentation/tokenizers/overview)                                                                                                                                                                                                                                                                                                                                                                                      |
| Token filters                  |       ✅       |     ✅    | 7 [filters](/documentation/token-filters/overview): [lowercase](/documentation/token-filters/lowercase), [stemmer](/documentation/token-filters/stemming), [stopwords](/documentation/token-filters/stopwords), [ascii\_folding](/documentation/token-filters/ascii-folding), [alpha\_num\_only](/documentation/token-filters/alphanumeric), [trim](/documentation/token-filters/trim), [token\_length](/documentation/token-filters/token-length) |
| Character filters              |       ✅       |     ❌    |                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| Synonyms                       |       ✅       |    ⚠️    | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Different search-time analyzer |       ✅       |     ✅    | Via [search\_tokenizer](/documentation/tokenizers/search-tokenizer) or [multiple tokenizers per field](/documentation/tokenizers/multiple-per-field)                                                                                                                                                                                                                                                                                               |
| Multi-language support         |       ✅       |     ✅    | Chinese ([Jieba](/documentation/tokenizers/available-tokenizers/jieba)), Japanese/Korean ([Lindera](/documentation/tokenizers/available-tokenizers/lindera)), [ICU](/documentation/tokenizers/available-tokenizers/icu)                                                                                                                                                                                                                            |
| Stemming                       |       ✅       |     ✅    | [19 languages](/documentation/token-filters/stemming)                                                                                                                                                                                                                                                                                                                                                                                              |
| Stopwords                      |       ✅       |     ✅    | [29 languages](/documentation/token-filters/stopwords)                                                                                                                                                                                                                                                                                                                                                                                             |
| N-gram tokenization            |       ✅       |     ✅    | [Configurable](/documentation/tokenizers/available-tokenizers/ngrams) min/max gram size                                                                                                                                                                                                                                                                                                                                                            |

## Aggregations

| Feature                   | Elasticsearch | ParadeDB | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ------------------------- | :-----------: | :------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Bucket aggregations       |       ✅       |     ✅    | [terms](/documentation/aggregates/bucket/terms), [histogram](/documentation/aggregates/bucket/histogram), [date\_histogram](/documentation/aggregates/bucket/datehistogram), [range](/documentation/aggregates/bucket/range), [filters](/documentation/aggregates/bucket/filters)                                                                                                                                                           |
| Metric aggregations       |       ✅       |     ✅    | [avg](/documentation/aggregates/metrics/average), [sum](/documentation/aggregates/metrics/sum), [min/max](/documentation/aggregates/metrics/minmax), [count](/documentation/aggregates/metrics/count), [stats](/documentation/aggregates/metrics/stats), [percentiles](/documentation/aggregates/metrics/percentiles), [cardinality](/documentation/aggregates/metrics/cardinality), [top\_hits](/documentation/aggregates/metrics/tophits) |
| Pipeline aggregations     |       ✅       |     ✅    | Use SQL window functions (`SUM() OVER()`, `LAG()`, etc.)                                                                                                                                                                                                                                                                                                                                                                                    |
| Nested aggregations       |       ✅       |     ✅    | Use `pdb.agg()` with SQL `GROUP BY`                                                                                                                                                                                                                                                                                                                                                                                                         |
| ES-compatible JSON syntax |       —       |     ✅    | [`pdb.agg()`](/documentation/aggregates/overview) accepts ES JSON directly                                                                                                                                                                                                                                                                                                                                                                  |
| SQL GROUP BY              |    Limited    |     ✅    | Full SQL aggregation support                                                                                                                                                                                                                                                                                                                                                                                                                |

<Note>
  Since `pdb.agg()` accepts Elasticsearch-compatible JSON, many of your existing
  aggregation queries can be migrated with minimal changes. See the [aggregates
  documentation](/documentation/aggregates/overview).
</Note>

## Scoring and Relevance

| Feature            | Elasticsearch | ParadeDB | Notes                                                                                                                      |
| ------------------ | :-----------: | :------: | -------------------------------------------------------------------------------------------------------------------------- |
| BM25 scoring       |       ✅       |     ✅    | [`pdb.score()`](/documentation/sorting/score)                                                                              |
| Custom boost       |       ✅       |     ✅    | [`pdb.boost()`](/documentation/sorting/boost) type cast                                                                    |
| Constant score     |       ✅       |     ✅    | [`pdb.const()`](/documentation/sorting/boost#constant-scoring)                                                             |
| Disjunction max    |       ✅       |     ✅    | `paradedb.disjunction_max()`                                                                                               |
| Function score     |       ✅       |     ❌    | Use [boost](/documentation/sorting/boost) / [const](/documentation/sorting/boost#constant-scoring) as partial alternatives |
| Script scoring     |       ✅       |     ❌    |                                                                                                                            |
| Decay functions    |       ✅       |     ❌    |                                                                                                                            |
| Field value factor |       ✅       |     ❌    |                                                                                                                            |

## Highlighting

| Feature              | Elasticsearch | ParadeDB | Notes                                                                        |
| -------------------- | :-----------: | :------: | ---------------------------------------------------------------------------- |
| Snippet highlighting |       ✅       |     ✅    | [`pdb.snippet()`](/documentation/full-text/highlight)                        |
| Multiple snippets    |       ✅       |     ✅    | [`pdb.snippets()`](/documentation/full-text/highlight#multiple-snippets)     |
| Custom tags          |       ✅       |     ✅    | `start_tag`, `end_tag` parameters                                            |
| Byte offsets         |       ❌       |     ✅    | [`pdb.snippet_positions()`](/documentation/full-text/highlight#byte-offsets) |
| Fuzzy highlighting   |       ✅       |     ❌    |                                                                              |

## Index Management

| Feature           | Elasticsearch | ParadeDB | Notes                                                                               |
| ----------------- | :-----------: | :------: | ----------------------------------------------------------------------------------- |
| Create index      |       ✅       |     ✅    | [`CREATE INDEX ... USING bm25`](/documentation/indexing/create-index)               |
| Drop index        |       ✅       |     ✅    | `DROP INDEX`                                                                        |
| Reindex           |       ✅       |     ✅    | [`REINDEX`](/documentation/indexing/reindexing)                                     |
| Index aliases     |       ✅       |     ✅    | Via Postgres views                                                                  |
| Index templates   |       ✅       |     ❌    |                                                                                     |
| Dynamic mapping   |       ✅       |     ❌    | Schema defined at index creation; requires `REINDEX` to change                      |
| Multi-field index |       ✅       |     ✅    | All columns included in [one index per table](/documentation/indexing/create-index) |

## Data Operations

| Feature            | Elasticsearch | ParadeDB | Notes                                                                                 |
| ------------------ | :-----------: | :------: | ------------------------------------------------------------------------------------- |
| ACID transactions  |       ❌       |     ✅    | Full Postgres ACID compliance                                                         |
| Real-time indexing |       ⚠️      |     ✅    | ES is near-real-time (requires refresh); ParadeDB provides immediate read-after-write |
| JOINs              |       ❌       |     ✅    | Full SQL [JOIN](/documentation/joins/overview) support                                |
| UPDATE / DELETE    |       ⚠️      |     ✅    | ES internally reindexes; Postgres handles natively                                    |
| Bulk insert        |       ✅       |     ✅    | [`COPY` or batch `INSERT`](/documentation/performance-tuning/writes)                  |
| SQL queries        |       ❌       |     ✅    | Full SQL including subqueries, CTEs, window functions                                 |

## Deployment and Operations

| Feature                    | Elasticsearch | ParadeDB | Notes                                                                      |
| -------------------------- | :-----------: | :------: | -------------------------------------------------------------------------- |
| Horizontal sharding        |       ✅       |    ⚠️    | Via [Citus](/deploy/citus) for distributed workloads                       |
| Read replicas              |       ✅       |     ✅    | Postgres streaming replication                                             |
| Kubernetes                 |       ✅       |     ✅    | [CNPG / Helm charts](/deploy/self-hosted/kubernetes)                       |
| Docker                     |       ✅       |     ✅    | [Official Docker image](/documentation/getting-started/install)            |
| Logical replication ingest |       ❌       |     ✅    | [Sync from existing Postgres](/deploy/logical-replication/getting-started) |
| Cross-cluster search       |       ✅       |     ❌    |                                                                            |
| Snapshot / restore         |       ✅       |     ✅    | Via Postgres backup tools (pg\_dump, WAL archiving)                        |
| Monitoring                 |       ✅       |     ✅    | pg\_stat, pganalyze, standard Postgres tools                               |

## Pagination

| Feature            | Elasticsearch | ParadeDB | Notes                                                            |
| ------------------ | :-----------: | :------: | ---------------------------------------------------------------- |
| `from` / `size`    |       ✅       |     ✅    | SQL `LIMIT` / `OFFSET`                                           |
| `scroll` API       |       ✅       |     ❌    | Use SQL cursors (`DECLARE` / `FETCH`) instead                    |
| `search_after`     |       ✅       |     ❌    | Use keyset pagination (`WHERE id > last_id ORDER BY id`) instead |
| Top K optimization |       ✅       |     ✅    | [`paradedb.limit_fetch_multiplier`](/documentation/sorting/topk) |


# Index Creation
Source: https://docs.paradedb.com/documentation/performance-tuning/create-index

Settings to make index creation faster

These actions can improve the performance and memory consumption of `CREATE INDEX` and `REINDEX` statements.

### Raise Parallel Indexing Workers

ParadeDB uses Postgres' `max_parallel_maintenance_workers` setting to determine the degree of parallelism during `CREATE INDEX`/`REINDEX`. Postgres' default is `2`, which may be too low for large tables.

```sql theme={null}
SET max_parallel_maintenance_workers = 8;
```

In order for `max_parallel_maintenance_workers` to take effect, it must be less than or equal to both `max_parallel_workers` and `max_worker_processes`.

### Configure Indexing Memory

The default Postgres `maintenance_work_mem` value of `64MB` is quite conservative and can slow down parallel index builds. We recommend at least `64MB` per
[parallel indexing worker](#raise-parallel-indexing-workers).

```sql theme={null}
SET maintenance_work_mem = '2GB';
```

<Note>
  Each worker is required to have at least `15MB` memory. If
  `maintenance_work_mem` is set too low, an error will be returned.
</Note>

### Defer Index Creation

If possible, creating the BM25 index should be deferred until **after** a table has been populated. To illustrate:

```sql theme={null}
-- This is preferred
CREATE TABLE test (id SERIAL, data text);
INSERT INTO test (data) VALUES ('hello world'), ('many more values');
CREATE INDEX ON test USING bm25 (id, data) WITH (key_field = 'id');

-- ...to this
CREATE TABLE test (id SERIAL, data text);
CREATE INDEX ON test USING bm25 (id, data) WITH (key_field = 'id');
INSERT INTO test (data) VALUES ('hello world'), ('many more values');
```

This allows the BM25 index to create a more tightly packed, efficient representation on disk and will lead to faster build times.


# How to Tune ParadeDB
Source: https://docs.paradedb.com/documentation/performance-tuning/overview

Settings for better read and write performance

ParadeDB uses Postgres' settings, which can be found in the `postgresql.conf` file. To find your `postgresql.conf` file, use `SHOW`.

```sql theme={null}
SHOW config_file;
```

These settings can be changed in several ways:

1. By editing the `postgresql.conf` file and restarting Postgres. This makes the setting permanent for all sessions. `postgresql.conf`
   accepts ParadeDB's custom `paradedb.*` settings.
2. By running `SET`. This temporarily changes the setting for the current session. Note that Postgres does not allow all `postgresql.conf` settings to be changed with `SET`.

```sql theme={null}
SET maintenance_work_mem = '8GB'
```

If ParadeDB is deployed with [CloudNativePG](/deploy/self-hosted/kubernetes), these settings should be set in your
`.tfvars` file.

```hcl .tfvars theme={null}
postgresql = {
    parameters = {
      max_worker_processes                   = 76
      max_parallel_workers                   = 64
      # Note that paradedb.* settings must be wrapped in double quotes
      "paradedb.global_mutable_segment_rows" = 1000
    }
}
```


# Read Throughput
Source: https://docs.paradedb.com/documentation/performance-tuning/reads

Settings to improve read performance

As a general rule of thumb, the performance of expensive search queries can be greatly improved
if they are able to access more parallel Postgres workers and more shared buffer memory.

## Raise Parallel Workers

There are three settings that control how many parallel workers ultimately get assigned to a query.

First, `max_worker_processes` is a global limit for the number of workers.
Next, `max_parallel_workers` is a subset of `max_worker_processes`, and sets the limit for workers used in
parallel queries. Finally, `max_parallel_workers_per_gather` limits how many workers a *single query* can receive.

```init postgresql.conf theme={null}
max_worker_processes = 72
max_parallel_workers = 64;
max_parallel_workers_per_gather = 4;
```

In the above example, the maximum number of workers that a single query can receive is set to `4`. The `max_parallel_workers` pool
is set to `64`, which means that `16` queries can execute simultaneously with `4` workers each. Finally, `max_worker_processes` is
set to `72` to give headroom for other workers like autovacuum and replication.

In practice, we recommend experimenting with different settings, as the best configuration depends on the underlying hardware,
query patterns, and volume of data.

<Note>
  If all `max_parallel_workers` are in use, Postgres will still execute
  additional queries, but those queries will run without parallelism. This means
  that queries do not fail — they just may run slower due to lack of
  parallelism.
</Note>

## Raise Shared Buffers

`shared_buffers` controls how much memory is available to the Postgres buffer cache. We recommend allocating no more than 40% of total memory
to `shared_buffers`.

```bash postgresql.conf theme={null}
shared_buffers = 8GB
```

The `pg_prewarm` extension can be used to load the BM25 index into the buffer cache after Postgres restarts. A higher `shared_buffers` value allows more of the index to be
stored in the buffer cache.

```sql theme={null}
CREATE EXTENSION pg_prewarm;
SELECT pg_prewarm('search_idx');
```

## Configure Autovacuum

If an index experiences frequent writes, the search performance of some queries like [sorting](/documentation/sorting/score) or
[aggregates](/documentation/aggregates/overview) can degrade if `VACUUM` has not been recently run. This is because writes can cause parts of Postgres' visibility map
to go out of date, and `VACUUM` updates the visibility map.

To determine if search performance is degraded by lack of `VACUUM`, run `EXPLAIN ANALYZE` over a query. A `Parallel Custom Scan`
in the query plan with a large number of `Heap Fetches` typically means that `VACUUM` should be run.

Postgres can be configured to automatically vacuum a table when a certain number of rows have been updated. Autovacuum settings
can be set globally in `postgresql.conf` or for a specific table.

```sql theme={null}
ALTER TABLE mock_items SET (autovacuum_vacuum_threshold = 500);
```

There are several [autovacuum settings](https://www.postgresql.org/docs/current/routine-vacuuming.html#AUTOVACUUM), but the important ones to
note are:

1. `autovacuum_vacuum_scale_factor` triggers an autovacuum if a certain percentage of rows in a table have been updated.
2. `autovacuum_vacuum_threshold` triggers an autovacuum if an absolute number of rows have been updated.
3. `autovacuum_naptime` ensures that vacuum does not run too frequently.

This means that setting `autovacuum_vacuum_scale_factor` to `0` and `autovacuum_vacuum_threshold` to `100000` will trigger an autovacuum
for every `100000` row updates. As a general rule of thumb, we recommend autovacuuming at least once every `100000` single-row updates.

## Adjust Target Segment Count

By default, `CREATE INDEX`/`REINDEX` will create as many segments as there are CPUs on the host machine. This can be changed using the
`target_segment_count` index option.

```sql theme={null}
CREATE INDEX search_idx ON mock_items USING bm25 (id, description, rating) WITH (key_field = 'id', target_segment_count = 32, ...);
```

This property is attached to the index so that during `REINDEX`, the same value will be used.

It can be changed with ALTER INDEX, like so:

```sql theme={null}
ALTER INDEX search_idx SET (target_segment_count = 8);
```

However, a `REINDEX` is required to rebalance the index to that segment count.

For optimal performance, the segment count should equal the number of parallel workers that a query can receive, which is controlled by
[`max_parallel_workers_per_gather`](/documentation/performance-tuning/reads#raise-parallel-workers). If `max_parallel_workers_per_gather` is greater than the number of CPUs on the host machine, then increasing the target segment count to match `max_parallel_workers_per_gather` can improve query
performance.

<Note>
  `target_segment_count` is merely a suggestion.

  While `pg_search` will endeavor to ensure the created index will have exactly this many segments, it is possible for it
  to have less or more. Mostly this depends on the distribution of work across parallel builder processes, memory
  constraints, and table size.
</Note>


# Write Throughput
Source: https://docs.paradedb.com/documentation/performance-tuning/writes

Settings to improve write performance

These actions can improve the throughput of `INSERT`/`UPDATE`/`COPY` statements to the BM25 index.

## Ensure Merging Happens in the Background

During every `INSERT`/`UPDATE`/`COPY`/`VACUUM`, the BM25 index runs a compaction process that looks for opportunities to merge segments
together. The goal is to consolidate smaller segments into larger ones, reducing the total number of segments and improving query performance.

Segments become candidates for merging if their combined size meets or exceeds one of several **configurable layer thresholds**. These thresholds define target
segment sizes — such as `10KB`, `100KB`, `1MB`, etc. For each layer, the compactor checks if there are enough smaller segments whose total size adds up to the threshold.

The default layer sizes are `100KB`, `1MB`, `100MB`, `1GB`, and `10GB` but can be configured.

```sql theme={null}
ALTER INDEX search_idx SET (background_layer_sizes = '100MB, 1GB');
```

By default, merging happens in the background so that writes are not blocked. The `layer_sizes` option allows merging to happen in the foreground.
This is not typically recommended because it slows down writes, but can be used to apply back pressure to writes if segments are being created faster
than they can be merged down.

```sql theme={null}
ALTER INDEX search_idx SET (layer_sizes = '100KB, 1MB');
```

Setting `layer_sizes` to `0` disables foreground merging, and setting `background_layer_sizes` to `0` disables background merging.

## Increase Work Memory for Bulk Updates

`work_mem` controls how much memory to allocate to a single `INSERT`/`UPDATE`/`COPY` statement. Each statement that writes to a BM25 index is required to have at least `15MB` memory. If
`work_mem` is below `15MB`, it will be ignored and `15MB` will be used.

If your typical update patterns are large, bulk updates (not single-row updates) a larger value may be better.

```sql theme={null}
SET work_mem = 64MB;
```

Since many write operations can be running concurrently, this value should be raised more conservatively than `maintenance_work_mem`.

## Increase Mutable Segment Size

The `mutable_segment_rows` setting enables use of mutable segments, which buffer new rows in order to amortize the cost of indexing them.
By default, it is set to `1000`, which means that 1000 writes are buffered before being flushed.

```sql theme={null}
ALTER INDEX search_idx SET (mutable_segment_rows = 1000);
```

A higher value generally improves write throughput at the expense of read performance,
since the mutable data structure is slower to search. Additionally, the mutable data structure is read into
memory, so higher values cause reads to consume more RAM.

Alternatively, this setting can be set to apply to all indexes in the database:

```sql theme={null}
SET paradedb.global_mutable_segment_rows = 1000
```

If both a per-index setting and global setting exist, the global `paradedb.global_mutable_segment_rows` will be used.
To ignore the global setting, set `paradedb.global_mutable_segment_rows` to `-1` (this is the default).

```sql theme={null}
SET paradedb.global_mutable_segment_rows = -1
```


# All
Source: https://docs.paradedb.com/documentation/query-builder/compound/all

Search all rows in the index

The all query means "search all rows in the index."

The primary use case for the all query is to force the query to be executed by the ParadeDB index instead of Postgres' other execution methods.
Because ParadeDB executes a query only when a ParadeDB operator is present in the query, the all query injects an operator into the query
without changing the query's meaning.

To use it, pass the [key field](/documentation/indexing/create-index#choosing-a-key-field) to the left-hand side of `@@@` and `pdb.all()` to the right-hand side.

<CodeGroup>
  ```sql SQL theme={null}
  -- Top K executed by standard Postgres
  SELECT id, description, rating, category
  FROM mock_items
  WHERE rating IS NOT NULL
  ORDER BY rating
  LIMIT 5;

  -- Top K executed by ParadeDB
  SELECT id, description, rating, category
  FROM mock_items
  WHERE rating IS NOT NULL AND id @@@ pdb.all()
  ORDER BY rating
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import All, ParadeDB

  # Top K executed by standard Postgres
  MockItem.objects.filter(
      rating__isnull=False
  ).order_by('rating')[:5]

  # Top K executed by ParadeDB
  MockItem.objects.filter(
      rating__isnull=False,
      id=ParadeDB(All())
  ).order_by('rating')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  standard_topn_stmt = (
      select(MockItem.id, MockItem.description, MockItem.rating, MockItem.category)
      .where(MockItem.rating.is_not(None))
      .order_by(MockItem.rating)
      .limit(5)
  )

  paradedb_topn_stmt = (
      select(MockItem.id, MockItem.description, MockItem.rating, MockItem.category)
      .where(MockItem.rating.is_not(None), search.all(MockItem.id))
      .order_by(MockItem.rating)
      .limit(5)
  )

  with Session(engine) as session:
      {
          "standard_rows": session.execute(standard_topn_stmt).all(),
          "paradedb_rows": session.execute(paradedb_topn_stmt).all(),
      }
  ```

  ```ruby Rails theme={null}
  # Top K executed by standard Postgres
  MockItem.where.not(rating: nil).order(:rating).limit(5)

  # Top K executed by ParadeDB
  MockItem.search(:id)
          .match_all
          .where.not(rating: nil)
          .order(:rating)
          .limit(5)
  ```
</CodeGroup>

This is useful for cases where queries that don't contain a ParadeDB operator can be more efficiently executed by ParadeDB vs. standard Postgres,
like [Top K](/documentation/sorting/topk) or [aggregate](/documentation/aggregates/overview) queries.


# Query Parser
Source: https://docs.paradedb.com/documentation/query-builder/compound/query-parser

Accept raw user-provided query strings

The parse query accepts a [Tantivy query string](https://docs.rs/tantivy/latest/tantivy/query/struct.QueryParser.html).
The intended use case is for accepting raw query strings provided by the end user.

To use it, pass the [key field](/documentation/indexing/create-index#choosing-a-key-field) to the left-hand side of `@@@` and `pdb.parse('<query>')` to the right-hand side.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category FROM mock_items
  WHERE id @@@ pdb.parse('description:(sleek shoes) AND rating:>3');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Parse

  MockItem.objects.filter(
      id=ParadeDB(Parse('description:(sleek shoes) AND rating:>3'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.parse(MockItem.id, "description:(sleek shoes) AND rating:>3"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .parse("description:(sleek shoes) AND rating:>3")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

Please refer to the [Tantivy docs](https://docs.rs/tantivy/latest/tantivy/query/struct.QueryParser.html) for an overview of
the query string language.

## Lenient Parsing

By default, strict syntax parsing is used. This means that if any part of the query does not conform to Tantivy’s query string syntax, the query fails. For instance, a valid field name must be provided before every query (i.e. `category:footwear`).
By setting `lenient` to `true`, the query is executed on a best-effort basis. For example, if no field names are provided, the query is executed over all fields in the index.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category FROM mock_items
  WHERE id @@@ pdb.parse('description:(sleek shoes) AND rating:>3', lenient => true);
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Parse

  MockItem.objects.filter(
      id=ParadeDB(Parse('description:(sleek shoes) AND rating:>3', lenient=True))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.parse(MockItem.id, "description:(sleek shoes) AND rating:>3", lenient=True))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .parse("description:(sleek shoes) AND rating:>3", lenient: true)
          .select(:description, :rating, :category)
  ```
</CodeGroup>

## Conjunction Mode

By default, terms in the query string are `OR`ed together. With `conjunction_mode` set to `true`, they are instead `AND`ed together.
For instance, the following query returns documents containing both `sleek` and `shoes`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category FROM mock_items
  WHERE id @@@ pdb.parse('description:(sleek shoes)', conjunction_mode => true);
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Parse

  MockItem.objects.filter(
      id=ParadeDB(Parse('description:(sleek shoes)', conjunction_mode=True))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.parse(MockItem.id, "description:(sleek shoes)", conjunction_mode=True))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:id)
          .parse("description:(sleek shoes)", conjunction_mode: true)
          .select(:description, :rating, :category)
  ```
</CodeGroup>


# How Advanced Query Functions Work
Source: https://docs.paradedb.com/documentation/query-builder/overview

ParadeDB's query builder functions provide advanced query types

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


# Phrase Prefix
Source: https://docs.paradedb.com/documentation/query-builder/phrase/phrase-prefix

Finds documents containing a phrase followed by a term prefix

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

<div />

<ParamField>
  An `ARRAY` of tokens that the search is looking to match, followed by a term
  prefix rather than a complete term.
</ParamField>

<ParamField>
  Limits the number of term variations that the prefix can expand to during the
  search. This helps in controlling the breadth of the search by setting a cap
  on how many different terms the prefix can match.
</ParamField>

## Performance Considerations

Expanding a prefix might lead to thousands of matching terms, which impacts search times.

With `max_expansions`, the prefix term is expanded to at most `max_expansions` terms
in lexicographic order. For instance, if `sh` matches `shall`, `share`, `shoe`, and `shore` but `max_expansions` is set to 3,
`sh` will only be expanded to `shall`, `share`, and `shoe`.


# Regex Phrase
Source: https://docs.paradedb.com/documentation/query-builder/phrase/regex-phrase

Matches a specific sequence of regex queries

Regex phrase matches a specific sequence of regex queries. Think of it like a conjunction of [regex](/documentation/query-builder/term/regex)
queries, with positions and ordering of tokens enforced.

For example, the regex phrase query for `ru.* shoes` will match `running shoes`, but will not match `shoes running`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ pdb.regex_phrase(ARRAY['ru.*', 'shoes']);
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, RegexPhrase

  MockItem.objects.filter(
      description=ParadeDB(RegexPhrase('ru.*', 'shoes'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.regex_phrase(MockItem.description, ["ru.*", "shoes"]))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .regex_phrase("ru.*", "shoes")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

<div />

<ParamField>
  An `ARRAY` of expressions that form the search phrase. These expressions must
  appear in the specified order within the document for a match to occur,
  although some flexibility is allowed based on the `slop` parameter. Please see
  [regex](/documentation/query-builder/term/regex) for allowed regex constructs.
</ParamField>

<ParamField>
  A slop of `0` requires the terms to appear exactly as they are in the phrase
  and adjacent to each other. Higher slop values allow for transpositions and
  distance between terms.
</ParamField>

<ParamField>
  Limits total number of terms that the regex phrase query can expand to. If
  this number is exceeded, an error will be returned.
</ParamField>


# More Like This
Source: https://docs.paradedb.com/documentation/query-builder/specialized/more-like-this

Finds documents that are "like" another document.

The more like this (MLT) query finds documents that are "like" another document.
To use this query, pass the [key field](/documentation/indexing/create-index#choosing-a-key-field) value of the input document
to `pdb.more_like_this`.

For instance, the following query finds documents that are "like" a document with an `id` of `3`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description, rating, category
  FROM mock_items
  WHERE id @@@ pdb.more_like_this(3)
  ORDER BY id;
  ```

  ```python Django theme={null}
  from paradedb import MoreLikeThis, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(MoreLikeThis(id=3))
  ).values('id', 'description', 'rating', 'category').order_by('id')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description, MockItem.rating, MockItem.category)
      .where(search.more_like_this(MockItem.id, document_id=3))
      .order_by(MockItem.id)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.more_like_this(3)
          .select(:id, :description, :rating, :category)
          .order(:id)
  ```
</CodeGroup>

```ini Expected Response theme={null}
 id |     description      | rating | category
----+----------------------+--------+----------
  3 | Sleek running shoes  |      5 | Footwear
  4 | White jogging shoes  |      3 | Footwear
  5 | Generic shoes        |      4 | Footwear
 13 | Sturdy hiking boots  |      4 | Footwear
 23 | Comfortable slippers |      3 | Footwear
 33 | Winter woolen socks  |      5 | Footwear
(6 rows)
```

In the output above, notice that documents matching any of the indexed fields, `description`, `rating`, and `category`, were returned.
This is because, by default, all fields present in the index are considered for matching.

<Note>
  The only exception is JSON fields, which are not yet supported and are ignored
  by the more like this query.
</Note>

To find only documents that match on specific fields, provide an array of field names as the second argument:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description, rating, category
  FROM mock_items
  WHERE id @@@ pdb.more_like_this(3, ARRAY['description'])
  ORDER BY id;
  ```

  ```python Django theme={null}
  from paradedb import MoreLikeThis, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(MoreLikeThis(id=3, fields=['description']))
  ).values('id', 'description', 'rating', 'category').order_by('id')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description, MockItem.rating, MockItem.category)
      .where(search.more_like_this(MockItem.id, document_id=3, fields=["description"]))
      .order_by(MockItem.id)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.more_like_this(3, fields: [:description])
          .select(:id, :description, :rating, :category)
          .order(:id)
  ```
</CodeGroup>

```ini Expected Response theme={null}
 id |     description     | rating | category
----+---------------------+--------+----------
  3 | Sleek running shoes |      5 | Footwear
  4 | White jogging shoes |      3 | Footwear
  5 | Generic shoes       |      4 | Footwear
(3 rows)
```

<Note>
  Because JSON fields are not yet supported for MLT, an error will be returned
  if a JSON field is passed into the array.
</Note>

## How It Works

Let's look at how the MLT query works under the hood:

1. Stored values for the input document's fields are retrieved. If they are text fields, they are tokenized and filtered in the same way
   as the field was during [index creation](/documentation/indexing/create-index).
2. A set of representative terms is created from the input document. For example, in the statement above, these terms would be
   `sleek`, `running`, and `shoes` for the `description` field; `5` for the `rating` field; `footwear` for the `category` field.
3. Documents with at least one term match across any of the fields are considered a match.

## Using a Custom Input Document

In addition to providing a key field value, a custom document can also be provided as JSON.
The JSON keys are field names and must correspond to field names in the index.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description, rating, category
  FROM mock_items
  WHERE id @@@ pdb.more_like_this('{"description": "Sleek running shoes", "category": "footwear"}')
  ORDER BY id;
  ```

  ```python Django theme={null}
  from paradedb import MoreLikeThis, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(MoreLikeThis(document={'description': 'Sleek running shoes', 'category': 'footwear'}))
  ).values('id', 'description', 'rating', 'category').order_by('id')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description, MockItem.rating, MockItem.category)
      .where(
          search.more_like_this(
              MockItem.id,
              document={"description": "Sleek running shoes", "category": "footwear"},
          )
      )
      .order_by(MockItem.id)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.more_like_this({ description: "Sleek running shoes", category: "footwear" }.to_json)
          .select(:id, :description, :rating, :category)
          .order(:id)
  ```
</CodeGroup>

## Configuration Options

### Term Frequency

`min_term_frequency` excludes terms that appear fewer than a certain number of times in the input document,
while `max_term_frequency` excludes terms that appear more than that many times. By default, no terms are excluded
based on term frequency.

For instance, the following query returns no results because no term appears twice in the input document.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description, rating, category
  FROM mock_items
  WHERE id @@@ pdb.more_like_this(3, min_term_frequency => 2)
  ORDER BY id;
  ```

  ```python Django theme={null}
  from paradedb import MoreLikeThis, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(MoreLikeThis(id=3, min_term_freq=2))
  ).values('id', 'description', 'rating', 'category').order_by('id')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description, MockItem.rating, MockItem.category)
      .where(search.more_like_this(MockItem.id, document_id=3, min_term_frequency=2))
      .order_by(MockItem.id)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.more_like_this(3, min_term_freq: 2)
          .select(:id, :description, :rating, :category)
          .order(:id)
  ```
</CodeGroup>

### Document Frequency

`min_doc_frequency` excludes terms that appear in fewer than a certain number of documents across the entire index,
while `max_doc_frequency` excludes terms that appear in more than that many documents. By default, no terms are excluded
based on document frequency.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description, rating, category
  FROM mock_items
  WHERE id @@@ pdb.more_like_this(3, min_doc_frequency => 3)
  ORDER BY id;
  ```

  ```python Django theme={null}
  from paradedb import MoreLikeThis, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(MoreLikeThis(id=3, min_doc_freq=3))
  ).values('id', 'description', 'rating', 'category').order_by('id')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description, MockItem.rating, MockItem.category)
      .where(search.more_like_this(MockItem.id, document_id=3, min_doc_frequency=3))
      .order_by(MockItem.id)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.more_like_this(3, min_doc_freq: 3)
          .select(:id, :description, :rating, :category)
          .order(:id)
  ```
</CodeGroup>

### Max Query Terms

By default, only the top 25 terms across all fields are considered for matching. Terms are scored using a combination of inverse document
frequency and term frequency (TF-IDF) -- this means that terms that appear frequently in the input document and are rare across the index
score the highest.

This can be configured with `max_query_terms`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description, rating, category
  FROM mock_items
  WHERE id @@@ pdb.more_like_this(3, max_query_terms => 10)
  ORDER BY id;
  ```

  ```python Django theme={null}
  from paradedb import MoreLikeThis, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(MoreLikeThis(id=3, max_query_terms=10))
  ).values('id', 'description', 'rating', 'category').order_by('id')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description, MockItem.rating, MockItem.category)
      .where(search.more_like_this(MockItem.id, document_id=3, max_query_terms=10))
      .order_by(MockItem.id)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.more_like_this(3, max_query_terms: 10)
          .select(:id, :description, :rating, :category)
          .order(:id)
  ```
</CodeGroup>

### Term Length

`min_word_length` and `max_word_length` can be used to exclude terms that are too short or too long, respectively. By default, no terms
are excluded based on length.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description, rating, category
  FROM mock_items
  WHERE id @@@ pdb.more_like_this(3, min_word_length => 5)
  ORDER BY id;
  ```

  ```python Django theme={null}
  from paradedb import MoreLikeThis, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(MoreLikeThis(id=3, min_word_length=5))
  ).values('id', 'description', 'rating', 'category').order_by('id')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description, MockItem.rating, MockItem.category)
      .where(search.more_like_this(MockItem.id, document_id=3, min_word_length=5))
      .order_by(MockItem.id)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.more_like_this(3, min_word_length: 5)
          .select(:id, :description, :rating, :category)
          .order(:id)
  ```
</CodeGroup>

### Custom Stopwords

To exclude terms from being considered, provide a text array to `stopwords`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description, rating, category
  FROM mock_items
  WHERE id @@@ pdb.more_like_this(3, stopwords => ARRAY['the', 'a'])
  ORDER BY id;
  ```

  ```python Django theme={null}
  from paradedb import MoreLikeThis, ParadeDB

  MockItem.objects.filter(
      id=ParadeDB(MoreLikeThis(id=3, stopwords=['the', 'a']))
  ).values('id', 'description', 'rating', 'category').order_by('id')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.description, MockItem.rating, MockItem.category)
      .where(search.more_like_this(MockItem.id, document_id=3, stopwords=["the", "a"]))
      .order_by(MockItem.id)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.more_like_this(3, stopwords: %w[the a])
          .select(:id, :description, :rating, :category)
          .order(:id)
  ```
</CodeGroup>


# Range Term
Source: https://docs.paradedb.com/documentation/query-builder/term/range-term

Filters over Postgres range types

`range_term` is the equivalent of Postgres' operators over [range types](https://www.postgresql.org/docs/current/rangetypes.html).
It supports operations like range containment, overlap, and intersection.

## Term Within

In this example, `weight_range` is an `int4range` type.
The following query finds all rows where `weight_range` contains `1`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, weight_range FROM mock_items
  WHERE weight_range @@@ pdb.range_term(1);
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, RangeTerm

  MockItem.objects.filter(
      weight_range=ParadeDB(RangeTerm(1))
  ).values('id', 'weight_range')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.weight_range)
      .where(search.range_term(MockItem.weight_range, 1))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:weight_range)
          .range_term(1)
          .select(:id, :weight_range)
  ```
</CodeGroup>

## Range Intersects

The following query finds all ranges that share at least one common
point with the query range:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, weight_range FROM mock_items
  WHERE weight_range @@@ pdb.range_term('(10, 12]'::int4range, 'Intersects');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, RangeTerm

  MockItem.objects.filter(
      weight_range=ParadeDB(RangeTerm('(10, 12]', relation='Intersects', range_type='int4range'))
  ).values('id', 'weight_range')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.weight_range)
      .where(
          search.range_term(
              MockItem.weight_range,
              "(10, 12]",
              relation="Intersects",
              range_type="int4range",
          )
      )
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:weight_range)
          .range_term("(10, 12]", relation: "Intersects", range_type: "int4range")
          .select(:id, :weight_range)
  ```
</CodeGroup>

## Range Contains

The following query finds all ranges that are contained by the query range:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, weight_range FROM mock_items
  WHERE weight_range @@@ pdb.range_term('(3, 9]'::int4range, 'Contains');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, RangeTerm

  MockItem.objects.filter(
      weight_range=ParadeDB(RangeTerm('(3, 9]', relation='Contains', range_type='int4range'))
  ).values('id', 'weight_range')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.weight_range)
      .where(
          search.range_term(
              MockItem.weight_range,
              "(3, 9]",
              relation="Contains",
              range_type="int4range",
          )
      )
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:weight_range)
          .range_term("(3, 9]", relation: "Contains", range_type: "int4range")
          .select(:id, :weight_range)
  ```
</CodeGroup>

## Range Within

The following query finds all ranges that contain the query range:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, weight_range FROM mock_items
  WHERE weight_range @@@ pdb.range_term('(2, 11]'::int4range, 'Within');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, RangeTerm

  MockItem.objects.filter(
      weight_range=ParadeDB(RangeTerm('(2, 11]', relation='Within', range_type='int4range'))
  ).values('id', 'weight_range')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.id, MockItem.weight_range)
      .where(
          search.range_term(
              MockItem.weight_range,
              "(2, 11]",
              relation="Within",
              range_type="int4range",
          )
      )
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:weight_range)
          .range_term("(2, 11]", relation: "Within", range_type: "int4range")
          .select(:id, :weight_range)
  ```
</CodeGroup>


# Regex
Source: https://docs.paradedb.com/documentation/query-builder/term/regex

Searches for terms that match a regex pattern

Regex queries search for terms that follow a pattern. For example, the wildcard pattern `key.*` finds all terms that start with `key`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ pdb.regex('key.*');
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Regex

  MockItem.objects.filter(
      description=ParadeDB(Regex('key.*'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.regex(MockItem.description, "key.*"))
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .regex("key.*")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

ParadeDB supports all regex constructs of the Rust [regex](https://docs.rs/regex/latest/regex/) crate, with the following exceptions:

1. Lazy quantifiers such as `+?`
2. Word boundaries such as `\b`

Otherwise, the full syntax of the [regex](https://docs.rs/regex/latest/regex/) crate is supported, including all Unicode support and relevant flags.

A list of regex flags and grouping options can be [found here](https://docs.rs/regex/latest/regex/#grouping-and-flags), which includes:

* named and numbered capture groups
* case insensitivty flag (`i`)
* multi-line mode (`m`)

<Note>
  Regex queries operate at the token level. To execute regex over the original
  text, use the keyword tokenizer.
</Note>

## Performance Considerations

During a regex query, ParadeDB doesn't scan through every single word. Instead, it uses a highly optimized structure called a [finite state transducer (FST)](https://en.wikipedia.org/wiki/Finite-state_transducer) that makes it possible to jump straight to the matching terms.
Even if the index contains millions of words, the regex query only looks at the ones that have a chance of matching, skipping everything else.

This is why the certain regex constructs are not supported -- they are difficult to implement efficiently.


# Relevance Tuning
Source: https://docs.paradedb.com/documentation/sorting/boost

Tune the BM25 score by adjusting the weights of individual queries

## Boosting

ParadeDB offers several ways to tune a document's [BM25 score](/documentation/sorting/score).
The first is boosting, which increases or decreases the impact of a specific query by multiplying its contribution to the overall BM25 score.

To boost a query, cast the query to the `boost` type. In this example, the `shoes` query is weighted twice as heavily as the `footwear` query.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.score(id), description, category
  FROM mock_items
  WHERE description ||| 'shoes'::pdb.boost(2) OR category ||| 'footwear'
  ORDER BY score DESC
  LIMIT 5;
  ```

  ```python Django theme={null}
  from django.db.models import Q
  from paradedb import Match, ParadeDB, Score

  MockItem.objects.filter(
      Q(description=ParadeDB(Match('shoes', operator='OR', boost=2))) |
      Q(category=ParadeDB(Match('footwear', operator='OR')))
  ).annotate(
      score=Score()
  ).values('id', 'score', 'description', 'category').order_by('-score')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import desc, or_, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(
          MockItem.id,
          pdb.score(MockItem.id).label("score"),
          MockItem.description,
          MockItem.category,
      )
      .where(
          or_(
              search.match_any(MockItem.description, "shoes", boost=2.0),
              search.match_any(MockItem.category, "footwear"),
          )
      )
      .order_by(desc("score"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("shoes", boost: 2)
          .or(MockItem.search(:category).matching_any("footwear"))
          .with_score
          .select(:id, :description, :category)
          .order(search_score: :desc)
          .limit(5)
  ```
</CodeGroup>

`boost` takes a numeric value, which is the multiplicative boost factor. It can be any floating point number between `-2048` and `2048`.

[Query builder functions](/documentation/query-builder/overview) can also be boosted:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description, category, pdb.score(id)
  FROM mock_items
  WHERE description @@@ pdb.regex('key.*')::pdb.boost(2)
  ORDER BY score DESC
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import ParadeDB, Regex, Score

  MockItem.objects.filter(
      description=ParadeDB(Regex('key.*', boost=2))
  ).annotate(
      score=Score()
  ).values('id', 'description', 'category', 'score').order_by('-score')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import desc, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(
          MockItem.id,
          MockItem.description,
          MockItem.category,
          pdb.score(MockItem.id).label("score"),
      )
      .where(search.regex(MockItem.description, "key.*", boost=2.0))
      .order_by(desc("score"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .regex("key.*", boost: 2)
          .with_score
          .select(:id, :description, :category)
          .order(search_score: :desc)
          .limit(5)
  ```
</CodeGroup>

Boost can be used in conjunction with other type casts, like [fuzzy](/documentation/full-text/fuzzy):

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, description, category, pdb.score(id)
  FROM mock_items
  WHERE description ||| 'shose'::pdb.fuzzy(2)::pdb.boost(2)
  ORDER BY score DESC
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Score

  MockItem.objects.filter(
      description=ParadeDB(Match('shose', operator='OR', distance=2, boost=2))
  ).annotate(
      score=Score()
  ).values('id', 'description', 'category', 'score').order_by('-score')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import desc, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(
          MockItem.id,
          MockItem.description,
          MockItem.category,
          pdb.score(MockItem.id).label("score"),
      )
      .where(search.match_any(MockItem.description, "shose", distance=2, boost=2.0))
      .order_by(desc("score"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("shose", distance: 2, boost: 2)
          .with_score
          .select(:id, :description, :category)
          .order(search_score: :desc)
          .limit(5)
  ```
</CodeGroup>

## Constant Scoring

Constant scoring assigns the same score to all documents that match a query. To apply a constant score, cast the query to the `const` type with a
numeric value.

For instance, the following query assigns a score of `1` to all documents matching the query `shoes`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.score(id), description, category
  FROM mock_items
  WHERE description ||| 'shoes'::pdb.const(1)
  ORDER BY score DESC
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Score

  MockItem.objects.filter(
      description=ParadeDB(Match('shoes', operator='OR', const=1))
  ).annotate(
      score=Score()
  ).values('id', 'score', 'description', 'category').order_by('-score')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import desc, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(
          MockItem.id,
          pdb.score(MockItem.id).label("score"),
          MockItem.description,
          MockItem.category,
      )
      .where(search.match_any(MockItem.description, "shoes", const=1.0))
      .order_by(desc("score"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("shoes", constant_score: 1)
          .with_score
          .select(:id, :description, :category)
          .order(search_score: :desc)
          .limit(5)
  ```
</CodeGroup>


# BM25 Scoring
Source: https://docs.paradedb.com/documentation/sorting/score

BM25 scores sort the result set by relevance

BM25 scores measure how relevant a score is for a given query. Higher scores indicate higher relevance.

## Basic Usage

The `pdb.score(<key_field>)` function produces a BM25 score and can be added to any query where any of the ParadeDB operators are present.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.score(id)
  FROM mock_items
  WHERE description ||| 'shoes'
  ORDER BY pdb.score(id) DESC
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB, Score

  MockItem.objects.filter(
      description=ParadeDB(Match('shoes', operator='OR'))
  ).annotate(
      score=Score()
  ).values('id', 'score').order_by('-score')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import desc, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(MockItem.id, pdb.score(MockItem.id).label("score"))
      .where(search.match_any(MockItem.description, "shoes"))
      .order_by(desc("score"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("shoes")
          .with_score
          .select(:id)
          .order(search_score: :desc)
          .limit(5)
  ```
</CodeGroup>

In order for a field to be factored into the BM25 score, it must be present in the BM25 index. For instance,
consider this query:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT id, pdb.score(id)
  FROM mock_items
  WHERE description ||| 'keyboard' OR rating < 2
  ORDER BY pdb.score(id) DESC
  LIMIT 5;
  ```

  ```python Django theme={null}
  from django.db.models import Q
  from paradedb import Match, ParadeDB, Score

  MockItem.objects.filter(
      Q(description=ParadeDB(Match('keyboard', operator='OR'))) | Q(rating__lt=2)
  ).annotate(
      score=Score()
  ).values('id', 'score').order_by('-score')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import desc, or_, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(MockItem.id, pdb.score(MockItem.id).label("score"))
      .where(or_(search.match_any(MockItem.description, "keyboard"), MockItem.rating < 2))
      .order_by(desc("score"))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("keyboard")
          .or(MockItem.where(rating: ...2))
          .with_score
          .select(:id)
          .order(search_score: :desc)
          .limit(5)
  ```
</CodeGroup>

While BM25 scores will be returned as long as `description` is indexed, including `rating` in the BM25 index definition will allow results matching
`rating < 2` to rank higher than those that do not match.

## Joined Scores

First, let's create a second table called `orders` that can be joined with `mock_items`:

```sql theme={null}
CALL paradedb.create_bm25_test_table(
  schema_name => 'public',
  table_name => 'orders',
  table_type => 'Orders'
);

ALTER TABLE orders
ADD CONSTRAINT foreign_key_product_id
FOREIGN KEY (product_id)
REFERENCES mock_items(id);

CREATE INDEX orders_idx ON orders
USING bm25 (order_id, product_id, order_quantity, order_total, customer_name)
WITH (key_field = 'order_id');
```

Next, let's compute a "combined BM25 score" over a join across both tables.
The Django example assumes an `Order` model with `product = models.ForeignKey(MockItem, db_column='product_id', to_field='id', ...)`.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT o.order_id, o.customer_name, m.description, pdb.score(o.order_id) + pdb.score(m.id) as score
  FROM orders o
  JOIN mock_items m ON o.product_id = m.id
  WHERE o.customer_name ||| 'Johnson' AND m.description ||| 'running shoes'
  ORDER BY score DESC, o.order_id
  LIMIT 5;
  ```

  ```python Django theme={null}
  from django.db.models import F, FloatField
  from django.db.models.expressions import RawSQL
  from paradedb import Match, ParadeDB, Score

  Order.objects.filter(
      customer_name=ParadeDB(Match('Johnson', operator='OR')),
      product__description=ParadeDB(Match('running shoes', operator='OR')),
  ).annotate(
      order_score=Score(),
      product_score=RawSQL('pdb.score(mock_items.id)', [], output_field=FloatField()),
  ).annotate(
      score=F('order_score') + F('product_score')
  ).values(
      'order_id', 'customer_name', 'product__description', 'score'
  ).order_by('-score', 'order_id')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import desc, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  stmt = (
      select(
          Order.order_id,
          Order.customer_name,
          MockItem.description,
          (pdb.score(Order.order_id) + pdb.score(MockItem.id)).label("score"),
      )
      .select_from(Order)
      .join(MockItem, Order.product_id == MockItem.id)
      .where(
          search.match_any(Order.customer_name, "Johnson"),
          search.match_any(MockItem.description, "running shoes"),
      )
      .order_by(desc("score"), Order.order_id)
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  orders = Order.arel_table
  mock_items = MockItem.arel_table
  combined_score = Arel::Nodes::Addition.new(
    orders[:order_id].pdb_score,
    mock_items[:id].pdb_score
  )
  join = orders.join(mock_items).on(orders[:product_id].eq(mock_items[:id])).join_sources

  Order.joins(join)
       .search(:customer_name)
       .matching_any("Johnson")
       .search(mock_items[:description])
       .matching_any("running shoes")
       .select(
         orders[:order_id],
         orders[:customer_name],
         mock_items[:description].as("product_description"),
         combined_score.as("score")
       )
       .order(
         Arel::Nodes::Descending.new(combined_score),
         Arel::Nodes::Ascending.new(orders[:order_id])
       )
       .limit(5)
  ```
</CodeGroup>

## Score Refresh

The scores generated by the BM25 index may be influenced by dead rows that have not been cleaned up by the `VACUUM` process.

Running `VACUUM` on the underlying table will remove all dead rows from the index and ensures that only rows visible to the current
transaction are factored into the BM25 score.

```sql theme={null}
VACUUM mock_items;
```

This can be automated with [autovacuum](/documentation/performance-tuning/overview).


# Top K
Source: https://docs.paradedb.com/documentation/sorting/topk

ParadeDB is optimized for quickly finding the Top K results in a table

ParadeDB is highly optimized for quickly returning the Top K results out of the index. In SQL, this means queries that contain an `ORDER BY...LIMIT`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ||| 'running shoes'
  ORDER BY rating
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='OR'))
  ).order_by('rating').values('description', 'rating', 'category')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(MockItem.description, "running shoes"))
      .order_by(MockItem.rating)
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running shoes")
          .order(:rating)
          .select(:description, :rating, :category)
          .limit(5)
  ```
</CodeGroup>

In order for a Top K query to be executed by ParadeDB vs. vanilla Postgres, all of the following conditions must be met:

1. All `ORDER BY` fields must be indexed. If they are text fields, they [must use the literal tokenizer](#sorting-by-text).
2. At least one ParadeDB text search operator must be present at the same level as the `ORDER BY...LIMIT`.
3. The query must have a `LIMIT`.
4. With the exception of `lower`, ordering by expressions is not supported -- only the raw fields themselves.

To verify that ParadeDB is executing the Top K, look for a `Custom Scan` with a `TopKScanExecState` in the `EXPLAIN` output:

```sql theme={null}
EXPLAIN SELECT description, rating, category
FROM mock_items
WHERE description ||| 'running shoes'
ORDER BY rating
LIMIT 5;
```

<Accordion title="Expected Response">
  ```csv theme={null}
                                                                                                     QUERY PLAN
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Limit  (cost=10.00..10.02 rows=3 width=552)
     ->  Custom Scan (ParadeDB Base Scan) on mock_items  (cost=10.00..10.02 rows=3 width=552)
           Table: mock_items
           Index: search_idx
           Segment Count: 1
           Exec Method: TopKScanExecState
           Scores: false
              TopK Order By: rating asc
              TopK Limit: 5
           Tantivy Query: {"with_index":{"query":{"match":{"field":"description","value":"running shoes","tokenizer":null,"distance":null,"transposition_cost_one":null,"prefix":null,"conjunction_mode":false}}}}
  (10 rows)
  ```
</Accordion>

If any of the above conditions are not met, the query cannot be fully optimized and you will not see a `TopKScanExecState` in the `EXPLAIN` output.

## Tiebreaker Sorting

To guarantee stable sorting in the event of a tie, additional columns can be provided to `ORDER BY`:

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ||| 'running shoes'
  ORDER BY rating, id
  LIMIT 5;
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('running shoes', operator='OR'))
  ).order_by('rating', 'id').values('description', 'rating', 'category')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(MockItem.description, "running shoes"))
      .order_by(MockItem.rating, MockItem.id)
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  MockItem.search(:description)
          .matching_any("running shoes")
          .order(:rating, :id)
          .select(:description, :rating, :category)
          .limit(5)
  ```
</CodeGroup>

<Note>
  ParadeDB is currently able to handle 3 `ORDER BY` columns. If there are more
  than 3 columns, the `ORDER BY` will not be efficiently executed by ParadeDB.
</Note>

## Sorting by Text

If a text field is present in the `ORDER BY` clause, it must be indexed with the [literal](/documentation/tokenizers/available-tokenizers/literal) or
[literal normalized](/documentation/tokenizers/available-tokenizers/literal-normalized) tokenizer.

Sorting by lowercase text using `lower(<text_field>)` is also supported. To enable this, the expression `lower(<text_field>)` must be indexed
with either the literal or literal normalized tokenizer. See [indexing expressions](/documentation/indexing/indexing-expressions) for more information.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (lower(description)::pdb.literal))
WITH (key_field='id');
```

This allows sorting by lowercase to be optimized.

<CodeGroup>
  ```sql SQL theme={null}
  SELECT description, rating, category
  FROM mock_items
  WHERE description ||| 'sleek running shoes'
  ORDER BY lower(description)
  LIMIT 5;
  ```

  ```python Django theme={null}
  from django.db.models.functions import Lower
  from paradedb import Match, ParadeDB

  MockItem.objects.filter(
      description=ParadeDB(Match('sleek running shoes', operator='OR'))
  ).order_by(Lower('description')).values('description', 'rating', 'category')[:5]
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import func, select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import search

  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(MockItem.description, "sleek running shoes"))
      .order_by(func.lower(MockItem.description))
      .limit(5)
  )

  with Session(engine) as session:
      session.execute(stmt).all()
  ```

  ```ruby Rails theme={null}
  description = MockItem.arel_table[:description]
  lower_description = Arel::Nodes::NamedFunction.new("LOWER", [description])

  MockItem.search(:description)
          .matching_any("sleek running shoes")
          .order(Arel::Nodes::Ascending.new(lower_description))
          .select(:description, :rating, :category)
          .limit(5)
  ```
</CodeGroup>

## Sorting by JSON

Ordering by JSON subfield is on the roadmap but not yet supported. For example, this query will not receive an optimized
Top K scan:

```sql theme={null}
SELECT id, description, metadata
FROM mock_items
WHERE description ||| 'sleek running shoes'
ORDER BY metadata->'weight'
LIMIT 5;
```


# Alpha Numeric Only
Source: https://docs.paradedb.com/documentation/token-filters/alphanumeric

Removes any tokens that contain characters that are not ASCII letters

The alpha numeric only filter removes any tokens that contain characters that are not ASCII letters (i.e. `a` to `z` and `A` to `Z`) or digits
(i.e. `0` to `9`). It is supported for all tokenizers besides the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer.

To enable, append `alpha_num_only=true` to the tokenizer's arguments.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('alpha_num_only=true')))
WITH (key_field='id');
```

To demonstrate this token filter, let's compare the output of the following two statements:

```sql theme={null}
SELECT
  'The café at 9pm!'::pdb.simple::text[],
  'The café at 9pm!'::pdb.simple('alpha_num_only=true')::text[];
```

```ini Expected Response theme={null}
       text        |     text
-------------------+--------------
 {the,café,at,9pm} | {the,at,9pm}
(1 row)
```


# ASCII Folding
Source: https://docs.paradedb.com/documentation/token-filters/ascii-folding

Strips away diacritical marks like accents

The ASCII folding filter strips away diacritical marks (accents, umlauts, tildes, etc.) while leaving the base character intact.
It is supported for all tokenizers besides the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer.

To enable, append `ascii_folding=true` to the tokenizer's arguments.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('ascii_folding=true')))
WITH (key_field='id');
```

To demonstrate this token filter, let's compare the output of the following two statements:

```sql theme={null}
SELECT
  'Café naïve coöperate'::pdb.simple::text[],
  'Café naïve coöperate'::pdb.simple('ascii_folding=true')::text[];
```

```ini Expected Response theme={null}
          text          |          text
------------------------+------------------------
 {café,naïve,coöperate} | {cafe,naive,cooperate}
(1 row)
```


# Lowercase
Source: https://docs.paradedb.com/documentation/token-filters/lowercase

Converts all characters to lowercase

The lowercase filter converts all characters to lowercase, allowing for case-insensitive queries. It is enabled by default but can be
configured for all tokenizers besides the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer.

To disable, append `lowercase=false` to the tokenizer's arguments:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('lowercase=false')))
WITH (key_field='id');
```

To demonstrate this token filter, let's compare the output of the following two statements:

```sql theme={null}
SELECT
  'Tokenize me!'::pdb.simple::text[],
  'Tokenize me!'::pdb.simple('lowercase=false')::text[];
```

```ini Expected Response theme={null}
     text      |     text
---------------+---------------
 {tokenize,me} | {Tokenize,me}
(1 row)
```


# How Token Filters Work
Source: https://docs.paradedb.com/documentation/token-filters/overview

Token filters apply additional processing to tokens like lowercasing or stemming

After a [tokenizer](/documentation/tokenizers/overview) splits up text into tokens, token filters
apply additional processing to each token. Common examples include [stemming](/documentation/token-filters/stemming)
to reduce words to their root form, or [ASCII folding](/documentation/token-filters/ascii-folding) to remove accents.

Token filters can be added to any tokenizer besides the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer, which by definition
must preserve the source text exactly.

To add a token filter to a tokenizer, append a configuration string to the argument list:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('stemmer=english', 'ascii_folding=true')))
WITH (key_field='id');
```


# Stemmer
Source: https://docs.paradedb.com/documentation/token-filters/stemming

Reduces words to their root form for a given language

Stemming is the process of reducing words to their root form. In English, for example, the root form of "running" and "runs" is "run".
Stemming can be configured for any tokenizer besides the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer. Stemmers
in ParadeDB are based on stemming algorithms obtained from the official [Snowball website](https://snowballstem.org/).

To set a stemmer, append `stemmer=<language>` to the tokenizer's arguments.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('stemmer=english')))
WITH (key_field='id');
```

Valid languages are `arabic`, `czech`, `danish`, `dutch`, `english`, `finnish`, `french`, `german`, `greek`, `hungarian`, `italian`, `norwegian`, `polish`, `portuguese`, `romanian`, `russian`, `spanish`, `swedish`, `tamil`, and `turkish`.

To demonstrate this token filter, let's compare the output of the following two statements:

```sql theme={null}
SELECT
  'I am running'::pdb.simple::text[],
  'I am running'::pdb.simple('stemmer=english')::text[];
```

```ini Expected Response theme={null}
      text      |    text
----------------+------------
 {i,am,running} | {i,am,run}
(1 row)
```


# Remove Stopwords
Source: https://docs.paradedb.com/documentation/token-filters/stopwords

Remove language-specific stopwords from the index

Stopwords are words that are so common or semantically insignificant in most contexts that they can be ignored during indexing.
In English, for example, stopwords include "a", "and", "or", etc.

All tokenizers besides the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer can be configured to automatically remove stopwords
for one or more languages.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('stopwords_language=english')))
WITH (key_field='id');
```

Valid languages are `Czech`, `Danish`, `Dutch`, `English`, `Finnish`, `French`, `German`, `Hungarian`, `Italian`, `Norwegian`, `Polish`, `Portuguese`, `Russian`, `Spanish`, and `Swedish`. Language names are case-insensitive.

## Multiple Languages

For documents containing multiple languages, you can specify multiple stopword languages as a comma-separated list:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('stopwords_language=English,French')))
WITH (key_field='id');
```

```sql theme={null}
SELECT 'the quick fox and le renard et'::pdb.simple('stopwords_language=English,French')::text[];
```

```ini Expected Response theme={null}
        text
--------------------
 {quick,fox,renard}
(1 row)
```

## Example

To demonstrate this token filter, let's compare the output of the following two statements:

```sql theme={null}
SELECT
  'The cat in the hat'::pdb.simple::text[],
  'The cat in the hat'::pdb.simple('stopwords_language=English')::text[];
```

```ini Expected Response theme={null}
         text         |   text
----------------------+-----------
 {the,cat,in,the,hat} | {cat,hat}
(1 row)
```


# Token Length
Source: https://docs.paradedb.com/documentation/token-filters/token-length

Remove tokens that are above or below a certain byte length from the index

The token length filter automatically removes tokens that are above or below a certain length in bytes.
To remove all tokens longer than a certain length, append a `remove_long` configuration to the tokenizer:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('remove_long=100')))
WITH (key_field='id');
```

To remove all tokens shorter than a length, use `remove_short`:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple('remove_short=3')))
WITH (key_field='id');
```

All tokenizers besides the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer accept these configurations.

To demonstrate this token filter, let's compare the output of the following two statements:

```sql theme={null}
SELECT
  'A supersupersuperlong token'::pdb.simple::text[],
  'A supersupersuperlong token'::pdb.simple('remove_short=2', 'remove_long=10')::text[];
```

```ini Expected Response theme={null}
             text              |  text
-------------------------------+---------
 {a,supersupersuperlong,token} | {token}
(1 row)
```


# Trim
Source: https://docs.paradedb.com/documentation/token-filters/trim

Remove trailing and leading whitespace from a token

The trim filter removes leading and trailing whitespace from a token (but not whitespace in the middle). If a token consists
entirely of whitespace, the token is eliminated entirely.

This filter is useful for tokenizers that don't already split on whitespace, like the [literal normalized](/documentation/tokenizers/available-tokenizers/literal-normalized)
tokenizer or certain language-specific tokenizers.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.literal_normalized('trim=true')))
WITH (key_field='id');
```

To demonstrate this token filter, let's compare the output of the following two statements:

```sql theme={null}
SELECT
  '    token with whitespace   '::pdb.literal_normalized::text[],
  '    token with whitespace   '::pdb.literal_normalized('trim=true')::text[];
```

```ini Expected Response theme={null}
               text               |           text
----------------------------------+---------------------------
 {"    token with whitespace   "} | {"token with whitespace"}
(1 row)
```


# Chinese Compatible
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/chinese-compatible

A simple tokenizer for Chinese, Japanese, and Korean characters

The Chinese compatible tokenizer is like the [simple](/documentation/tokenizers/available-tokenizers/simple) tokenizer -- it lowercases non-CJK characters and splits on
any non-alphanumeric character. Additionally, it treats each CJK character as its own token.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.chinese_compatible))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Hello world! 你好!'::pdb.chinese_compatible::text[];
```

```ini Expected Response theme={null}
        text
---------------------
 {hello,world,你,好}
(1 row)
```


# ICU
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/icu

Splits text according to the Unicode standard

The ICU (International Components for Unicode) tokenizer breaks down text according to the Unicode standard. It can be used to tokenize most languages and recognizes the nuances in word boundaries across different languages.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.icu))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Hello world! 你好!'::pdb.icu::text[];
```

```ini Expected Response theme={null}
        text
--------------------
 {hello,world,你好}
(1 row)
```


# Jieba
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/jieba

The most advanced Chinese tokenizer that leverages both a dictionary and statistical models

The Jieba tokenizer is a tokenizer for Chinese text that leverages both a dictionary and statistical models. It is generally considered to be better at identifying ambiguous Chinese word boundaries
compared to the [Chinese Lindera](/documentation/tokenizers/available-tokenizers/lindera) and [Chinese compatible](/documentation/tokenizers/available-tokenizers/chinese-compatible) tokenizers, but
the tradeoff is that it is slower.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.jieba))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Hello world! 你好!'::pdb.jieba::text[];
```

```ini Expected Response theme={null}
              text
--------------------------------
 {hello," ",world,!," ",你好,!}
(1 row)
```


# Lindera
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/lindera

Uses prebuilt dictionaries to tokenize Chinese, Japanese, and Korean text

The Lindera tokenizer is a more advanced CJK tokenizer that uses prebuilt Chinese, Japanese, or Korean dictionaries to break text into meaningful tokens (words or phrases) rather than on individual characters.
Chinese Lindera uses the CC-CEDICT dictionary, Korean Lindera uses the KoDic dictionary, and Japanese Lindera uses the IPADIC dictionary.

By default, non-CJK text is lowercased, and punctuation is not ignored.
As of version 0.22.4, whitespace is removed by default. On earlier versions it is preserved.

<CodeGroup>
  ```sql Chinese Lindera theme={null}
  CREATE INDEX search_idx ON mock_items
  USING bm25 (id, (description::pdb.lindera(chinese)))
  WITH (key_field='id');
  ```

  ```sql Korean Lindera theme={null}
  CREATE INDEX search_idx ON mock_items
  USING bm25 (id, (description::pdb.lindera(korean)))
  WITH (key_field='id');
  ```

  ```sql Japanese Lindera theme={null}
  CREATE INDEX search_idx ON mock_items
  USING bm25 (id, (description::pdb.lindera(japanese)))
  WITH (key_field='id');
  ```
</CodeGroup>

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Hello world! 你好!'::pdb.lindera(chinese)::text[];
```

```ini Expected Response theme={null}
              text
------------------------
 {hello,world,!,你好,!}
(1 row)
```

## Keep Whitespace

By default, whitespace is not tokenized. To include it, set `keep_whitespace` to `true`.

```sql theme={null}
SELECT 'Hello world! 你好!'::pdb.lindera(chinese, 'keep_whitespace=true')::text[];
```

```ini Expected Response theme={null}
              text
--------------------------------
 {hello," ",world,!," ",你好,!}
(1 row)
```


# Literal
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/literal

Indexes the text in its raw form, without any splitting or processing

<Note>
  The literal tokenizer is not ideal for text search queries like
  [match](/documentation/full-text/match) or
  [phrase](/documentation/full-text/phrase). If you need to do text search over
  a field that is literal tokenized, consider using [multiple
  tokenizers](/documentation/tokenizers/multiple-per-field).
</Note>

<Note>
  Because the literal tokenizer preserves the source text exactly, [token
  filters](/documentation/token-filters/overview) cannot be configured for this
  tokenizer.
</Note>

The literal tokenizer applies no tokenization to the text, preserving it as-is. It is the default for `uuid` fields (since
exact UUID matching is a common use case), and is useful for doing exact string matching over text fields.

It is also required if the text field is used as a sort field in a [Top K](/documentation/sorting/topk) query,
or as part of an [aggregate](/documentation/aggregates/overview).

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.literal))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Tokenize me!'::pdb.literal::text[];
```

```ini Expected Response theme={null}
       text
------------------
 {"Tokenize me!"}
(1 row)
```


# Literal Normalized
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/literal-normalized

Like the literal tokenizer, but allows for token filters

<Note>
  For all patch versions greater than `0.20.8` in the `20` minor version, and
  all patch versions greater than `0.21.4` in the `21` minor version, fields
  using the [literal
  normalized](/documentation/tokenizers/available-tokenizers/literal-normalized)
  tokenizer are also columnar indexed. This means that they can be used in
  [aggregates](/documentation/aggregates/overview) and [Top K
  queries](/documentation/sorting/topk). Indexes created prior to these versions
  must be reindexed to use this feature.
</Note>

The literal normalized tokenizer is similar to the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer in that it does not split the source text.
All text is treated as a single token, regardless of how many words are contained.

However, unlike the literal tokenizer, this tokenizer allows [token filters](/documentation/token-filters/overview) to be applied. By default, the literal normalized tokenizer
also [lowercases](/documentation/token-filters/lowercase) the text.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.literal_normalized))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Tokenize me!'::pdb.literal_normalized::text[];
```

```ini Expected Response theme={null}
       text
------------------
 {"tokenize me!"}
(1 row)
```


# Ngram
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/ngrams

Splits text into small chunks called grams, useful for partial matching

The ngram tokenizer splits text into "grams," where each "gram" is of a certain length.

The tokenizer takes two arguments. The first is the minimum character length of a "gram," and the second is the maximum character length. Grams will be generated for all sizes between
the minimum and maximum gram size, inclusive. For example, `pdb.ngram(2,5)` will generate tokens of size `2`, `3`, `4`, and `5`.

To generate grams of a single fixed length, set the minimum and maximum gram size equal to each other.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.ngram(3,3)))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Tokenize me!'::pdb.ngram(3,3)::text[];
```

```ini Expected Response theme={null}
                      text
-------------------------------------------------
 {tok,oke,ken,eni,niz,ize,"ze ","e m"," me",me!}
(1 row)
```

## Ngram Prefix Only

The generate ngram tokens for only the first `n` characters in the text, set `prefix_only` to `true`.

```sql theme={null}
SELECT 'Tokenize me!'::pdb.ngram(3,3,'prefix_only=true')::text[];
```

```ini Expected Response theme={null}
 text
-------
 {tok}
(1 row)
```

## Phrase and Proximity Queries with Ngram

Because multiple ngram tokens can overlap, the ngram tokenizer does not store token positions. As a result,
queries that rely on token positions like [phrase](/documentation/full-text/phrase), [phrase prefix](/documentation/query-builder/phrase/phrase-prefix), [regex phrase](/documentation/query-builder/phrase/regex-phrase) and [proximity](/documentation/full-text/proximity) are not supported over ngram-tokenized
fields.

An exception is if the min gram size equals the max gram size, which guarantees unique token positions. In this case, setting
`positions=true` enables these queries.

```sql theme={null}
SELECT 'Tokenize me!'::pdb.ngram(3,3,'positions=true')::text[];
```

### Exact Substring Matching with Phrase Queries

With `positions=true`, [phrase queries](/documentation/full-text/phrase) over ngram fields perform exact substring matching.
This is faster than using [match conjunction](/documentation/full-text/match#match-conjunction) on an ngram field, which
creates a `Must` clause for every ngram token and intersects them independently. A phrase query uses a single positional
intersection instead.

The tradeoff is that phrase queries are stricter: they require tokens at consecutive positions within a single field value,
while match conjunction only requires all tokens to appear somewhere in the document.

```sql theme={null}
CREATE TABLE books (id SERIAL PRIMARY KEY, titles TEXT[]);
INSERT INTO books (titles) VALUES
    (ARRAY['The Dragon Hatchling', 'Wings of Gold']),
    (ARRAY['Dragon Slayer', 'Hatchling Care']);

CREATE INDEX ON books
USING bm25 (id, (titles::pdb.ngram(4,4,'positions=true')))
WITH (key_field='id');

-- Phrase: matches exact substring "Dragon Hatchling" — only row 1
SELECT * FROM books WHERE titles ### 'Dragon Hatchling';

-- Match conjunction: matches all ngrams anywhere — also only row 1 here,
-- but on larger datasets could match rows where the ngrams are scattered
SELECT * FROM books WHERE titles ||| 'Dragon Hatchling';

DROP TABLE books;
```

When constructing queries as JSON, use `tokenized_phrase` to achieve the same
result as the `###` operator. It tokenizes the input string with the field's tokenizer and builds
a phrase query from the resulting tokens:

```json theme={null}
{ "tokenized_phrase": { "field": "titles", "phrase": "Dragon Hatchling" } }
```


# Regex Patterns
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/regex

Tokenizes text using a regular expression

The `regex_pattern` tokenizer tokenizes text using a regular expression. The regular expression can be specified with the pattern parameter.
For instance, the following tokenizer creates tokens only for words starting with the letter `h`:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.regex_pattern('(?i)\bh\w*')))
WITH (key_field='id');
```

The regex tokenizer uses the Rust [regex](https://docs.rs/regex/latest/regex/) crate, which supports all regex constructs with the following
exceptions:

1. Lazy quantifiers such as `+?`
2. Word boundaries such as `\b`

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Hello world!'::pdb.regex_pattern('(?i)\bh\w*')::text[];
```

```ini Expected Response theme={null}
  text
---------
 {hello}
(1 row)
```


# Simple
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/simple

Splits on any non-alphanumeric character

The simple tokenizer splits on any non-alphanumeric character (e.g. whitespace, punctuation, symbols). All characters are
[lowercased](/documentation/token-filters/lowercase) by default.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.simple))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Tokenize me!'::pdb.simple::text[];
```

```ini Expected Response theme={null}
     text
---------------
 {tokenize,me}
(1 row)
```


# Source Code
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/source-code

Tokenizes text that is actually code

The source code tokenizer is intended for tokenizing code. In addition to splitting on whitespace,
punctuation, and symbols, it also splits on common casing conventions like camel case and snake case. For instance, text like
`my_variable` or `myVariable` would get split into `my` and `variable`.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.source_code))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'let my_variable = 2;'::pdb.source_code::text[];
```

```ini Expected Response theme={null}
        text
---------------------
 {let,my,variable,2}
(1 row)
```


# Unicode
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/unicode

The default text tokenizer in ParadeDB

The unicode tokenizer splits text according to word boundaries defined by the [Unicode Standard Annex #29](https://www.unicode.org/reports/tr29/)
rules. All characters are [lowercased](/documentation/token-filters/lowercase) by default.

This tokenizer is the default text tokenizer. If no tokenizer is specified for a text field, the unicode tokenizer will be used
(unless the text field is the [key field](/documentation/indexing/create-index#choosing-a-key-field), in which case the text is not tokenized).

```sql theme={null}
-- The following two configurations are equivalent
CREATE INDEX search_idx ON mock_items
USING bm25 (id, description)
WITH (key_field='id');

CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.unicode_words))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Tokenize me!'::pdb.unicode_words::text[];
```

```ini Expected Response theme={null}
     text
---------------
 {tokenize,me}
(1 row)
```

## Remove Emojis

By default, emojis in the source text are preserved. To remove emojis, set `remove_emojis` to `true`.

```sql theme={null}
SELECT 'Tokenize me! 😊'::pdb.unicode_words('remove_emojis=true')::text[];
```

```ini Expected Response theme={null}
     text
---------------
 {tokenize,me}
(1 row)
```


# Whitespace
Source: https://docs.paradedb.com/documentation/tokenizers/available-tokenizers/whitespace

Tokenizes text by splitting on whitespace

The whitespace tokenizer splits only on whitespace. It also [lowercases](/documentation/token-filters/lowercase) characters by default.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.whitespace))
WITH (key_field='id');
```

To get a feel for this tokenizer, run the following command and replace the text with your own:

```sql theme={null}
SELECT 'Tokenize me!'::pdb.whitespace::text[];
```

```ini Expected Response theme={null}
      text
----------------
 {tokenize,me!}
(1 row)
```


# Multiple Tokenizers Per Field
Source: https://docs.paradedb.com/documentation/tokenizers/multiple-per-field

Apply different token configurations to the same field

In many cases, a text field needs to be tokenized multiple ways. For instance, using the [unicode](/documentation/tokenizers/available-tokenizers/unicode)
tokenizer for search, and the [literal](/documentation/tokenizers/available-tokenizers/literal) tokenizer for [Top K ordering](/documentation/sorting/topk).

To tokenize a field in more than one way, append an `alias=<alias_name>` argument to the additional tokenizer configurations.
The alias name can be any string you like. For instance, the following statement tokenizes `description` using both the simple and literal tokenizers.

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (
  id,
  (description::pdb.literal),
  (description::pdb.simple('alias=description_simple'))
) WITH (key_field='id');
```

Under the hood, two distinct fields are created in the index: a field called `description`, which uses the literal tokenizer,
and an aliased field called `description_simple`, which uses the simple tokenizer.

To query against the aliased field, cast it to `pdb.alias('alias_name')`:

<CodeGroup>
  ```sql SQL theme={null}
  -- Query against `description_simple`
  SELECT description, rating, category
  FROM mock_items
  WHERE description::pdb.alias('description_simple') ||| 'Sleek running shoes';

  -- Query against `description`
  SELECT description, rating, category
  FROM mock_items
  WHERE description ||| 'Sleek running shoes';
  ```

  ```python Django theme={null}
  from paradedb import Match, ParadeDB

  # Query against `description_simple`
  MockItem.objects.extra(
      where=["(description::pdb.alias('description_simple')) ||| 'Sleek running shoes'"]
  ).values('description', 'rating', 'category')

  # Query against `description`
  MockItem.objects.filter(
      description=ParadeDB(Match('Sleek running shoes', operator='OR'))
  ).values('description', 'rating', 'category')
  ```

  ```python SQLAlchemy theme={null}
  from sqlalchemy import select
  from sqlalchemy.orm import Session
  from paradedb.sqlalchemy import pdb, search

  # Query against `description_simple`
  stmt_alias = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(pdb.alias(MockItem.description, "description_simple"), "Sleek running shoes"))
  )

  # Query against `description`
  stmt = (
      select(MockItem.description, MockItem.rating, MockItem.category)
      .where(search.match_any(MockItem.description, "Sleek running shoes"))
  )

  with Session(engine) as session:
      {
          "rows_alias": session.execute(stmt_alias).all(),
          "rows": session.execute(stmt).all(),
      }
  ```

  ```ruby Rails theme={null}
  # Query against `description_simple`
  MockItem.search(:description_simple)
          .matching_any("Sleek running shoes")
          .select(:description, :rating, :category)

  # Query against `description`
  MockItem.search(:description)
          .matching_any("Sleek running shoes")
          .select(:description, :rating, :category)
  ```
</CodeGroup>

<Note>
  If a text field uses multiple tokenizers and one of them is [literal](/documentation/tokenizers/available-tokenizers/literal), we recommend aliasing
  the other tokenizers and leaving the literal tokenizer un-aliased. This is so queries that `GROUP BY`, `ORDER BY`, or aggregate the
  text field can reference the field directly:

  ```sql SQL theme={null}
  CREATE INDEX search_idx ON mock_items
  USING bm25 (
    id,
    (description::pdb.literal),
    (description::pdb.simple('alias=description_simple'))
  ) WITH (key_field='id');

  SELECT description, rating, category
  FROM mock_items
  WHERE description @@@ 'shoes'
  ORDER BY description
  LIMIT 5;
  ```
</Note>


# How Tokenizers Work
Source: https://docs.paradedb.com/documentation/tokenizers/overview

Tokenizers split large chunks of text into small, searchable units called tokens

Before text is indexed, it is first split into searchable units called tokens.

The default tokenizer in ParadeDB is the [unicode\_words tokenizer](/documentation/tokenizers/available-tokenizers/unicode). It splits text according to word boundaries defined by the Unicode Standard Annex #29 rules. All characters are lowercased by default. To visualize how this tokenizer works, you can cast a text string to the tokenizer type, and then to `text[]`:

```sql theme={null}
SELECT 'Hello world!'::pdb.unicode_words::text[];
```

```ini Expected Response theme={null}
     text
---------------
 {hello,world}
(1 row)
```

On the other hand, the [ngrams](/documentation/tokenizers/available-tokenizers/ngrams) tokenizer splits text into "grams" of size `n`. In this example, `n = 3`:

```sql theme={null}
SELECT 'Hello world!'::pdb.ngram(3,3)::text[];
```

```ini Expected Response theme={null}
                      text
-------------------------------------------------
 {hel,ell,llo,"lo ","o w"," wo",wor,orl,rld,ld!}
(1 row)
```

Choosing the right tokenizer is crucial to getting the search results you want. For instance, the simple tokenizer works best for whole-word matching like "hello" or "world", while the ngram tokenizer enables partial matching.

To configure a tokenizer for a column in the index, simply cast it to the desired tokenizer type:

```sql theme={null}
CREATE INDEX search_idx ON mock_items
USING bm25 (id, (description::pdb.ngram(3,3)))
WITH (key_field='id');
```


# Search Tokenizer
Source: https://docs.paradedb.com/documentation/tokenizers/search-tokenizer

Use a different tokenizer at search time than at index time

By default, ParadeDB uses the same tokenizer at both index time and search time. This makes sense for most cases — you want queries
tokenized the same way the data was indexed.

But sometimes you need different tokenizers. The classic example is **autocomplete**:

* **Index time** — edge ngram: `"shoes"` → `s`, `sh`, `sho`, `shoe`, `shoes`
* **Search time** — unicode: `"sho"` → `sho`

If you used edge ngram at search time too, typing `"sho"` would produce `s`, `sh`, `sho` — matching far too many documents.

## Usage

Set `search_tokenizer` as a `WITH` option on the index to define a default search-time tokenizer for all text and JSON fields:

```sql theme={null}
CREATE INDEX search_idx ON products
USING bm25 (
  id,
  (title::pdb.ngram(1, 10, 'prefix_only=true'))
) WITH (key_field='id', search_tokenizer='unicode_words');
```

With this configuration:

* **Index time**: `title` is tokenized with edge ngram to create prefix tokens
* **Search time**: queries against `title` automatically use the unicode tokenizer

The `search_tokenizer` value can include parameters, e.g. `search_tokenizer='simple(lowercase=false)'`.

Because `search_tokenizer` only affects query-time behavior, you can change it without reindexing:

```sql theme={null}
ALTER INDEX search_idx SET (search_tokenizer = 'simple(lowercase=false)');
```

## Example

```sql theme={null}
CREATE TABLE products (
    id serial8 NOT NULL PRIMARY KEY,
    title text
);
INSERT INTO products (title) VALUES
    ('shoes'), ('shirt'), ('shorts'), ('shoelaces'), ('socks');

CREATE INDEX idx_products ON products USING bm25
    (id, (title::pdb.ngram(1, 10, 'prefix_only=true')))
    WITH (key_field = 'id', search_tokenizer = 'unicode_words');

-- "sho" stays as one token → matches shoes, shorts, shoelaces
SELECT id, title FROM products WHERE title ||| 'sho' ORDER BY id;

-- "s" stays as one token → matches all five titles
SELECT id, title FROM products WHERE title ||| 's' ORDER BY id;
```

Without `search_tokenizer`, the query `'sho'` would be edge-ngrammed into `s`, `sh`, `sho` and match
every title starting with `s` — not just those starting with `sho`.

## Overriding at Query Time

You can still override the search tokenizer for a specific query by casting the query string:

```sql theme={null}
-- Force edge ngram tokenization at query time
SELECT id, title FROM products WHERE title ||| 'sho'::pdb.ngram(1, 10, 'prefix_only=true') ORDER BY id;
```

## Priority

When resolving which tokenizer to use at search time, ParadeDB checks in this order:

1. **Query-level cast** — e.g. `'sho'::pdb.ngram(...)` (highest priority)
2. **Index-level WITH option** — e.g. `WITH (search_tokenizer='unicode_words')`
3. **Index-time tokenizer** — the tokenizer used to build the index (fallback)

## Supported Tokenizers

Any [available tokenizer](/documentation/tokenizers/overview) can be used as a `search_tokenizer`:
`unicode_words`, `simple`, `whitespace`, `ngram`, `literal`, `literal_normalized`, `chinese_compatible`,
`lindera`, `icu`, `jieba`, `source_code`.


# Integrate with AI
Source: https://docs.paradedb.com/welcome/ai-agents

Teach your coding assistant to use ParadeDB

Before getting started, let's give your coding agent full context of ParadeDB by adding the ParadeDB agent skill.

```bash theme={null}
npx skills add paradedb/agent-skills
```

This installs `paradedb-skill` into your agent's skills directory (for example, Codex uses `$CODEX_HOME/skills/paradedb-skill`) and works with all major
coding assistants like Claude Code, Cursor, Codex, Windsurf, Gemini, and more.

For manual and tool-specific setup instructions, see the [agent-skills repository](https://github.com/paradedb/agent-skills).

## MCP Integration

ParadeDB documentation is available via the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) for direct integration with MCP-compatible agents.

**MCP Endpoint:**

```
https://docs.paradedb.com/mcp
```

This allows MCP-enabled tools to query ParadeDB documentation programmatically and provide contextual assistance.


# Architecture
Source: https://docs.paradedb.com/welcome/architecture

A deep dive into how ParadeDB is built on Postgres

ParadeDB introduces modern query execution paths and data structures, optimized for high-ingest search and analytics workloads, to Postgres.

## Custom Index

<img alt="Custom Index Architecture" />

In Postgres, indexes provide alternative data structures for accessing the data in a table (which Postgres calls a "heap table") more efficiently.
ParadeDB introduces a custom index called the *BM25 index*.

When a table row is inserted or updated, the BM25 index is immediately notified. These changes are recorded as part of the current transaction, ensuring that index updates are real-time.

## Data Model

<img alt="Data Model" />

The BM25 index is laid out as an [LSM tree](#lsm-tree), where each segment in the tree consists of both an inverted index and columnar index.
The inverted and columnar indexes optimize for fast reads, while the LSM tree optimizes for high-frequency writes.

### Inverted Index

An inverted index is a structure that maps each term (i.e., tokenized word) to a list of documents that contain that term (called a "postings list") along with metadata like term frequency and document frequency. This structure allows ParadeDB to efficiently retrieve all documents matching a particular search term or phrase without scanning the entire table.

### Columnar Index

Alongside the inverted index, ParadeDB also maintains a structure that stores fields in a column-oriented format. Columnar formats are standard
for analytical (i.e. OLAP) databases because they store values contiguously and enable efficient scans over large datasets compared to Postgres'
row-oriented layout. All text fields which use the [literal](/documentation/tokenizers/available-tokenizers/literal) or [literal normalized](/documentation/tokenizers/available-tokenizers/literal-normalized) tokenizer, or are non-text,
are stored in the columnstore.

In Tantivy these structures are referred to as [fast fields](https://docs.rs/tantivy/latest/tantivy/fastfield/index.html), but they are largely transparent in ParadeDB.

### LSM Tree

To support real-time updates, the BM25 index uses a [Log-Structured Merge (LSM) tree](https://en.wikipedia.org/wiki/Log-structured_merge-tree).

An LSM tree is a write-optimized data structure commonly used in systems like RocksDB and Cassandra. The core idea behind an LSM tree is to turn random writes into sequential ones. Incoming writes are first stored in an in-memory buffer, which is fast to update. Once the buffer fills up or the current statement finishes, it is flushed to disk as an immutable "segment" file.

These segment files are organized by size into layers or levels. Newer data is written to the topmost layer. Over time, data is gradually pushed down into lower levels through a process called merging or compaction, where data from smaller segments is merged, deduplicated, and rewritten into larger segments.

In ParadeDB, every `INSERT`/`UPDATE`/`COPY` statement creates a new segment. Each segment has its own inverted index and columnar index, which means that the BM25 index
is actually a collection of many inverted/columnar indexes, each of which allows for very dense intersection queries to rapidly filter matches.

## Query Execution

### Custom Operators

ParadeDB introduces several new text search operators to Postgres. For example, `|||` is used for [match disjunction](/documentation/full-text/match) queries, whereas `###`
is for [phrase](/documentation/full-text/phrase) queries.

```sql theme={null}
SELECT * FROM mock_items
WHERE description ||| 'running shoes';
```

ParadeDB’s custom query execution paths are only triggered when at least one of ParadeDB's operators is present in the query. Otherwise, it is executed entirely by native Postgres.

### Custom Scan

Whenever a ParadeDB operator is present in a query, ParadeDB will execute the query using a [custom scan](https://www.postgresql.org/docs/current/custom-scan.html).

Custom scans are execution nodes set aside by Postgres that allow extensions to run custom logic during a query. They are more powerful and versatile than typical Postgres index scans because they
allow the extension to "take over" large parts of the query, including aggregates, `WHERE`, and even [`GROUP BY` clauses](/welcome/roadmap#analytics).

From a performance perspective, custom scans significantly speed up queries by pushing down filters, aggregates, and other operations directly into the index, rather than applying them afterward in separate phases.

To understand what kind of scan is used, run `EXPLAIN`:

```sql theme={null}
-- Native Postgres scan, no ParadeDB operator
EXPLAIN SELECT * FROM mock_items
WHERE description = 'running shoes' AND rating <= 5;

-- Custom scan, ParadeDB operator used
EXPLAIN SELECT * FROM mock_items
WHERE description ||| 'running shoes' AND rating <= 5;
```

As a rule of thumb: if `EXPLAIN` shows a custom scan (or, in rare cases, a BM25 index scan), then that part of query is going through ParadeDB. Otherwise, the query passes through standard Postgres.

### Parallelization

For queries that need to read large amounts of data like [Top K](/documentation/sorting/topk) or aggregate queries, the custom scan automatically spawns additional workers to execute the query
in parallel. To see if a query was parallelized, run `EXPLAIN ANALYZE`:

```sql theme={null}
-- Top K queries may be parallelized
EXPLAIN ANALYZE SELECT * FROM mock_items
WHERE description ||| 'running shoes'
ORDER BY rating LIMIT 5;
```

<Note>
  Parallelization also depends on the [number of available
  workers](/documentation/performance-tuning/reads).
</Note>

Parallel workers are another reason why the BM25 index is significantly faster than Postgres' native text search and aggregates,
which are mostly not capable of parallelization.

## Design Philosophy

* **Keep it Boring**. Use robust extension points in Postgres vs. hacking around the internals. Adopt battle-tested tools, like industry standard file formats and query engine libraries, instead of cutting-edge but less-proven alternatives.
* **Behave Exactly Like Postgres**. This extends from user-facing aspects, like the SQL query syntax and ORM compatibility, all the way down to low-level integrations with Postgres' storage system and query planner.
* **Works Out of the Box**. Users should be able to get satisfying search results and performance with minimal tuning or configuration.

## Dependencies

The three main dependencies of `pg_search` are:

* [`pgrx`](https://github.com/pgcentralfoundation/pgrx/tree/develop) — the library for writing Postgres extensions in Rust
* [Tantivy](https://github.com/quickwit-oss/tantivy) — a Rust-based full-text search library inspired by [Lucene](https://github.com/apache/lucene)
* [Apache DataFusion](https://github.com/apache/datafusion) — an extensible query execution framework for OLAP processing


# Guarantees
Source: https://docs.paradedb.com/welcome/guarantees

ParadeDB ensures ACID compliance, concurrency, data integrity, and replication safety

### ACI(D)

All reads and writes go through Postgres’ transaction engine. This means that inserts, updates, and deletes to indexed columns are atomic, consistent, and respect Postgres' [isolation levels](https://www.postgresql.org/docs/current/transaction-iso.html).

Durability — the "D" in ACID — means that once a transaction is committed, its changes will survive crashes or failovers. In PostgreSQL, this guarantee is provided by the write-ahead log (WAL), which ensures that all changes are safely recorded before being applied to disk.

[ParadeDB Community](https://github.com/paradedb/paradedb) does **not** write to the WAL, and therefore does not guarantee durability in the face of crashes. For production use cases that require full durability, [ParadeDB Enterprise](/deploy/enterprise) — a closed-source fork of ParadeDB for enterprise customers — includes full WAL integration.

### Concurrency

ParadeDB is designed to support concurrent reads and writes in the same way that Postgres does — by adhering to Postgres' [multi-version
concurrency control (MVCC)](https://www.postgresql.org/docs/current/mvcc.html) rules. We maintain an internal testing suite that rigorously measures the read and write throughput of the BM25
index under concurrent load.

Both read and write throughput under concurrent load can be improved by tuning Postgres' settings. For instance, read throughput can be improved
by configuring the [`max_parallel_workers` pool](/documentation/performance-tuning/reads#raise-parallel-workers) and [buffer cache size](/documentation/performance-tuning/reads#raise-shared-buffers),
whereas writes can be improved by increasing [per-statement memory](/documentation/performance-tuning/writes#increase-memory-for-bulk-updates).

### Correctness vs. Performance

While ParadeDB optimizes heavily around performance, there are some situations where the database can squeeze more performance by relaxing correctness
constraints. In these cases, ParadeDB — like Postgres — will guarantee correctness, even if it comes at the cost of slower query execution.

### Replication Safety

ParadeDB distinguishes between logical replication and physical replication.

Logical replication refers to replicating changes from a standard Postgres primary (e.g. AWS RDS) into a ParadeDB instance. This is commonly used when ParadeDB acts as a search node built from upstream Postgres changes.

Physical replication refers to running ParadeDB itself in a multi-node, high-availability (HA) setup using write-ahead log (WAL) shipping.

[ParadeDB Community](https://github.com/paradedb/paradedb) supports logical replication, but not physical replication:

* It can act as a logical replica, ingesting changes from a Postgres primary and indexing them transactionally.
* The BM25 index does not get physically replicated and won't be available on other nodes in a high availability setup.

[ParadeDB Enterprise](/deploy/enterprise) supports both:

* It can act as a logical replica, ingesting changes from a Postgres primary and indexing them transactionally.
* It supports physical replication and high availability, ensuring that the BM25 index remains consistent and crash-safe across nodes.

If your deployment requires high availability, or failover, we recommend using [ParadeDB Enterprise](/deploy/enterprise).

### Data Integrity

All data inserted into the BM25 index must conform to the column’s declared type. ParadeDB relies on Postgres’ type system and input/output functions to ensure validity. For example, invalid data will result in a Postgres error at insert time, not at query time.


# Simple, Elastic-Quality Search for Postgres
Source: https://docs.paradedb.com/welcome/introduction

ParadeDB is the modern Elastic alternative built as a Postgres extension.

<img alt="ParadeDB Banner" />

## Who is ParadeDB for?

You are likely a good fit for ParadeDB if you identify with the following:

1. Your **primary database is Postgres**, either managed (e.g. AWS RDS) or self-managed
2. You **have used Postgres' built-in search** capabilities via `tsvector` and the GIN index, but have reached a scale where you're limited by **performance bottlenecks** or **missing features** like BM25 scoring or fuzzy search
3. You are evaluating a search engine like Elasticsearch, but **don't want to introduce another cumbersome dependency** to your stack

## Why ParadeDB?

For teams that already use Postgres, ParadeDB is the simplest way to bring Elastic-quality search to your application.

### Zero ETL Required

Syncing Postgres with an external search engine like Elastic can be a time-consuming, error-prone process that involves babysitting ETL pipelines
and debugging data inconsistency issues. ParadeDB eliminates this class of problems because you can:

* [Install](/deploy/self-hosted/extension) the ParadeDB extension directly inside your Postgres, if it is self-managed
* [Run ParadeDB as a logical replica](/deploy/logical-replication/getting-started) of your primary Postgres, if you use managed Postgres providers like RDS

### Search That Feels Like Postgres

In ParadeDB, writing a search query is as simple as writing SQL. ParadeDB supports JOINs, which removes the complexity of denormalizing your existing schema.

### As Reliable As Postgres

ParadeDB supports Postgres transactions and ACID guarantees. This means that data is searchable immediately
after it's written to ParadeDB, and durable thanks to Postgres write-ahead logging.

## ParadeDB vs. Alternatives

People usually compare ParadeDB to two other types of systems: OLTP databases like vanilla Postgres and search engines like Elastic.

|                             | **OLTP database**                                                        | **Search engine**                                                                                      | **ParadeDB**                                                                                                              |
| --------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| **Primary role**            | System of record                                                         | Search and retrieval engine                                                                            | System of record **and** search/analytics engine                                                                          |
| **Examples**                | Postgres, MySQL                                                          | Elasticsearch, OpenSearch                                                                              |                                                                                                                           |
| **Search features**         | Basic FTS (no BM25, weak ranking)                                        | Rich search features (BM25, fuzzy matching, faceting, hybrid search)                                   | Rich search features (BM25, fuzzy matching, faceting, hybrid search)                                                      |
| **Analytics features**      | Not an analytical DB (no column store, batch processing, etc.)           | Column store, batch processing, parallelization via sharding                                           | Column store, batch processing, parallelization via Postgres [parallel workers](/documentation/performance-tuning/writes) |
| **Lag**                     | None in a single cluster                                                 | At least network, ETL transformation, and indexing time                                                | None in a single cluster                                                                                                  |
| **Operational complexity**  | Simple (single datastore)                                                | Complex (ETL pipelines, managing multiple systems)                                                     | Simple (single datastore)                                                                                                 |
| **Scalability**             | Vertical scaling in a single node, horizontal scaling through Kubernetes | Horizontal scaling through sharding                                                                    | Vertical scaling in a single node, horizontal scaling through [Kubernetes](/deploy/self-hosted/kubernetes)                |
| **Language**                | SQL                                                                      | Custom DSL                                                                                             | Standard SQL with custom search operators                                                                                 |
| **ACID guarantees**         | Full ACID compliance, read-after-write guarantees                        | No transactions, atomic only per-document, eventual consistency, durability not guaranteed until flush | Full ACID compliance, read-after-write guarantees                                                                         |
| **Update & delete support** | Built for fast-changing data                                             | Struggles with updates/deletes                                                                         | Built for fast-changing data                                                                                              |

## Production Readiness

As a company, ParadeDB is over two years old. ParadeDB launched in the [Y Combinator (YC)](https://ycombinator.com) S23 batch and has been validated in
production since December 2023.

[ParadeDB Community](https://github.com/paradedb/paradedb), the open-source version of ParadeDB, has been deployed over 700,000 times.
ParadeDB Enterprise, the durable and production-hardened edition of ParadeDB, powers core search and analytics use cases at enterprises ranging from Fortune 500s to fast-growing startups. A few
examples include:

* **Alibaba Cloud**, the largest Asia-Pacific cloud provider, uses ParadeDB to power search inside their data warehouse. [Case study available](https://www.paradedb.com/customers/case-study-alibaba).
* **Bilt Rewards**, a rent payments technology company that processed over \$36B in payments in 2024. [Case study available](https://www.paradedb.com/customers/case-study-bilt).
* **Modern Treasury**, a financial technology company that automates the full cycle of money movement. [Case study available](https://www.paradedb.com/customers/case-study-modern-treasury).
* **Span**<sup>1</sup>, one of the fastest-growing AI developer productivity platforms.
* **TCDI**<sup>1</sup>, a giant in the legal software and litigation management space.

*1. Case study coming soon.*

## Next Steps

You're now ready to jump into our guides.

<CardGroup>
  <Card title="Getting Started" icon="forward-fast" href="/documentation/getting-started/install">
    Get started with ParadeDB in under five minutes.
  </Card>

  <Card title="Architecture" icon="diagram-project" href="/welcome/architecture">
    Learn how ParadeDB is built.
  </Card>

  <Card title="Reference" icon="magnifying-glass" href="/documentation/full-text/overview">
    API reference for full text search and analytics.
  </Card>

  <Card title="Deploy" icon="server" href="/deploy/overview">
    Deploy ParadeDB as a Postgres extension or standalone database.
  </Card>
</CardGroup>


# Limitations & Tradeoffs
Source: https://docs.paradedb.com/welcome/limitations

Understand ParadeDB's key limitations and tradeoffs

## Distributed Workloads

ParadeDB is designed to scale vertically on a single Postgres node with potentially many read replicas, and many production deployments comfortably operate in the 1–10TB range. The largest single ParadeDB database we’ve seen in production is 10TB.

For datasets that significantly exceed this scale, ParadeDB supports partitioned tables and can be deployed in sharded Postgres configurations. ParadeDB is fully compatible with [Citus](https://github.com/citusdata/citus) for distributed search workloads — you can create BM25 indexes on distributed tables and run search queries across shards. See our [Citus deployment guide](/deploy/citus) for more details.

If you're working with very large datasets, please [reach out to us](mailto:support@paradedb.com). We'd be happy to provide guidance and share our roadmap for future distributed query support.

## Join Support

ParadeDB supports all PostgreSQL `JOIN` types. As of v0.22.0, ParadeDB includes [join pushdown](/documentation/joins/overview) (beta) for `INNER`, `SEMI`, and `ANTI` joins, which pushes search predicates directly into the index for significantly better performance. Other join types work correctly but fall back to standard Postgres execution — pushdown support for these is coming soon. See the [joins guide](/documentation/joins/overview) for more details.

## Covering Index

The BM25 index in ParadeDB is a covering index, which means it stores all indexed columns inside a single index per table. This
decision is intentional -- by colocating all the relevant data, ParadeDB optimizes for fast reads and boolean conditions.

However, this means that all columns must be defined up front at index creation time. Adding or removing columns requires a `REINDEX`.

## DDL Replication

A commonly known limitation of Postgres logical replication is that DDL (Data Definition Language) statements are not replicated. This includes operations like `CREATE TABLE` or `CREATE INDEX`.

If ParadeDB is running as a logical replica of a primary Postgres, DDL statements from the primary must be executed manually on the replica.
We recommend version-controlling your schema changes and applying them in a coordinated, repeatable way — either through a migration tool or deployment automation — to keep source and target databases in sync. See the [logical replication guide](/deploy/logical-replication/getting-started) for more details.


# Roadmap
Source: https://docs.paradedb.com/welcome/roadmap

The main features that we are currently working on

We're a lean team that likes to ship at [incredibly high velocity](https://github.com/paradedb/paradedb/releases).

## In Progress

### JOIN Improvements

* **Join pushdown (beta)**. [Join pushdown](/documentation/joins/overview) is available for `INNER`, `SEMI`, and `ANTI` joins, pushing search predicates directly into the index for significantly better performance.
* **Scoring and highlighting across JOINs**. BM25 score and snippet functions can be used in `JOIN` queries.
* **Smarter JOIN planning for search indexes**. Apply index-aware optimizations and cost estimation strategies when multiple BM25-indexed tables are joined.
* **More join types for pushdown**. Extending pushdown support to `LEFT`, `RIGHT`, `FULL OUTER`, `CROSS`, and `LATERAL` joins.

### Ecosystem Integrations

* **ORMs**. Official support for more ORMs, like Prisma and others, is coming. [Django](https://github.com/paradedb/django-paradedb), [Rails](https://github.com/paradedb/rails-paradedb), and [SQLAlchemy](https://github.com/paradedb/sqlalchemy-paradedb) are already available.
* **AI Frameworks**. Official support for LangChain, LLamaIndex, CrewAI, and others are coming.
* **PaaS Providers**. Official tutorials for hosting ParadeDB on more platform-as-a-service providers like Porter.run and others is coming. [Railway](/deploy/cloud-platforms/railway), [Render](/deploy/cloud-platforms/render), and [DigitalOcean](/deploy/cloud-platforms/digitalocean) are already available.

## Long Term

### Deeper Analytics Improvements

* **Push Postgres visibility rules into the index**. This is currently a filter applied post index scan that adds overhead to large scans.
* **DataFusion-powered aggregates**. Migrate aggregate query execution from Tantivy to Apache DataFusion to broaden SQL aggregate coverage and improve performance.

### Vector Search Improvements

* Improve vector search performance in Postgres by addressing pgvector's limitations around filtered queries — specifically, queries that combine vector similarity with metadata filters or full-text search predicates.

### Managed Cloud

* Today, you can [deploy ParadeDB](/deploy/overview) self-hosted, on cloud platforms, or with ParadeDB BYOC. We are working on a fully managed cloud offering, with a focus on scalability and supporting distributed workloads.

## Completed

### Analytics

* **A custom scan node for aggregates**. This will allow "plain SQL" aggregates to go through the same fast execution path as
  our [aggregate UDFs](/documentation/aggregates/tantivy), further accelerating aggregates like `COUNT`, and SQL clauses like `GROUP BY`.

### Write Throughput

* **Background merging**. Improves write performance by merging index segments asynchronously without blocking inserts.
* **Pending list**. Buffers recent write before flushing them to the LSM tree.

### Improved UX

* **More intuitive index configuration**. Overhaul the complicated JSON `WITH` index options.
* **More ORM friendly**. Overhaul the [query builder functions](/documentation/query-builder/overview) to use actual column references instead of string literals.
* **New operators**. In addition to the existing `@@@` operator, introduce new operators for different query types (e.g. phrase, term, conjunction/disjunction).

## We're Hiring

We're tackling some of the hardest and (in our opinion) most impactful problems in Postgres. If you want to be a part of it,
please check out our [open roles](https://paradedb.notion.site)!


# Help and Support
Source: https://docs.paradedb.com/welcome/support

How to obtain support for ParadeDB

For questions regarding enterprise support or commercial licensing, please [contact sales](mailto:sales@paradedb.com).
For community support and general questions, please join the [ParadeDB Community Slack](https://www.paradedb.com/slack).

## Ask a Question

Use the **"Ask a question..."** bar at the bottom of any page to get instant answers about ParadeDB. The AI assistant has full context of the documentation and can help with queries, troubleshooting, and best practices.


# ParadeDB BYOC
Source: https://docs.paradedb.com/deploy/byoc

Deploy ParadeDB Bring Your Own Cloud (BYOC) within your cloud environment

<Info>
  For access to ParadeDB BYOC, [contact sales](mailto:sales@paradedb.com).
</Info>

ParadeDB BYOC (Bring Your Own Cloud) is a managed deployment of ParadeDB within your cloud environment.
It combines the benefits of a managed platform with the security posture of a self-hosted deployment.

ParadeDB BYOC is supported on GCP and AWS, including GovCloud regions and airgapped environments.
To request access for Azure, Oracle Cloud, or another cloud platform please contact [sales@paradedb.com](mailto:sales@paradedb.com).

## How BYOC Works

ParadeDB BYOC provisions a Kubernetes cluster in your cloud environment with [high availability](/deploy/self-hosted/high-availability) preconfigured.
It also configures [logical replication](/deploy/logical-replication/getting-started) with your primary Postgres, backups, connection pooling, monitoring, access control, and audit logging.

ParadeDB BYOC can be deployed and managed in one of two ways:

* **Fully Managed**: ParadeDB will deploy and manage the ParadeDB BYOC module for you. ParadeDB requires a sub-account or project within your cloud provider via an IAM user or a service account.
* **Just-in-Time Managed**: You will deploy the ParadeDB BYOC module and can choose to provide just-in-time access to the ParadeDB team when support is required. This is typically useful for airgapped environments.

<img alt="ParadeDB BYOC Topology" />

## Getting Started

This section assumes that you have received access to the ParadeDB BYOC module and are deploying it yourself on AWS or GCP.
In a fully managed deployment, these steps will be performed by ParadeDB on your behalf.

### Install Dependencies

First, ensure that you are in the BYOC module repository. Next, install Terraform, Kubectl, PostgreSQL, and the CLI for your desired cloud provider:

<CodeGroup>
  ```bash macOS theme={null}
  brew install terraform kubectl postgresql
  ```

  ```bash Ubuntu theme={null}
  sudo apt-get install -y terraform kubectl postgresql
  ```
</CodeGroup>

### Authenticate CLI

Install and authenticate with either the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) or [GCP CLI](https://cloud.google.com/sdk/docs/install#deb).

<CodeGroup>
  ```bash AWS theme={null}
  aws configure
  ```

  ```bash GCP theme={null}
  gcloud init
  gcloud auth application-default login
  ```
</CodeGroup>

### Provision ParadeDB

Our Terraform project will provision a Kubernetes cluster (EKS or GKE) along with all the necessary infrastructure to run ParadeDB.

First, copy either `aws.example.tfvars` or `gcp.example.tfvars` into a new file called `byoc.tfvars`.

<CodeGroup>
  ```bash AWS theme={null}
  cp aws.example.tfvars byoc.tfvars
  ```

  ```bash GCP theme={null}
  cp gcp.example.tfvars byoc.tfvars
  ```
</CodeGroup>

Next, open and configure `byoc.tfvars`. Configuration instructions can be found directly within the file.

```bash theme={null}
open byoc.tfvars || xdg-open byoc.tfvars
```

### Run Terraform

First, initialize Terraform.

<CodeGroup>
  ```bash AWS theme={null}
  terraform -chdir=infrastructure/aws init
  ```

  ```bash GCP theme={null}
  terraform -chdir=infrastructure/gcp init
  ```
</CodeGroup>

Next, run Terraform `apply`.

<CodeGroup>
  ```bash AWS theme={null}
  terraform -chdir=infrastructure/aws apply -var-file=../../byoc.tfvars
  ```

  ```bash GCP theme={null}
  terraform -chdir=infrastructure/gcp apply -var-file=../../byoc.tfvars
  ```
</CodeGroup>

<Note>
  It may take up to 30 minutes to provision all the necessary infrastructure.
</Note>

When this command is complete, you will see a `kubectl` command printed as Terraform output to the terminal.
Run this command, which will add the EKS or GKE cluster configuration to your local `.kubeconfig` file.

That's it! You're now ready to connect to ParadeDB.

### Connect to ParadeDB

#### Access the Grafana Dashboard

First, port-forward the Grafana service to localhost.

```bash theme={null}
kubectl --namespace monitoring port-forward service/prometheus-grafana 8080:80
```

Then, go to `http://localhost:8080`. Your Grafana credentials have been printed in the terminal output of the above Terraform `apply` command.

You can find the ParadeDB dashboard by typing `CloudNativePG` in the search bar, and selecting `paradedb` for the Database Namespace.

By default, the dashboard will display metrics over the last 7 days. If you've just spun up the cluster, change it to the last 15 minutes to start seeing results immediately.

#### Access the ParadeDB Instance

First, retrieve the database credentials.

```bash theme={null}
kubectl --namespace paradedb get secrets paradedb-superuser -o json | jq -r '.data | map_values(@base64d) | .uri |= sub("\\*"; "paradedb") | .dbname = "paradedb"'
```

Next, port-forward the ParadeDB service to localhost.

```bash theme={null}
kubectl --namespace paradedb port-forward service/paradedb-rw 5432:5432
```

Now you can connect to the ParadeDB instance using the credentials you've retrieved.

```bash theme={null}
PGPASSWORD=<your-password> psql -h localhost -d paradedb -p 5432 -U <your-user>
```


# GitHub Actions
Source: https://docs.paradedb.com/deploy/ci/github-actions

How to run ParadeDB in Github Actions CI

## Sample GitHub Actions Workflow

```yaml theme={null}
name: ParadeDB in GitHub Actions

on:
  pull_request:
    branches:
      - main
  workflow_dispatch:

jobs:
  paradedb-in-github-actions:
    name: ParadeDB in GitHub Actions
    runs-on: ubuntu-latest

    services:
      paradedb:
        # The list of available tags can be found at https://hub.docker.com/r/paradedb/paradedb/tags
        image: paradedb/paradedb:latest
        env:
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpassword
          POSTGRES_DB: testdb
        ports:
          - 5432:5432
        options: >-
          --health-cmd="pg_isready -U postgres"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

    steps:
      - name: Checkout repository
        uses: actions/checkout@v6

      - name: Wait for PostgreSQL to be ready
        run: |
          for i in {1..10}; do
            if psql -h localhost -U testuser -d testdb -c "SELECT 1;" > /dev/null 2>&1; then
              echo "Database is ready!"
              break
            fi
            echo "Waiting for database..."
            sleep 5
          done

      - name: Run ParadeDB example queries
        run: |
          psql -h localhost -U testuser -d testdb -c "CALL paradedb.create_bm25_test_table(schema_name => 'public', table_name => 'mock_items');"
          psql -h localhost -U testuser -d testdb -c "SELECT description, rating, category FROM mock_items LIMIT 3;"
          psql -h localhost -U testuser -d testdb -c "CREATE INDEX search_idx ON mock_items USING bm25 (id, description, category, rating, in_stock, created_at, metadata, weight_range) WITH (key_field='id');"
          psql -h localhost -U testuser -d testdb -c "SELECT description, rating, category FROM mock_items WHERE description @@@ 'shoes' OR category @@@ 'footwear' AND rating @@@ '>2' ORDER BY description LIMIT 5;"
```


# GitLab CI
Source: https://docs.paradedb.com/deploy/ci/gitlab-ci

How to run ParadeDB in Gitlab CI

## Sample GitLab CI Workflow

```yaml theme={null}
paradedb-in-gitlab-ci:
  # The list of available tags can be found at https://hub.docker.com/r/paradedb/paradedb/tags
  image: paradedb/paradedb:latest
  services:
    - postgres
  variables:
    POSTGRES_USER: testuser
    POSTGRES_DB: testdb
    POSTGRES_HOST_AUTH_METHOD: trust
  script:
    - psql -h "postgres" -U testuser -d testdb -c "CALL paradedb.create_bm25_test_table(schema_name => 'public', table_name => 'mock_items');"
    - psql -h "postgres" -U testuser -d testdb -c "SELECT description, rating, category FROM mock_items LIMIT 3;"
    - psql -h "postgres" -U testuser -d testdb -c "CREATE INDEX search_idx ON mock_items USING bm25 (id, description, category, rating, in_stock, created_at, metadata, weight_range) WITH (key_field='id');"
    - psql -h "postgres" -U testuser -d testdb -c "SELECT description, rating, category FROM mock_items WHERE description @@@ 'shoes' OR category @@@ 'footwear' AND rating @@@ '>2' ORDER BY description LIMIT 5;"
```


# Using ParadeDB with Citus
Source: https://docs.paradedb.com/deploy/citus

Distributed full-text search with Citus and ParadeDB

[Citus](https://github.com/citusdata/citus) transforms PostgreSQL into a distributed database with horizontal sharding. ParadeDB is fully compatible with Citus, enabling distributed full-text search across sharded tables.

## What's Supported

* **BM25 indexes on distributed tables** — Create search indexes after distributing tables with `create_distributed_table()`
* **Distributed queries with search operators** — Use the `|||` (match disjunction) and `&&&` (match conjunction) operators in queries across sharded tables
* **Subqueries with LIMIT** — Complex queries with subqueries and LIMIT clauses work correctly
* **JOIN queries** — Search with JOINs across distributed tables

## Installation

Both `citus` and `pg_search` must be added to `shared_preload_libraries` in the correct order:

```bash theme={null}
# Install Citus first
curl https://install.citusdata.com/community/deb.sh | sudo bash
apt-get install -y postgresql-18-citus-14.0

# Add both extensions to shared_preload_libraries
sed -i "s/^shared_preload_libraries = .*/shared_preload_libraries = 'citus,pg_search'/" /var/lib/postgresql/data/postgresql.conf

# Restart PostgreSQL
# Then create extensions in your database
```

<Note>
  The order in `shared_preload_libraries` matters. Always list `citus` before
  `pg_search` to ensure proper planner hook chaining.
</Note>

## Usage Example

Here's a complete example of setting up distributed search with Citus:

```sql theme={null}
CREATE EXTENSION citus;
CREATE EXTENSION pg_search;

-- Create a table with a distribution key
CREATE TABLE articles (
    id SERIAL,
    author_id INT NOT NULL,
    title TEXT,
    body TEXT,
    PRIMARY KEY (author_id, id)  -- Must include distribution column
);

-- Distribute the table across shards
SELECT create_distributed_table('articles', 'author_id');

-- Create a BM25 index on the distributed table
CREATE INDEX articles_search_idx ON articles
USING bm25 (id, title, body)
WITH (key_field='id');

-- Insert some data
INSERT INTO articles (author_id, title, body) VALUES
    (1, 'PostgreSQL Performance', 'Optimizing PostgreSQL queries for large datasets'),
    (1, 'Distributed Databases', 'Understanding sharding and replication strategies'),
    (2, 'Full-Text Search', 'Building search engines with PostgreSQL');

-- Search across shards
SELECT id, title FROM articles
WHERE body ||| 'PostgreSQL distributed'
ORDER BY id;

-- Results:
--  id |         title
-- ----+------------------------
--   1 | PostgreSQL Performance
--   3 | Full-Text Search
```

### Verify Distributed Execution

You can verify that both ParadeDB and Citus are working together by examining the query plan:

```sql theme={null}
EXPLAIN (VERBOSE)
SELECT id, title FROM articles
WHERE body ||| 'PostgreSQL distributed'
ORDER BY id;
```

The plan should show:

1. **Citus Adaptive Custom Scan** — Coordinating distributed query execution across shards
2. **ParadeDB Base Scan** — Using the BM25 index within each shard
3. **Task Count: 32** — Query distributed across 32 shards (default Citus shard count)

<Accordion title="Example EXPLAIN Output">
  ```
  Sort  (cost=11041.82..11291.82 rows=100000 width=36)
    Output: remote_scan.id, remote_scan.title
    Sort Key: remote_scan.id
    ->  Custom Scan (Citus Adaptive)  (cost=0.00..0.00 rows=100000 width=36)
          Output: remote_scan.id, remote_scan.title
          Task Count: 32
          Tasks Shown: One of 32
          ->  Task
                Query: SELECT id, title FROM public.articles_102008 articles WHERE (id OPERATOR(pg_catalog.@@@) ...)
                Node: host=localhost port=5432 dbname=postgres
                ->  Custom Scan (ParadeDB Base Scan) on public.articles_102008 articles  (cost=10.00..10.01 rows=1 width=36)
                      Output: id, title
                      Table: articles_102008
                      Index: articles_search_idx_102008
                      Tantivy Query: {"with_index":{"query":{"with_index":{"query":{"match":{"field":"body","value":"PostgreSQL distributed"}}}}}}
  ```
</Accordion>

## Distributed JOINs with Search

ParadeDB search operators work seamlessly with Citus distributed JOINs:

```sql theme={null}
-- Create and distribute a second table
CREATE TABLE authors (
    id INT PRIMARY KEY,
    name TEXT,
    bio TEXT
);

SELECT create_distributed_table('authors', 'id');

-- JOIN with search operators
SELECT a.name, ar.title
FROM authors a
JOIN articles ar ON a.id = ar.author_id
WHERE ar.body ||| 'PostgreSQL'
ORDER BY a.name;

-- Results:
--  name  |         title
-- -------+------------------------
--  Alice | PostgreSQL Performance
--  Bob   | Full-Text Search
```

### Verify Distributed JOIN Execution

Check the execution plan for distributed JOINs with search:

```sql theme={null}
EXPLAIN (VERBOSE)
SELECT a.name, ar.title
FROM authors a
JOIN articles ar ON a.id = ar.author_id
WHERE ar.body ||| 'PostgreSQL'
ORDER BY a.name;
```

<Accordion title="Example EXPLAIN Output for JOIN">
  ```
  Sort  (cost=12067.32..12317.32 rows=100000 width=64)
    Output: remote_scan.name, remote_scan.title
    Sort Key: remote_scan.name
    ->  Custom Scan (Citus Adaptive)  (cost=0.00..0.00 rows=100000 width=64)
          Output: remote_scan.name, remote_scan.title
          Task Count: 32
          Tasks Shown: One of 32
          ->  Task
                Query: SELECT a.name, ar.title FROM (public.authors_102040 a JOIN public.articles_102008 ar ON (...))
                Node: host=localhost port=5432 dbname=postgres
                ->  Nested Loop  (cost=10.15..18.20 rows=1 width=64)
                      Output: a.name, ar.title
                      Inner Unique: true
                      ->  Custom Scan (ParadeDB Base Scan) on public.articles_102008 ar  (cost=10.00..10.01 rows=1 width=36)
                            Output: ar.title, ar.author_id
                            Table: articles_102008
                            Index: articles_search_idx_102008
                            Tantivy Query: {"with_index":{"query":{"with_index":{"query":{"match":{"field":"body","value":"PostgreSQL"}}}}}}
                      ->  Index Scan using authors_pkey_102040 on public.authors_102040 a  (cost=0.15..8.17 rows=1 width=36)
                            Output: a.id, a.name, a.bio
                            Index Cond: (a.id = ar.author_id)
  ```

  Key indicators:

  * `Nested Loop` shows efficient JOIN execution on each shard
  * `Custom Scan (ParadeDB Base Scan)` on the outer side of the JOIN uses BM25 for filtering
  * `Index Scan` on authors table uses the primary key for lookups
  * JOINs execute **locally on each shard** for optimal performance
</Accordion>

## Known Limitations

* ❌ **Citus columnar tables** — BM25 indexes and other PostgreSQL indexes (like GiST, GIN) cannot be created on Citus columnar tables due to limitations in Citus's columnar storage implementation. However, you can use regular distributed tables with BM25 indexes alongside columnar tables for analytics.

## Performance Considerations

When using ParadeDB with Citus:

* **Index creation** happens locally on each shard, enabling parallel index building
* **Search queries** execute in parallel across shards and results are merged by the coordinator
* **Distribution column** should be chosen based on your query patterns to minimize cross-shard operations

For more guidance on optimizing distributed search workloads, please reach out to us in the [ParadeDB Community Slack](https://www.paradedb.com/slack) or via [email](mailto:support@paradedb.com).


# DigitalOcean
Source: https://docs.paradedb.com/deploy/cloud-platforms/digitalocean

Deploy ParadeDB on a DigitalOcean Droplet

<Note>
  Cloud platform deployments run ParadeDB Community, which does not include WAL
  support. This makes them suitable for hobby, development, and staging
  environments. For production, we recommend [ParadeDB
  Enterprise](/deploy/enterprise) deployed via
  [Kubernetes](/deploy/self-hosted/kubernetes) or [BYOC](/deploy/byoc).
</Note>

[DigitalOcean](https://www.digitalocean.com) is a cloud platform for deploying and managing applications. This guide walks through
deploying ParadeDB on a DigitalOcean Droplet using Docker. Docker packages PostgreSQL and `pg_search` together, so you don't need to install them manually.

## Prerequisites

1. A DigitalOcean account
2. Your local machine's public IPv4 address (used to restrict access to the Droplet)

## Create a Droplet

1. In the DigitalOcean console, create a new Droplet
2. Select **Ubuntu 24.04 (LTS) x64** as the image
3. Choose a plan size — see the [DigitalOcean sizing guide](https://docs.digitalocean.com/products/droplets/concepts/choosing-a-plan/) for recommendations

Once the Droplet is running, SSH into it to complete the remaining steps.

## Install Docker

```bash theme={null}
curl -fsSL https://get.docker.com | sh
```

## Install ParadeDB

The `tag` query parameter pins the ParadeDB version. See the [Docker Hub page](https://hub.docker.com/r/paradedb/paradedb/tags) for available tags.

```bash theme={null}
curl -fsSL "https://paradedb.com/install.sh?tag=0.22.6-pg18" | sh
```

Once the install completes, note the password printed to the terminal — you will need it for the `psql` connection string below.

To ensure the container restarts automatically if the Droplet reboots:

```bash theme={null}
docker update --restart unless-stopped paradedb
```

## Configure Firewall

In the DigitalOcean console, navigate to **Networking → Firewalls** and create a firewall with the following inbound rule:

| Type   | Protocol | Port   | Sources                |
| ------ | -------- | ------ | ---------------------- |
| Custom | TCP      | `5432` | `<YOUR_IP_ADDRESS>/32` |

Replace `<YOUR_IP_ADDRESS>` with your local machine's public IPv4 address (not the Droplet IP). To allow access from any IP, use `0.0.0.0/0` instead. Apply the firewall to your Droplet.

## Connect to ParadeDB

From your local machine:

```bash theme={null}
psql postgres://myuser:mypassword@<DROPLET_IP>:5432/paradedb
```

Replace `<DROPLET_IP>` with the public IPv4 address of your Droplet, found on the DigitalOcean console.


# Railway
Source: https://docs.paradedb.com/deploy/cloud-platforms/railway

Deploy ParadeDB on Railway with one click

<Note>
  Cloud platform deployments run ParadeDB Community, which does not include WAL
  support. This makes them suitable for hobby, development, and staging
  environments. For production, we recommend [ParadeDB
  Enterprise](/deploy/enterprise) deployed via
  [Kubernetes](/deploy/self-hosted/kubernetes) or [BYOC](/deploy/byoc).
</Note>

[Railway](https://railway.com) is a cloud platform for deploying and managing applications. The
[ParadeDB Railway template](https://railway.com/deploy/paradedb) provides a one-click deployment
that runs ParadeDB Community with persistent storage and a TCP proxy.

## One-Click Deploy

The fastest way to get started is to click the button below, which will deploy ParadeDB to your Railway account.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/paradedb?referralCode=l5qxN4\&utm_medium=integration\&utm_source=button\&utm_campaign=paradedb)

## Configuration

Railway automatically provisions a Docker container running `paradedb/paradedb:latest` with the following
environment variables:

| Variable              | Description               | Default        |
| --------------------- | ------------------------- | -------------- |
| `POSTGRES_USER`       | Database user             | `postgres`     |
| `POSTGRES_PASSWORD`   | Database password         | Auto-generated |
| `POSTGRES_DB`         | Database name             | `paradedb`     |
| `PGPORT`              | Connection port           | `5432`         |
| `DATABASE_URL`        | Private connection string | Auto-generated |
| `DATABASE_PUBLIC_URL` | Public connection string  | Auto-generated |

## Connecting to ParadeDB

Railway provides both private and public connection strings. You can find these in the **Variables** tab of your
service in the Railway dashboard.

To connect from other services on your Railway project, use the private `DATABASE_URL`:

```bash theme={null}
psql $DATABASE_URL
```

To connect from your local machine, use the public connection string:

```bash theme={null}
psql $DATABASE_PUBLIC_URL
```


# Render
Source: https://docs.paradedb.com/deploy/cloud-platforms/render

Deploy ParadeDB on Render with one click

<Note>
  Cloud platform deployments run ParadeDB Community, which does not include WAL
  support. This makes them suitable for hobby, development, and staging
  environments. For production, we recommend [ParadeDB
  Enterprise](/deploy/enterprise) deployed via
  [Kubernetes](/deploy/self-hosted/kubernetes) or [BYOC](/deploy/byoc).
</Note>

[Render](https://render.com) is a cloud platform that makes it easy to deploy and manage applications. The
[ParadeDB Render Blueprint](https://github.com/paradedb/render-blueprint) provides a one-click deployment
that runs ParadeDB Community as a private service with persistent SSD storage.

## One-Click Deploy

The fastest way to get started is to click the button below, which will fork the template repository and deploy
ParadeDB to your Render account.

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/paradedb/render-blueprint)

## Manual Setup

If you prefer to configure the deployment yourself:

1. Fork the [deployment-render](https://github.com/paradedb/render-blueprint) repository
2. In the Render dashboard, create a new **Private Service** and connect your forked repository
3. Select **Docker** as the runtime
4. Attach a **Disk** of at least 10 GB mounted at `/var/lib/postgresql`
5. Set the following environment variables:

| Variable            | Description       | Default        |
| ------------------- | ----------------- | -------------- |
| `POSTGRES_USER`     | Database user     | `postgres`     |
| `POSTGRES_PASSWORD` | Database password | Auto-generated |
| `POSTGRES_DB`       | Database name     | `paradedb`     |

## Connecting to ParadeDB

ParadeDB runs as a **private service** on Render, which means it is not exposed to the public internet. You can
connect from other services on your Render account via the internal network:

```bash theme={null}
psql -h paradedb -U postgres -d paradedb
```

To connect from your local machine, set up [Render SSH](https://docs.render.com/ssh) and then run:

```bash theme={null}
psql -U postgres paradedb
```


# ParadeDB Enterprise
Source: https://docs.paradedb.com/deploy/enterprise

Feature comparison between ParadeDB Community and Enterprise

<Note>
  If you're a non-profit or a non-commercial open source project and are
  interested in ParadeDB Enterprise, please [contact
  sales](mailto:sales@paradedb.com). We provide complimentary access on a
  case-by-case basis.
</Note>

ParadeDB ships in two versions: ParadeDB Community and ParadeDB Enterprise.

[ParadeDB Community](https://github.com/paradedb/paradedb) is our open source product, licensed under [AGPL-3.0](https://www.gnu.org/licenses/agpl-3.0.en.html).
This license permits free use, modification, and distribution of the software, provided that distributed, derivative works of the software are released under the same license
(copyleft provision).

In addition to all of the features of ParadeDB Community, ParadeDB Enterprise:

1. Waives the copyleft provision of AGPL-3.0
2. Contains several close-source features that are recommended for ParadeDB to service enterprise, production workloads

For access to ParadeDB Enterprise, please [contact sales](mailto:sales@paradedb.com).

## Feature Comparison

|                                      | ParadeDB Community | ParadeDB Enterprise |
| ------------------------------------ | ------------------ | ------------------- |
| **Index Configuration**              |                    |                     |
| Support for most Postgres types      | ✅                  | ✅                   |
| Custom tokenizers and filters        | ✅                  | ✅                   |
| Multiple tokenizers per field        | ✅                  | ✅                   |
| **Full Text Search and Analytics**   |                    |                     |
| Query builder API                    | ✅                  | ✅                   |
| Efficient Top K ordering             | ✅                  | ✅                   |
| BM25 scoring                         | ✅                  | ✅                   |
| Highlighting                         | ✅                  | ✅                   |
| Hybrid search                        | ✅                  | ✅                   |
| Parallelized fast field aggregates   | ✅                  | ✅                   |
| **Concurrency and Consistency**      |                    |                     |
| Postgres MVCC-safe<sup>1</sup>       | ✅                  | ✅                   |
| Concurrent, non-blocking writes      | ✅                  | ✅                   |
| Block storage integration            | ✅                  | ✅                   |
| Buffer cache integration<sup>2</sup> | ✅                  | ✅                   |
| **Deployment** <sup>3</sup>          |                    |                     |
| Maximum cluster size <sup>4</sup>    | 1                  | Unlimited           |
| Physical (i.e. WAL) Replication      | ❌                  | ✅                   |
| Crash Recovery                       | ❌                  | ✅                   |
| Point in Time Recovery               | ❌                  | ✅                   |
| Logical Replication                  | ✅                  | ✅                   |

<Info>
  **Footnotes**

  <p>
    1. The BM25 index supports Postgres' multi-version concurrency control (MVCC)
       rules. The index reflects the current state of the underlying table at all
       times, changes to the index are atomic, and queries are transactionally
       consistent with the table.
    2. The BM25 index is built on block storage, Postgres' native storage API.
       This means that it leverages the Postgres buffer cache, which minimizes disk
       I/O.
    3. All listed deployment features and limitations are specific to the BM25 index. For instance,
       ParadeDB Community supports physical/logical replication, crash recovery, etc. for heap tables and other Postgres indexes like B-Tree.
    4. In a primary-replica topology, BM25 indexes in ParadeDB Community are only available on the primary, as
       the Community edition does not support physical (WAL) replication.
  </p>
</Info>


# Schema Changes
Source: https://docs.paradedb.com/deploy/logical-replication/configuration

Handle DDL/schema changes when running ParadeDB as a logical replica

<Note>
  This section assumes that you have successfully completed the [getting
  started](/deploy/logical-replication/getting-started) guide and reviewed the
  [Logical Replication Operational
  Guide](/deploy/logical-replication/operational-guide).
</Note>

## Schema Changes

PostgreSQL logical replication copies row changes, not DDL. That means schema
changes on the publisher are not applied automatically on ParadeDB.

Keep these rules in mind:

* Existing replicated tables must stay schema-compatible on both sides
* New tables must exist on ParadeDB before they can replicate there
* BM25 indexes are local to ParadeDB and must be created or rebuilt there
* Publication membership still controls whether a new table is replicated at all

```sql theme={null}
-- On Publisher
ALTER TABLE mock_items ADD COLUMN num_stock int;
INSERT INTO mock_items (description, category, in_stock, latest_available_time, last_updated_date, metadata, created_at, rating, num_stock)
VALUES ('Green running shoes', 'Footwear', true, '14:00:00', '2024-07-09', '{}', '2024-07-09 14:00:00', 2, 900);

-- On Subscriber
ERROR: logical replication target relation "public.mock_items" is missing some replicated columns
```

For the safe rollout sequence, including subscriber-first additive DDL and how
to handle non-additive changes, see [Roll Out DDL
Safely](/deploy/logical-replication/operational-guide#roll-out-ddl-safely).

If replication is already failing because the schemas diverged or because a
conflict stopped the apply worker, see [Troubleshoot Apply
Failures](/deploy/logical-replication/operational-guide#troubleshoot-apply-failures).

If you want a new table to replicate to ParadeDB, that table must be included
in the publication. Publications created with `FOR ALL TABLES` include new
tables automatically, and publications created with `FOR TABLES IN SCHEMA ...`
include new tables created in those schemas automatically. If your publication
was created from an explicit table list, new tables will not replicate until
you add them manually. If you do not want a table replicated to ParadeDB, leave
it out of the publication.

For the full sequence for adding a replicated searchable table, see [Add New
Tables](/deploy/logical-replication/operational-guide#add-new-tables).

```sql theme={null}
-- On Publisher
ALTER PUBLICATION marketplace_pub ADD TABLE newly_added_table;

-- On Subscriber
ALTER SUBSCRIPTION marketplace_sub REFRESH PUBLICATION;
```


# Getting Started with Logical Replication
Source: https://docs.paradedb.com/deploy/logical-replication/getting-started

Configure ParadeDB as a logical subscriber to an existing Postgres primary

<Note>
  In order for ParadeDB to run as a logical subscriber, ParadeDB must be using
  Postgres 17+.
</Note>

In production, ParadeDB is commonly deployed as a logical subscriber to your
primary Postgres. Your application continues to write to the source database,
while ParadeDB receives the same row changes and maintains local BM25 indexes
for search and analytics.

This deployment model is useful when:

* Your primary Postgres runs on a managed service such as AWS RDS, Aurora,
  Cloud SQL, AlloyDB, or Azure Database for PostgreSQL
* You want search and analytics queries to run away from your OLTP workload
* You want to keep Postgres as the system of record and add ParadeDB as a
  dedicated read and search node

<Warning>
  Logical replication copies row changes, not schema changes or indexes. The
  published tables must already exist on ParadeDB, and any DDL must be applied
  on both sides. For ongoing operations, see the [Logical Replication
  Operational Guide](/deploy/logical-replication/operational-guide).
</Warning>

ParadeDB supports logical replication from any primary Postgres.

## Managed Postgres Providers

Each managed provider has its own prerequisite steps for enabling logical
replication. In every case, the managed database is the **publisher** and
ParadeDB is the **subscriber**.

* **AWS RDS/Aurora**: Follow AWS'
  [tutorial](https://aws.amazon.com/blogs/database/using-logical-replication-to-replicate-managed-amazon-rds-for-postgresql-and-amazon-aurora-to-self-managed-postgresql/)
* **Azure Database for PostgreSQL**: Follow Azure's
  [tutorial](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-logical)
* **Cloud SQL for PostgreSQL**: Follow Google's
  [tutorial](https://cloud.google.com/sql/docs/postgres/replication/configure-logical-replication#set-up-native-postgresql-logical-replication)
* **AlloyDB for PostgreSQL**: Follow Google's
  [tutorial](https://cloud.google.com/alloydb/docs/omni/replicate-data-omni-other-db)

<Note>
  Azure Cosmos DB for PostgreSQL [does not support logical
  replication](https://learn.microsoft.com/en-us/answers/questions/1193391/does-azure-cosmos-db-for-postgresql-support-logica).
</Note>

## Self-Hosted Postgres

The example below shows a minimal self-hosted setup where Postgres publishes
changes and ParadeDB subscribes to them.

### Environment Setup

We'll use the following environment:

**Publisher**

* **OS**: Ubuntu 24.04
* **IP**: 192.168.0.30
* **Database Name**: `marketplace`
* **Replication User**: `replicator`
* **Replication Password**: `passw0rd`

**Subscriber (ParadeDB)**

* **OS**: Ubuntu 24.04
* **IP**: 192.168.0.31

### 1. Configure the Publisher

Ensure that `postgresql.conf` on the publisher has the following settings:

```ini theme={null}
listen_addresses = 'localhost,192.168.0.30'
wal_level = logical
max_replication_slots = 10
max_wal_senders = 10
```

Leave headroom in `max_replication_slots` and `max_wal_senders` for the initial
copy phase, not just the steady-state subscription. For sizing guidance, see
[Choose Publication and Subscription Boundaries](/deploy/logical-replication/operational-guide#choose-publication-and-subscription-boundaries).

Then allow the subscriber to connect in `pg_hba.conf`:

```ini theme={null}
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
host    replication     all             192.168.0.0/24          scram-sha-256
```

Create a replication user:

```bash theme={null}
sudo -u postgres createuser --pwprompt --replication replicator
```

### 2. Create the Source Schema on the Publisher

Create a database and a table on the publisher:

```bash theme={null}
sudo -u postgres -H createdb marketplace
```

```sql theme={null}
CREATE TABLE mock_items (
  id SERIAL PRIMARY KEY,
  description TEXT,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  category VARCHAR(255),
  in_stock BOOLEAN,
  metadata JSONB,
  created_at TIMESTAMP,
  last_updated_date DATE,
  latest_available_time TIME
);


INSERT INTO mock_items (description, category, in_stock, latest_available_time, last_updated_date, metadata, created_at, rating)
VALUES ('Red sports shoes', 'Footwear', true, '12:00:00', '2024-07-10', '{}', '2024-07-10 12:00:00', 1);
```

PostgreSQL's default replica identity uses the primary key. Because
`mock_items` has a primary key, it already has a valid replica identity
for `INSERT`, `UPDATE`, and `DELETE`, so no additional replica identity
configuration is needed here.

### 3. Bootstrap the Schema on ParadeDB

Logical replication does not copy schema definitions, so create the same
database and tables on ParadeDB before you subscribe. A schema-only dump is the
simplest way to do this:

```bash theme={null}
createdb -h 192.168.0.31 -U postgres marketplace

pg_dump --schema-only --no-owner --no-privileges \
  -h 192.168.0.30 -U postgres marketplace \
  | psql -h 192.168.0.31 -U postgres marketplace
```

The target tables on ParadeDB should start empty if you are using the default
initial copy behavior of `CREATE SUBSCRIPTION`.

### 4. Install and Load `pg_search` on ParadeDB

[Deploy ParadeDB](/deploy/overview) on the subscriber, then load the extension in the subscriber database:

```sql theme={null}
CREATE EXTENSION pg_search;
```

### 5. Create a Publication on the Publisher

```sql theme={null}
CREATE PUBLICATION marketplace_pub FOR TABLE mock_items;
```

If you plan to replicate several large or update-heavy tables, consider one
publication/subscription pair per large hot table rather than grouping
everything together. See [Choose Publication and Subscription
Boundaries](/deploy/logical-replication/operational-guide#choose-publication-and-subscription-boundaries)
for the reasoning.

### 6. Create a Subscription on ParadeDB

```sql theme={null}
CREATE SUBSCRIPTION marketplace_sub
CONNECTION 'host=192.168.0.30 port=5432 dbname=marketplace user=replicator password=passw0rd application_name=marketplace_sub'
PUBLICATION marketplace_pub;
```

By default, PostgreSQL copies existing rows from the publisher and then keeps
streaming new changes. If you do not want the initial copy, create the
subscription with `WITH (copy_data = false)` and backfill the tables by another
method.

### 7. Verify Replication

First check that the existing row is present on ParadeDB:

```sql theme={null}
SELECT id, description, category
FROM mock_items
ORDER BY id;
```

Then insert a new row on the publisher:

```sql theme={null}
INSERT INTO mock_items (description, category, in_stock, latest_available_time, last_updated_date, metadata, created_at, rating)
VALUES ('Blue running shoes', 'Footwear', true, '14:00:00', '2024-07-10', '{}', '2024-07-10 14:00:00', 2);
```

Now verify that the new row arrives on ParadeDB:

```sql theme={null}
SELECT id, description, category
FROM mock_items
WHERE description = 'Blue running shoes';
```

At this point, the base table is replicating correctly and you can create BM25
indexes locally on ParadeDB. Continue to the [Logical Replication Operational
Guide](/deploy/logical-replication/operational-guide) for BM25
index build timing, monitoring, WAL retention, and troubleshooting.


# Multi-Database Replication for Microservices
Source: https://docs.paradedb.com/deploy/logical-replication/multi-database

Consolidate multiple microservice databases into a single ParadeDB instance for app-wide search and cross-database joins

## Problem Statement

Organizations often have multiple Postgres databases, each connected to a different microservice. The goal is to logically replicate all of these databases into a single ParadeDB instance. This enables:

* App-wide search across all microservices
* Cross-database joins for analytics and reporting
* Centralized data access without modifying individual microservices

However, table naming collisions can occur since each microservice and its database operate independently.

## Logical Replication Background

Postgres' Logical Replication is designed from the perspective of one source database and one destination database. Logical replication resolves tables by their schema-qualified name. It does not have native primitives to remap schema or table names during replication.

## Solution

For logical replication to work, all source database tables need to have a unique signature that avoids name collisions. They also need to be identifiable by their source database. This can be achieved by using a different schema in each database instead of the `public` schema. The schema name should match the database name.

### Architecture

The solution involves replicating multiple independent microservice databases into a single ParadeDB instance. Each source database uses a schema named after the database itself, ensuring no naming conflicts.

<img alt="Multi-database replication architecture" />

As shown in the diagram:

* Each microservice database (db1, db2, db3) uses a schema matching its database name
* All databases replicate to a single ParadeDB instance via logical replication
* In ParadeDB, tables are accessible with fully-qualified names (e.g., `db1.table1`, `db2.table1`)
* This enables cross-database joins like: `SELECT db1.users.user_id FROM db1.users, db2.orders WHERE db1.users.id = db2.orders.user_id`

Instead of having all tables in the `public` schema across multiple databases:

```
Database: users_service
Schema: public
  - users
  - profiles

Database: orders_service
Schema: public
  - orders
  - payments
```

Reorganize each database to use a dedicated schema:

```
Database: users_service
Schema: users_service
  - users
  - profiles

Database: orders_service
Schema: orders_service
  - orders
  - payments
```

This approach ensures that when replicated to ParadeDB, all tables have unique fully-qualified names and you can identify the source of each table.

## Zero-Downtime Migration

This migration strategy reorganizes tables from the `public` schema into dedicated schemas while maintaining complete backwards compatibility through updatable views.

### Migration Steps

For each microservice database, execute the following:

```sql theme={null}
BEGIN;

-- Create new schema named after the database
CREATE SCHEMA IF NOT EXISTS <database_name>;

-- Move tables to new schema
ALTER TABLE public.table1 SET SCHEMA <database_name>;
ALTER TABLE public.table2 SET SCHEMA <database_name>;
-- Repeat for all tables...

-- Create backwards-compatible views in public schema
CREATE OR REPLACE VIEW public.table1 AS SELECT * FROM <database_name>.table1;
CREATE OR REPLACE VIEW public.table2 AS SELECT * FROM <database_name>.table2;
-- Repeat for all tables...

COMMIT;
```

### Example

For a `users_service` database:

```sql theme={null}
BEGIN;

-- Create new schema
CREATE SCHEMA IF NOT EXISTS users_service;

-- Move tables
ALTER TABLE public.users SET SCHEMA users_service;
ALTER TABLE public.profiles SET SCHEMA users_service;

-- Create backwards-compatible views
CREATE OR REPLACE VIEW public.users AS SELECT * FROM users_service.users;
CREATE OR REPLACE VIEW public.profiles AS SELECT * FROM users_service.profiles;

COMMIT;
```

### Benefits of This Approach

* **Zero Downtime**: Existing applications continue to function without modification during the transition period for all queries (SELECT, INSERT, UPDATE, DELETE)
* **Gradual Migration**: Application queries can be updated over time to reference the new schema directly
* **Rollback Capability**: Each migration step is reversible if needed
* **View Cleanup**: Once applications are updated, views in the `public` schema can be safely removed

### Setting Up Logical Replication

After completing the schema migration for all source databases:

1. Configure each source database as a publisher following the [getting started guide](/deploy/logical-replication/getting-started)
2. Set up ParadeDB as a subscriber for all source databases
3. Create publications on each source database for their respective schemas:

```sql theme={null}
-- On users_service database
CREATE PUBLICATION users_pub FOR TABLES IN SCHEMA users_service;

-- On orders_service database
CREATE PUBLICATION orders_pub FOR TABLES IN SCHEMA orders_service;
```

4. Create subscriptions on ParadeDB for each source database:

```sql theme={null}
-- On ParadeDB instance
CREATE SUBSCRIPTION users_sub
    CONNECTION 'host=users_db port=5432 dbname=users_service user=replicator password=...'
    PUBLICATION users_pub;

CREATE SUBSCRIPTION orders_sub
    CONNECTION 'host=orders_db port=5432 dbname=orders_service user=replicator password=...'
    PUBLICATION orders_pub;
```

## Trade-offs

### Pros

* **Multi Database BM25 Search**: Perform full-text search across tables distributed across multiple microservice databases in a single query
* **Avoid Distributed Joins in Application**: Execute cross-database joins directly in ParadeDB instead of implementing complex join logic in your application
* **Simple Architecture**: Uses standard PostgreSQL logical replication without extra infrastructure
* **Namespace Isolation**: Schema-based separation prevents naming conflicts
* **No Source Database Changes**: Microservices continue operating independently; ParadeDB acts as a read replica

### Cons

* Source databases will access tables from their dedicated schema (e.g., `users_service`) instead of `public`
* Requires coordination across microservice teams for initial migration
* Existing database tooling may need configuration updates to work with non-public schemas


# Logical Replication Operational Guide
Source: https://docs.paradedb.com/deploy/logical-replication/operational-guide

Monitor, troubleshoot, and safely operate ParadeDB as a permanent logical replica

This guide covers how to operate ParadeDB after logical replication has been
set up.

Use [Getting Started with Logical
Replication](/deploy/logical-replication/getting-started) to create
the publication and subscription first. This page focuses on what happens after
the link is established and ParadeDB is staying in sync continuously.

## Operating Model

When ParadeDB is used as a logical subscriber:

1. Your application writes to tables on the publisher
2. PostgreSQL logical replication applies those row changes to matching tables
   on ParadeDB
3. ParadeDB maintains BM25 indexes locally on the subscriber
4. Search and analytics queries run against ParadeDB instead of the primary

This keeps the source database authoritative while isolating search traffic from
OLTP traffic.

<Note>
  Logical replication copies row changes into ParadeDB, but it does not copy
  BM25 indexes from the publisher. For the deployment described in this guide,
  build the BM25 indexes you plan to query on the ParadeDB subscriber.
</Note>

## Baseline Workflow

### 1. Wait for the Initial Copy to Finish

Let PostgreSQL finish copying the base table data before you build BM25 indexes.
This avoids extra indexing work during the bootstrap phase.

On ParadeDB, you can check whether the initial copy is still running with:

```sql theme={null}
SELECT
  subname,
  worker_type,
  CASE WHEN relid = 0 THEN NULL ELSE relid::regclass END AS table_name,
  latest_end_time
FROM pg_stat_subscription
ORDER BY 1, 2, 3;
```

The initial copy is complete when there are no remaining rows with
`worker_type = 'table synchronization'`. If you want a stricter per-table
check, run:

```sql theme={null}
SELECT srrelid::regclass AS table_name, srsubstate
FROM pg_subscription_rel
ORDER BY 1;
```

The initial copy is complete when every replicated table is in state `r`
(`ready`).

### 2. Build BM25 Indexes on ParadeDB

Once the replicated tables are caught up, create BM25 indexes locally on
ParadeDB:

```sql theme={null}
CREATE INDEX mock_items_bm25_idx ON public.mock_items
USING bm25 (id, description, category, rating)
WITH (key_field='id');
```

After this, ongoing replicated `INSERT`, `UPDATE`, and `DELETE` operations will
keep the BM25 index current automatically.

### 3. Query ParadeDB

Your application can now issue search queries to ParadeDB without adding search
indexes to the primary database:

```sql theme={null}
SELECT id, description, pdb.score(id) AS score
FROM mock_items
WHERE description @@@ 'running shoes'
ORDER BY score DESC
LIMIT 10;
```

## Day-2 Operations

### Choose Publication and Subscription Boundaries

For large or high-churn production tables, use one publication and one
subscription per large table, or group only small related tables together.

This gives each subscription its own main apply worker and replication slot.
In normal steady-state replication, PostgreSQL does not parallelize ordinary
change application across tables within a single subscription, so one hot table
can delay other tables that share that apply worker. A publication per table
alone does not provide that isolation unless it also has its own subscription.

If you split replication this way, size the replication worker settings for the
number of subscriptions you plan to run:

* On the publisher, set `max_replication_slots` to at least the number of
  subscriptions plus reserve for initial table synchronization workers. During
  bootstrap, each active table synchronization worker can temporarily consume
  its own replication slot on the publisher. With the default
  `max_sync_workers_per_subscription = 2`, leave room for the main subscription
  plus up to two extra sync slots per bootstrapping subscription, and set
  `max_wal_senders` high enough to cover the same plus any physical replicas.
* On the subscriber, set `max_replication_slots` and
  `max_logical_replication_workers` to at least the number of subscriptions plus
  reserve for table synchronization workers. On PostgreSQL 18+,
  `max_active_replication_origins` controls replication origin tracking
  separately and should also be sized accordingly. `max_worker_processes` must
  be high enough to accommodate those logical replication workers and any other
  background workers used by the system.
* `max_sync_workers_per_subscription` controls initial-copy parallelism when a
  subscription is created or refreshed. The default is `2`, so multi-table
  publications normally copy at most two tables at a time unless you raise it.

### Add New Tables

When you want ParadeDB to index a new table:

1. Apply the new table DDL on the publisher
2. Apply the same DDL on ParadeDB
3. Make sure the publication includes the table
4. Refresh the subscription
5. Build a BM25 index on ParadeDB if the table should be searchable

Whether step 3 is manual depends on how the publication was defined. If the
publication uses `FOR ALL TABLES`, the new table is included automatically. If
it uses `FOR TABLES IN SCHEMA ...`, new tables in those schemas are included
automatically. If it was created from an explicit table list, add the table
manually. If you do not want the table on ParadeDB, do not include it in the
publication.

```sql theme={null}
-- On the publisher
ALTER PUBLICATION app_search_pub ADD TABLE public.new_table;

-- On ParadeDB
ALTER SUBSCRIPTION app_search_sub REFRESH PUBLICATION;
```

### Change Indexed Columns

If you add or remove a column that is part of a BM25 index:

1. Apply the table change on both the publisher and ParadeDB
2. Let replication catch up again
3. Rebuild the BM25 index on ParadeDB

See [Reindexing](/documentation/indexing/reindexing) for the BM25 rebuild
workflow.

### Roll Out DDL Safely

PostgreSQL logical replication does not replicate schema changes. That means
the publisher and ParadeDB must be kept in sync manually.

In practice, most teams do this through their existing migration runner or
framework tooling, whether that is Rails migrations, Django migrations, Prisma
Migrate, or another migration system.

For additive changes such as `ADD COLUMN`, the safest rollout is usually:

1. Apply the additive DDL on ParadeDB first
2. Apply the same DDL on the publisher
3. Let replication continue normally
4. Rebuild any BM25 indexes whose indexed column list changed

This follows PostgreSQL's recommendation to apply additive schema changes on the
subscriber first whenever possible, which avoids intermittent apply failures.
Logical replication can tolerate extra columns on the subscriber, so adding a
column on ParadeDB first will not stop replication by itself. Those extra
subscriber-only columns use their local default value, or `NULL` if no default
is defined, until the publisher starts sending that column.

If the new column must be `NOT NULL`, give it a compatible default on both
sides or use a coordinated maintenance window. Otherwise replicated `INSERT`
operations can fail before the publisher-side change is in place.

If the change is not additive, such as a column rename, drop, or incompatible
type change, use a short maintenance window, pause writes to the affected
tables if possible, and coordinate both sides explicitly:

```sql theme={null}
-- On Subscriber
ALTER SUBSCRIPTION marketplace_sub DISABLE;
ALTER TABLE mock_items RENAME COLUMN category TO product_category;

-- On Publisher
ALTER TABLE mock_items RENAME COLUMN category TO product_category;

-- Back on Subscriber
ALTER SUBSCRIPTION marketplace_sub ENABLE;
```

<Warning>
  Do not leave a disabled subscription in place longer than necessary. The
  logical slot on the publisher can continue retaining WAL while the subscriber
  is disabled.
</Warning>

### Handle Tables Without Primary Keys

PostgreSQL needs a replica identity to replicate `UPDATE` and `DELETE`
operations. A primary key is best. Another suitable unique index can also be
used as the replica identity. If a table has no suitable key, you can use the
per-table fallback:

```sql theme={null}
ALTER TABLE public.events REPLICA IDENTITY FULL;
```

Do not think of this as a server-wide setting. `REPLICA IDENTITY FULL` is set
per published table and should be treated as a fallback rather than the default
design.

PostgreSQL explicitly warns that subscriber-side `UPDATE` and `DELETE` can
become very inefficient under `FULL`, because the subscriber must locate the
matching row using the entire old row image rather than a compact key.
`FULL` also increases WAL volume and replication traffic on the publisher,
since every `UPDATE` and `DELETE` writes the full before-image of the row
into WAL instead of just the key columns.

### Monitor the Publisher

Permanent logical replication is operationally safe only if you watch the
publisher, not just the subscriber. The most important signal is how much WAL a
logical slot is retaining.

```sql theme={null}
SELECT
  slot_name,
  active,
  restart_lsn,
  confirmed_flush_lsn,
  pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal,
  wal_status,
  safe_wal_size,
  inactive_since
FROM pg_replication_slots
WHERE slot_type = 'logical';
```

Watch for:

* `retained_wal` growing steadily because the subscriber is not acknowledging
  WAL quickly enough
* `inactive_since` becoming non-`NULL` for longer than expected
* `wal_status` showing that the slot is under pressure
* Filesystem usage on the volume that contains `pg_wal`

To reduce blast radius, configure `max_slot_wal_keep_size` on the publisher.
This caps how much WAL a slot may retain, but it can also invalidate a lagging
subscriber, so it should be paired with alerting and a reseed plan.

### Monitor the Subscriber

Use the subscriber to confirm that apply workers are healthy and that errors are
not accumulating:

```sql theme={null}
SELECT subname, worker_type, received_lsn, latest_end_lsn, latest_end_time
FROM pg_stat_subscription;

SELECT subname, apply_error_count, sync_error_count
FROM pg_stat_subscription_stats;
```

If `latest_end_time` stops advancing or `apply_error_count` increases, inspect
the subscriber logs immediately.

### Troubleshoot Apply Failures

One common cause of apply-worker failures is schema drift between the publisher
and subscriber.

Two common log patterns for schema drift are:

```text theme={null}
logical replication target relation "public.doctor" is missing replicated columns: "personnel_id", "role_function_id"
```

```text theme={null}
logical replication apply worker for subscription "paradedb_subscription" has started
background worker "logical replication apply worker" (PID 2570238) exited with exit code 1
```

The first message is the root cause. The second means the apply worker crashed
after hitting that error and PostgreSQL will try to restart it.

When you see these messages:

1. Inspect the subscriber logs for the first schema-mismatch error, not just the
   worker restart message
2. Compare the affected table definition on the publisher and ParadeDB
3. Apply the missing DDL on ParadeDB
4. Re-enable or refresh the subscription if needed
5. Rebuild any BM25 indexes affected by the schema change

Another common cause of apply-worker failures is a logical replication conflict.
For example, a duplicate key, a permissions failure on the target table, or
row-level security on the subscriber can stop replication even when the schemas
match.

```text theme={null}
ERROR: duplicate key value violates unique constraint ...
CONTEXT: processing remote data during INSERT for replication target relation ...
```

When you suspect a replication conflict:

1. Inspect the subscriber logs for the first conflict error and note the finish
   LSN and replication origin if PostgreSQL logged them
2. Resolve the underlying issue on the subscriber, such as conflicting local
   data, missing privileges, or row-level security policy interference
3. Resume replication normally once the conflict is removed
4. Only if you intentionally want to discard that remote transaction, use
   `ALTER SUBSCRIPTION ... SKIP` with care

Skipping a conflicting transaction can leave the subscriber inconsistent, so it
should be treated as a last resort rather than the default fix. For conflict
types and the PostgreSQL recovery workflow, see the [PostgreSQL logical
replication conflicts
documentation](https://www.postgresql.org/docs/current/logical-replication-conflicts.html).

### Emergency: WAL Keeps Accumulating on the Publisher

If the logical slot on the publisher is filling disk and ParadeDB cannot catch
up quickly enough, the priority is protecting the publisher.

1. First, fix the subscriber if the issue is simple and recent, such as a
   schema mismatch or networking issue
2. If the publisher is running out of disk and the subscriber can be rebuilt,
   remove the subscription or drop the logical slot so the publisher can recycle
   WAL again
3. Recreate the subscription and reseed ParadeDB once the publisher is safe

<Warning>
  Disabling the subscription is not an emergency fix for WAL buildup. A disabled
  subscription still leaves the logical slot behind on the publisher, and that
  slot can continue retaining WAL.
</Warning>

If the subscriber is reachable and healthy enough to cleanly tear down, dropping
the subscription is the cleanest path:

```sql theme={null}
DROP SUBSCRIPTION paradedb_subscription;
```

To protect the publisher from continued `pg_wal` growth when you are
intentionally giving up the current replica state, drop the slot on the
publisher:

```sql theme={null}
SELECT pg_drop_replication_slot('paradedb_subscription');
```

After either step, ParadeDB must be reinitialized from a fresh schema and data
copy before it can resume as a logical subscriber.

## Common Pitfalls

* Starting with pre-populated subscriber tables while using `copy_data = true`
* Applying DDL on only one side of the replication link
* Forgetting that new tables must be added to the publication and refreshed on
  the subscription
* Writing directly to subscribed tables on ParadeDB, which can create conflicts
  with incoming replicated changes
* Leaving a broken logical slot unattended on the publisher until `pg_wal`
  fills disk
* Assuming `ALTER SUBSCRIPTION ... DISABLE` relieves publisher-side WAL pressure

For schema-change basics, see [Schema
Changes](/deploy/logical-replication/configuration). For multiple source
databases, see [Multi-Database Replication for
Microservices](/deploy/logical-replication/multi-database).


# Deploying ParadeDB
Source: https://docs.paradedb.com/deploy/overview

Explore the different ways to deploy ParadeDB into production

<Note>
  Running ParadeDB Community in a production application that serves paying customers is discouraged.

  This is because ParadeDB Community [does not have write-ahead log (WAL) support](/deploy/enterprise). Without WALs, data can be lost or corrupted if
  the server crashes or restarts, which would necessitate a reindex and incur downtime for your application. For more details, see [guarantees](/welcome/guarantees#aci-d).

  When you are ready to deploy in ParadeDB to production, [contact us](mailto:sales@paradedb.com) for access to ParadeDB Enterprise, which has WAL support.
</Note>

There are three ways to deploy ParadeDB:

* **[Cloud Platforms](#cloud-platforms)** — deploy a ParadeDB container to Railway, Render, or DigitalOcean with minimal setup
* **[Self-Hosted](#self-hosted-paradedb)** — run ParadeDB inside Kubernetes or as an extension in your existing Postgres
* **[ParadeDB BYOC](#paradedb-byoc)** — a managed deployment of ParadeDB Enterprise inside your own AWS or GCP account

## Cloud Platforms

For hobby, development, or staging environments, ParadeDB Community can be deployed to cloud platforms with minimal setup. These all use Docker containers, which package PostgreSQL and `pg_search` together:

* [Railway](/deploy/cloud-platforms/railway) — One-click deploy to Railway
* [Render](/deploy/cloud-platforms/render) — One-click deploy to Render
* [DigitalOcean](/deploy/cloud-platforms/digitalocean) — Deploy on a DigitalOcean Droplet

## Self-Hosted ParadeDB

ParadeDB can be deployed as an [extension](/deploy/self-hosted/extension) inside an existing self-hosted Postgres or via our [Kubernetes Helm chart](/deploy/self-hosted/kubernetes), which is based on the [CloudNativePG](https://cloudnative-pg.io/) Helm chart. When self-hosting, we always recommend configuring [high availability](/deploy/self-hosted/high-availability).

## ParadeDB BYOC

[ParadeDB BYOC (Bring Your Own Cloud)](/deploy/byoc) is a managed deployment of ParadeDB Enterprise inside your AWS or GCP account. Please [contact sales](mailto:sales@paradedb.com) for access.


# Extension
Source: https://docs.paradedb.com/deploy/self-hosted/extension

How to install ParadeDB as an extension inside an existing self-managed Postgres

<Note>
  We recommend running ParadeDB Enterprise, not Community, in production to
  maximize uptime. See [overview](/deploy/overview#self-hosted).
</Note>

If you already self-manage Postgres, you may prefer to install ParadeDB directly within your self-managed
Postgres instead of deploying the ParadeDB Helm chart.

This can be done by installing the `pg_search` extension, which powers all of ParadeDB's custom functionalities.

## Prerequisites

<Note>
  Prebuilt binaries are compiled for modern CPUs: x86-64-v3 (Intel/AMD 2013+),
  ARMv8.2-A+RCpc (AWS Graviton 2+, Ampere Altra, 2020+), and Apple M1+ (2020+).
  Older CPUs are not supported.
</Note>

Ensure that you have superuser access to the Postgres database.

## Install the ParadeDB Postgres Extension

### ParadeDB Community

ParadeDB provides prebuilt binaries of our extension for Postgres 15+ on:

* Debian 12 (Bookworm) and 13 (Trixie)
* Ubuntu 22.04 (Jammy) and 24.04 (Noble)
* macOS 14 (Sonoma) and 15 (Sequoia)
* Red Hat Enterprise Linux 9 and 10

If you are using a different version of Postgres or a different operating system, you will need to build the extension from source.

#### pg\_search

The prebuilt releases can be found in [GitHub Releases](https://github.com/paradedb/paradedb/releases).

<Note>
  You can replace `0.22.6` with the `pg_search` version you wish to install and
  `17` with the version of Postgres you are using.
</Note>

<CodeGroup>
  ```bash Ubuntu 24.04 theme={null}
  # Available arch versions are amd64, arm64
  curl -L "https://github.com/paradedb/paradedb/releases/download/v0.22.6/postgresql-17-pg-search_0.22.6-1PARADEDB-noble_amd64.deb" -o /tmp/pg_search.deb
  sudo apt-get install -y /tmp/*.deb
  ```

  ```bash Ubuntu 22.04 theme={null}
  # Available arch versions are amd64, arm64
  curl -L "https://github.com/paradedb/paradedb/releases/download/v0.22.6/postgresql-17-pg-search_0.22.6-1PARADEDB-jammy_amd64.deb" -o /tmp/pg_search.deb
  sudo apt-get install -y /tmp/*.deb
  ```

  ```bash Debian 13 theme={null}
  # Available arch versions are amd64, arm64
  curl -L "https://github.com/paradedb/paradedb/releases/download/v0.22.6/postgresql-17-pg-search_0.22.6-1PARADEDB-trixie_amd64.deb" -o /tmp/pg_search.deb
  sudo apt-get install -y /tmp/*.deb
  ```

  ```bash Debian 12 theme={null}
  # Available arch versions are amd64, arm64
  curl -L "https://github.com/paradedb/paradedb/releases/download/v0.22.6/postgresql-17-pg-search_0.22.6-1PARADEDB-bookworm_amd64.deb" -o /tmp/pg_search.deb
  sudo apt-get install -y /tmp/*.deb
  ```

  ```bash RHEL 10 theme={null}
  # Available arch versions are x86_64, aarch64
  curl -L "https://github.com/paradedb/paradedb/releases/download/v0.22.6/pg_search_17-0.22.6-1PARADEDB.el10.x86_64.rpm" -o /tmp/pg_search.rpm
  sudo dnf install -y /tmp/*.rpm
  ```

  ```bash RHEL 9 theme={null}
  # Available arch versions are x86_64, aarch64
  curl -L "https://github.com/paradedb/paradedb/releases/download/v0.22.6/pg_search_17-0.22.6-1PARADEDB.el9.x86_64.rpm" -o /tmp/pg_search.rpm
  sudo dnf install -y /tmp/*.rpm
  ```

  ```bash macOS 15 (Sequoia) theme={null}
  # Available arch version is arm64
  curl -L "https://github.com/paradedb/paradedb/releases/download/v0.22.6/pg_search@17--0.22.6.arm64_sequoia.pkg" -o ~/Downloads/pg_search.pkg
  sudo installer -pkg ~/Downloads/pg_search.pkg -target /
  ```

  ```bash macOS 14 (Sonoma) theme={null}
  # Available arch version is arm64
  curl -L "https://github.com/paradedb/paradedb/releases/download/v0.22.6/pg_search@17--0.22.6.arm64_sonoma.pkg" -o ~/Downloads/pg_search.pkg
  sudo installer -pkg ~/Downloads/pg_search.pkg -target /
  ```
</CodeGroup>

### ParadeDB Enterprise

If you are a [ParadeDB Enterprise](/deploy/enterprise) user, you should have received a copy of the enterprise binaries. Please [contact sales](mailto:sales@paradedb.com) for access.

## Update `postgresql.conf`

Next, add the extension(s) to `shared_preload_libraries` in `postgresql.conf`.

```ini theme={null}
shared_preload_libraries = 'pg_search'
```

Reload the Postgres server for these changes to take effect.

## Load the Extension

Finally, connect to your Postgres database via your client of choice (e.g. `psql`) and run the following command:

```sql theme={null}
CREATE EXTENSION pg_search;
```

<Note>
  `pg_search` can be combined with `pgvector` for hybrid search. You can find
  the instructions for installing `pgvector` [on the `pgvector` GitHub
  repository](https://github.com/pgvector/pgvector?tab=readme-ov-file#installation).
</Note>


# High Availability
Source: https://docs.paradedb.com/deploy/self-hosted/high-availability

Use read replicas to minimize downtime in production

High availability (HA) minimizes downtime in the event of failures and is crucial for production deployments. To achieve high availability, you need to have
[ParadeDB Enterprise](/deploy/enterprise) deployed inside a [CNPG Kubernetes cluster](/deploy/self-hosted/kubernetes).

## How High Availability Works

In a highly available configuration, ParadeDB deploys as a cluster of Postgres instances. One instance is designated as the **primary** while the other instances are designated as
**standby** instances. The primary server sends write-ahead logs (WAL) to the standby servers, which replicate the primary by replaying these logs.

If the primary server goes down, a standby server is promoted to become the new primary server. This process is called failover.

For a thorough architecture overview, please consult the [CloudNativePG Architecture documentation](https://cloudnative-pg.io/docs/1.28/architecture).

## Enable High Availability

Prior to starting the CNPG cluster, modify the `values.yaml` file to increase the number of instances.

```yaml ParadeDB Enterprise theme={null}
type: paradedb-enterprise
mode: standalone

cluster:
  instances: 3
  storage:
    size: 256Mi
```

The number of replicas is equal to `instances - 1`. Having at least `3` instances guarantees that a standby will be available even while a failover process is occurring.

## Synchronous Replication

Between physical replicas, ParadeDB requires the use of a few settings (which are automatically set by [CNPG](/deploy/self-hosted/kubernetes)) in order to avoid query cancellation due to ongoing reorganization of the data on the primary replica.

* `hot_standby_feedback=on` - The [`hot_standby_feedback`](https://www.postgresql.org/docs/current/runtime-config-replication.html#GUC-HOT-STANDBY-FEEDBACK) setting controls whether nodes acting as `hot_standby`s (the replicas in physical replication) send feedback to the leader about their current transaction status. ParadeDB uses this transaction status to determine when it is safe for the primary to garbage collect its segments.
* `primary_slot_name=$something` - The [`primary_slot_name`](https://www.postgresql.org/docs/current/runtime-config-replication.html#GUC-PRIMARY-SLOT-NAME) setting declares the name of the replication slot that a replica should use when it connects to the primary. In order for `hot_standby_feedback` to be used and persistent, a replication slot must be used.

Without these settings, ParadeDB physical replicas will see much more frequent query cancels, and will report a message recommending that they are used.

## Asynchronous vs. Synchronous Replication

By default, ParadeDB ships with asynchronuous replication, meaning transactions on the primary **do not** wait for confirmation from
the standby instances before committing.

**Quorum-based synchronous replication** ensures that a transaction is successfully written to standbys before it completes.
Please consult the [CloudNativePG Replication documentation](https://cloudnative-pg.io/docs/1.28/replication#synchronous-replication) for details.

## Backup and Disaster Recovery

ParadeDB supports backups to cloud object stores (e.g. S3, GCS, etc.) and point-in-time-recovery
via [Barman](https://pgbarman.org/). To configure the frequency and location of backups, please consult the [CloudNativePG Backup documentation](https://cloudnative-pg.io/docs/1.28/backup).


# Kubernetes
Source: https://docs.paradedb.com/deploy/self-hosted/kubernetes

How to deploy ParadeDB as a Kubernetes cluster into production

Kubernetes is the recommended way to run ParadeDB in production. Both ParadeDB Community and Enterprise binaries
can be deployed on Kubernetes.

<Note>
  We recommend running ParadeDB Enterprise, not Community, with Kubernetes in
  production to maximize uptime. See [overview](/deploy/overview#self-hosted).
</Note>

This guide uses the [ParadeDB Helm Chart](https://github.com/paradedb/charts). The chart is also available on [Artifact Hub](https://artifacthub.io/packages/helm/paradedb/paradedb).

## Prerequisites

This guide assumes you have installed [Helm](https://helm.sh/docs/intro/install/) and have a Kubernetes cluster running v1.25+.
For local testing, we recommend [Minikube](https://minikube.sigs.k8s.io/docs/start/).

## Install the Prometheus Stack

The ParadeDB Helm chart supports monitoring via Prometheus and Grafana. To enable this, you need to have the Prometheus CRDs installed before installing the CloudNativePG operator. If you do not yet have the Prometheus CRDs installed on your Kubernetes cluster, you can install it with:

```bash theme={null}
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --atomic --install prometheus-community \
--create-namespace \
--namespace prometheus-community \
--values https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/kube-stack-config.yaml \
prometheus-community/kube-prometheus-stack
```

## Install the CloudNativePG Operator

Skip this step if the CloudNativePG operator is already installed in your cluster. If you do not wish to monitor your cluster, omit the `--set` commands.

```bash theme={null}
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --atomic --install cnpg \
--create-namespace \
--namespace cnpg-system \
--set monitoring.podMonitorEnabled=true \
--set monitoring.grafanaDashboard.create=true \
cnpg/cloudnative-pg
```

## Start a ParadeDB CNPG Cluster

Create a `values.yaml` and configure it to your requirements. Here is a basic example:

<CodeGroup>
  ```yaml ParadeDB Community theme={null}
  type: paradedb
  mode: standalone

  cluster:
    instances: 1
    storage:
      size: 256Mi
  ```

  ```yaml ParadeDB Enterprise theme={null}
  type: paradedb-enterprise
  mode: standalone

  cluster:
    instances: 1
    storage:
      size: 256Mi
  ```
</CodeGroup>

<Note>
  If you are using ParadeDB Enterprise, `instances` should be set to a number
  greater than `1` for [high
  availability](/deploy/self-hosted/high-availability).
</Note>

Next, create a namespace for this step or use an existing namespace. The namespace can be any value.

```bash theme={null}
kubectl create namespace <your-namespace>
```

For ParadeDB Enterprise, you should have received an enterprise Docker username and personal access token. The following step passes these
credentials to Kubernetes and should be skipped if you are deploying ParadeDB Community.

```bash ParadeDB Enterprise theme={null}
kubectl create secret docker-registry paradedb-enterprise-registry-cred
--namespace <your-namespace>
--docker-server="https://index.docker.io/v1/"
--docker-username="<enterprise_docker_username>"
--docker-password="<enterprise_docker_access_token>"
```

Finally, launch the ParadeDB cluster.

```bash theme={null}
helm repo add paradedb https://paradedb.github.io/charts
helm upgrade --atomic --install paradedb \
--namespace <your-namespace> \
--values values.yaml \
--set cluster.monitoring.enabled=true \
paradedb/paradedb
```

## Connect to the Cluster

The command to connect to the primary instance of the cluster will be printed in your terminal. If you do not modify any settings, it will be:

```bash theme={null}
kubectl --namespace paradedb exec --stdin --tty services/paradedb-rw -- bash
```

This will launch a Bash shell inside the instance. You can connect to the ParadeDB database via `psql` with:

```bash theme={null}
psql -d paradedb
```

## Connect to the Grafana Dashboard

To connect to the Grafana dashboard for your cluster, we suggested port forwarding the Kubernetes service running Grafana to localhost:

```bash theme={null}
kubectl --namespace prometheus-community port-forward svc/prometheus-community-grafana 3000:80
```

`You can then access the Grafana dasbhoard at `localhost:3000` using the credentials`admin`as username
and`prom-operator` as password. These default credentials are defined in the [`kube-stack-config.yaml`](https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/kube-stack-config.yaml)
file used as the `values.yaml`file in [Installing the Prometheus CRDs](#installing-the-prometheus-stack) and can be modified by providing
your own`values.yaml\` file. A more detailed guide on monitoring the cluster can be found in the [CloudNativePG documentation](https://cloudnative-pg.io/docs/1.28/monitoring).


# Installing Third Party Extensions
Source: https://docs.paradedb.com/deploy/third-party-extensions

How to install additional extensions into ParadeDB

<Note>
  [Foreign data
  wrapper](https://www.postgresql.org/docs/current/ddl-foreign-data.html)
  extensions can be used to query AWS S3 and other external data stores directly
  from ParadeDB.
</Note>

Postgres has a rich ecosystem of extensions. ParadeDB is designed to work alongside other PostgreSQL extensions for a complete data platform.

## Pre-installed Extensions

To keep the ParadeDB Docker image size manageable, the following extensions are pre-installed:

* **`pg_search`** — Full-text and hybrid search with BM25
* **`pgvector`** — Vector similarity search
* **`postgis`** — Geospatial queries and indexing
* **`pg_ivm`** — Incremental materialized views
* **`pg_cron`** — Scheduled jobs and background tasks

<Note>
  `pg_cron` is configured on the default `postgres` database and cannot be
  changed.
</Note>

## Compatible Extensions

ParadeDB has been tested with and supports the following popular extensions:

* **[Citus](/deploy/citus)** — Distributed PostgreSQL for horizontal scaling
* **`pg_partman`** — Automated partition management
* **`pg_stat_statements`** — Query performance monitoring
* **`postgres_fdw`** — Foreign data wrappers for federated queries

<Note>
  If you encounter any issues with extension compatibility, please [open an
  issue](https://github.com/paradedb/paradedb/issues) or reach out to our
  [community](https://www.paradedb.com/slack).
</Note>

## Installing Third Party Extensions

The process for installing an extension varies by extension. Generally speaking, it requires:

* Download the prebuilt binaries inside ParadeDB
* Install the extension binary and any dependencies inside ParadeDB
* Add the extension to `shared_preload_libraries` in `postgresql.conf`, if required by the extension
* Run `CREATE EXTENSION <extension name>`

We recommend installing third party extensions from prebuilt binaries to keep the image size small. As an
example, let's install [pg\_partman](https://github.com/pgpartman/pg_partman), an extension for managing table partition sets.

### Install Prebuilt Binaries

First, enter a shell with root permissions in the ParadeDB image.

```bash theme={null}
docker exec -it --user root paradedb bash
```

<Note>
  This command assumes that your ParadeDB container name is `paradedb`.
</Note>

Next, install the [prebuilt binaries](https://pkgs.org/search/?q=partman).
Most popular Postgres extensions can be installed with `apt-get install`.

```bash theme={null}
apt-get update
apt-get install -y --no-install-recommends postgresql-17-partman
```

<Note>
  If the extension is not available with `apt-get install`, you can usually
  `curl` the prebuilt binary from a GitHub Release page. You will need to first
  install `curl` via `apt-get install` if you are taking this approach.
</Note>

### Add to `shared_preload_libraries`

<Accordion title="Modifying shared_preload_libraries">
  If you are installing an extension which requires this step, you can do so
  via the following command, replacing `<extension_name>` with your extension's name:

  ```bash theme={null}
  sed -i "/^shared_preload_libraries/s/'\([^']*\)'/'\1,<extension_name>'/" /var/lib/postgresql/data/postgresql.conf
  ```

  For `pg_partman`, the command is:

  ```bash theme={null}
  sed -i "/^shared_preload_libraries/s/'\([^']*\)'/'\1,pg_partman_bgw'/" /var/lib/postgresql/data/postgresql.conf
  ```
</Accordion>

Postgres must be restarted afterwards. We recommend simply restarting the Docker container.

### Create the Extension

Connect to ParadeDB via `psql` and create the extension.

```sql theme={null}
CREATE EXTENSION pg_partman;
```

`pg_partman` is now ready to use!

Note that this is a simple example of installing `pg_partman`. The full list of settings and optional dependencies can be found in the [official installation instructions](https://github.com/pgpartman/pg_partman?tab=readme-ov-file#installation).


# Upgrading ParadeDB
Source: https://docs.paradedb.com/deploy/upgrading

How to update ParadeDB to the latest version

## Overview

ParadeDB ships its functionality inside a Postgres extension, `pg_search`. Upgrading ParadeDB is as simple as updating the `pg_search` extension.

<Note>
  ParadeDB uses `pgvector` for vector search. This extension is not managed by
  ParadeDB. Please refer to the [pgvector
  documentation](https://github.com/pgvector/pgvector?tab=readme-ov-file#upgrading)
  for instructions on how to upgrade it.
</Note>

## Getting the Current Version

To inspect the current version of an extension, run the following command.

```sql theme={null}
SELECT extversion FROM pg_extension WHERE extname = 'pg_search';
```

Verify that it matches `paradedb.version_info()`:

```sql theme={null}
SELECT * FROM paradedb.version_info();
```

The reason that there are two statements is because `paradedb.version_info()` is the actual version of `pg_search` that is installed,
whereas `pg_extension` is what Postgres' catalog thinks the version of the extension is.

If `paradedb.version_info()` is greater than `pg_extension`, it typically means that `ALTER EXTENSION` was not run after the previous upgrade, and that the SQL upgrade scripts were not applied.
If `pg_extension` is greater than `paradedb.version_info()`, it means that the extension didn't fully upgrade, and that Postgres needs to be restarted.

## Getting the Latest Version

The latest version of `pg_search` is `0.22.6`. Please refer to the [releases](https://github.com/paradedb/paradedb/releases) page for all available versions of `pg_search`.

## Updating ParadeDB

### Helm Chart

To upgrade the ParadeDB Helm chart:

1. Update the `paradedb` chart to the latest version.

```bash theme={null}
helm repo update
```

2. Get the latest version of the `paradedb` chart.

```bash theme={null}
helm search repo paradedb
```

3. Get the latest version of the ParadeDB extension, which is the value of `version.paradedb` in the chart [README](https://github.com/paradedb/charts/tree/main/charts/paradedb#values).

4. Run `helm upgrade` with the latest version of the chart and the latest version of the extension.

```bash theme={null}
helm upgrade paradedb paradedb/paradedb --namespace paradedb --reuse-values --version <helm_version> --set version.paradedb=<paradedb_version> --atomic
```

Replace `<helm_version>` with the latest version of the chart and `<paradedb_version>` with the latest version of the extension.

5. If you are using [ParadeDB BYOC](/deploy/byoc), an automatic rollout will begin. One by one, the pods will be restarted to apply the new version of the extension.

### Docker Image

To upgrade the ParadeDB Docker image while preserving your data volume:

1. Stop the ParadeDB Docker image via `docker stop paradedb`.

2. Run the following command to pull a specific version of the Docker image. You can set the version number
   to `latest` to pull the latest Docker image. You can find the full list of available tags on [Docker Hub](https://hub.docker.com/r/paradedb/paradedb/tags).

```bash theme={null}
docker pull paradedb/paradedb:0.22.6
```

The latest version of the Docker image should be `0.22.6`.

3. Start the new ParadeDB Docker image via `docker run paradedb`.

### Self-Managed Postgres

To upgrade the extensions running in a self-managed Postgres:

1. Stop Postgres (e.g. `pg_ctl stop -D </path/to/data/directory>`).
2. Download and install the extension you wish to upgrade in the same way that it was initially installed.
3. Start Postgres (e.g. `pg_ctl start -D </path/to/data/directory>`).

## Alter Extension

After ParadeDB has been upgraded, connect to it and run the following command in all databases that `pg_search` is installed in. This step is required regardless of the environment that ParadeDB is installed in (Helm, Docker, or self-managed Postgres).

```sql theme={null}
ALTER EXTENSION pg_search UPDATE TO '0.22.6';
```

## Verify the Upgrade

After upgrading the extension and restarting Postgres, verify that the version numbers returned by the following commands match:

```sql theme={null}
SELECT extversion FROM pg_extension WHERE extname = 'pg_search';
SELECT * FROM paradedb.version_info();
```

If the two versions do not match, restart Postgres and try again.

