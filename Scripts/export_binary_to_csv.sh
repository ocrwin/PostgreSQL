#!/bin/bash

array=( 2eda24g1-77fa-45e9-b860-a2d13ffffad0 a056725a-27f5-4b67-c646-ade7782d8840 ) 

	
for i in "${array[@]}"
do
  psql -d mydb -c "\copy (SELECT encode(content::bytea,'hex') from myschema.mytable where document_id='$i') to STDOUT" | xxd -p -r > $i.csv
done


