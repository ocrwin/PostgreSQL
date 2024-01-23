#!/bin/bash

for i in $(psql -t -c "select distinct(pid) from pg_locks where mode = 'RowExclusiveLock';");do psql -c "select pg_terminate_backend($i)"; done

for i in $(psql -t -c "select pid from pg_stat_activity where state = 'idle in transaction'";);do psql -c "select pg_terminate_backend($i)"; done

exit
