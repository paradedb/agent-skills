> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# How to Tune ParadeDB

> Settings for better read and write performance

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
