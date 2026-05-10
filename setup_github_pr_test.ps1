# Setup GitHub PR test for AGENT 3 workflow
# Run this script step-by-step in PowerShell as admin
# Stop after each step, verify output, then continue

Write-Host "=== STEP 1: Install gh CLI (admin prompt expected) ===" -ForegroundColor Cyan
winget install --id GitHub.cli --accept-package-agreements --accept-source-agreements
Write-Host ""

Write-Host "=== STEP 2: Install ngrok (admin prompt expected) ===" -ForegroundColor Cyan
winget install --id Ngrok.Ngrok --accept-package-agreements --accept-source-agreements
Write-Host ""

Write-Host "=== STEP 3: Verify installs ===" -ForegroundColor Cyan
Write-Host "Restart PowerShell first, then run:"
Write-Host "  gh --version"
Write-Host "  ngrok --version"
Write-Host ""

Write-Host "=== STEP 4: Login to GitHub (browser opens) ===" -ForegroundColor Cyan
Write-Host "Run: gh auth login"
Write-Host "Choose: GitHub.com -> HTTPS -> Yes -> Login with web browser"
Write-Host "Copy code from terminal, paste in browser when asked"
Write-Host ""

Write-Host "=== STEP 5: Setup ngrok authtoken ===" -ForegroundColor Cyan
Write-Host "Go to https://dashboard.ngrok.com/get-started/your-authtoken"
Write-Host "Sign up free, copy token, run:"
Write-Host "  ngrok config add-authtoken <your-token-here>"
Write-Host ""

Write-Host "=== STEP 6: Init git in atlas-test-repo ===" -ForegroundColor Cyan
cd "C:\Users\lukas\atlas-test-repo"
@"
sim-out/
*.log
.env
"@ | Out-File -Encoding utf8 .gitignore
git init
git config user.email "lukashtrzeciak@gmail.com"
git config user.name "Lukasz Trzeciak"
git add .
git commit -m "init: atlas token report workflow"
Write-Host ""

Write-Host "=== STEP 7: Create PRIVATE GitHub repo + push ===" -ForegroundColor Cyan
Write-Host "Run: gh repo create eureka-atlas-test --private --source=. --push"
Write-Host ""

Write-Host "=== STEP 8: Open SECOND PowerShell window, start ngrok ===" -ForegroundColor Cyan
Write-Host "In NEW window run: ngrok http 8000"
Write-Host "Copy URL like: https://abc123.ngrok-free.app"
Write-Host "Keep window OPEN throughout the test"
Write-Host ""

Write-Host "=== STEP 9: Set ngrok URL as GitHub secret ===" -ForegroundColor Cyan
Write-Host "Back in FIRST window run (replace URL):"
Write-Host '  gh secret set ATLAS_URL --body "https://YOUR-NGROK-URL.ngrok-free.app"'
Write-Host ""

Write-Host "=== STEP 10: Create test PR ===" -ForegroundColor Cyan
Write-Host "Run these in order:"
Write-Host "  git checkout -b test-pr"
Write-Host "  'first test commit' | Out-File -Append README.md"
Write-Host "  git add ."
Write-Host '  git commit -m "test: first commit"'
Write-Host "  git push -u origin test-pr"
Write-Host '  gh pr create --title "Atlas test" --body "Live test of Atlas token report workflow"'
Write-Host ""

Write-Host "=== STEP 11: Open PR in browser, wait 30s for workflow ===" -ForegroundColor Cyan
Write-Host "Run: gh pr view --web"
Write-Host "Wait 30-45 sekund for workflow to complete"
Write-Host "Refresh page - Atlas Token Report comment should appear"
Write-Host "SCREENSHOT 1: save as screenshot_pr_first.png"
Write-Host ""

Write-Host "=== STEP 12: Make second commit (test sticky) ===" -ForegroundColor Cyan
Write-Host "Run:"
Write-Host "  'second test commit' | Out-File -Append README.md"
Write-Host "  git add ."
Write-Host '  git commit -m "test: second commit"'
Write-Host "  git push"
Write-Host ""

Write-Host "=== STEP 13: Wait 30s, refresh PR page ===" -ForegroundColor Cyan
Write-Host "The SAME comment should update (NOT a new one)"
Write-Host "SCREENSHOT 2: save as screenshot_pr_sticky.png"
Write-Host ""

Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "After 2 screenshots:"
Write-Host "1. Close ngrok window (Ctrl+C in second PowerShell)"
Write-Host "2. Atlas returns to localhost-only"
Write-Host "3. Send screenshots to Designer for verification"
Write-Host "4. Use screenshots in LinkedIn carousel"
