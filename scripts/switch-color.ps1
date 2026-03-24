# Switch Color Script
# Quickly switch the reverse proxy to a different color (for rollback)

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("blue", "green")]
    [string]$Color
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Set-Location $ProjectRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Switching to $Color" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Update active color file
$ActiveColorFile = Join-Path $ProjectRoot "nginx/active-color.conf"
"set `$active_color $Color;" | Out-File -FilePath $ActiveColorFile -Encoding utf8 -NoNewline

Write-Host "Updated active-color.conf" -ForegroundColor Green

# Reload nginx
docker exec reverse-proxy nginx -s reload
if ($LASTEXITCODE -eq 0) {
    Write-Host "Nginx reloaded successfully" -ForegroundColor Green
} else {
    Write-Host "Warning: Nginx reload may have failed" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Switch Complete!" -ForegroundColor Green
Write-Host "  Active color: $Color" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Verify
Write-Host "`nVerifying..." -ForegroundColor Cyan
$Response = Invoke-WebRequest -Uri "http://localhost/status" -UseBasicParsing 2>$null
Write-Host $Response.Content -ForegroundColor White
