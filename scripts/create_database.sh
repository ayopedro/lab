#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Database connection details
DB_CONTAINER_NAME="lab-postgres-1"
DB_USER="ayotunde"
DB_PASSWORD="password"
DB_NAME=""
DB_TYPE="postgres"
DRY_RUN=0

show_help() {
    cat <<'EOF'
Usage: create_database.sh [options]

Creates or recreates a Postgres or MySQL/MariaDB database inside a running Docker container.

Required:
    -n, --name <dbname>          Database name to create/recreate

Optional:
    -t, --type <postgres|mysql>  Database type (default: postgres)
    -u, --user <user>            DB user (default: ayotunde)
    -p, --password <password>    DB password (MySQL only; default: password)
    -c, --container <name>       Container name (default: lab-postgres-1)
    -f, --dump-file <file>       Dump file to restore (pg_restore / mysql import)
        -h, --help                   Show this help message
        --dry-run                    Show planned actions without executing

Examples:
    create_database.sh -n app_dev
    create_database.sh -n app_dev -t mysql -c lab-mysql-1 -u root -p secret
    create_database.sh -n app_dev -f ~/backups/app_dev.dump

Notes:
    For Postgres dumps use: pg_dump -Fc -U <user> <db> > file.dump
    Ensure the container is running before invoking.
EOF
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--user) DB_USER="$2"; shift 2 ;;
        -p|--password) DB_PASSWORD="$2"; shift 2 ;;
        -n|--name) DB_NAME="$2"; shift 2 ;;
        -c|--container) DB_CONTAINER_NAME="$2"; shift 2 ;;
        -f|--dump-file) DB_DUMP_FILE="$2"; shift 2 ;;
        -t|--type) DB_TYPE="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        --dry-run) DRY_RUN=1; shift ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

if [ -z "$DB_NAME" ]; then
    echo "❌ Database name is required. Use -n <dbname>"
    exit 1
fi

# Drop DB if exists
check_and_terminate() {
    local db_name="$1"
    local result

    if [ "$DB_TYPE" == "postgres" ]; then
        result=$(docker exec -i "$DB_CONTAINER_NAME" psql -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name'")
        if [ "$result" == "1" ]; then
            echo "⚠️ Dropping existing database $db_name"
                        if [[ $DRY_RUN -eq 1 ]]; then
                            echo "[dry-run] Terminate connections & drop database $db_name"
                        else
                            docker exec -i "$DB_CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$db_name' AND pid <> pg_backend_pid();"
                            docker exec -i "$DB_CONTAINER_NAME" dropdb -U "$DB_USER" "$db_name" || { echo "Failed to drop database $db_name"; exit 1; }
                        fi
        fi
    elif [ "$DB_TYPE" == "mysql" ]; then
        result=$(docker exec -i "$DB_CONTAINER_NAME" mariadb -u "$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES LIKE '$db_name';" | grep "$db_name")
        if [ "$result" == "$db_name" ]; then
            echo "⚠️ Dropping existing database $db_name"
                        if [[ $DRY_RUN -eq 1 ]]; then
                            echo "[dry-run] Drop database $db_name"
                        else
                            docker exec -i "$DB_CONTAINER_NAME" mariadb -u "$DB_USER" -p"$DB_PASSWORD" -e "DROP DATABASE $db_name;" || { echo "Failed to drop database $db_name"; exit 1; }
                        fi
        fi
    fi
}

# Create DB
create_or_recreate_database() {
    local db_name="$1"
    check_and_terminate "$db_name"

    if [ "$DB_TYPE" == "postgres" ]; then
        echo "✅ Creating PostgreSQL database $db_name"
                if [[ $DRY_RUN -eq 1 ]]; then
                    echo "[dry-run] Create PostgreSQL database $db_name"
                else
                    docker exec -i "$DB_CONTAINER_NAME" createdb -U "$DB_USER" "$db_name" || { echo "Failed to create database $db_name"; exit 1; }
                fi

        if [ -n "$DB_DUMP_FILE" ] && [ -f "$DB_DUMP_FILE" ]; then
            echo "📦 Restoring database from dump file $DB_DUMP_FILE"
                        if [[ $DRY_RUN -eq 1 ]]; then
                            echo "[dry-run] Restore dump $DB_DUMP_FILE into $db_name"
                        else
                            docker exec -i "$DB_CONTAINER_NAME" pg_restore -U "$DB_USER" -d "$db_name" < "$DB_DUMP_FILE" || { echo "Failed to restore database"; exit 1; }
                        fi
        fi
    elif [ "$DB_TYPE" == "mysql" ]; then
        echo "✅ Creating MySQL database $db_name"
                if [[ $DRY_RUN -eq 1 ]]; then
                    echo "[dry-run] Create MySQL database $db_name"
                else
                    docker exec -i "$DB_CONTAINER_NAME" mariadb -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE $db_name;" || { echo "Failed to create database $db_name"; exit 1; }
                fi

        if [ -n "$DB_DUMP_FILE" ] && [ -f "$DB_DUMP_FILE" ]; then
            echo "📦 Restoring database from dump file $DB_DUMP_FILE"
                        if [[ $DRY_RUN -eq 1 ]]; then
                            echo "[dry-run] Restore dump $DB_DUMP_FILE into $db_name"
                        else
                            docker exec -i "$DB_CONTAINER_NAME" mariadb -u "$DB_USER" -p"$DB_PASSWORD" "$db_name" < "$DB_DUMP_FILE" || { echo "Failed to restore database"; exit 1; }
                        fi
        fi
    fi
}

# Main
echo "🚀 Creating or recreating database $DB_NAME (type: $DB_TYPE) in container $DB_CONTAINER_NAME..."
create_or_recreate_database "$DB_NAME"
echo "🎉 Done!"