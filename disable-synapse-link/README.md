<!--
---
page_type: sample
languages:
- powershell
- bash
products:
- fabric
- fabric-database-cosmos-db
- cosmos-db-synapse-link
name: |
    Disable Synapse Link Helper
urlFragment: disable-synapse-link-helper
description: Helper scripts that disable Synapse Link analytical storage across Cosmos DB SQL containers once Fabric Mirroring replaces it.
---
-->

# Disable Synapse Link Helper

These scripts turn off analytical storage (Synapse Link) for Azure Cosmos DB SQL containers by setting `analyticalStorageTTL` to `0`. Synapse Link is in maintenance mode and we **strongly** recommend moving to Fabric Mirroring. 

**Run these scripts only after you have completed your migration and no longer need the existing analytical store.**

## Why run this?

- Stop ongoing analytical store charges once Fabric Mirroring is live and Synapse Link is no longer needed.
- Apply the change across every container in the account with a single command instead of editing each container manually.
- Finish your Fabric Mirroring migration first; disabling sets analyticalStorageTTL to 0 and the existing analytical store is inaccessible immediately.

## What the scripts do

- Enumerates databases and containers within a Cosmos DB account.
- Detects analytical storage that remains enabled (`analyticalStorageTTL > 0`).
- Confirmation step before disabling all listed containers (use `-Force` or `--yes` to skip when automating).
- Sets the TTL to `0`, disabling Synapse Link immediately.

## Files

| File | Description |
|------|-------------|
| Disable-CosmosDBAnalyticalStorage.ps1 | PowerShell script with preview and confirmation flags |
| Disable-CosmosDBAnalyticalStorage.sh | Equivalent script but for Bash/Azure CLI implementation for automated pipelines |

## Prerequisites

### PowerShell

- PowerShell 7+ or Windows PowerShell 5.1
- Az PowerShell modules (`Install-Module Az -Scope CurrentUser`)
- Logged in with `Connect-AzAccount` and permissions to update Cosmos DB containers

### Bash

- Azure CLI 2.49 or later (`az version`)
- Logged in with `az login` and write access to the Cosmos DB account
- Bash environment (Azure Cloud Shell, WSL, macOS, or Linux)

## Usage

### PowerShell Script

```powershell
# Disable Synapse Link across the account
.\Disable-CosmosDBAnalyticalStorage.ps1 `
    -ResourceGroupName "rg-name" `
    -AccountName "cosmos-account"

# Restrict to a specific database
.\Disable-CosmosDBAnalyticalStorage.ps1 `
    -ResourceGroupName "rg-name" `
    -AccountName "cosmos-account" `
    -DatabaseName "db-name"

# Preview containers with analytical storage enabled
.\Disable-CosmosDBAnalyticalStorage.ps1 `
    -ResourceGroupName "rg-name" `
    -AccountName "cosmos-account" `
    -ListEnabled

# Skip confirmation for automation
.\Disable-CosmosDBAnalyticalStorage.ps1 `
    -ResourceGroupName "rg-name" `
    -AccountName "cosmos-account" `
    -Force
```

### Bash Script

```bash
chmod +x Disable-CosmosDBAnalyticalStorage.sh

# Disable Synapse Link across the account
./Disable-CosmosDBAnalyticalStorage.sh --resource-group rg-name --account-name cosmos-account

# Restrict to a specific database
./Disable-CosmosDBAnalyticalStorage.sh --resource-group rg-name --account-name cosmos-account --database-name db-name

# Preview containers with analytical storage enabled
./Disable-CosmosDBAnalyticalStorage.sh --resource-group rg-name --account-name cosmos-account --list-enabled

# Skip confirmation for automation
./Disable-CosmosDBAnalyticalStorage.sh --resource-group rg-name --account-name cosmos-account --yes
```

## Parameters

| Option | Description |
|--------|-------------|
| `-ResourceGroupName` / `--resource-group` | Resource group hosting the Cosmos DB account |
| `-AccountName` / `--account-name` | Cosmos DB account name to scan |
| `-DatabaseName` / `--database-name` | Optional. Limit processing to one SQL database |
| `-ListEnabled` / `--list-enabled` | Preview containers with analytical storage enabled |
| `-Force` / `--yes` | Bypass confirmation prompts for unattended runs |

## Verification

```powershell
Get-AzCosmosDBSqlContainer `
    -ResourceGroupName "rg-name" `
    -AccountName "cosmos-account" `
    -DatabaseName "db-name" | `
    Select-Object Name, @{Name='AnalyticalStorageTTL';Expression={$_.Resource.AnalyticalStorageTtl}}
```

```bash
az cosmosdb sql container list \
  --resource-group rg-name \
  --account-name cosmos-account \
  --database-name db-name \
  --query "[].{name:name, analyticalStorageTTL:resource.analyticalStorageTtl}"
```

Every container should report `analyticalStorageTTL` equal to `0`.

## Caveats and troubleshooting

- Run the scripts only after Fabric Mirroring has fully replaced Synapse Link in production scenarios.
- Disabling analytical storage is irreversible for existing history; re-enabling creates a new, empty analytical store seeded from current transactional data.
- Use the preview option first to confirm the targeted containers before applying changes.
- To avoid 403 Forbidden responses in the Azure Portal like the one shown above, ensure you have Cosmos DB Account Contributor rights (PowerShell) or the built-in data-plane roles Cosmos DB Built-in Data Reader and Cosmos DB Built-in Data Writer (CLI). These Azure Portal errors do not affect your containers Analytical Store TTL.
