# Deploy script for Gym Management System
# This script is idempotent - can be run multiple times safely

param(
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deploying Gym Management System" -ForegroundColor Cyan
Write-Host "  Image Tag: $ImageTag" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get the script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Change to project root
Set-Location $ProjectRoot

Write-Host "`n[1/4] Stopping existing containers..." -ForegroundColor Yellow
docker compose -f docker-compose.prod.yml down
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: docker compose down returned non-zero exit code (containers may not have been running)" -ForegroundColor Yellow
}

Write-Host "`n[2/4] Pulling latest images from GHCR..." -ForegroundColor Yellow
docker pull ghcr.io/nazaro73/cloudnative-backend:$ImageTag
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to pull backend image" -ForegroundColor Red
    exit 1
}

docker pull ghcr.io/nazaro73/cloudnative-frontend:$ImageTag
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to pull frontend image" -ForegroundColor Red
    exit 1
}

Write-Host "`n[3/4] Starting containers..." -ForegroundColor Yellow
$env:IMAGE_TAG = $ImageTag
docker compose -f docker-compose.prod.yml up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to start containers" -ForegroundColor Red
    exit 1
}

Write-Host "`n[4/4] Running database migrations..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
docker exec backend npx prisma migrate deploy
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Migration may have failed or already applied" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nServices:" -ForegroundColor Cyan
Write-Host "  - Frontend: http://localhost:8080" -ForegroundColor White
Write-Host "  - Backend:  http://localhost:3000" -ForegroundColor White
Write-Host "  - Database: localhost:5432" -ForegroundColor White

Write-Host "`nContainer Status:" -ForegroundColor Cyan
docker ps --filter "name=postgres" --filter "name=backend" --filter "name=frontend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
