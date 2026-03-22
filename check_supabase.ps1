# check_supabase.ps1 — Verify Supabase project reachability and API key
#
# Usage:
#   .\check_supabase.ps1
#   .\check_supabase.ps1 -url "https://xyz.supabase.co" -key "eyJ..."

param (
    [string]$url,
    [string]$key
)

# Load from supabase_service.dart if not provided
if (-not $url -or -not $key) {
    Write-Host "🔍 Searching for credentials in lib/services/supabase_service.dart..." -ForegroundColor Cyan
    $content = Get-Content "lib/services/supabase_service.dart" -Raw
    
    if ($content -match "defaultValue: '(https://[^']+)'") {
        $url = $Matches[1]
    }
    if ($content -match "defaultValue: '([^']{20,})'") {
        $key = $Matches[1]
    }
}

if (-not $url -or $url -like "*YOUR_PROJECT*") {
    Write-Host "❌ Error: Supabase URL not set or is a placeholder." -ForegroundColor Red
    Write-Host "Update kSupabaseUrl in lib/services/supabase_service.dart or pass via -url"
    exit 1
}

Write-Host "🌐 Testing Connection to: $url" -ForegroundColor Cyan

# 1. Ping the host
$uri = [Uri]$url
try {
    $ping = Test-NetConnection -ComputerName $uri.Host -Port 443 -ErrorAction SilentlyContinue
    if ($ping.TcpTestSucceeded) {
        Write-Host "✅ Host is reachable on port 443." -ForegroundColor Green
    } else {
        Write-Host "❌ Host is NOT reachable. Check your internet or project status." -ForegroundColor Red
    }
} catch {
    Write-Host "⚠️  Ping test skipped (requires admin/ICMP)." -ForegroundColor Yellow
}

# 2. Test API Key validity via REST health check
Write-Host "🔑 Verifying API Key..." -ForegroundColor Cyan
$headers = @{
    "apikey" = $key
    "Authorization" = "Bearer $key"
}

try {
    $response = Invoke-RestMethod -Uri "$url/rest/v1/" -Headers $headers -Method Get
    Write-Host "✅ API Key is VALID. Project is active." -ForegroundColor Green
} catch {
    $err = $_.Exception.Response
    if ($err.StatusCode -eq "Unauthorized") {
        Write-Host "❌ Error: API Key (Anon Key) is INVALID." -ForegroundColor Red
    } else {
        Write-Host "❌ Request Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nRecommendation:" -ForegroundColor White
Write-Host "If this script fails but your keys are correct, ensure you've enabled 'Anonymous sign-ins' in your Supabase Auth settings." -ForegroundColor Gray
