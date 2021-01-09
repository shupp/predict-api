#!/bin/bash

# To be run from a mysql container
# Operate from the directory of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

DB_ADDR=${DB_ADDR:-mysql}
DB_USER=${DB_USER:-predict-api}
DB_NAME=${DB_NAME:-predict-api}
SECRET_DB_PASS=${SECRET_DB_PASS:-password}

DATE=`date +%s`
OUTPUT_FILE=/tmp/seed-mysql-data-${DATE}.txt
printf "MySQL data seeding starting:\n"

RETURN_CODE=1
COUNT=0
SLEEP=1
LIMIT=60 # Let's only wait for 60 seconds before bailing

printf "Waiting for mysql service to be available ...\n"
while [ $RETURN_CODE -ne 0 ] && [ $COUNT -lt $LIMIT ]; do
    mysql -h ${DB_ADDR} -u ${DB_USER} -p${SECRET_DB_PASS} -e QUIT ${DB_NAME} >${OUTPUT_FILE} 2>&1
    RETURN_CODE=$?
    COUNT=$((COUNT + 1))

    if [ ${RETURN_CODE} -ne 0 ]; then
        sleep ${SLEEP}
    else
        printf "MySQL is now available\n"
        break
    fi
done

# Check for connection failure
if [ ${RETURN_CODE} != 0 ]; then
    printf "Unable to connect to mysql: "
    cat ${OUTPUT_FILE}
    rm ${OUTPUT_FILE}
    exit ${RETURN_CODE}
fi

# Expecting our files to be in .
printf "Creating tables: \n"
mysql -h ${DB_ADDR} -u ${DB_USER} -p${SECRET_DB_PASS} ${DB_NAME} < create-tables.sql >${OUTPUT_FILE} 2>&1
RETURN_CODE=$?
if [ ${RETURN_CODE} != 0 ] ; then
    printf "Unable to create tables: "
    cat ${OUTPUT_FILE}
    rm ${OUTPUT_FILE}
    exit ${RETURN_CODE}
else
    printf "done.\n"
fi
printf "Populating tables: \n"
mysql -h ${DB_ADDR} -u ${DB_USER} -p${SECRET_DB_PASS} ${DB_NAME} < ./data.sql >${OUTPUT_FILE} 2>&1
RETURN_CODE=$?
if [ ${RETURN_CODE} != 0 ] ; then
    printf "Unable to populate tables: "
    cat ${OUTPUT_FILE}
    rm ${OUTPUT_FILE}
    exit ${RETURN_CODE}
fi

printf "Adding timezones shapefile to db\n"
ogr2ogr -progress -lco engine=MYISAM -f MySQL \
    MySQL:${DB_NAME},user=${DB_USER},password=${SECRET_DB_PASS},host=${DB_ADDR} /combined-shapefile.shp

printf "done\n"

cat ${OUTPUT_FILE}
rm ${OUTPUT_FILE}
