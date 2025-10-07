# Simple PowerShell script to download missing files
$ProjectPath = "C:\Users\My PC\Desktop\flutter\Capstone\capstone_2"
$GitHubRepo = "https://raw.githubusercontent.com/mtolang/Capstone/main"

$FilesToCheck = @(
    "lib\screens\therapist\ther_progress.dart",
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

Write-Host "Downloading missing files..."

foreach ($file in $FilesToCheck) {
    $fullPath = Join-Path $ProjectPath $file
    $directory = Split-Path $fullPath -Parent
    $url = "$GitHubRepo/$($file.Replace('\', '/'))"
    
    if (Test-Path $fullPath) {
        Write-Host "EXISTS: $file"
        continue
    }
    
    if (!(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        Write-Host "Created directory: $directory"
    }
    
    try {
        Write-Host "Downloading: $file"
        Invoke-WebRequest -Uri $url -OutFile $fullPath -ErrorAction Stop
        Write-Host "Downloaded: $file"
    } catch {
        Write-Host "Failed: $file"
    }
}

Write-Host "Download complete!"