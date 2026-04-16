> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Alpha Numeric Only

> Removes any tokens that contain characters that are not ASCII letters

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
