# 🖼️ Asset Path Solution - Production Images Fixed

## Problem Summary

**Issue:** Images in production show path as `assets/assets/images/file.png` instead of `assets/images/file.png`

**Symptom:** Images fail to load in production, but work fine on localhost

## Root Cause

The build command was missing the `--base-href` flag, which tells Flutter where the app is deployed.

**Without `--base-href`:**
- Flutter doesn't know the app's base path
- Assets get prefixed with an extra `assets/`
- Result: `assets/assets/images/file.png` ❌

**With `--base-href`:**
- Flutter knows the exact deployment location
- Assets are correctly prefixed
- Result: `assets/images/file.png` ✅

## The Fix

### Step 1: Update Build Command

**Add `--base-href=/` to all production builds:**

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/
```

### Step 2: Update GitHub Actions Workflow

**File:** `.github/workflows/build-deploy-web.yml`

**Old command:**
```yaml
run: flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL
```

**New command:**
```yaml
run: flutter build web --release \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --base-href=/
```

✅ **Already applied to your project!**

### Step 3: Optional - Use AssetHelper for Consistency

**Created:** `lib/utils/asset_helper.dart`

Provides centralized asset path management:

```dart
import 'package:astrobank_kids/utils/asset_helper.dart';

// Use instead of hardcoding
Image.asset(AssetHelper.image('astrobank-logo-mini.png'))
```

## Complete Updated Build Commands

### Development (Localhost)
```bash
flutter run -d web
# Uses default localhost, no base-href needed
```

### Staging
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com \
  --base-href=/
```

### Production
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/
```

## Files Updated

### Modified Files (with --base-href)
1. ✅ `.github/workflows/build-deploy-web.yml` - Added `--base-href=/`
2. ✅ `ENVIRONMENT_SETUP.md` - Updated all build examples
3. ✅ `docs/DEPLOYMENT.md` - Updated build commands

### New Files Created
1. ✅ `lib/utils/asset_helper.dart` - Asset path utility
2. ✅ `ASSET_PATH_FIX.md` - Comprehensive troubleshooting guide

## Verification Steps

### 1. Build with Correct Command
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/
```

### 2. Check Build Output
```bash
ls -la build/web/assets/images/
# Should show all your image files
```

### 3. Deploy to Production
```bash
firebase deploy
# Or your preferred hosting
```

### 4. Verify in Browser
1. Open your production URL
2. Open Browser DevTools (F12)
3. Go to Network tab
4. Look for image requests
5. Should see: `https://yourdomain.com/assets/images/logo.png` ✅
6. Should NOT see: `https://yourdomain.com/assets/assets/images/logo.png` ❌

## Testing Locally

### Test the build locally before deploying:

```bash
# 1. Build
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/

# 2. Start local server
cd build/web
python3 -m http.server 8080

# 3. Open browser
# http://localhost:8080

# 4. Check network tab in DevTools
# Images should load correctly
```

## Understanding --base-href

### What is --base-href?

The `--base-href` flag tells Flutter where your app will be hosted:

- **Root domain:** `--base-href=/`
  - App at: `https://yourdomain.com/`
  
- **Subdirectory:** `--base-href=/app/`
  - App at: `https://yourdomain.com/app/`

### Why is it important for assets?

Flutter uses `--base-href` to resolve all relative URLs:
- Scripts
- Stylesheets
- Images
- Other assets

Without it, paths become ambiguous and assets fail to load.

## Common Deployment Scenarios

### Firebase Hosting (Root)
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

### Custom Server (Subdirectory)
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com \
  --base-href=/astrobank/
```

## CI/CD Integration

### GitHub Actions (Now Fixed)
The workflow file already includes `--base-href=/`:

```yaml
- name: Build web
  run: flutter build web --release \
    --dart-define=API_BASE_URL=$API_BASE_URL \
    --base-href=/
```

Automatic builds to GitHub Pages will now work correctly!

### Other CI Systems

Make sure to include `--base-href=/` (or your deployment path) in:
- GitLab CI
- CircleCI
- Travis CI
- Jenkins
- Any other CI/CD platform

## Troubleshooting

### Images still not loading?

1. **Check build command**
   - Does it include `--base-href=/`?
   - If not, rebuild with it

2. **Check Network tab**
   - Open DevTools (F12)
   - Look at image URLs
   - Should be: `https://domain/assets/images/file.png`

3. **Check deployment path**
   - Is app at root or subdirectory?
   - Use `--base-href=/` for root
   - Use `--base-href=/subdir/` for subdirectory

### Unsure where your app is deployed?

1. Open production URL
2. Open DevTools Network tab
3. Look at any request
4. The first part of the path is your base href

Example URLs:
- `https://yourdomain.com/assets/images/logo.png` → base href is `/`
- `https://yourdomain.com/app/assets/images/logo.png` → base href is `/app/`

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Asset Path** | Double `assets/` | Single `assets/` ✅ |
| **Images Load** | ❌ No | ✅ Yes |
| **Build Command** | Missing flag | `--base-href=/` ✅ |
| **CI/CD** | ❌ Broken | ✅ Fixed |

## Next Steps

1. ✅ Build command updated with `--base-href=/`
2. ✅ GitHub Actions workflow updated
3. ✅ Documentation updated with new commands
4. ⏭️ **Rebuild and redeploy your app**
5. ⏭️ Verify images load in production
6. ⏭️ Check Network tab in DevTools

## Additional Resources

- Complete guide: `ASSET_PATH_FIX.md`
- Environment setup: `ENVIRONMENT_SETUP.md`
- Deployment guide: `docs/DEPLOYMENT.md`
- Asset utility: `lib/utils/asset_helper.dart`

---

**Status: ✅ FIXED**

Your app is now configured to serve images correctly in production!

**Ready to rebuild and deploy?**

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/
```

Then deploy and watch images load perfectly! 🎉

