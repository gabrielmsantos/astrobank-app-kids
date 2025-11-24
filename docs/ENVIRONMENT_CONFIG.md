# 🔧 Environment Configuration Guide

Set different API endpoints for development, staging, and production environments using Dart's `--dart-define` flag.

## Overview

The AstroBank Kids app supports environment-specific configuration through compile-time constants using `String.fromEnvironment()`. This allows you to build the same codebase with different API endpoints without code changes.

## How It Works

### Configuration in Code

**File:** `lib/config/app_config.dart`

```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
```

**Key Points:**
- `String.fromEnvironment('API_BASE_URL')` - Reads from compile-time environment variable
- `defaultValue: 'http://localhost:8000'` - Falls back to localhost if not defined
- Compile-time constant - Value set at build time, not runtime
- No performance overhead

## Usage

### Development (Localhost)

```bash
# Default - uses localhost:8000
flutter run -d web

# Or explicitly set
flutter run -d web --dart-define=API_BASE_URL=http://localhost:8000
```

### Staging Environment

```bash
flutter run -d web --dart-define=API_BASE_URL=https://staging-api.astrobank.com

# Or build
flutter build web --release --dart-define=API_BASE_URL=https://staging-api.astrobank.com
```

### Production Environment

```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.astrobank.com
```

### Production with Custom Port

```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.astrobank.com:3000
```

## Environment Examples

### Development
```bash
flutter run -d web \
  --dart-define=API_BASE_URL=http://localhost:8000
```

### Testing
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://test-api.astrobank.com
```

### Staging
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com
```

### Production
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com
```

## Multiple Environment Variables

You can define multiple variables at once:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --dart-define=LOG_LEVEL=production \
  --dart-define=ENABLE_ANALYTICS=true
```

## Setting Up Additional Environment Variables

To add more environment variables, follow this pattern in `app_config.dart`:

```dart
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // Log Level (example)
  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 'debug',
  );

  // Analytics Enabled (example)
  static const bool analyticsEnabled = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  // API Timeout (example - must be parsed)
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30,
  );
}
```

Then use in code:

```dart
// String variable
print('API: ${AppConfig.apiBaseUrl}');

// Boolean variable
if (AppConfig.analyticsEnabled) {
  // Initialize analytics
}

// Integer variable
final timeout = Duration(seconds: AppConfig.apiTimeoutSeconds);
```

## Build Scripts

Create convenient build scripts in your project:

### `scripts/build-dev.sh`
```bash
#!/bin/bash
echo "Building for Development..."
flutter build web --release \
  --dart-define=API_BASE_URL=http://localhost:8000
```

### `scripts/build-staging.sh`
```bash
#!/bin/bash
echo "Building for Staging..."
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com
```

### `scripts/build-prod.sh`
```bash
#!/bin/bash
echo "Building for Production..."
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com
```

Then run:
```bash
chmod +x scripts/build-*.sh
./scripts/build-prod.sh
```

## GitHub Actions CI/CD

### Automated Deployment by Environment

**`.github/workflows/deploy.yml`**

```yaml
name: Deploy AstroBank Kids

on:
  push:
    branches:
      - main
      - staging
      - develop

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    env:
      # Set API based on branch
      API_BASE_URL: |
        ${{ (github.ref == 'refs/heads/main' && 'https://api.astrobank.com') ||
            (github.ref == 'refs/heads/staging' && 'https://staging-api.astrobank.com') ||
            'http://localhost:8000' }}
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.13.9'
      
      - run: flutter pub get
      
      - name: Build for ${{ github.ref }}
        run: |
          flutter build web --release \
            --dart-define=API_BASE_URL=${{ env.API_BASE_URL }}
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          projectId: astrobank-kids
          channelId: live
```

## Environment-Specific Builds

### Production Build Steps

```bash
# 1. Build with production API
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com

# 2. Output is in build/web/

# 3. Deploy to Firebase
firebase deploy --project astrobank-production

# 4. Verify
curl -I https://astrobank-kids.web.app/
```

### Staging Build Steps

```bash
# 1. Build with staging API
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com

# 2. Deploy to staging Firebase project
firebase deploy --project astrobank-staging

# 3. Test
# Open https://astrobank-kids-staging.web.app/
```

## Verifying Configuration

### Check Build Configuration

Create a debug screen to display current configuration:

```dart
// File: lib/screens/config_debug_screen.dart
import 'package:flutter/material.dart';
import 'package:astrobank_kids/config/app_config.dart';

class ConfigDebugScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configuration')),
      body: ListView(
        children: [
          ListTile(
            title: Text('API Base URL'),
            subtitle: Text(AppConfig.apiBaseUrl),
          ),
          ListTile(
            title: Text('API Version'),
            subtitle: Text(AppConfig.apiVersion),
          ),
          ListTile(
            title: Text('Page Size'),
            subtitle: Text('${AppConfig.defaultPageSize}'),
          ),
          ListTile(
            title: Text('Timeout'),
            subtitle: Text('${AppConfig.apiTimeout.inSeconds}s'),
          ),
        ],
      ),
    );
  }
}
```

Add to your app (development only):

```dart
// In lib/main.dart
if (kDebugMode) {
  // Show config debug screen
  routes['/config'] = (_) => ConfigDebugScreen();
}
```

### Print Configuration on Startup

```dart
// In lib/main.dart
void main() {
  if (kDebugMode) {
    print('=== AstroBank Configuration ===');
    print('API Base URL: ${AppConfig.apiBaseUrl}');
    print('API Version: ${AppConfig.apiVersion}');
    print('API Timeout: ${AppConfig.apiTimeout.inSeconds}s');
    print('==============================');
  }
  
  runApp(const AstroBankKidsApp());
}
```

## Common Use Cases

### Local Development

```bash
# Run with local API
flutter run -d web
```

### Testing with Staging API

```bash
# Run connected to staging
flutter run -d web --dart-define=API_BASE_URL=https://staging-api.astrobank.com
```

### Building for Multiple Platforms

```bash
# Web
flutter build web --release --dart-define=API_BASE_URL=https://api.astrobank.com

# iOS (if applicable)
flutter build ios --release --dart-define=API_BASE_URL=https://api.astrobank.com

# Android (if applicable)
flutter build apk --release --dart-define=API_BASE_URL=https://api.astrobank.com
```

## Troubleshooting

### API Still Points to Localhost

**Problem:** Even with `--dart-define`, API still uses localhost

**Solution:** 
1. Make sure `--dart-define` flag is present
2. Clean build: `flutter clean && flutter build web --release --dart-define=API_BASE_URL=...`
3. Verify in debug screen

### Wrong API Endpoint Used

**Problem:** Production build uses staging API

**Solution:**
1. Check command: `flutter build web --release --dart-define=API_BASE_URL=https://api.astrobank.com`
2. Verify compile-time value (not runtime)
3. Check AppConfig class uses `String.fromEnvironment()`

### Build Fails with dart-define

**Problem:** `flutter build web --release --dart-define=...` fails

**Solution:**
1. Make sure no spaces in URL
2. Use quotes if URL has special characters: `--dart-define=API_BASE_URL="https://api.com?v=1"`
3. Check flag syntax: `--dart-define=KEY=VALUE`

## Best Practices

✅ **Always use dart-define for environment config**
- Set at build time, not runtime
- No performance impact
- Compile-time safety

✅ **Use meaningful default values**
- Development default: localhost
- Fallback should be safe

✅ **Create build scripts**
- Standardize commands
- Reduce human error
- Easy CI/CD integration

✅ **Document environment URLs**
- Keep list of all environments
- Update when APIs change

✅ **Verify configuration**
- Add debug screen
- Print on startup
- Show in error messages

✅ **Use in CI/CD**
- Automate builds per environment
- Reduce manual deployment steps
- Consistent builds

## Security Notes

⚠️ **Compile-Time Constants**
- Values baked into app at build time
- Cannot be changed after deployment
- Always rebuild for environment changes

⚠️ **API Keys**
- Never put secrets in dart-define
- Use secure secret management service
- Never commit secrets to git

✅ **Safe to Share**
- API base URLs are safe to share
- They're not credentials
- Environment-specific, not secret

## Summary

| Aspect | Details |
|--------|---------|
| Method | `String.fromEnvironment()` |
| Time | Compile-time (build-time) |
| Syntax | `--dart-define=API_BASE_URL=https://...` |
| Environments | Unlimited |
| Performance | No overhead |
| Rebuild | Required on change |

---

**Environment configuration is now complete and flexible!** 🔧✨

