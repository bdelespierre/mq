# TODO

## Additional Aggregate Shortcuts

`%count` and `%rand` exist, but `%sum`, `%avg`, `%min`, and `%max` are absent. They follow the exact same alias pattern and are equally common in ad-hoc queries.

```bash
mq select %max price from products where category=:electronics
mq select %avg rating from reviews where product_id=:42
mq select %min created_at from orders
mq select %sum quantity from order_items where order_id=:7
```

## EXPLAIN Prefix

Prepending `EXPLAIN` to understand query plans is a common operation when debugging slow queries. A `%explain` token or `-e` flag could prepend it automatically, and `%explain-analyze` could use `EXPLAIN ANALYZE`.

```bash
mq %explain select %all from users where email=:john@example.com
mq -e select %all from orders where total %gt :100
```

## Query Bookmarks

A `~/.mq/queries/` directory where named queries can be saved and replayed.

```bash
mq --save active-users select %count from users where status=:active
mq --run active-users
```

## BETWEEN Operator

Given that `%gt`, `%lt`, etc. all exist, `%between` is a natural addition. It consumes two `:value` arguments.

```bash
mq select %all from orders where created_at %between :2024-01-01 :2024-12-31
mq select %all from products where price %between :10 :50
```
