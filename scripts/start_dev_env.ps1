# Start Development Environment Script
# This script starts Firebase emulators and other development services

Write-Host "🚀 Starting StubStreet Development Environment..." -ForegroundColor Green

# Check if Firebase CLI is installed
try {
    $firebaseVersion = firebase --version
    Write-Host "✅ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI not found. Please install it with:" -ForegroundColor Red
    Write-Host "   npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Check if we're in the right directory
if (!(Test-Path "pubspec.yaml")) {
    Write-Host "❌ Not in a Flutter project directory" -ForegroundColor Red
    exit 1
}

# Start Firebase emulators
Write-Host "🔥 Starting Firebase emulators..." -ForegroundColor Yellow
Write-Host "   - Auth emulator on port 9099" -ForegroundColor White
Write-Host "   - Firestore emulator on port 8080" -ForegroundColor White
Write-Host "   - Storage emulator on port 9199" -ForegroundColor White
Write-Host "   - Emulator UI on port 4000" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop all emulators" -ForegroundColor Cyan
Write-Host ""

# Start emulators (this will run in foreground)
firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
