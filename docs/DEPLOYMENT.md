# 🚀 Deployment Guide

Complete guide to building and deploying AstroBank Kids as a PWA.

## Table of Contents
1. [Development](#development)
2. [Production Build](#production-build)
3. [Deployment Options](#deployment-options)
4. [PWA Installation](#pwa-installation)
5. [Configuration](#configuration)
6. [Troubleshooting](#troubleshooting)

---

## Development

### Prerequisites
- Flutter 3.9.2+
- Dart 3.9.2+
- Node.js (for deployment tools)

### Local Development Server

```bash
# Navigate to project
cd /Users/gabrielsantos/Projects/flutter/AstroBankProject/astrobank_kids

# Install dependencies
flutter pub get

# Run development server
flutter run -d web
```

**Development URL:** `http://localhost:54321`

**Hot Reload:**
- Press 'r' to reload code changes
- Press 'R' to reload entire app
- Changes take effect immediately

**DevTools:**
- Press 'D' in terminal to open browser DevTools
- Check Network tab for API calls
- Check Console for errors

---

## Production Build

### Build Web Version

```bash
# Build optimized release version
flutter build web --release

# Output location: build/web/
```

**Build Output:**
```
build/web/
├── index.html
├── main.dart.js
├── main.dart.js.map
├── flutter.js
├── flutter_service_worker.js
├── assets/
├── canvaskit/
└── ...
```

**Build Time:** ~2-5 minutes (depends on machine)

**Build Size:** ~50-100 MB (will be optimized by hosting)

### Optimization Options

```bash
# Build with specific options
flutter build web --release \
  --dart-define=FLUTTER_WEB_USE_SKIA=false \
  --web-renderer html

# For maximum performance
flutter build web --release --profile
```

**Options Explained:**
- `FLUTTER_WEB_USE_SKIA=false`: Use HTML renderer (faster on low-end devices)
- `--web-renderer html`: Force HTML rendering
- `--profile`: Enable profiling (smaller build size)

---

## Deployment Options

### Option 1: Firebase Hosting (Recommended)

**Advantages:**
- Free tier with generous limits
- Automatic HTTPS
- Global CDN
- Easy deployment
- Great performance

**Setup:**

```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Initialize Firebase project
firebase init

# During init, select:
# - Hosting: Configure files for Firebase Hosting
# - Use existing project or create new
# - Set public directory to: build/web
# - Rewrite URLs for SPA: Yes

# 4. Build Flutter app
flutter build web --release

# 5. Deploy
firebase deploy

# 6. Your app is live!
# URL: https://your-project.web.app
```

**firebase.json Configuration:**
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

**Custom Domain:**
```bash
# In Firebase Console:
# 1. Go to Hosting tab
# 2. Click "Add custom domain"
# 3. Follow verification steps
```

---

### Option 2: Netlify

**Advantages:**
- Simple drag-and-drop deployment
- Automatic HTTPS
- Continuous deployment from Git
- Good free tier

**Setup:**

```bash
# 1. Install Netlify CLI
npm install -g netlify-cli

# 2. Build Flutter app
flutter build web --release

# 3. Deploy (first time)
netlify deploy --prod --dir build/web

# Follow prompts to create project

# 4. Future deployments
netlify deploy --prod --dir build/web
```

**With Git (Recommended):**
1. Push code to GitHub/GitLab/Bitbucket
2. Connect repository to Netlify
3. Automatic deploys on push to main branch

**netlify.toml Configuration:**
```toml
[build]
  command = "flutter pub get && flutter build web --release"
  publish = "build/web"

[context.production]
  command = "flutter pub get && flutter build web --release"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

---

### Option 3: Vercel

**Advantages:**
- Excellent performance
- Automatic deployments
- Environment variables
- Analytics included

**Setup:**

```bash
# 1. Build Flutter app locally
flutter build web --release

# 2. Push to GitHub
git push origin main

# 3. Go to https://vercel.com
# 4. Click "New Project"
# 5. Import your GitHub repository
# 6. Configure:
#    - Build Command: flutter pub get && flutter build web --release
#    - Output Directory: build/web
# 7. Click Deploy
```

**Automatic Deployments:**
- Every push to main triggers build and deploy
- Preview URLs for pull requests
- Automatic rollbacks if needed

---

### Option 4: Docker

**Advantages:**
- Works anywhere Docker runs
- Consistent environment
- Easy scaling
- Full control

**Dockerfile:**
```dockerfile
# Build stage
FROM node:18-alpine as build
RUN npm install -g firebase-tools
RUN curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.13.9-stable.tar.xz | tar xJ
ENV PATH="$PATH:/flutter/bin"

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Runtime stage
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf:**
```nginx
server {
    listen 80;
    server_name _;
    
    root /usr/share/nginx/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**Build and Run:**
```bash
# Build Docker image
docker build -t astrobank-kids .

# Run container
docker run -p 80:80 astrobank-kids

# Access at: http://localhost
```

**Push to Docker Hub:**
```bash
# Tag image
docker tag astrobank-kids username/astrobank-kids

# Login to Docker Hub
docker login

# Push image
docker push username/astrobank-kids
```

---

### Option 5: Traditional Web Server

**Using Nginx:**

```bash
# Build Flutter app
flutter build web --release

# Copy to web server
sudo cp -r build/web /var/www/astrobank-kids

# Configure Nginx
sudo nano /etc/nginx/sites-available/astrobank-kids
```

**Nginx Configuration:**
```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    root /var/www/astrobank-kids;
    index index.html;
    
    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**Enable Site:**
```bash
sudo ln -s /etc/nginx/sites-available/astrobank-kids /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**SSL Certificate (Let's Encrypt):**
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
sudo systemctl restart nginx
```

---

## PWA Installation

### iPhone/iPad (Safari)

1. **Open the deployed app URL in Safari**
   ```
   https://your-app-url.com
   ```

2. **Tap Share button** (bottom of screen)

3. **Scroll down and tap "Add to Home Screen"**

4. **Enter app name** (or keep default)

5. **Tap "Add"**

6. **Launch app from home screen**

**Note:** PWA support on iOS is limited but improving with each iOS update.

### Android (Chrome)

1. **Open the deployed app URL in Chrome**
   ```
   https://your-app-url.com
   ```

2. **Tap menu** (three dots, top right)

3. **Tap "Install app"** or **"Add to Home screen"**

4. **Confirm installation**

5. **Launch app from home screen**

---

## Configuration

### API Endpoint Setup (Using dart-define)

Set different API endpoints for each environment using compile-time constants:

**Development (Localhost):**
```bash
# Uses default localhost:8000
flutter run -d web

# Or explicitly:
flutter run -d web --dart-define=API_BASE_URL=http://localhost:8000
```

**Staging Environment:**
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com
```

**Production Environment:**
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com
```

**How It Works:**
- File: `lib/config/app_config.dart`
- Uses `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000')`
- Set at build time, baked into the app
- No code changes needed between environments
- Single codebase for all environments

### Multiple Build Scripts

Create convenient build scripts:

**Development:**
```bash
# Run with local API
flutter run -d web
```

**Staging Build:**
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://staging-api.astrobank.com
```

**Production Build:**
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.astrobank.com
```

**For Complete Environment Configuration Guide:**
See [Environment Configuration Guide](./ENVIRONMENT_CONFIG.md) for:
- Detailed examples
- Build scripts setup
- CI/CD integration
- GitHub Actions configuration
- Multiple environment variables
- Troubleshooting

### Security Headers

**Production Security Headers:**

Add to server configuration:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self' https:; script-src 'self'
```

**Firebase Headers (automatic):**
```bash
# .firebaserc already configured with security headers
firebase deploy
```

---

## Monitoring & Analytics

### Google Analytics Setup

```html
<!-- Add to web/index.html -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_ID');
</script>
```

### Performance Monitoring

**Firebase Performance Monitoring:**

```bash
# Already included in Flutter PWA
# Check in Firebase Console > Performance
```

**Lighthouse Audit:**
1. Open DevTools (F12)
2. Go to "Lighthouse" tab
3. Click "Analyze page load"
4. Review PWA score

**Target Metrics:**
- Performance: > 90
- Accessibility: > 90
- Best Practices: > 90
- SEO: > 90
- PWA: ✅ Installable

---

## Pre-Deployment Checklist

Before deploying to production:

- [ ] Update API endpoint to production URL
- [ ] Test all features locally
- [ ] Build web version: `flutter build web --release`
- [ ] Test built version locally
- [ ] Check for console errors
- [ ] Verify images load correctly
- [ ] Test on mobile devices (browser)
- [ ] Test offline functionality (if PWA)
- [ ] Set up security headers
- [ ] Configure CORS on API server
- [ ] Enable HTTPS on hosting
- [ ] Set up monitoring/analytics
- [ ] Configure custom domain
- [ ] Test PWA installation on iOS/Android
- [ ] Run Lighthouse audit (target: 90+)
- [ ] Create deployment documentation
- [ ] Set up automatic backups

---

## Continuous Deployment

### GitHub Actions (Automatic)

**`.github/workflows/deploy.yml`:**

```yaml
name: Deploy to Firebase

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.13.9'
      
      - run: flutter pub get
      
      - run: flutter build web --release
      
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: your-project-id
          channelId: live
```

**Setup:**
1. Create `.github/workflows/deploy.yml`
2. Add Firebase service account to GitHub Secrets
3. Push to main branch
4. Automatic deployment on every push

---

## Troubleshooting

### App Blank Page After Deploy

**Cause:** CORS headers, base URL, or routing issues

**Solutions:**
1. Check browser console for errors (F12)
2. Verify API endpoint is accessible
3. Check CORS headers on API server
4. Verify manifest.json is valid
5. Clear browser cache (Ctrl+Shift+Delete)

### Service Worker Not Updating

**Solution:**
```bash
# Hard refresh cache
Ctrl+Shift+R (Windows/Linux)
Cmd+Shift+R (Mac)

# Or unregister manually
# DevTools > Application > Service Workers > Unregister
```

### PWA Not Installable

**Checklist:**
- [ ] HTTPS enabled (except localhost)
- [ ] manifest.json valid
- [ ] Icons present and correct size
- [ ] Service worker registered
- [ ] App has name and description
- [ ] No console errors

### API Calls Failing

**Debugging:**
1. Open DevTools (F12)
2. Check Network tab
3. Look for API requests
4. Check response status and body
5. Verify CORS headers

**Common Issues:**
- Wrong base URL in `app_config.dart`
- API server not running
- CORS not configured on API
- Invalid authentication token

### Performance Issues

**Optimization:**
1. Enable minification (automatic in `--release`)
2. Use HTML renderer: `--web-renderer html`
3. Check bundle size: `flutter build web --release --analyze-size`
4. Optimize images
5. Enable gzip compression on server

---

## Rollback Procedure

### Firebase

```bash
# List previous deployments
firebase hosting:channel:list

# Deploy to specific version
firebase deploy --only hosting:channel-name
```

### Manual Rollback

```bash
# Keep previous build
cp -r build/web build/web-v1.0

# Build new version
flutter build web --release

# If issues, restore previous
rm -rf build/web
cp -r build/web-v1.0 build/web
firebase deploy
```

---

## Performance Tips

- Use Firebase Hosting for best performance
- Enable gzip compression on server
- Configure caching headers
- Optimize images before deployment
- Monitor bundle size
- Use CDN for static assets

---

**Ready to deploy!** 🚀

Choose a deployment option above and follow the setup instructions.

