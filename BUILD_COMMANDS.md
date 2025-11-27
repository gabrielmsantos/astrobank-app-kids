# 📋 Build Commands Reference

**Quick reference for all build scenarios.**

## Standard Commands

### Development (Localhost)
```bash
flutter run -d web
```
- Uses default localhost:8000
- No build needed, hot reload enabled
- Assets load from local file system

### Staging Build
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com \
  --base-href=/
```
- Connects to staging API
- Correct asset paths for web
- Ready to deploy to staging server

### Production Build
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/
```
- Connects to production API
- Correct asset paths for web
- Ready to deploy to production server

---

## Complete Deployment Examples

### Firebase Hosting
```bash
# 1. Build
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/

# 2. Deploy
firebase deploy
```

### Netlify
```bash
# 1. Build
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/

# 2. Deploy (via CLI or git push)
# Option A: CLI
netlify deploy --prod --dir=build/web

# Option B: Git (connect repo to Netlify)
git push origin main
```

### Vercel
```bash
# 1. Build
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/

# 2. Deploy (via CLI)
vercel --prod

# Or use git push if connected
```

### Custom Server (Subdirectory)
```bash
# If app deployed to /app/
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com \
  --base-href=/app/

# Upload build/web to your server
```

---

## GitHub Actions Deployment

Automatically triggered on push to `main`:

**File:** `.github/workflows/build-deploy-web.yml`

Current configuration:
- ✅ Runs on push to main
- ✅ Builds with `--dart-define=API_BASE_URL`
- ✅ Deploys to GitHub Pages
- ✅ Uses correct `--base-href=/`

No manual action needed!

---

## Environment Variables

### Using Environment Variables in Commands

```bash
# Set variable
API_URL=https://api.astrobank.com

# Use in command
flutter build web --release \
  --dart-define=API_BASE_URL=$API_URL \
  --base-href=/
```

### GitHub Actions Secrets

In `.github/workflows/build-deploy-web.yml`:
```yaml
env:
  API_BASE_URL: ${{ secrets.API_BASE_URL_PROD }}

jobs:
  build:
    run: flutter build web --release \
      --dart-define=API_BASE_URL=${{ env.API_BASE_URL }} \
      --base-href=/
```

---

## Testing Before Deployment

### Build Locally
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/
```

### Test Locally
```bash
cd build/web
python3 -m http.server 8080
```

Then open: `http://localhost:8080`

### Verify Assets
1. Open DevTools (F12)
2. Go to Network tab
3. Check image URLs
4. Should be: `http://localhost:8080/assets/images/file.png` ✅

---

## Common Issues & Solutions

### Issue: Images show double `assets/`

**Problem:** `assets/assets/images/file.png`

**Solution:** Add `--base-href=/` to build command

### Issue: Wrong API endpoint

**Problem:** App connects to staging instead of production

**Solution:** Check `--dart-define=API_BASE_URL=...` value

### Issue: App deployed to subdirectory doesn't work

**Problem:** App doesn't load or assets 404

**Solution:** Use `--base-href=/your-subdir/` instead of `--base-href=/`

---

## Checklist Before Production

- [ ] Using `--base-href=/` in build command
- [ ] API_BASE_URL set to production endpoint
- [ ] Build command includes both flags
- [ ] Tested locally with `python3 -m http.server`
- [ ] Images load correctly in test
- [ ] No 404 errors in DevTools Network tab
- [ ] API calls go to production server
- [ ] Ready to deploy!

---

## Quick Copy-Paste Commands

### Production (Copy & Paste)
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com \
  --base-href=/ && firebase deploy
```

### Staging (Copy & Paste)
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com \
  --base-href=/
```

---

## What Each Flag Does

### `flutter build web --release`
- Builds optimized web app
- Minifies code and assets
- Removes debug info

### `--dart-define=API_BASE_URL=...`
- Sets API endpoint at compile time
- Baked into app
- Cannot be changed after build

### `--base-href=/`
- Tells Flutter where app is deployed
- Fixes asset loading
- Essential for web apps

---

## References

📄 **Full Documentation:**
- [ENVIRONMENT_SETUP.md](./ENVIRONMENT_SETUP.md) - Detailed environment guide
- [ASSET_PATH_SOLUTION.md](./ASSET_PATH_SOLUTION.md) - Asset path fixes
- [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md) - Deployment guide

---

**Ready to build and deploy?** Use the commands above! 🚀

