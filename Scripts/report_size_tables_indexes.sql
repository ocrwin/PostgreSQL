select
        tablename
        , indexname
        ,  pg_size_pretty(pg_relation_size(tablename::regclass)) as table_size
        , pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
        , idx_scan
from
        pg_indexes
        join pg_stat_all_indexes on indexname = indexrelname
where
        pg_indexes.schemaname = 'myschema'
order by 1,2;
