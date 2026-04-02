#!/usr/bin/env pwsh
# Why: We standardize on port 8080 for local web development so teammates, docs,
# and automation all reference the same URL. Choosing a common port reduces
# friction when switching environments and avoids hard-to-guess random ports.
#
# Note: We keep using `--dart-define-from-file=.env` to inject configuration
# at runtime rather than passing secrets via CLI flags, aligning with our
# project convention to source environment values from a file for repeatability
# and safety.
Write-Host "🚀 Starting StubStreet on port 8080..." -ForegroundColor Green
Write-Host "📍 URL: http://localhost:8080" -ForegroundColor Cyan

# Why: We explicitly set USE_EMULATOR=false to ensure the app connects to real
# Firebase services in web runs unless the caller overrides it. This avoids
# accidental coupling to local emulators when teammates expect production-like
# behavior. The order matters: values from .env are loaded first, and this
# explicit flag acts as a safe default override.
flutter run -d chrome --web-port 8080 --dart-define-from-file=.env --dart-define=USE_EMULATOR=false
