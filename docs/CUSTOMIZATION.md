# 🎨 Customization Guide

How to customize AstroBank Kids for your needs.

## Table of Contents
1. [Colors & Theme](#colors--theme)
2. [Typography](#typography)
3. [API Endpoints](#api-endpoints)
4. [Pagination](#pagination)
5. [UI Elements](#ui-elements)
6. [Adding Features](#adding-features)

---

## Colors & Theme

### Change Primary Colors

**File:** `lib/theme/app_colors.dart`

```dart
class AppColors {
  // Primary Colors
  static const Color primaryPurple = Color(0xFF7C3AED); // Change this
  static const Color successGreen = Color(0xFF00C950);
  static const Color errorRed = Color(0xFFFB2C36);
  
  // Add custom colors
  static const Color brandBlue = Color(0xFF0066FF);
  static const Color brandOrange = Color(0xFFFF9500);
}
```

**Update App Theme:**

File: `lib/main.dart`

```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryPurple, // Change here
      brightness: Brightness.dark,
    ),
  ),
)
```

### Change Main Balance Card Gradient

**File:** `lib/screens/home_screen.dart` (~line 390)

```dart
// Current (Teal to Indigo)
colors: [
  const Color(0xFF0D9488), // Teal
  const Color(0xFF4338CA), // Indigo
],

// Change to:
colors: [
  const Color(0xFF7C3AED), // Purple
  const Color(0xFF1E40AF), // Dark Blue
],
```

**Available Options:**
```dart
// Option 1: Purple to Dark Blue
colors: [const Color(0xFF7C3AED), const Color(0xFF1E40AF)]

// Option 2: Deep Space Purple to Navy
colors: [const Color(0xFF4C1D95), const Color(0xFF0F172A)]

// Option 3: Teal to Indigo (Current)
colors: [const Color(0xFF0D9488), const Color(0xFF4338CA)]

// Option 4: Slate to Bright Blue
colors: [const Color(0xFF475569), const Color(0xFF3B82F6)]

// Option 5: Mint to Purple
colors: [const Color(0xFF10B981), const Color(0xFFA855F7)]
```

---

## Typography

### Change Main Font

**File:** `pubspec.yaml`

```yaml
dependencies:
  google_fonts: ^6.2.1
  # Already included
```

**Update in Code:**

File: `lib/main.dart` or specific widgets

```dart
import 'package:google_fonts/google_fonts.dart';

// Use in text
Text(
  'Example',
  style: GoogleFonts.inter( // Change font
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
)
```

**Available Google Fonts:**
```dart
GoogleFonts.roboto()
GoogleFonts.poppins()
GoogleFonts.inter()
GoogleFonts.ubuntu()
GoogleFonts.montserrat()
GoogleFonts.playfairDisplay()
// And hundreds more...
```

### Change Username Font

**File:** `lib/screens/home_screen.dart` (~line 330)

```dart
// Current
Text(
  _customer.alias,
  style: GoogleFonts.jersey25( // Change 'jersey25'
    color: Colors.white,
    fontSize: 42,
    letterSpacing: 1.2,
  ),
)

// Alternative fonts
GoogleFonts.fredoka()
GoogleFonts.roboto()
GoogleFonts.poppins()
GoogleFonts.righteous()
```

### Change Font Size

```dart
// Increase all text by 10%
Text(
  'Example',
  style: TextStyle(
    fontSize: 16, // Change this
    fontWeight: FontWeight.bold,
  ),
)
```

---

## API Endpoints

### Change API Base URL

**File:** `lib/config/app_config.dart`

```dart
static const String apiBaseUrl = 'http://localhost:3000';
// Change to your API server URL

// For production
static const String apiBaseUrl = 'https://api.yourdomain.com';
```

### Change API Version

```dart
static const String apiVersion = 'v1';
// Change if your API uses different version
// e.g., 'v2', 'v3'
```

### Change API Timeout

```dart
static const Duration apiTimeout = Duration(seconds: 30);
// Change to: Duration(seconds: 60) for slower connections
```

### Add New API Endpoint

**Step 1:** Add to `app_config.dart`

```dart
static String invoiceDetails(String invoiceId) => 
  '$apiBaseUrl/api/$apiVersion/invoices/$invoiceId';
```

**Step 2:** Add to appropriate service

```dart
// File: lib/services/card_service.dart

static Future<Map<String, dynamic>> getInvoiceDetails(String invoiceId) async {
  try {
    final response = await http.get(
      Uri.parse(AppConfig.invoiceDetails(invoiceId)),
      headers: {'Content-Type': 'application/json'},
    ).timeout(AppConfig.apiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load invoice details');
    }
  } catch (e) {
    throw Exception('Error: $e');
  }
}
```

---

## Pagination

### Change Page Size

**File:** `lib/config/app_config.dart`

```dart
static const int defaultPageSize = 15;
// Change to 20, 30, 50 etc.
```

**Affects:**
- Transactions per page
- Invoices per page

### Change Scroll Threshold

**File:** `lib/screens/home_screen.dart`

```dart
const int _loadMoreThreshold = 300; // pixels from bottom

// Change to trigger earlier or later
const int _loadMoreThreshold = 100; // Trigger sooner
const int _loadMoreThreshold = 500; // Trigger later
```

---

## UI Elements

### Change Background Image

**File:** `lib/widgets/space_background.dart`

```dart
// Current
image: AssetImage('images/background3.jpg'),

// Change to:
image: AssetImage('images/background.jpg'),
image: AssetImage('images/background2.jpg'),
```

**Add New Background:**
1. Add image to `assets/images/`
2. Update `pubspec.yaml`:
   ```yaml
   assets:
     - images/background.jpg
     - images/background2.jpg
     - images/your_new_image.jpg
   ```
3. Update code to use it

### Change App Logo

**File:** `lib/screens/home_screen.dart` (~line 380)

```dart
// Current
Image.asset(
  'images/astrobank-logo-mini.png',
  width: 110,
  height: 110,
  fit: BoxFit.cover,
),

// Change to:
Image.asset(
  'images/your-logo.png',
  width: 110,
  height: 110,
  fit: BoxFit.cover,
),
```

### Change Button Styles

**Find Button Widget:**

```dart
// Before customization, locate the button in code
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryPurple,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
  child: const Text('Button'),
)
```

**Customize:**

```dart
style: ElevatedButton.styleFrom(
  backgroundColor: Colors.green, // Change color
  foregroundColor: Colors.white, // Text color
  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Size
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Shape
)
```

### Change Card Styling

**Example: Invoice Card**

```dart
// File: lib/screens/home_screen.dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16), // Change border radius
    gradient: LinearGradient(
      colors: [...], // Change colors
    ),
    border: Border.all(color: Colors.white30), // Change border
    boxShadow: [...], // Change shadow
  ),
)
```

---

## Adding Features

### Add New Tab

**Step 1:** Add tab button

```dart
// File: lib/screens/home_screen.dart
TabBar(
  tabs: [
    Tab(text: 'Overview'),
    Tab(text: 'Transactions'),
    Tab(text: 'Cards'),
    Tab(text: 'New Tab'), // Add here
  ],
)
```

**Step 2:** Add tab content

```dart
TabBarView(
  children: [
    OverviewTab(),
    TransactionsTab(),
    CardsTab(),
    NewTab(), // Add here
  ],
)
```

**Step 3:** Create widget

```dart
// File: lib/screens/new_tab.dart
class NewTab extends StatefulWidget {
  @override
  State<NewTab> createState() => _NewTabState();
}

class _NewTabState extends State<NewTab> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(child: Text('New Tab Content')),
    );
  }
}
```

### Add New Screen

**Step 1:** Create screen file

```dart
// File: lib/screens/new_screen.dart
import 'package:flutter/material.dart';

class NewScreen extends StatefulWidget {
  @override
  State<NewScreen> createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Screen')),
      body: Center(child: const Text('Content')),
    );
  }
}
```

**Step 2:** Add route in main.dart

```dart
// File: lib/main.dart
onGenerateRoute: (settings) {
  switch (settings.name) {
    case '/home':
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    case '/new':
      return MaterialPageRoute(builder: (_) => const NewScreen());
    default:
      return null;
  }
}
```

**Step 3:** Navigate to it

```dart
// From any screen
Navigator.pushNamed(context, '/new');
```

### Add New Widget

**Step 1:** Create widget file

```dart
// File: lib/widgets/custom_card.dart
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final String description;
  
  const CustomCard({
    required this.title,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}
```

**Step 2:** Use widget

```dart
// In any screen
CustomCard(
  title: 'Example',
  description: 'This is a custom card widget',
)
```

---

## Configuration Options

### Required Setup

Before first run, update:
1. `lib/config/app_config.dart` - API endpoint
2. `pubspec.yaml` - Any additional dependencies
3. `web/manifest.json` - App name and description

### Optional Customizations

- Colors in `lib/theme/app_colors.dart`
- Fonts using Google Fonts
- Background in `lib/widgets/space_background.dart`
- API timeout in `lib/config/app_config.dart`
- Page size in `lib/config/app_config.dart`

---

## Best Practices

1. **Keep API configuration centralized** - Use `app_config.dart`
2. **Use theme colors** - Reference `AppColors` instead of hardcoding colors
3. **Create reusable widgets** - Don't duplicate code
4. **Add comments** - Document your changes
5. **Test thoroughly** - After each change
6. **Use consistent naming** - Follow existing patterns
7. **Keep services separate** - API logic separate from UI

---

**Happy customizing!** 🎨

