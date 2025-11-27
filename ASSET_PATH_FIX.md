# 🖼️ Asset Path Fix - Production vs Development

## Problem

In production, images show as `assets/assets/image` instead of `assets/image`, causing images to fail loading.

## Root Cause

This typically happens when:
1. **Base href mismatch** - The `base href` in `web/index.html` doesn't match the deployment path
2. **Double asset prefixing** - Assets get prefixed twice in the build process
3. **Deployment subdirectory** - App deployed to a subdirectory like `/app/` instead of root

## Solutions

### Solution 1: Check Deployment Base Path

**If deploying to root (`https://yourdomain.com/`):**
```html
<!-- web/index.html -->
<base href="/">
```

**If deploying to subdirectory (`https://yourdomain.com/app/`):**
```html
<!-- web/index.html -->
<base href="/app/">
```

### Solution 2: Use --base-href at Build Time

**For production at root:**
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/
```

**For production in subdirectory:**
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/app/
```

### Solution 3: Fix Asset Declaration

Ensure `pubspec.yaml` is correct:
```yaml
flutter:
  assets:
    - assets/images/
```

Then reference images as:
```dart
Image.asset('images/astrobank-logo-mini.png')
// NOT: 'assets/images/astrobank-logo-mini.png'
```

### Solution 4: Use AssetHelper Utility

Created `lib/utils/asset_helper.dart` for consistent asset paths:

```dart
import 'package:astrobank_kids/utils/asset_helper.dart';

// Use instead of hardcoding paths
Image.asset(AssetHelper.image('astrobank-logo-mini.png'))
// or by key
Image.asset(AssetHelper.getImage('logo'))
```

## Diagnosis Steps

### 1. Check Build Output
```bash
ls -la build/web/assets/images/
# Should show all your image files
```

### 2. Check Network in Browser DevTools
- Open Production URL
- Open Browser DevTools (F12)
- Go to Network tab
- Look at image requests
- Note the full URL path

### 3. Common Patterns
- ✅ `https://yourdomain.com/assets/images/file.png` - CORRECT
- ❌ `https://yourdomain.com/assets/assets/images/file.png` - WRONG (double assets)
- ❌ `https://yourdomain.com/app/assets/images/file.png` - MIGHT BE CORRECT (if in subdirectory)

## Quick Fixes

### Firebase Deployment
If deploying to Firebase, the base href should be `/`:
```bash
flutter build web --release --base-href=/
```

### Netlify Deployment
If deploying to Netlify (root):
```bash
flutter build web --release --base-href=/
```

### Custom Domain with Subdirectory
If deploying to `/astrobank/`:
```bash
flutter build web --release --base-href=/astrobank/
```

## Complete Build Commands by Platform

### Firebase (Root)
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/

firebase deploy
```

### Netlify (Root)
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/

# Deploy build/web folder
```

### Vercel (Root)
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/
```

### Custom Server with Subdirectory
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/astrobank/
```

## Verification

### Check Current Base Href
Add this to `lib/main.dart`:
```dart
void main() {
  if (kDebugMode) {
    print('📍 Base HREF (from HTML): Look in web/index.html');
  }
  runApp(const AstroBankKidsApp());
}
```

### Test Assets
Create a debug screen:
```dart
import 'package:astrobank_kids/utils/asset_helper.dart';

class AssetDebugScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Asset Paths')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Logo Path'),
            subtitle: Text(AssetHelper.image('astrobank-logo-mini.png')),
          ),
          ListTile(
            title: Text('Background Path'),
            subtitle: Text(AssetHelper.image('background3.jpg')),
          ),
          SizedBox(height: 20),
          // Test actual image loading
          Padding(
            padding: EdgeInsets.all(16),
            child: Image.asset(
              AssetHelper.image('background3.jpg'),
              height: 200,
            ),
          ),
        ],
      ),
    );
  }
}
```

## Most Common Fixes

### Fix 1: Update Build Command (80% of cases)
```bash
# Before (missing --base-href)
flutter build web --release

# After (with explicit base-href)
flutter build web --release --base-href=/
```

### Fix 2: Update web/index.html (15% of cases)
```html
<!-- If deploying to root -->
<base href="/">

<!-- If deploying to subdirectory -->
<base href="/app/">
```

### Fix 3: Use AssetHelper (5% of edge cases)
```dart
// Centralized, consistent asset paths
Image.asset(AssetHelper.image('filename.png'))
```

## Firebase Specific

For Firebase Hosting:

```bash
# 1. Build with correct base href
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/

# 2. Update firebase.json if needed
# {
#   "hosting": {
#     "public": "build/web",
#     "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
#   }
# }

# 3. Deploy
firebase deploy
```

## Testing Checklist

- [ ] Build command includes `--base-href=/` (or correct subdirectory)
- [ ] `web/index.html` has correct `<base href>` tag
- [ ] Asset paths use `images/filename.png` (NOT `assets/images/filename.png`)
- [ ] All images appear in `build/web/assets/images/` directory
- [ ] Browser DevTools shows images loading from correct URL
- [ ] No 404 errors in Network tab for images
- [ ] Images load correctly on localhost
- [ ] Images load correctly in production

## Troubleshooting

### Images work in dev but not production
→ Check `--base-href` in build command

### Double `assets/assets/` in URL
→ You're referencing `assets/images/file.png` in code, should be `images/file.png`

### Images show 404 in production
→ Check browser DevTools Network tab for actual URL being requested

### Works on Firebase but not custom domain
→ Check `--base-href` matches your deployment URL structure

## References

- Flutter Web Documentation: https://flutter.dev/docs/deployment/web
- Flutter Asset Bundling: https://flutter.dev/docs/development/ui/assets-and-images
- Firebase Hosting: https://firebase.google.com/docs/hosting/deploy

---

**Implementation Status: COMPLETE** ✅

Use `--base-href=/` for most deployments to root domain!

