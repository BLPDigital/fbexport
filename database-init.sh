#!/bin/bash

DATA_DIR=/mnt/firebird-init

GENERATED_FILES=(
    "db_create_tables.sql"
    "db_create_index.sql"
)

function load_data() {
    local DATABASE="$1"

    echo "Loading data for ${DATABASE}..."

    for TABLE in "${TABLE_NAMES[@]}"; do
        if [ -f "${DATA_DIR}/${DATABASE}/${TABLE}.fbx" ]; then
            fbexport -I -A WIN1252 -V ${TABLE} \
                -H "" -U "${ISC_USER}" -P "${ISC_PASSWORD}" \
                -D "${DB_DIR}/${DATABASE}.fdb" \
                -F "${DATA_DIR}/${DATABASE}/${TABLE}.fbx" \
                -R
        fi
    done
}

function database_init() {
    export FIREBIRD_DATABASE=$1

    cat "${INIT_DIR}/db_create.sql" | envsubst | isql-fb -q

    for filename in ${GENERATED_FILES[@]}; do
        isql-fb -i "${INIT_GEN_DIR}/${filename}" "${DB_DIR}/${FIREBIRD_DATABASE}.fdb"
    done

    isql-fb -i "${INIT_DIR}/db_auth.sql" "${DB_DIR}/${FIREBIRD_DATABASE}.fdb"


    if [ -d "${DATA_DIR}/${FIREBIRD_DATABASE}" ]; then
        load_data "${FIREBIRD_DATABASE}"
    fi
}

