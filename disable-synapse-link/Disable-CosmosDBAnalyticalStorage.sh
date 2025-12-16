#!/usr/bin/env bash

set -euo pipefail

# Default retry configuration matches PowerShell script
MAX_RETRIES=5
DELAY_SECONDS=5

print_usage() {
    cat <<'EOF'
Usage: Disable-CosmosDBAnalyticalStorage.sh --resource-group <name> --account-name <name> [--database-name <name>] [--list-enabled] [--yes]

Options:
  --resource-group, -g   Resource group name containing the Cosmos DB account (required)
  --account-name, -a     Cosmos DB account name (required)
  --database-name, -d    Specific database name to target (optional)
  --list-enabled, -l     Lists containers with analytical storage enabled without disabling
    --yes, -y              Skips the confirmation prompt before disabling analytical storage
  --help, -h             Show this help message
EOF
}

RESOURCE_GROUP=""
ACCOUNT_NAME=""
DATABASE_NAME=""
LIST_ENABLED=0
AUTO_CONFIRM=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --resource-group|-g)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        --account-name|-a)
            ACCOUNT_NAME="$2"
            shift 2
            ;;
        --database-name|-d)
            DATABASE_NAME="$2"
            shift 2
            ;;
        --list-enabled|-l)
            LIST_ENABLED=1
            shift 1
            ;;
        --yes|-y)
            AUTO_CONFIRM=1
            shift 1
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            print_usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$RESOURCE_GROUP" || -z "$ACCOUNT_NAME" ]]; then
    echo "--resource-group and --account-name are required" >&2
    print_usage >&2
    exit 1
fi

for tool in az jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required tool '$tool' not found. Install it before running this script." >&2
        exit 1
    fi
done

if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
    CYAN="$(tput setaf 6)"
    YELLOW="$(tput setaf 3)"
    GREEN="$(tput setaf 2)"
    RED="$(tput setaf 1)"
    MAGENTA="$(tput setaf 5)"
    WHITE="$(tput setaf 7)"
    DARK_YELLOW="$(tput setaf 3)"
    RESET="$(tput sgr0)"
else
    CYAN=""
    YELLOW=""
    GREEN=""
    RED=""
    MAGENTA=""
    WHITE=""
    DARK_YELLOW=""
    RESET=""
fi

invoke_with_retry() {
    local max_retries=$1
    local delay_seconds=$2
    shift 2

    local attempt=1
    local output
    while (( attempt <= max_retries )); do
        if output="$("$@")"; then
            printf '%s' "$output"
            return 0
        fi

        local status=$?
        if (( attempt == max_retries )); then
            return "$status"
        fi

        printf '  %sRetry %d/%d failed, waiting %d seconds...%s\n' "$DARK_YELLOW" "$attempt" "$max_retries" "$delay_seconds" "$RESET" >&2
        sleep "$delay_seconds"
        ((attempt++))
    done
}

if ! az account show >/dev/null 2>&1; then
    printf '%sNot logged into Azure. Initiating login...%s\n' "$YELLOW" "$RESET"
    az login >/dev/null
    printf '%sLogin successful. Initializing Azure context...%s\n' "$GREEN" "$RESET"
fi

printf '\n%sCosmos DB Analytical Storage Management%s\n' "$CYAN" "$RESET"
printf '%sAccount: %s | Resource Group: %s%s\n\n' "$WHITE" "$ACCOUNT_NAME" "$RESOURCE_GROUP" "$RESET"

databases_json=""
if [[ -n "$DATABASE_NAME" ]]; then
    if ! databases_json=$(invoke_with_retry "$MAX_RETRIES" "$DELAY_SECONDS" az cosmosdb sql database show \
        --resource-group "$RESOURCE_GROUP" \
        --account-name "$ACCOUNT_NAME" \
        --name "$DATABASE_NAME" \
        --output json); then
        echo "Failed to retrieve database '$DATABASE_NAME'." >&2
        exit 1
    fi
    databases_json="[$databases_json]"
else
    if ! databases_json=$(invoke_with_retry "$MAX_RETRIES" "$DELAY_SECONDS" az cosmosdb sql database list \
        --resource-group "$RESOURCE_GROUP" \
        --account-name "$ACCOUNT_NAME" \
        --output json); then
        echo "Failed to retrieve databases." >&2
        exit 1
    fi
fi

database_count=$(jq 'length' <<<"$databases_json")
printf '%sProcessing %d database(s)...%s\n\n' "$GREEN" "$database_count" "$RESET"

declare -a enabled_containers=()
disabled_count=0

# Use array instead of piping to avoid nested loop issues
mapfile -t database_array < <(jq -c '.[]' <<<"$databases_json")

for db in "${database_array[@]}"; do
    db_name=$(jq -r '.name' <<<"$db")
    if [[ -z "$db_name" ]]; then
        continue
    fi

    if ! containers_json=$(invoke_with_retry "$MAX_RETRIES" "$DELAY_SECONDS" az cosmosdb sql container list \
        --resource-group "$RESOURCE_GROUP" \
        --account-name "$ACCOUNT_NAME" \
        --database-name "$db_name" \
        --output json); then
        printf '%sFailed to retrieve containers for %s%s\n' "$RED" "$db_name" "$RESET" >&2
        continue
    fi

    while IFS= read -r container; do
        container_name=$(jq -r '.name' <<<"$container")
        ttl=$(jq -r '.analyticalStorageTtl // .resource.analyticalStorageTtl // empty' <<<"$container")

        if [[ -n "$ttl" && "$ttl" != "0" ]]; then
            enabled_containers+=("$db_name|$container_name|$ttl")
        fi
    done < <(jq -c '.[]' <<<"$containers_json")
done

printf '%s==========================================%s\n' "$CYAN" "$RESET"

if (( LIST_ENABLED == 1 )); then
    printf '%sCONTAINERS WITH ANALYTICAL STORAGE ENABLED%s\n' "$CYAN" "$RESET"
    printf '%s===========================================%s\n' "$CYAN" "$RESET"

    if (( ${#enabled_containers[@]} == 0 )); then
        printf '\n%sNo containers with analytical storage enabled.%s\n\n' "$GREEN" "$RESET"
    else
        printf '\n'
        mapfile -t sorted_containers < <(printf '%s\n' "${enabled_containers[@]}" | sort)
        current_db=""
        total_containers=${#sorted_containers[@]}

        for entry in "${sorted_containers[@]}"; do
            IFS='|' read -r db_name container_name ttl <<<"$entry"
            if [[ "$db_name" != "$current_db" ]]; then
                printf '%s%s%s\n' "$CYAN" "$db_name" "$RESET"
                current_db="$db_name"
            fi
            printf '    %s%s%s (TTL: %s)\n' "$YELLOW" "$container_name" "$RESET" "$ttl"
        done
        printf '\n'
        total_databases=$(printf '%s\n' "${sorted_containers[@]}" | cut -d'|' -f1 | sort -u | wc -l | tr -d ' ')
        printf '%sTotal: %d database(s), %d container(s)%s\n' "$WHITE" "$total_databases" "$total_containers" "$RESET"
        printf '\n%sRun without --list-enabled to disable these containers.%s\n\n' "$MAGENTA" "$RESET"
    fi
else
    printf '%sSUMMARY%s\n' "$CYAN" "$RESET"
    printf '%s===========================================%s\n' "$CYAN" "$RESET"

    if (( ${#enabled_containers[@]} == 0 )); then
        printf '%sNo databases have containers with analytical storage enabled.%s\n\n' "$GREEN" "$RESET"
        exit 0
    fi

    printf '\n%sContainers ready to disable (previously enabled):%s\n' "$YELLOW" "$RESET"
    mapfile -t sorted_containers < <(printf '%s\n' "${enabled_containers[@]}" | sort)
    current_db=""
    for entry in "${sorted_containers[@]}"; do
        IFS='|' read -r db_name container_name ttl <<<"$entry"
        if [[ "$db_name" != "$current_db" ]]; then
            printf '  %s%s%s\n' "$CYAN" "$db_name" "$RESET"
            current_db="$db_name"
        fi
        printf '    %s%s%s (TTL: %s)\n' "$YELLOW" "$container_name" "$RESET" "$ttl"
    done

    if (( AUTO_CONFIRM == 0 )); then
           printf '\nDo you want to disable analytical storage for %d container(s)? This action cannot be undone. [y/N]: ' "${#enabled_containers[@]}"
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            printf '%sOperation cancelled.%s\n\n' "$YELLOW" "$RESET"
            exit 0
        fi
    fi

    printf '\n%sStarting disable process for %d containers...%s\n' "$CYAN" "${#sorted_containers[@]}" "$RESET" >&2
    
    # Temporarily disable strict error handling for the disable loop
    set +e
    
    # Use the same simple loop pattern as the display section
    container_number=0
    for entry in "${sorted_containers[@]}"; do
        ((container_number++))
        printf '%sProcessing entry %d/%d: %s%s\n' "$MAGENTA" "$container_number" "${#sorted_containers[@]}" "$entry" "$RESET" >&2
        IFS='|' read -r db_name container_name ttl <<<"$entry"
        printf '%sDisabling %s/%s...%s\n' "$YELLOW" "$db_name" "$container_name" "$RESET"
        
        if invoke_with_retry "$MAX_RETRIES" "$DELAY_SECONDS" az cosmosdb sql container update \
            --resource-group "$RESOURCE_GROUP" \
            --account-name "$ACCOUNT_NAME" \
            --database-name "$db_name" \
            --name "$container_name" \
            --analytical-storage-ttl 0 >/dev/null; then
            printf '%s✓ Successfully disabled %s/%s%s\n' "$GREEN" "$db_name" "$container_name" "$RESET"
            ((disabled_count++))
        else
            printf '%s✗ Failed to disable %s/%s%s\n' "$RED" "$db_name" "$container_name" "$RESET" >&2
        fi
        printf '%sCompleted processing %s/%s (%d/%d)%s\n' "$CYAN" "$db_name" "$container_name" "$container_number" "${#sorted_containers[@]}" "$RESET" >&2
    done
    
    # Re-enable strict error handling
    set -euo pipefail
    
    printf '%sFinished disable loop%s\n' "$CYAN" "$RESET" >&2

    printf '\n%sOperation completed. Containers disabled: %d%s\n\n' "$GREEN" "$disabled_count" "$RESET"
fi

exit 0
