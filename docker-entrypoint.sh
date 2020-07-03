#!/bin/bash

source /etc/firebird/3.0/SYSDBA.password

set -x

sed -i -e '/RemoteBindAddress =/ s/= .*/= /' /etc/firebird/3.0/firebird.conf

export DB_DIR=/var/lib/firebird/3.0/data

# init directory contains metadata that we ship with the image
INIT_DIR=/etc/firebird/3.0/init
INIT_GEN_DIR=/var/lib/firebird/3.0/init

# configuration injected on the fly (e.g. via k8s configmap)
CONF_DIR=/etc/firebird/3.0/conf.d

mkdir -p ${DB_DIR}
mkdir -p ${INIT_GEN_DIR}


if [ -f "${INIT_DIR}/tables.conf" ]; then
    readarray -t TABLE_NAMES <"${INIT_DIR}/tables.conf"
fi

if [ -f "${CONF_DIR}/databases.conf" ]; then
    readarray -t DATABASE_NAMES <"${CONF_DIR}/databases.conf"
fi


USER_CONF=$(
cat<<EOF
CREATE DATABASE '${DB_DIR}/global.fdb';
CREATE USER machine PASSWORD '${FIREBIRD_PASSWORD}';
CREATE USER replicant PASSWORD '${FIREBIRD_PASSWORD}';
COMMIT;
EOF
)

if [ ! -f "${DB_DIR}/global.fdb" -a -n "${FIREBIRD_PASSWORD}" ]; then
    echo "${USER_CONF}" | isql-fb -q
fi

source /usr/local/bin/database-init.sh

for FIREBIRD_DATABASE in ${DATABASE_NAMES[@]}; do

    exits=$(grep "${DB_DIR}/${FIREBIRD_DATABASE}" /etc/firebird/3.0/databases.conf)
    if [ "$?" -ne 0 ]; then
        echo "${FIREBIRD_DATABASE} = ${DB_DIR}/${FIREBIRD_DATABASE}.fdb" >> /etc/firebird/3.0/databases.conf
    fi

    if [ ! -f "${DB_DIR}/${FIREBIRD_DATABASE}.fdb" ]; then
        database_init "${FIREBIRD_DATABASE}"
    fi
done

exec /usr/sbin/fbguard
