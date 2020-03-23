#!/bin/bash

source /etc/firebird/3.0/SYSDBA.password

sed -i -e '/RemoteBindAddress =/ s/= .*/= /' /etc/firebird/3.0/firebird.conf
echo "${FIREBIRD_DATABASE} = /var/lib/firebird/3.0/data/${FIREBIRD_DATABASE}.fdb" >> /etc/firebird/3.0/databases.conf

DB_DIR=/var/lib/firebird/3.0/data
INIT_DIR=/etc/firebird/3.0/init
mkdir -p ${DB_DIR}

TABLE_NAMES=(
    "ARTIKEL"
    "BEST"
    "BESTERL"
    "BESTPOS"
    "CUSTOMER"
    "EINHEIT"
    "FIRMA"
    "LIEFRANT"
    "LIEFRANTERL"
    "NEBENKOS"
    "PEINHEIT"
    "REWAKON"
    "REWAKONABWMWST"
    "REWAKONERL"
    "REWAKONPOS"
    "REWAKONPROTOKOLL"
    "WAEIN"
    "WAEINERL"
    "WAEINPOS"
    "WAEINPOSP"
    "WANEBKOS"
    "WANEBKOSDEL"
)

SQLDUMP_FILES=(
    "db_create_tables.sql"
    "db_create_index.sql"
    "db_auth.sql"
)

sed -i -e "s/SUB_TYPE BLR/SUB_TYPE BINARY/g" ${INIT_DIR}/db_meta.sql
echo ${TABLE_NAMES[*]} | xargs -n 1 | xargs -I{} awk '/CREATE TABLE {} \(/,/^$/' ${INIT_DIR}/db_meta.sql >> ${INIT_DIR}/db_create_tables.sql
echo ${TABLE_NAMES[*]} | xargs -n 1 | xargs -I{} awk '/CREATE INDEX [^ ]+ ON {} /' ${INIT_DIR}/db_meta.sql >> ${INIT_DIR}/db_create_index.sql



if [ ! -f "${DB_DIR}/${FIREBIRD_DATABASE}.fdb" ]; then

    cat ${INIT_DIR}/db_create.sql | isql-fb
    for filename in ${SQLDUMP_FILES[@]}; do
        isql-fb -i ${INIT_DIR}/${filename} "${DB_DIR}/${FIREBIRD_DATABASE}.fdb"
    done
fi

exec /usr/sbin/fbguard