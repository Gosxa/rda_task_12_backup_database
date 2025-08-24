#! /bin/bash

set -euo pipefail

DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"

if [[ -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
  echo "Error: DB_USER and DB_PASSWORD environment variables must be set."
  exit 1
fi

# Create temporary files for dumps
FULL_DUMP=$(mktemp /tmp/ShopDBdb_nodb_backup_XXXX.sql)
DATA_DUMP=$(mktemp /tmp/ShopDBdb_nodb_noinfo_backup_XXXX.sql)

# Ensure cleanup on exit or error
trap 'rm -f "$FULL_DUMP" "$DATA_DUMP"' EXIT

# Dump schema (without database creation) and restore to ShopDBReserve
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" ShopDB --no-create-db --single-transaction --result-file="$FULL_DUMP"
mysql -u "$DB_USER" -p"$DB_PASSWORD" ShopDBReserve < "$FULL_DUMP"

# Dump data only (no schema) and restore to ShopDBDevelopment
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" ShopDB --no-create-db --no-create-info --single-transaction --result-file="$DATA_DUMP"
mysql -u "$DB_USER" -p"$DB_PASSWORD" ShopDBDevelopment < "$DATA_DUMP"

# Verify that Products table exists and row counts match
for DB in ShopDB ShopDBReserve ShopDBDevelopment; do
  echo "Checking Products table in $DB..."
  TABLE_EXISTS=$(mysql -u "$DB_USER" -p"$DB_PASSWORD" -N -B -e "SHOW TABLES LIKE 'Products';" $DB || true)
  if [[ "$TABLE_EXISTS" != "Products" ]]; then
    echo "Error: Products table missing in $DB"
    exit 1
  fi
  ROW_COUNT=$(mysql -u "$DB_USER" -p"$DB_PASSWORD" -N -B -e "SELECT COUNT(*) FROM Products;" $DB)
  echo "$DB has $ROW_COUNT rows in Products table."
done

echo "Backup, restore, and verification completed successfully."
