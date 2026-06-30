#!/bin/bash
# Author: Praneeth_Perera

set -euo pipefail

BACKUP_DIR="/path/to/backups"
ENCR_DIR="${BACKUP_DIR}/encrypted"
LOG_FILE="${BACKUP_DIR}/logs/backup.log"
TIMESTAMP=$(date +"%d-%m-%y")
SECRET_KEY="your-gpg-key@domain.com"     # Change this
DB_NAME="your_database_name"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

log "Starting backup process..."

mkdir -p "$BACKUP_DIR" "$ENCR_DIR" "${BACKUP_DIR}/logs"

# Perform backup
pg_dump -h 127.0.0.1 -U postgres "$DB_NAME" > "$BACKUP_DIR/$TIMESTAMP-$DB_NAME.sql"

if [ $? -ne 0 ]; then
    log "ERROR: PostgreSQL backup failed"
    exit 1
fi

# Create compressed archive
tar -czvf "$BACKUP_DIR/$TIMESTAMP-DB.tar.gz" "$BACKUP_DIR/$TIMESTAMP-$DB_NAME.sql"

# Remove raw SQL
rm -f "$BACKUP_DIR/$TIMESTAMP-$DB_NAME.sql"

# Encrypt
gpg --trust-model always -r "$SECRET_KEY" -e "$BACKUP_DIR/$TIMESTAMP-DB.tar.gz"

# Cleanup
rm -f "$BACKUP_DIR/$TIMESTAMP-DB.tar.gz"
mv "$BACKUP_DIR/$TIMESTAMP-DB.tar.gz.gpg" "$ENCR_DIR/"

log "Backup completed successfully: $TIMESTAMP-DB.tar.gz.gpg"

Upload to S3
aws s3 cp "$ENCR_DIR/$TIMESTAMP-DB.tar.gz.gpg" s3://your-bucket/backups/

