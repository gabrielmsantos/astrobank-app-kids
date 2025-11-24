# ⚡ Quick Start Guide

Get the AstroBank Kids app running in just 5 minutes!

## 🎯 Prerequisites

- Flutter 3.9.2+
- Dart 3.9.2+
- API server running (usually `http://localhost:3000`)

## 🚀 Step-by-Step Setup

### 1. Navigate to Project
```bash
cd /Users/gabrielsantos/Projects/flutter/AstroBankProject/astrobank_kids
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure API Endpoint
Edit `lib/config/app_config.dart`:

```dart
static const String apiBaseUrl = 'http://localhost:3000';
// Change to your API server URL
```

### 4. Run Development Server
```bash
flutter run -d web
```

Your app will open in the browser at: `http://localhost:54321`

### 5. Login
Use test credentials from your API:
- **Email**: test@example.com
- **Password**: password

## 📱 Main Sections

### Login Screen
- Email/password authentication
- Error handling for invalid credentials
- Loading state during authentication

### Home Screen Tabs

#### Overview Tab
- Customer profile information
- Account balance display
- Customer details

#### Transactions Tab
- View all transactions
- Infinite scroll (loads 15 items per page)
- Scroll to load more data

#### Cards Tab
- Credit card list
- Card details (masked number, expiry date)
- Available credit limit
- Invoice history for each card

## 🎨 Key Features to Try

1. **Login**: Use your credentials to authenticate
2. **View Transactions**: Scroll down to load more (infinite scroll)
3. **View Cards**: Check credit card information
4. **Pull to Refresh**: Swipe down to reload all data
5. **Pay Invoice**: Click "Pay" button on any invoice
   - Use numeric keypad to enter amount
   - Click "Pay Full Amount" to pay entire balance
   - Confirm payment

## 🛠️ Troubleshooting

### "Connection refused" error
- Verify API server is running
- Check `apiBaseUrl` in `lib/config/app_config.dart`
- Ensure you can access the API URL in your browser

### "Invalid credentials"
- Double-check email and password
- Verify test credentials exist in your API

### Data not loading
- Check browser console (F12) for errors
- Verify API response format matches expected structure
- Check Network tab to see API requests

### App not running
- Run `flutter pub get` again
- Try `flutter clean` then `flutter pub get`
- Check Flutter version: `flutter --version`

## 🌐 Build for Web (Production)

```bash
# Build optimized release version
flutter build web --release

# Output will be in: build/web/
```

## 📱 Install as PWA on Devices

### iPhone/iPad
1. Open Safari
2. Navigate to your PWA URL
3. Tap Share button
4. Tap "Add to Home Screen"
5. Confirm

### Android
1. Open Chrome
2. Navigate to your PWA URL
3. Tap menu (⋮)
4. Tap "Install app"
5. Confirm

## 🔧 Key Configuration Files

| File | Purpose |
|------|---------|
| `lib/config/app_config.dart` | API endpoints and configuration |
| `lib/theme/app_colors.dart` | Color scheme |
| `web/manifest.json` | PWA configuration |
| `pubspec.yaml` | Dependencies |

## 📚 Next Steps

- Read [Project Overview](./PROJECT_OVERVIEW.md) for complete feature list
- Check [API Reference](./API_REFERENCE.md) for API details
- Review [Architecture Guide](./ARCHITECTURE.md) for code structure
- Visit [Deployment Guide](./DEPLOYMENT.md) to deploy

## 💡 Tips

1. **Hot Reload**: Press 'r' in terminal to reload without restarting
2. **DevTools**: Press 'D' in terminal to open DevTools
3. **Mobile Testing**: Use Chrome DevTools mobile emulation
4. **API Testing**: Use Postman to test API endpoints before running app

---

**All set! Your app is running. Start exploring!** 🚀

