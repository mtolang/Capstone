# PowerShell script to download missing files from GitHub repository
# Save as: download-missing-files.ps1

$ProjectPath = "C:\Users\My PC\Desktop\flutter\Capstone\capstone_2"
$GitHubRepo = "https://raw.githubusercontent.com/mtolang/Capstone/main"

# List of files that might be missing based on GitHub repo
$FilesToCheck = @(
    "lib\screens\parent\parent_materials.dart",
    "lib\widgets\mini_trend_line.dart", 
    "lib\screens\therapist\ther_progress.dart",
    "lib\screens\therapist\therapist_progress_tracking.dart",
    "lib\screens\parent\games\trace_and_pop_pro.dart",
    "lib\app_routes_full.dart",
    "lib\app_routes_demo.dart",
    "lib\widgets\call_test_widget.dart",
    "lib\widgets\osm_map_example.dart",
    "lib\chat\calling.dart",
    "lib\screens\call_history_screen.dart",
    "AUTH_SETUP.md",
    "OPENSTREETMAP_GUIDE.md",
    "MATERIALS_INTEGRATION_GUIDE.md",
    "YOUTUBE_API_GUIDE.md",
    "SCREEN_SHARING_IMPLEMENTATION.md",
    "FIREBASE_AUTH_SOLUTION.md"
)

Write-Host "=== DOWNLOADING MISSING FILES FROM GITHUB ===" -ForegroundColor Green
Write-Host "Repository: mtolang/Capstone" -ForegroundColor Yellow
Write-Host "Target Directory: $ProjectPath" -ForegroundColor Yellow
Write-Host ""

$Downloaded = 0
$Skipped = 0
$Failed = 0

foreach ($file in $FilesToCheck) {
    $fullPath = Join-Path $ProjectPath $file
    $directory = Split-Path $fullPath -Parent
    $url = "$GitHubRepo/$($file.Replace('\', '/'))"
    
    # Check if file already exists
    if (Test-Path $fullPath) {
        Write-Host "✅ EXISTS: $file" -ForegroundColor Green
        $Skipped++
        continue
    }
    
    # Create directory if it doesn't exist
    if (!(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        Write-Host "📁 Created directory: $directory" -ForegroundColor Blue
    }
    
    try {
        # Download the file
        Write-Host "⬇️  Downloading: $file" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $fullPath -ErrorAction Stop
        Write-Host "✅ Downloaded: $file" -ForegroundColor Green
        $Downloaded++
    } catch {
        Write-Host "❌ Failed: $file - $($_.Exception.Message)" -ForegroundColor Red
        $Failed++
    }
}

Write-Host ""
Write-Host "=== DOWNLOAD SUMMARY ===" -ForegroundColor Yellow
Write-Host "✅ Downloaded: $Downloaded files" -ForegroundColor Green
Write-Host "⏭️  Skipped (already exist): $Skipped files" -ForegroundColor Blue  
Write-Host "❌ Failed: $Failed files" -ForegroundColor Red
Write-Host ""

if ($Downloaded -gt 0) {
    Write-Host "🎉 Successfully downloaded $Downloaded new files!" -ForegroundColor Green
    Write-Host "💡 Run flutter pub get and flutter analyze to check for any issues." -ForegroundColor Yellow
} else {
    Write-Host "ℹ️  No new files were downloaded. All files may already exist." -ForegroundColor Blue
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")