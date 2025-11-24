# 🔧 Quick Environment Setup Reference

## TL;DR - Commands for Each Environment

### Development (Localhost)
```bash
# Run with default localhost:8000
flutter run -d web
```

### Staging Build
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com
```

### Production Build
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com
```

---

## How It Works

**File:** `lib/config/app_config.dart`

```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
```

- `String.fromEnvironment()` reads compile-time values
- `--dart-define=KEY=VALUE` sets these values during build
- Value is baked into the app at build time
- Cannot be changed after deployment

---

## Environment URLs

| Environment | URL | Command |
|-------------|-----|---------|
| Development | `http://localhost:8000` | `flutter run -d web` |
| Staging | `https://staging-api.astrobank.com` | See below ⬇️ |
| Production | `https://api.astrobank.com` | See below ⬇️ |

### Build Commands

```bash
# Staging
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com

# Production
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com
```

---

## Full Build & Deploy Example

### For Production

```bash
# 1. Build with production API
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com

# 2. Test locally (optional)
# cd build/web && python3 -m http.server

# 3. Deploy to Firebase
firebase deploy

# 4. Verify
curl -I https://astrobank-kids.web.app/
```

### For Staging

```bash
# 1. Build with staging API
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com

# 2. Deploy to staging project
firebase deploy --project astrobank-staging

# 3. Test
# Open https://astrobank-kids-staging.web.app/
```

---

## Running Tests

```bash
# Test configuration
flutter test test/config_test.dart

# Test with environment
flutter test test/config_test.dart \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com
```

---

## Verify Configuration

### Check Current API Base URL

Add this to your app (development only):

```dart
print('🔧 API Base URL: ${AppConfig.apiBaseUrl}');
```

### Create Debug Screen

```dart
// In any screen
import 'package:astrobank_kids/config/app_config.dart';

@override
Widget build(BuildContext context) {
  return ListView(
    children: [
      ListTile(
        title: Text('API Base URL'),
        subtitle: Text(AppConfig.apiBaseUrl),
      ),
    ],
  );
}
```

---

## Common Use Cases

### Local Development
```bash
# Default localhost
flutter run -d web
```

### Testing with Different API
```bash
# Run against staging while developing
flutter run -d web --dart-define=API_BASE_URL=https://staging-api.astrobank.com
```

### Multiple Dart Defines
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --dart-define=LOG_LEVEL=production
```

### Building for CI/CD
```bash
# GitHub Actions or similar
flutter build web --release --dart-define=API_BASE_URL=$API_URL
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| API still uses localhost | Make sure `--dart-define=API_BASE_URL=...` is in build command |
| Wrong URL in production | Verify build command has correct `--dart-define` flag |
| Command too long | Create build scripts (see ENVIRONMENT_CONFIG.md) |
| URL with special chars | Use quotes: `--dart-define=API_BASE_URL="https://..."` |

---

## Next Steps

- 📖 [Full Environment Configuration Guide](./docs/ENVIRONMENT_CONFIG.md)
- 🚀 [Deployment Guide](./docs/DEPLOYMENT.md)
- 🔍 [Troubleshooting](./docs/TROUBLESHOOTING.md)

---

**Ready to deploy!** 🚀

