@echo off
REM Why: Align local web port to 8080 for consistency across docs and tooling.
REM We keep using --dart-define-from-file to load env vars from .env safely.
REM Additionally, force USE_EMULATOR=false so the app uses real Firebase services
REM unless explicitly overridden at run time.
echo Starting StubStreet on port 8080...
flutter run -d chrome --web-port 8080 --dart-define-from-file=.env --dart-define=USE_EMULATOR=false
