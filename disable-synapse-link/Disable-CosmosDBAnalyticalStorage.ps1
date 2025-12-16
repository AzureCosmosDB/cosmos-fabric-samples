<#
.SYNOPSIS
    Disables Cosmos DB Analytical Storage (Synapse Link) for containers.

.PARAMETER ResourceGroupName
    Resource group name containing the Cosmos DB account.

.PARAMETER AccountName
    Cosmos DB account name.

.PARAMETER DatabaseName
    (Optional) Specific database name. Processes all databases if not specified.

.PARAMETER ListEnabled
    Lists containers with analytical storage enabled without making changes.

.PARAMETER Force
    Skips the confirmation prompt before disabling analytical storage.

.EXAMPLE
    .\Disable-CosmosDBAnalyticalStorage.ps1 -ResourceGroupName "myRG" -AccountName "myAccount" -ListEnabled
    .\Disable-CosmosDBAnalyticalStorage.ps1 -ResourceGroupName "myRG" -AccountName "myAccount"
    .\Disable-CosmosDBAnalyticalStorage.ps1 -ResourceGroupName "myRG" -AccountName "myAccount" -DatabaseName "myDatabase"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$AccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName,
    
    [switch]$ListEnabled,
    [switch]$Force
)

# Check for Az.CosmosDB module
if (-not (Get-Module -ListAvailable -Name Az.CosmosDB)) {
    Write-Error "Az.CosmosDB module required. Install with: Install-Module -Name Az.CosmosDB"
    exit 1
}

Import-Module Az.CosmosDB

# Retry helper function
function Invoke-WithRetry {
    param(
        [ScriptBlock]$ScriptBlock,
        [int]$MaxRetries = 5,
        [int]$DelaySeconds = 5
    )
    
    $attempt = 1
    while ($attempt -le $MaxRetries) {
        try {
            return & $ScriptBlock
        }
        catch {
            if ($attempt -eq $MaxRetries) {
                throw
            }
            Write-Host "  Retry $attempt/$MaxRetries failed, waiting $DelaySeconds seconds..." -ForegroundColor DarkYellow 
            Start-Sleep -Seconds $DelaySeconds
            $attempt++
        }
    }
}

# Ensure Azure login
if (-not (Get-AzContext)) {
    Write-Host "Not logged into Azure. Initiating login..." -ForegroundColor Yellow
    Connect-AzAccount
    Write-Host "Login successful. Initializing Azure context..." -ForegroundColor Green
}

Write-Host ""
Write-Host "Cosmos DB Analytical Storage Management" -ForegroundColor Cyan
Write-Host "Account: $AccountName | Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host ""

# Get databases
if ($DatabaseName) {
    $databases = @(Invoke-WithRetry -ScriptBlock {
        Get-AzCosmosDBSqlDatabase -ResourceGroupName $ResourceGroupName -AccountName $AccountName -Name $DatabaseName -ErrorAction Stop
    })
}
else {
    $databases = Invoke-WithRetry -ScriptBlock {
        Get-AzCosmosDBSqlDatabase -ResourceGroupName $ResourceGroupName -AccountName $AccountName -ErrorAction Stop
    }
}

Write-Host "Processing $($databases.Count) database(s)..." -ForegroundColor Green
Write-Host ""

# Track results
$enabledContainers = @{}
$containersToDisable = @()
$disabledCount = 0

# Process each database
foreach ($db in $databases) {
    $containers = Invoke-WithRetry -ScriptBlock {
        Get-AzCosmosDBSqlContainer -ResourceGroupName $ResourceGroupName -AccountName $AccountName -DatabaseName $db.Name -ErrorAction Stop
    }
    $dbEnabledList = @()
    
    foreach ($container in $containers) {
        $ttl = $container.Resource.AnalyticalStorageTtl
        
        # Check if analytical storage is enabled
        if ($null -ne $ttl -and $ttl -ne 0) {
            $containerInfo = [pscustomobject]@{
                Database = $db.Name
                Name      = $container.Name
                TTL       = $ttl
            }
            $dbEnabledList += $containerInfo
            $containersToDisable += $containerInfo
        }
    }
    
    if ($dbEnabledList.Count -gt 0) {
        $enabledContainers[$db.Name] = $dbEnabledList
    }
}

if (-not $ListEnabled -and $containersToDisable.Count -gt 0) {
    Write-Host "Containers with analytical storage enabled:" -ForegroundColor Yellow
    foreach ($dbName in $enabledContainers.Keys | Sort-Object) {
        Write-Host "  $dbName" -ForegroundColor Cyan
        foreach ($info in $enabledContainers[$dbName]) {
            Write-Host "    $($info.Name) (TTL: $($info.TTL))" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    if (-not $Force) {
        $confirmation = Read-Host "Do you want to disable analytical storage for $($containersToDisable.Count) container(s)? This action cannot be undone. [y/N]"
        if ($confirmation -notmatch '^[Yy]$') {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return
        }
    }

    foreach ($item in $containersToDisable) {
        try {
            Invoke-WithRetry -ScriptBlock {
                Update-AzCosmosDBSqlContainer -ResourceGroupName $ResourceGroupName -AccountName $AccountName -DatabaseName $item.Database -Name $item.Name -AnalyticalStorageTtl 0 -ErrorAction Stop | Out-Null
            }
            $disabledCount++
        }
        catch {
            Write-Host "Failed to disable $($item.Database)/$($item.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Display results
Write-Host "===========================================" -ForegroundColor Cyan

if ($ListEnabled) {
    Write-Host "CONTAINERS WITH ANALYTICAL STORAGE ENABLED" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    
    if ($enabledContainers.Count -eq 0) {
        Write-Host ""
        Write-Host "No containers with analytical storage enabled." -ForegroundColor Green
        Write-Host ""
    }
    else {
        Write-Host ""
        foreach ($dbName in $enabledContainers.Keys | Sort-Object) {
            Write-Host $dbName -ForegroundColor Cyan
            foreach ($info in $enabledContainers[$dbName]) {
                Write-Host "    $($info.Name) (TTL: $($info.TTL))" -ForegroundColor Yellow
            }
            Write-Host ""
        }
        $totalContainers = ($enabledContainers.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
        Write-Host "Total: $($enabledContainers.Count) database(s), $totalContainers container(s)" -ForegroundColor White
        Write-Host ""
        Write-Host "Run without -ListEnabled to disable these containers." -ForegroundColor Magenta
        Write-Host ""
    }
}
else {
    Write-Host "SUMMARY" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    
    if ($containersToDisable.Count -eq 0) {
        Write-Host "No databases have containers with analytical storage enabled." -ForegroundColor Green
    }
    else {
        Write-Host "Containers processed (previously enabled):" -ForegroundColor Yellow
        foreach ($dbName in $enabledContainers.Keys | Sort-Object) {
            Write-Host "  $dbName" -ForegroundColor Cyan
            foreach ($info in $enabledContainers[$dbName]) {
                Write-Host "    $($info.Name)" -ForegroundColor Yellow
            }
        }
        Write-Host ""
        Write-Host "Containers disabled: $disabledCount" -ForegroundColor Green
    }
    Write-Host ""
}
