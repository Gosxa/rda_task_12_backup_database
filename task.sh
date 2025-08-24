#! /bin/bash

DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"

if [[ -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
  echo "Error: DB_USER and DB_PASSWORD environment variables must be set."
  exit 1
fi

mysqldump -u "$DB_USER" -p"$DB_PASSWORD" ShopDB --no-create-db --result-file=ShopDBdb_nodb_backup.sql
mysql -u "$DB_USER" -p"$DB_PASSWORD" ShopDBReserve < ShopDBdb_nodb_backup.sql

mysqldump -u "$DB_USER" -p"$DB_PASSWORD" ShopDB --no-create-db --no-create-info --result-file=ShopDBdb_nodb_noinfo_backup.sql
mysql -u "$DB_USER" -p"$DB_PASSWORD" ShopDBDevelopment < ShopDBdb_nodb_noinfo_backup.sql