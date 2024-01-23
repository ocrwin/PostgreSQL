#!/bin/bash

EXIT_SUCCESS=0
EXIT_FAILURE=255
ERR_NOT_POSTGRES_ID=-100
ERR_NOT_ENOUGH_ARGUMENTS=-101
ERR_NOT_NUMERIC=-102
ERR_YEAR_NOT_IN_4_CHARS=-103
ERR_MONTH_NOT_IN_2_CHARS=-104

POSTGRES_ID=$(id -u postgres)

display_usage() { 
        echo "*******************************************************"
        echo "* CAREFUL : This script must be run as postgres user. *" 
        echo "*******************************************************"
        echo -e "\nUsage: $0 YYYY MM" 
        echo -e "Example: $0 2023 05\n" 
}

is_numeric() {
        if ! [[ "$1" =~ ^[0-9]+$ ]] ; then
                echo -e "\nError: $1 is not a number\n" 
                display_usage; exit $ERR_NOT_NUMERIC
        fi
}

# if the script is not run as postgres user, display usage
if [[ "$EUID" -ne "$POSTGRES_ID" ]] ; then 
        display_usage; exit $ERR_NOT_POSTGRES_ID
fi 

# if less than two arguments supplied, display usage
if [[ $# -lt 2 ]] ; then
        display_usage; exit $ERR_NOT_ENOUGH_ARGUMENTS
fi

# check whether user has supplied -h or --help, if yes display usage
if [[ ( $@ == "--help") ||  $@ == "-h" ]] ; then
        display_usage; exit $EXIT_SUCCESS
fi

# check if arguments are correct
YEAR=$1
MONTH=$2
is_numeric $YEAR
is_numeric $MONTH

if [[ "${#YEAR}" -lt 4 || "${#YEAR}" -gt 4 ]] ; then
        display_usage; exit $ERR_YEAR_NOT_IN_4_CHARS
fi

if [[ "${#MONTH}" -lt 2 || "${#MONTH}" -gt 2 ]] ; then
        display_usage; exit $ERR_MONTH_NOT_IN_2_CHARS
fi

# main program
echo -e "psql -d mydb -c \"create table cleaning.mytable_raw_${YEAR}_${MONTH} as select * from myschema.mytable_raw where date_part('month', created) = $MONTH;\""
psql -d mydb -c "create table cleaning.mytable_raw_${YEAR}_${MONTH} as select * from myschema.mytable_raw where date_part('month', created) = $MONTH;" &
wait $!

if [[ $? -gt 0 ]] ; then
        exit $EXIT_FAILURE
fi

echo -e "pg_dump -F p -Z 6 -t cleaning.mytable_raw_${YEAR}_${MONTH} mydb > /backups/ondemand/mytable_raw_${YEAR}_${MONTH}.pgdump.gz"
pg_dump -F p -Z 6 -t cleaning.mytable_raw_${YEAR}_${MONTH} mydb > /backups/ondemand/mytable_raw_${YEAR}_${MONTH}.pgdump.gz &
wait $!

if [[ $? -gt 0 ]] ; then
        exit $EXIT_FAILURE
fi

echo -e "psql -d mydb -c \"delete from myschema.mytable_raw where date_part('month', created) = ${MONTH};\"" &
psql -d mydb -c "delete from myschema.mytable_raw where date_part('month', created) = ${MONTH};" &
wait $!

if [[ $? -gt 0 ]] ; then
        exit $EXIT_FAILURE
fi

echo -e "psql -d mydb -c \"drop table cleaning.mytable_raw_${YEAR}_${MONTH};\"" &
psql -d mydb -c "drop table cleaning.mytable_raw_${YEAR}_${MONTH};" &
wait $!

if [[ $? -gt 0 ]] ; then
        exit $EXIT_FAILURE
fi

exit $EXIT_SUCCESS