# Local simulator for atlas-token-report.yml
# Replicates bash logic from workflow steps without GitHub Actions environment
# Per R055: run twice, both PASS = STABLE eligibility

param(
    [string]$AtlasUrl = "http://localhost:8000",
    [string]$AtlasApiKey = "demo",
    [string]$WorkDir = "C:\Users\lukas\atlas-test-repo\sim-out"
)

$jq = "C:\Users\lukas\AppData\Local\Microsoft\WinGet\Packages\jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe\jq.exe"
if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null }
$statsFile = "$WorkDir\stats.json"
$bodyFile = "$WorkDir\comment_body.md"

# === Step 1 simulator: curl /v1/stats ===
Write-Host "=== STEP 1: Fetch Atlas /v1/stats ===" -ForegroundColor Cyan
$reachable = $false
try {
    $r = Invoke-WebRequest -Uri "$AtlasUrl/v1/stats?window_minutes=60" -Headers @{"Authorization"="Bearer $AtlasApiKey"} -UseBasicParsing -TimeoutSec 10
    $r.Content | Out-File -FilePath $statsFile -Encoding UTF8
    if ($r.StatusCode -eq 200 -and (Get-Item $statsFile).Length -gt 0) {
        $reachable = $true
        Write-Host "  HTTP 200, stats.json size: $((Get-Item $statsFile).Length) bytes" -ForegroundColor Green
    }
} catch {
    Write-Host "  Atlas unreachable: $($_.Exception.Message)" -ForegroundColor Yellow
    "{}" | Out-File -FilePath $statsFile -Encoding UTF8
}

# === Step 2 simulator: parse + format markdown ===
Write-Host "=== STEP 2: Format markdown summary ===" -ForegroundColor Cyan
$nowUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

if ($reachable) {
    $processed = & $jq -r '.total_tokens_processed // 0' $statsFile
    $saved = & $jq -r '.total_tokens_saved // 0' $statsFile
    $reduction = & $jq -r '.reduction_pct // 0' $statsFile
    $entries = & $jq -r '.total_entries // 0' $statsFile
    $window = & $jq -r '.window_hours // 1' $statsFile

    # Use jq filter file to avoid PowerShell quote stripping of inner double-quotes
    $jqFilter = "C:\Users\lukas\atlas-test-repo\top3_filter.jq"
    $top3 = & $jq -r -f $jqFilter $statsFile

    # Force en-US culture for thousands separator (commas not spaces)
    $usCulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
    $processedFmt = ([int64]$processed).ToString("N0", $usCulture)
    $savedFmt = ([int64]$saved).ToString("N0", $usCulture)

    $body = @"
## :coin: Atlas Token Report
<!-- atlas-token-report-marker -->

**Window**: last ${window}h (rolling)
**Tokens processed**: ${processedFmt}
**Tokens saved**: ${savedFmt} (**${reduction}%** reduction)
**Total tool calls**: ${entries}

### Top 3 tools by savings
${top3}

---
*Powered by Eureca Atlas - updated ${nowUtc}*
"@
} else {
    $body = @"
## :coin: Atlas Token Report
<!-- atlas-token-report-marker -->

**Status**: Atlas server unreachable. Token report unavailable for this commit.

- Check ATLAS_URL secret is set correctly
- Verify Atlas server health endpoint responds
- Self-hosted users: ensure server is running

*Workflow did not fail - this comment is informational only.*

---
*Powered by Eureca Atlas - updated ${nowUtc}*
"@
}

$body | Out-File -FilePath $bodyFile -Encoding UTF8
Write-Host "  Comment body written: $bodyFile ($((Get-Item $bodyFile).Length) bytes)" -ForegroundColor Green

# === Verification checks ===
Write-Host "=== VERIFICATION ===" -ForegroundColor Cyan
$content = Get-Content $bodyFile -Raw
$checks = @{
    "Marker present" = $content -match "<!-- atlas-token-report-marker -->"
    "Header present" = $content -match "Atlas Token Report"
    "Reachable mode AND processed numeric" = (-not $reachable) -or ($content -match "Tokens processed[^\d]*[\d,]+")
    "Reachable mode AND reduction percentage" = (-not $reachable) -or ($content -match "\d+\.?\d*%.*reduction")
    "Reachable mode AND top 3 list" = (-not $reachable) -or ($content -match "(?s)Top 3 tools.*\d+ tokens saved")
    "Unreachable fallback present" = $reachable -or ($content -match "Atlas server unreachable")
    "UTC timestamp present" = $content -match "\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z"
}

$pass = 0; $fail = 0
foreach ($k in $checks.Keys) {
    if ($checks[$k]) { Write-Host "  PASS: $k" -ForegroundColor Green; $pass++ }
    else { Write-Host "  FAIL: $k" -ForegroundColor Red; $fail++ }
}

Write-Host "`n=== SUMMARY ==="
Write-Host "Atlas reachable: $reachable"
Write-Host "Checks: $pass PASS / $fail FAIL"
if ($fail -eq 0) { Write-Host "VERDICT: PASS" -ForegroundColor Green; exit 0 }
else { Write-Host "VERDICT: FAIL" -ForegroundColor Red; exit 1 }
