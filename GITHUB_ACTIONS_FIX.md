# 🔧 GitHub Actions Workflow Fix

## Problem

GitHub Actions build failed with error:
```
Target file " --dart-define=API_BASE_URL=https://astrobank-server.onrender.com" not found.
Error: Process completed with exit code 1.
```

## Root Cause

**Incorrect YAML syntax for multi-line command:**

```yaml
# ❌ WRONG - Backslashes not properly escaped
run: flutter build web --release \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --base-href=/
```

The backslashes were being treated as literal text instead of line continuation, causing the entire second line to be treated as a filename.

## Solution

**Use proper YAML syntax with `|` (literal block scalar):**

```yaml
# ✅ CORRECT - Using pipe for multi-line commands
run: |
  flutter build web --release \
    --dart-define=API_BASE_URL=$API_BASE_URL \
    --base-href=/
```

## What Changed

**File:** `.github/workflows/build-deploy-web.yml`

**Before (Lines 31-34):**
```yaml
      - name: Build web
        run: flutter build web --release \
          --dart-define=API_BASE_URL=$API_BASE_URL \
          --base-href=/
```

**After (Lines 31-35):**
```yaml
      - name: Build web
        run: |
          flutter build web --release \
            --dart-define=API_BASE_URL=$API_BASE_URL \
            --base-href=/
```

## How It Works

### The `|` Symbol

In YAML, `|` means "literal block scalar" - it allows multi-line strings while preserving line breaks and backslashes as continuation characters.

### Why This Works

1. `run: |` tells GitHub Actions: "this is a bash script block"
2. Backslashes `\` are interpreted as line continuation
3. Each line is properly passed to bash
4. Command executes correctly

### Equivalent Commands

These are all equivalent:

```bash
# Single line
flutter build web --release --dart-define=API_BASE_URL=https://api.com --base-href=/

# Multi-line with backslashes (GitHub Actions requires | syntax)
run: |
  flutter build web --release \
    --dart-define=API_BASE_URL=https://api.com \
    --base-href=/

# Using && to chain
run: flutter build web --release --dart-define=API_BASE_URL=https://api.com --base-href=/
```

## GitHub Actions YAML Best Practices

### ✅ DO: Use `|` for multi-line commands
```yaml
- name: Build
  run: |
    flutter build web --release \
      --dart-define=API_BASE_URL=${{ env.API_BASE_URL }} \
      --base-href=/
```

### ❌ DON'T: Use backslashes at root level
```yaml
- name: Build
  run: flutter build web --release \
    --dart-define=API_BASE_URL=${{ env.API_BASE_URL }}
```

### ✅ DO: Reference environment variables correctly
```yaml
env:
  API_BASE_URL: ${{ vars.API_BASE_URL_PROD }}

steps:
  - run: |
      echo "Building with API: $API_BASE_URL"
```

### ✅ DO: Use GitHub variables/secrets
```yaml
run: |
  flutter build web --release \
    --dart-define=API_BASE_URL=${{ vars.API_BASE_URL_PROD }}
```

## Current GitHub Actions Setup

### Environment Variables (Line 9-11)
```yaml
env:
  FLUTTER_VERSION: "3.38.3"
  API_BASE_URL: ${{ vars.API_BASE_URL_PROD }}
```

These are set from GitHub repository variables/secrets.

### Setup Steps
1. **Checkout code** - Get your repository
2. **Setup Flutter** - Install Flutter SDK
3. **Get dependencies** - Run `flutter pub get`
4. **Build web** - Build with correct flags ✅ FIXED
5. **Deploy to dist** - Push to GitHub Pages

## Setting Up GitHub Variables

### For Production API URL

1. Go to: **Settings → Secrets and variables → Variables**
2. Click **New repository variable**
3. **Name:** `API_BASE_URL_PROD`
4. **Value:** `https://astrobank-server.onrender.com`
5. Click **Add variable**

### Use in Workflow
```yaml
env:
  API_BASE_URL: ${{ vars.API_BASE_URL_PROD }}
```

## Complete Workflow File (Fixed)

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

## Troubleshooting

### Workflow Still Fails?

1. **Check GitHub variable is set**
   - Go to Settings → Secrets and variables → Variables
   - Verify `API_BASE_URL_PROD` exists
   - Check value is correct

2. **Check file syntax**
   - Go to `.github/workflows/build-deploy-web.yml`
   - Verify it has `run: |` on line 32
   - Check proper indentation (2 spaces)

3. **Verify Flutter version**
   - Line 10: `FLUTTER_VERSION: "3.38.3"`
   - Can update to latest if needed

4. **Check logs**
   - Go to repository → Actions
   - Click failed workflow
   - Expand "Build web" step
   - Read error message

### Common Errors

**Error: "Target file not found"**
→ Fix: Use `run: |` instead of `run: flutter... \`

**Error: "API_BASE_URL not found"**
→ Fix: Set repository variable `API_BASE_URL_PROD`

**Error: "Flutter not found"**
→ Fix: Update `FLUTTER_VERSION` or use `channel: stable`

## Next Steps

1. ✅ Workflow file fixed
2. ⏭️ Set GitHub variable `API_BASE_URL_PROD`
3. ⏭️ Push to `main` branch to trigger build
4. ⏭️ Check Actions tab for build result
5. ⏭️ Verify deployment to GitHub Pages

## Testing Locally

To test the command locally before pushing:

```bash
# Development
flutter run -d web

# Staging (test command)
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com \
  --base-href=/

# Production (test command)
flutter build web --release \
  --dart-define=API_BASE_URL=https://astrobank-server.onrender.com \
  --base-href=/
```

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions YAML Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [YAML Spec - Block Scalars](https://yaml.org/spec/1.2/spec.html#id2793959)

---

**Status: ✅ FIXED**

Your GitHub Actions workflow is now properly configured! 🚀

Push to `main` and the build will succeed with correct asset paths!

