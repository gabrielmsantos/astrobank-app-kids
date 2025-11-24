# 🐛 Troubleshooting Guide

Solutions to common issues in AstroBank Kids.

## Table of Contents
1. [Setup Issues](#setup-issues)
2. [Runtime Issues](#runtime-issues)
3. [API Issues](#api-issues)
4. [PWA Issues](#pwa-issues)
5. [Performance Issues](#performance-issues)

---

## Setup Issues

### Flutter Not Found

**Error:** `flutter: command not found`

**Solution:**
1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Add to PATH:
   ```bash
   export PATH="$PATH:/path/to/flutter/bin"
   ```
3. Verify: `flutter --version`

### Pub Get Fails

**Error:** `pub get` fails or hangs

**Solution:**
```bash
# Clear pub cache
flutter pub cache clean

# Try again
flutter pub get

# Or force update
flutter pub upgrade
```

### Chrome Not Found

**Error:** `Unable to locate Chrome`

**Solution:**
```bash
# Install Chrome
# macOS: brew install google-chrome
# Linux: sudo apt install chromium-browser
# Windows: Download from google.com/chrome

# Or use Firefox
flutter run -d web --web-browser-flag "--browser=firefox"
```

---

## Runtime Issues

### App Crashes on Startup

**Error:** `Exception while loading...` or blank screen

**Check:**
1. Open DevTools (F12)
2. Check Console tab for errors
3. Check Network tab for failed requests
4. Look for specific error message

**Common Causes:**
- API endpoint wrong in `app_config.dart`
- API server not running
- JSON parsing error

**Solution:**
```dart
// Check app_config.dart
static const String apiBaseUrl = 'http://localhost:3000';
// Should match your actual API server

// Check if API is running
curl http://localhost:3000/api/v1/auth/login
```

### Login Fails

**Error:** `Invalid credentials` or connection refused

**Check:**
1. Verify API server is running
2. Check email/password are correct
3. Check network connectivity
4. Verify API endpoint

**Solution:**
```bash
# Test API directly
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Should return: {"token": "...", "customer_id": "..."}
```

### Data Not Loading

**Error:** Empty screens, no transactions/cards showing

**Check:**
1. Verify customer has data in database
2. Check API endpoints
3. Look at Network tab for API responses
4. Check console for errors

**Solution:**
1. Open DevTools (F12)
2. Go to Network tab
3. Look for `/api/v1/transactions` or similar
4. Click request and check:
   - Status code (should be 200)
   - Response body
   - Error message if any

### Numbers Not Working in Keypad

**Error:** Numeric input doesn't work, shows wrong amount

**Check:**
1. Are digits appearing?
2. Is decimal being added?
3. Is backspace working?

**Solution:**
- Updated numeric keypad should handle properly
- Internal storage as cents (integer)
- Display as dollars (2 decimal places)
- No decimal button (removed)

### Payment Fails

**Error:** "Payment could not be processed"

**Check:**
1. Do you have sufficient balance?
2. Is amount greater than 0?
3. Is amount within invoice limit?

**Solution:**
```
Validation Flow:
1. Balance > 0? → If no, show "No balance"
2. Amount ≤ Balance? → If no, offer adjustment
3. Amount ≤ Invoice? → If no, offer adjustment
4. Process payment
```

---

## API Issues

### "Connection Refused"

**Error:** `Connection refused` or `ECONNREFUSED`

**Cause:** API server not running

**Solution:**
```bash
# Check if API is running
curl http://localhost:3000/

# If not, start it
# Depends on your API setup

# Verify in app_config.dart
static const String apiBaseUrl = 'http://localhost:3000';
```

### "404 Not Found"

**Error:** `404 Not Found`

**Cause:** Wrong API endpoint

**Solution:**
1. Check endpoint in `lib/config/app_config.dart`
2. Verify API route exists
3. Check API documentation

**Example:**
```dart
// Wrong: apiBaseUrl + '/api/v1/transactions' = 'http://localhost:3000/api/v1/transactions'
// If API expects: '/api/transactions' then you need to adjust

// Check your API server routes first
```

### "CORS Error"

**Error:** `Access to XMLHttpRequest blocked by CORS policy`

**Cause:** API doesn't allow requests from web app

**Solution:**

**On API Server:**
```
Add CORS headers:
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

**For Node.js/Express:**
```javascript
const cors = require('cors');
app.use(cors());
```

**For Python/Flask:**
```python
from flask_cors import CORS
CORS(app)
```

### "Timeout"

**Error:** `Request timeout` after 30 seconds

**Cause:** API is slow or not responding

**Solution:**
1. Check API server status
2. Check network connection
3. Increase timeout in `app_config.dart`:
   ```dart
   static const Duration apiTimeout = Duration(seconds: 60);
   ```

### "Invalid JSON"

**Error:** `FormatException: Unexpected end of input`

**Cause:** API response is not valid JSON

**Solution:**
1. Test API endpoint with Postman
2. Check response body is valid JSON
3. Check Content-Type header is `application/json`

---

## PWA Issues

### App Not Installable

**Error:** No install option in Chrome

**Check:**
1. Is HTTPS enabled? (Required except localhost)
2. Is manifest.json valid?
3. Are icons present?
4. Is service worker registered?

**Solution:**
```bash
# Check manifest
# File: web/manifest.json
{
  "name": "AstroBank Kids",
  "short_name": "AstroBank",
  "start_url": "/",
  "display": "standalone",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    }
  ]
}

# Verify icons exist
ls web/icons/
# Should show Icon-192.png and Icon-512.png
```

### Service Worker Not Updating

**Error:** Old version of app still showing

**Solution:**
```bash
# Hard refresh cache
Ctrl+Shift+R (Windows/Linux)
Cmd+Shift+R (Mac)

# Or manually unregister
# DevTools > Application > Service Workers > Unregister
# Then refresh
```

### Installation Fails on iPhone

**Error:** Can't add to home screen, or app doesn't work after install

**Check:**
1. Using Safari (not Chrome on iOS)
2. App URL is HTTPS
3. Manifest is valid
4. Try different connection (WiFi vs cellular)

**Solution:**
1. Upgrade iOS to latest version
2. Try in private browsing mode
3. Clear Safari cache: Settings > Safari > Clear History and Website Data
4. Try again

### Offline Not Working

**Error:** App doesn't work offline after installation

**This is Expected:**
- PWA is cached but needs API responses
- Without API, some features won't work
- This is normal behavior

---

## Performance Issues

### App Slow or Laggy

**Check:**
1. Open DevTools (F12)
2. Go to Performance tab
3. Record and analyze
4. Look for long tasks

**Common Causes:**
- Too many transactions loaded
- Large images
- Too many API requests
- Browser issue

**Solutions:**
```bash
# Clear browser cache
# Try in new private window
# Use different browser
# Check network speed (throttle to 3G in DevTools)

# Or optimize app
flutter build web --release --web-renderer html
```

### Build Very Large

**Error:** `flutter build web` creates huge files

**Solution:**
```bash
# Check size
flutter build web --release --analyze-size

# Optimize
flutter build web --release \
  --dart-define=FLUTTER_WEB_USE_SKIA=false \
  --web-renderer html

# Expected size: ~50-100 MB (will be compressed by server)
```

### Infinite Scroll Not Working

**Error:** Scrolling down doesn't load more items

**Check:**
1. Are there more items? (check `has_more` response)
2. Is cursor being used?
3. Check Network tab for pagination requests

**Solution:**
```dart
// Verify in home_screen.dart
Future<void> _loadMoreTransactions() async {
  if (!_hasMoreTransactions || _transactionsCursor == null) {
    return; // No more to load
  }
  
  final result = await TransactionService.getTransactionsPaginated(
    customerId: _customer.customerId,
    cursor: _transactionsCursor, // Must include cursor
  );
}
```

### Pull-to-Refresh Not Working

**Error:** Swipe down doesn't refresh

**Check:**
1. Are you at the top of the list?
2. Try hard refresh (F5)
3. Check console for errors

**Solution:**
```dart
// Verify RefreshIndicator is implemented
RefreshIndicator(
  onRefresh: () async {
    await _refreshAllData();
  },
  child: ListView(...),
)
```

---

## Debugging Tips

### Enable Debug Logging

```dart
// Add to services for debugging
import 'dart:developer' as developer;

Future<void> loadData() async {
  developer.log('Loading data...');
  try {
    // Your code
  } catch (e) {
    developer.log('Error: $e');
  }
}
```

### Check Network Requests

1. Open DevTools (F12)
2. Go to Network tab
3. Reload page (F5)
4. Look for failed requests (red)
5. Click request to see details

### Check Console Errors

1. Open DevTools (F12)
2. Go to Console tab
3. Look for red errors
4. Click to see stack trace

### Test API Directly

```bash
# Test API endpoints with curl
curl -X GET http://localhost:3000/api/v1/customers/123
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

### Use Postman

1. Download Postman: https://www.postman.com/
2. Create requests for each API endpoint
3. Test with different parameters
4. Compare responses

---

## Common Error Messages

### "RenderFlex overflowed"
**Cause:** Widget too large for container
**Solution:** Adjust layout, use Flexible/Expanded

### "NoSuchMethodError"
**Cause:** Null value or missing method
**Solution:** Add null checks, check variable initialization

### "Unhandled Exception"
**Cause:** Uncaught error in async function
**Solution:** Check stack trace, add try-catch

### "Bad state: 'Already disposed'"
**Cause:** Using disposed widget
**Solution:** Check mounted before setState

---

## Getting Help

1. **Check docs**: Read relevant documentation file
2. **Check console**: Look for error messages (F12)
3. **Check Network**: Verify API responses
4. **Check code**: Review related dart file
5. **Search**: Google the error message
6. **Test API**: Use Postman to verify API works

---

**Still stuck?** Check the specific documentation file for your issue! 📖

