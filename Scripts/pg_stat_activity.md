```
select 
	pid, 
	usename,
	client_addr, 
	backend_start, 
	query_start, 
	state, 
	wait_event, 
	wait_event_type, 
	substr(query,1,40) as query 
  from 
  	pg_stat_activity 
 where 
 	usename not in ('zbx_monitor', 'monitor') 
 	and datname='mydb' 
 order by backend_start;
```