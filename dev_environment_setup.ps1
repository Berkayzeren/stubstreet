# StubStreet Development Environment Setup Script for Windows
# This script sets up a clean development environment for Flutter development

Write-Host "🚀 Setting up StubStreet Development Environment..." -ForegroundColor Green

# Check if Flutter is installed
Write-Host "📱 Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version
    Write-Host "✅ Flutter is installed: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter is not installed. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Check if Git is installed
Write-Host "🔧 Checking Git installation..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "✅ Git is installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git is not installed. Please install Git first." -ForegroundColor Red
    exit 1
}

# Clean Flutter environment
Write-Host "🧹 Cleaning Flutter environment..." -ForegroundColor Yellow
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run Flutter Doctor
Write-Host "🔍 Running Flutter Doctor..." -ForegroundColor Yellow
flutter doctor

# Install Firebase CLI (optional check)
Write-Host "🔥 Checking Firebase CLI..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version
    Write-Host "✅ Firebase CLI is installed: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Firebase CLI is not installed. Install it with: npm install -g firebase-tools" -ForegroundColor Orange
}

# Create development environment files
Write-Host "📁 Creating development environment files..." -ForegroundColor Yellow

# Create .env file for development
$envContent = @"
# Development Environment Variables
FLUTTER_ENV=development
API_BASE_URL=https://api-dev.stubstreet.com
FIREBASE_PROJECT_ID=device-streaming-70d2d53c
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_key_here
ENABLE_LOGGING=true
DEBUG_MODE=true
"@

Set-Content -Path ".env" -Value $envContent
Write-Host "✅ Created .env file for development" -ForegroundColor Green

# Create local Firebase emulator configuration
$firebaseEmulatorConfig = @"
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "storage": {
      "port": 9199
    },
    "functions": {
      "port": 5001
    },
    "hosting": {
      "port": 5000
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
"@

Set-Content -Path "firebase-emulator.json" -Value $firebaseEmulatorConfig
Write-Host "✅ Created Firebase emulator configuration" -ForegroundColor Green

Write-Host "🎉 Development environment setup complete!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Configure your .env file with actual API keys" -ForegroundColor White
Write-Host "   2. Run 'firebase emulators:start' to start local development" -ForegroundColor White
Write-Host "   3. Run 'flutter run' to start the app" -ForegroundColor White
