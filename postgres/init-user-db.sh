#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER devprom;
    ALTER USER devprom WITH PASSWORD '$POSTGRES_DEVPROM_PASSWORD';
	CREATE DATABASE devprom WITH OWNER = devprom;
	GRANT ALL PRIVILEGES ON DATABASE devprom TO devprom;
EOSQL
