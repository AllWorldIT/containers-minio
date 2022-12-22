#!/bin/sh

set -ex

chown -R minio:minio /var/lib/minio

chown root:minio /var/lib/minio
chmod 0770 /var/lib/minio

echo "NOTICE: Initializing settings"

if [ -z "$MINIO_ROOT_USER" ]; then
	echo "WARNING: Environment variable 'MINIO_ROOT_USER' not set, minio will use defaults!"
	export MINIO_ROOT_USER=minioadmin
fi

if [ -z "$MINIO_ROOT_PASSWORD" ]; then
	echo "WARNING: Environment variable 'MINIO_ROOT_PASSWORD' not set, minio will use defaults!"
	export MINIO_ROOT_PASSWORD=minioadmin
fi

# Create minio configuration directory
chown root:minio /etc/minio
chmod 0750 /etc/minio

# Write out environment and fix perms of the config file
set | grep '^MINIO_' > /etc/minio/minio.conf || true
chown root:minio /etc/minio/minio.conf
chmod 0640 /etc/minio/minio.conf
