# Blue/Green Deployment Script
# This script deploys to the inactive color and switches the reverse proxy

param(
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

# Get the script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Set-Location $ProjectRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Blue/Green Deployment" -ForegroundColor Cyan
Write-Host "  Image Tag: $ImageTag" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Read current active color
Write-Host "`n[1/6] Reading current active color..." -ForegroundColor Yellow
$ActiveColorFile = Join-Path $ProjectRoot "nginx/active-color.conf"
$CurrentColor = "blue"

if (Test-Path $ActiveColorFile) {
    $Content = Get-Content $ActiveColorFile -Raw
    if ($Content -match 'set \$active_color (\w+);') {
        $CurrentColor = $Matches[1]
    }
}

Write-Host "Current active color: $CurrentColor" -ForegroundColor White

# Step 2: Determine target color
Write-Host "`n[2/6] Determining target color..." -ForegroundColor Yellow
if ($CurrentColor -eq "blue") {
    $TargetColor = "green"
} else {
    $TargetColor = "blue"
}

Write-Host "Target color: $TargetColor" -ForegroundColor White

# Step 3: Pull new images
Write-Host "`n[3/6] Pulling new images..." -ForegroundColor Yellow
docker pull ghcr.io/nazaro73/cloudnative-backend:$ImageTag
docker pull ghcr.io/nazaro73/cloudnative-frontend:$ImageTag

# Step 4: Deploy to target color
Write-Host "`n[4/6] Deploying to $TargetColor..." -ForegroundColor Yellow
$env:IMAGE_TAG = $ImageTag

# Ensure base infrastructure is running
docker compose -f docker-compose.base.yml up -d

# Deploy target color
docker compose -f docker-compose.base.yml -f "docker-compose.$TargetColor.yml" up -d

# Step 5: Wait for services to be healthy
Write-Host "`n[5/6] Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Run migrations on the new backend
$BackendContainer = "backend-$TargetColor"
Write-Host "Running migrations on $BackendContainer..." -ForegroundColor White
docker exec $BackendContainer npx prisma migrate deploy 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Migration may have failed or already applied" -ForegroundColor Yellow
}

# Health check
$MaxRetries = 10
$Retry = 0
$Healthy = $false

while (-not $Healthy -and $Retry -lt $MaxRetries) {
    try {
        $Response = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 5 2>$null
        if ($Response.StatusCode -eq 200) {
            $Healthy = $true
            Write-Host "Health check passed!" -ForegroundColor Green
        }
    } catch {
        $Retry++
        Write-Host "Health check attempt $Retry/$MaxRetries..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
}

if (-not $Healthy) {
    Write-Host "ERROR: New deployment is not healthy. Aborting switch." -ForegroundColor Red
    Write-Host "Rollback: The previous version ($CurrentColor) is still active." -ForegroundColor Yellow
    exit 1
}

# Step 6: Switch the proxy
Write-Host "`n[6/6] Switching reverse proxy to $TargetColor..." -ForegroundColor Yellow
"set `$active_color $TargetColor;" | Out-File -FilePath $ActiveColorFile -Encoding utf8 -NoNewline

# Reload nginx
docker exec reverse-proxy nginx -s reload
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Nginx reload may have failed" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "  Active color: $TargetColor" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nServices:" -ForegroundColor Cyan
Write-Host "  - Application: http://localhost" -ForegroundColor White
Write-Host "  - Status: http://localhost/status" -ForegroundColor White

Write-Host "`nTo rollback, run:" -ForegroundColor Yellow
Write-Host "  .\scripts\switch-color.ps1 -Color $CurrentColor" -ForegroundColor White

Write-Host "`nContainer Status:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String -Pattern "postgres|backend|frontend|reverse-proxy"
