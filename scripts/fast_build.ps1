# Fast Build and Test Script for StubStreet
# This script provides fast development workflows

param(
    [string]$Target = "test",
    [switch]$Watch = $false,
    [switch]$Coverage = $false,
    [switch]$Verbose = $false
)

function Write-Step {
    param([string]$Message)
    Write-Host "🔄 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

Write-Host "🚀 StubStreet Fast Build Script" -ForegroundColor Yellow
Write-Host "Target: $Target" -ForegroundColor White

# Ensure we're in the right directory
if (!(Test-Path "pubspec.yaml")) {
    Write-Error "Not in a Flutter project directory"
    exit 1
}

switch ($Target) {
    "test" {
        Write-Step "Running Flutter tests..."
        
        if ($Coverage) {
            if ($Watch) {
                # Watch mode with coverage is not directly supported, so run once
                flutter test --coverage
            } else {
                flutter test --coverage
            }
            
            # Generate HTML coverage report
            if (Get-Command "genhtml" -ErrorAction SilentlyContinue) {
                Write-Step "Generating coverage report..."
                genhtml coverage/lcov.info -o coverage/html
                Write-Success "Coverage report generated in coverage/html/"
            }
        } else {
            if ($Watch) {
                # Use a simple file watcher approach
                Write-Host "👀 Watching for changes... Press Ctrl+C to stop" -ForegroundColor Yellow
                $watcher = New-Object System.IO.FileSystemWatcher
                $watcher.Path = "lib"
                $watcher.IncludeSubdirectories = $true
                $watcher.EnableRaisingEvents = $true
                
                Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action {
                    Write-Host "🔄 File changed, running tests..." -ForegroundColor Cyan
                    flutter test
                }
                
                # Keep the script running
                try {
                    while ($true) {
                        Start-Sleep 1
                    }
                } finally {
                    $watcher.Dispose()
                }
            } else {
                flutter test
            }
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "All tests passed!"
        } else {
            Write-Error "Some tests failed!"
            exit 1
        }
    }
    
    "build" {
        Write-Step "Building for debug..."
        flutter build apk --debug
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Build completed successfully!"
        } else {
            Write-Error "Build failed!"
            exit 1
        }
    }
    
    "release" {
        Write-Step "Building for release..."
        flutter build apk --release --obfuscate --split-debug-info=build/symbols
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Release build completed!"
            Write-Host "📱 APK location: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor White
        } else {
            Write-Error "Release build failed!"
            exit 1
        }
    }
    
    "analyze" {
        Write-Step "Analyzing code..."
        flutter analyze
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Code analysis passed!"
        } else {
            Write-Error "Code analysis found issues!"
            exit 1
        }
    }
    
    "format" {
        Write-Step "Formatting code..."
        flutter format .
        Write-Success "Code formatted!"
    }
    
    "clean" {
        Write-Step "Cleaning project..."
        flutter clean
        flutter pub get
        flutter pub run build_runner build --delete-conflicting-outputs
        Write-Success "Project cleaned and dependencies updated!"
    }
    
    "full" {
        Write-Step "Running full CI pipeline locally..."
        
        # Format
        Write-Step "1/5 Formatting code..."
        flutter format .
        
        # Analyze
        Write-Step "2/5 Analyzing code..."
        flutter analyze
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Analysis failed!"
            exit 1
        }
        
        # Test
        Write-Step "3/5 Running tests..."
        flutter test --coverage
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Tests failed!"
            exit 1
        }
        
        # Build debug
        Write-Step "4/5 Building debug APK..."
        flutter build apk --debug
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Debug build failed!"
            exit 1
        }
        
        # Build release
        Write-Step "5/5 Building release APK..."
        flutter build apk --release --obfuscate --split-debug-info=build/symbols
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Release build failed!"
            exit 1
        }
        
        Write-Success "Full CI pipeline completed successfully!"
    }
    
    default {
        Write-Host "Usage: .\fast_build.ps1 -Target [test|build|release|analyze|format|clean|full]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Options:" -ForegroundColor White
        Write-Host "  -Target test     Run unit tests" -ForegroundColor Gray
        Write-Host "  -Target build    Build debug APK" -ForegroundColor Gray
        Write-Host "  -Target release  Build release APK" -ForegroundColor Gray
        Write-Host "  -Target analyze  Run code analysis" -ForegroundColor Gray
        Write-Host "  -Target format   Format code" -ForegroundColor Gray
        Write-Host "  -Target clean    Clean and rebuild" -ForegroundColor Gray
        Write-Host "  -Target full     Run complete CI pipeline" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Flags:" -ForegroundColor White
        Write-Host "  -Watch          Watch for changes (test only)" -ForegroundColor Gray
        Write-Host "  -Coverage       Generate coverage report (test only)" -ForegroundColor Gray
        Write-Host "  -Verbose        Verbose output" -ForegroundColor Gray
    }
}
