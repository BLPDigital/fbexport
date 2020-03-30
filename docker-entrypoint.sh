#!/bin/bash

source /etc/firebird/3.0/SYSDBA.password

sed -i -e '/RemoteBindAddress =/ s/= .*/= /' /etc/firebird/3.0/firebird.conf

export DB_DIR=/var/lib/firebird/3.0/data
INIT_DIR=/etc/firebird/3.0/init
GEN_CONF_DIR=/var/lib/firebird/3.0/init

mkdir -p ${DB_DIR}
mkdir -p ${GEN_CONF_DIR}

# TODO: move this step to metadata extraction
sed -i -e "s/SUB_TYPE BLR/SUB_TYPE BINARY/g" ${INIT_DIR}/db_meta.sql

if [ -f "${INIT_DIR}/tables.conf" ]; then
    readarray -t TABLE_NAMES <"${INIT_DIR}/tables.conf"

    # Generate schema common to all databases
    echo ${TABLE_NAMES[*]} | xargs -n 1 | xargs -I{} awk '/CREATE TABLE {} \(/,/^$/' ${INIT_DIR}/db_meta.sql >>${GEN_CONF_DIR}/db_create_tables.sql
    echo ${TABLE_NAMES[*]} | xargs -n 1 | xargs -I{} awk '/CREATE INDEX [^ ]+ ON {} /' ${INIT_DIR}/db_meta.sql >>${GEN_CONF_DIR}/db_create_index.sql
fi

if [ -f "${INIT_DIR}/databases.conf" ]; then
    readarray -t DATABASE_NAMES <"${INIT_DIR}/databases.conf"
fi


USER_CONF=$(
cat<<EOF
CREATE DATABASE '${DB_DIR}/global.fdb';
CREATE USER machine PASSWORD '${FIREBIRD_PASSWORD}';
COMMIT;
EOF
)

if [ ! -f "${DB_DIR}/global.fdb" -a -n "${FIREBIRD_PASSWORD}" ]; then
    echo "${USER_CONF}" | isql-fb
fi

source /usr/local/bin/database-init.sh

for FIREBIRD_DATABASE in ${DATABASE_NAMES[@]}; do
    if [ ! -f "${DB_DIR}/${FIREBIRD_DATABASE}.fdb" ]; then
        database_init "${FIREBIRD_DATABASE}"
    fi
done

exec /usr/sbin/fbguard
