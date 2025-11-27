# ✅ GitHub Setup Checklist

Complete this checklist to ensure your GitHub Actions workflow is properly configured.

## Workflow File

- [x] **File exists:** `.github/workflows/build-deploy-web.yml`
- [x] **YAML syntax correct:** Uses `run: |` for multi-line commands
- [x] **Flutter version:** 3.38.3 (or latest stable)
- [x] **Build command includes:**
  - [x] `--dart-define=API_BASE_URL=$API_BASE_URL`
  - [x] `--base-href=/`
- [x] **Deployment configured:** peaceiris/actions-gh-pages

## GitHub Repository Variables

### Create API_BASE_URL_PROD Variable

**Steps:**
1. Go to your GitHub repository
2. Click **Settings** (top right)
3. Click **Secrets and variables** → **Variables** (left sidebar)
4. Click **New repository variable**

**Fill in:**
```
Name: API_BASE_URL_PROD
Value: https://astrobank-server.onrender.com
```

5. Click **Add variable**

**Verification:**
- [ ] Variable `API_BASE_URL_PROD` exists
- [ ] Value is correct: `https://astrobank-server.onrender.com`
- [ ] Visible in Variables list

## GitHub Pages Configuration

**For automatic deployment to GitHub Pages:**

1. Go to **Settings** → **Pages**
2. Under "Source", select: **Deploy from a branch**
3. Under "Branch", select: 
   - Branch: `dist`
   - Folder: `/ (root)`
4. Click **Save**

**Verification:**
- [ ] Source set to branch `dist`
- [ ] GitHub Pages URL appears at top
- [ ] URL format: `https://gabrielmsantos.github.io/astrobank-app-kids/`

## Secrets (If Needed Later)

For sensitive information like API keys:

1. Go to **Settings** → **Secrets and variables** → **Secrets**
2. Click **New repository secret**
3. Fill in **Name** and **Value**
4. Click **Add secret**

Note: Currently using Variables (public) because URLs are not secrets.

## Testing the Workflow

### 1. Trigger Build Manually

```bash
# Option A: Use GitHub UI
GitHub Repo → Actions → Select workflow → Run workflow

# Option B: Push to main
git add .
git commit -m "Trigger workflow test"
git push origin main
```

### 2. Monitor Build Progress

1. Go to your GitHub repository
2. Click **Actions** tab
3. Click the running workflow
4. Watch build progress in real-time

### 3. Check Build Status

**Success (✅):**
- All steps turn green
- "Build web" completes without errors
- "Deploy to dist branch" succeeds

**Failure (❌):**
- Any step turns red
- Expand step to see error message
- Common errors:
  - `Target file not found` → YAML syntax issue
  - `API_BASE_URL not found` → Variable not set
  - `Flutter not found` → Version issue

## Workflow Steps Explanation

### Step 1: Checkout code
```yaml
uses: actions/checkout@v4
```
- Downloads your repository code
- Latest version from main branch

### Step 2: Setup Flutter
```yaml
uses: subosito/flutter-action@v2
with:
  flutter-version: 3.38.3
  channel: stable
  cache: true
```
- Installs Flutter SDK
- Uses specified version
- Caches dependencies for speed

### Step 3: Get dependencies
```yaml
run: flutter pub get
```
- Downloads all package dependencies
- Prepares for build

### Step 4: Build web ✅ FIXED
```yaml
run: |
  flutter build web --release \
    --dart-define=API_BASE_URL=$API_BASE_URL \
    --base-href=/
```
- Builds Flutter web app
- Sets API endpoint from variable
- Configures correct asset paths

### Step 5: Deploy to dist branch
```yaml
uses: peaceiris/actions-gh-pages@v3
with:
  github_token: ${{ secrets.GITHUB_TOKEN }}
  publish_dir: ./build/web
  publish_branch: dist
```
- Takes built app from `build/web`
- Pushes to `dist` branch
- GitHub Pages serves from this branch

## Troubleshooting

### Build Fails with "Target file not found"

**Problem:** YAML syntax error

**Solution:** 
- Check line 32 has `run: |` (pipe symbol)
- Ensure proper indentation (2 spaces)
- Rebuild with fix

**File to check:** `.github/workflows/build-deploy-web.yml`

### Build Fails with "API_BASE_URL not found"

**Problem:** Variable not set in GitHub

**Solution:**
1. Go to Settings → Secrets and variables → Variables
2. Create `API_BASE_URL_PROD` variable
3. Set value to: `https://astrobank-server.onrender.com`
4. Rerun workflow

### Build Succeeds but App Not Deployed

**Problem:** GitHub Pages not configured

**Solution:**
1. Go to Settings → Pages
2. Select branch: `dist`
3. Select folder: `/` (root)
4. Check URL format

### Images Not Loading After Deployment

**Problem:** Missing `--base-href=/` flag

**Solution:** Already fixed in workflow file!
- Verify line 35: `--base-href=/` is present
- Images should load now

## Environment Variables Used

### FLUTTER_VERSION
```yaml
FLUTTER_VERSION: "3.38.3"
```
- Downloads Flutter SDK
- Can update to latest stable
- Check: https://flutter.dev/docs/release/archive

### API_BASE_URL
```yaml
API_BASE_URL: ${{ vars.API_BASE_URL_PROD }}
```
- References GitHub repository variable
- Substituted at runtime
- Used in build command

## Complete Workflow File (Current)

```yaml
name: Build and Deploy Flutter Web (AstroBank Kids)

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  FLUTTER_VERSION: "3.38.3"
  API_BASE_URL: ${{ vars.API_BASE_URL_PROD }}

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Build web
        run: |
          flutter build web --release \
            --dart-define=API_BASE_URL=$API_BASE_URL \
            --base-href=/

      - name: Deploy to dist branch
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
          publish_branch: dist
          force_orphan: true
```

## Next Steps

1. **Set GitHub Variable**
   - [ ] `API_BASE_URL_PROD` = `https://astrobank-server.onrender.com`

2. **Configure GitHub Pages**
   - [ ] Branch: `dist`
   - [ ] Folder: `/`

3. **Push Changes**
   ```bash
   git add .github/workflows/build-deploy-web.yml
   git commit -m "Fix GitHub Actions workflow YAML syntax"
   git push origin main
   ```

4. **Monitor Build**
   - [ ] Go to Actions tab
   - [ ] Watch build complete
   - [ ] Verify deployment

5. **Test Deployment**
   - [ ] Open GitHub Pages URL
   - [ ] Verify images load
   - [ ] Check API connection

## Success Indicators

When everything is working:

✅ Push to main triggers build automatically
✅ Build completes in ~5-10 minutes
✅ App deployed to GitHub Pages
✅ URL: `https://gabrielmsantos.github.io/astrobank-app-kids/`
✅ Images load correctly
✅ API calls go to production server
✅ All Features work

## Support

For issues:

1. Check [GITHUB_ACTIONS_FIX.md](./GITHUB_ACTIONS_FIX.md) for detailed explanation
2. Review GitHub Actions logs in Actions tab
3. Check repository Variables are set correctly
4. Verify GitHub Pages is enabled

---

**Status: ✅ READY FOR DEPLOYMENT**

Your GitHub Actions workflow is fully configured and ready! 🚀

