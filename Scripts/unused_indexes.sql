CREATE VIEW stats_index_aggregate as
-- Index for partitionned tables
select 
    'partitioned index' as indextype,
    nsp.nspname as schemaname,
    table_class.relname as tablename,
    parent_class.relname as indexname,
    index_columns.idx_columns as idx_columns,
    seek_childs.nb_child_index,
    seek_childs.nb_scans,
    seek_childs.index_size
from pg_class parent_class
join pg_index parent_index on parent_index.indexrelid = parent_class.oid
join pg_namespace nsp on nsp.oid = parent_class.relnamespace -- to get schemaname
join pg_class table_class on table_class.oid = parent_index.indrelid
, lateral (
    select count(stats_child.idx_scan) as nb_child_index,
    sum(stats_child.idx_scan) as nb_scans,
    sum(pg_relation_size(stats_child.indexrelid)) as index_size
    from pg_catalog.pg_stat_user_indexes stats_child
    join pg_inherits pi on pi.inhrelid = stats_child.indexrelid 
    where pi.inhparent = parent_class.oid
) seek_childs
, LATERAL (
    SELECT string_agg(attname, ', ' order by attnum) AS idx_columns
    FROM   pg_attribute
    WHERE  attrelid = parent_class.oid
) index_columns
where parent_class.relkind = 'I'
    AND 0 <>ALL (parent_index.indkey)  -- no index column is an expression
    AND NOT parent_index.indisunique   -- is not a UNIQUE index
    AND NOT EXISTS          -- does not enforce a constraint
    (SELECT 1 FROM pg_catalog.pg_constraint cc WHERE cc.conindid = parent_index.indexrelid)
    and table_class.relname not like '%template' -- filter for template tables
union
-- Index for regular tables
select 
    'regular index' as indextype,
    stats_child.schemaname,
    stats_child.relname AS tablename,
    c.relname as indexname,
    index_columns.idx_columns as idx_columns,
    null as nb_child_index,
    stats_child.idx_scan as id_scan_count,
    pg_relation_size(stats_child.indexrelid) as index_size
from pg_class c
join pg_index idx_parent on idx_parent.indexrelid = c.oid
join pg_catalog.pg_stat_user_indexes stats_child on c.oid = stats_child.indexrelid 
, LATERAL (
    SELECT string_agg(attname, ', ' order by attnum) AS idx_columns
    FROM   pg_attribute
    WHERE  attrelid = c.oid
) index_columns
where c.relkind = 'i'
     AND 0 <>ALL (idx_parent.indkey)  -- no index column is an expression
     AND NOT idx_parent.indisunique   -- is not a UNIQUE index
     AND NOT EXISTS          -- does not enforce a constraint
         (SELECT 1 FROM pg_catalog.pg_constraint cc
          WHERE cc.conindid = idx_parent.indexrelid)
     AND NOT EXISTS          -- is not a child index
         (SELECT 1 FROM pg_inherits pi 
         where pi.inhrelid = c.oid)
     and stats_child.relname not like '%template';  -- filter for template tables
