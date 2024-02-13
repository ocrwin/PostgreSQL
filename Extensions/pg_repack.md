# pg_repack - Reorganize tables in PostgreSQL databases with minimal locks

## Source
[https://reorg.github.io/pg_repack/]()

## Downtime
NO

## What is it ?
pg_repack is a PostgreSQL extension which lets you remove bloat from tables and indexes, and optionally restore the physical order of clustered indexes. Unlike CLUSTER and VACUUM FULL it works online, without holding an exclusive lock on the processed tables during processing. 

## ALWAYS USE -D
Always use -D (--no-kill-backend) as it will not kill other backends when timed out.

## How does it work ?
pg_repack will:

- create a log table to record changes made to the original table
- add a trigger onto the original table, logging INSERTs, UPDATEs and DELETEs into our log table
- create a new table containing all the rows in the old table
- build indexes on this new table
- apply all changes which have accrued in the log table to the new table
- swap the tables, including indexes and toast tables, using the system catalogs
- drop the original table

pg\_repack will only hold an ACCESS EXCLUSIVE lock for a short period during initial setup and during the final swap-and-drop phase. For the rest of its time, pg_repack only needs to hold an ACCESS SHARE lock on the original table, meaning INSERTs, UPDATEs, and DELETEs may proceed as usual.

## What happens when there are too many accesses to the table ?
```
postgres@db001:~$ pg_repack -D -d mydb -p 5432 -t myschema.mytable
INFO: repacking table "myschema.mytable"
WARNING: timed out, do not cancel conflicting backends
INFO: Skipping repack myschema.mytable due to timeout
```
