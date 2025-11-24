# 🏗️ Architecture Guide

Deep dive into the code structure and design patterns used in AstroBank Kids.

## Project Structure

```
astrobank_kids/
├── lib/
│   ├── main.dart                      # App entry point & initialization
│   ├── config/
│   │   └── app_config.dart           # API endpoints & configuration
│   ├── models/                        # Data models (5 files)
│   │   ├── customer_model.dart       # Customer data structure
│   │   ├── transaction_model.dart    # Transaction data structure
│   │   ├── credit_card_model.dart    # Credit card data structure
│   │   ├── invoice_model.dart        # Invoice data structure
│   │   └── invoice_item_model.dart   # Invoice line items
│   ├── services/                      # API services (4 files)
│   │   ├── auth_service.dart         # Authentication API
│   │   ├── customer_service.dart     # Customer profile API
│   │   ├── transaction_service.dart  # Transaction API with pagination
│   │   └── card_service.dart         # Cards & invoices API
│   ├── screens/                       # UI screens (2 files)
│   │   ├── login_screen.dart         # Login form & authentication
│   │   └── home_screen.dart          # Main dashboard with 3 tabs
│   ├── widgets/                       # Reusable components (2 files)
│   │   ├── space_background.dart     # Space-themed background
│   │   └── transaction_item.dart     # Transaction list item widget
│   └── theme/
│       └── app_colors.dart           # Color constants
├── web/
│   ├── index.html                     # Web entry point
│   ├── manifest.json                  # PWA configuration
│   └── icons/                         # PWA app icons
├── assets/
│   └── images/                        # Image assets
├── pubspec.yaml                       # Dependencies
└── docs/                              # Documentation
```

## Layered Architecture

The app follows a **clean layered architecture**:

```
┌─────────────────────────────────────┐
│     Presentation Layer              │
│  (UI Screens & Widgets)             │
│                                     │
│  • LoginScreen                      │
│  • HomeScreen (3 tabs)              │
│  • Custom Widgets                   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     Business Logic Layer            │
│  (Services)                         │
│                                     │
│  • AuthService                      │
│  • CustomerService                  │
│  • TransactionService               │
│  • CardService                      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     Data Layer                      │
│  (Models)                           │
│                                     │
│  • Customer                         │
│  • Transaction                      │
│  • CreditCard                       │
│  • Invoice                          │
│  • InvoiceItem                      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     API Integration Layer           │
│  (HTTP Requests)                    │
│                                     │
│  • REST API Client                  │
│  • URL Configuration                │
│  • Error Handling                   │
└─────────────────────────────────────┘
```

## Key Classes & Components

### Main Entry Point

**`lib/main.dart`**
- App initialization
- Root widget setup
- Route configuration
- Theme application

### Screens

**`lib/screens/login_screen.dart`**
- Login form UI
- Email/password input
- Authentication logic
- Error handling

**`lib/screens/home_screen.dart`** (Main Dashboard)
- 3-tab interface
  - **Overview Tab**: Customer profile
  - **Transactions Tab**: Transaction list with infinite scroll
  - **Cards Tab**: Credit cards and invoices
- Pull-to-refresh functionality
- State management
- All data loading logic

### Models (Data Structures)

**`lib/models/customer_model.dart`**
```dart
Customer({
  required String customerId,
  required String alias,
  required String name,
  required String email,
  required String balance,
  String? birthdate,
  String? gender,
  String? avatarUrl,
})
```

**`lib/models/transaction_model.dart`**
```dart
Transaction({
  required String id,
  required String type,
  required String nature,
  required String title,
  required String description,
  required String date,
  required String value,
  String? bankerAlias,
  String? customerAlias,
})
```

**`lib/models/credit_card_model.dart`**
```dart
CreditCard({
  required String cardId,
  required String cardNumber,
  required String cardType,
  required String expirationDate,
  required String limitAmount,
  required String availableLimit,
  required String status,
  required bool virtual,
})
```

**`lib/models/invoice_model.dart`**
```dart
Invoice({
  required String id,
  required String closingDate,
  String? dueDate,
  required String totalAmount,
  required String paidAmount,
  required String status,
})
```

**`lib/models/invoice_item_model.dart`**
```dart
InvoiceItem({
  required String id,
  required String postingDate,
  required String title,
  String? description,
  required String category,
  required String type,
  required String amount,
})
```

### Services (API Integration)

**`lib/services/auth_service.dart`**
```dart
static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
})
```
- Handles user authentication
- Returns customer data and token
- Error handling for failed logins

**`lib/services/customer_service.dart`**
```dart
static Future<Customer> getCustomerProfile(String customerId)
```
- Fetches customer profile
- Updates balance information
- Refreshes customer data

**`lib/services/transaction_service.dart`**
```dart
static Future<Map<String, dynamic>> getTransactionsPaginated({
  required String customerId,
  String? cursor,
  int? limit,
})
```
- Implements keyset pagination
- Returns transactions with next cursor
- Handles pagination state

**`lib/services/card_service.dart`**
```dart
static Future<List<CreditCard>> getCustomerCards(String customerId)
static Future<Map<String, dynamic>> getCardInvoices(
  String cardId, 
  String fromDate, 
  String toDate,
)
static Future<List<InvoiceItem>> getInvoiceItems(String invoiceId)
static Future<Map<String, dynamic>> recordInvoicePayment(
  String invoiceId,
  {required double amount},
)
```
- Manages card operations
- Handles invoice retrieval
- Processes invoice payments

### Configuration

**`lib/config/app_config.dart`**
- API base URL
- API version
- Pagination settings
- Timeout configuration
- Endpoint definitions

### Theme

**`lib/theme/app_colors.dart`**
- Color constants
- Hex values
- Theme palette
- Semantic colors (success, error, etc.)

## Data Flow Patterns

### Authentication Flow
```
LoginScreen → AuthService.login()
           ↓
         API Call → POST /auth/login
           ↓
      Parse Response → Customer Data
           ↓
       Save in State
           ↓
    Navigate to HomeScreen
```

### Transaction Loading (Infinite Scroll)
```
HomeScreen Init → Load 15 items
                ↓
         ListView with ScrollController
                ↓
    User scrolls → Detect threshold (300px)
                ↓
         Load next 15 items with cursor
                ↓
         Append to existing list
                ↓
        Update UI setState
```

### Payment Processing Flow
```
User clicks Pay
        ↓
   Show numeric keypad modal
        ↓
   User enters amount
        ↓
   Validate amount:
   - Check balance > 0
   - Check amount ≤ balance
   - Check amount ≤ invoice
        ↓
   Call recordInvoicePayment()
        ↓
   POST to /invoices/{id}/payments
        ↓
   Update invoice list
        ↓
   Refresh customer balance
```

### Pull-to-Refresh Flow
```
User swipes down
        ↓
   Show refresh indicator
        ↓
   Refresh customer data
   Refresh transactions (reset cursor)
   Refresh cards
   Refresh invoices
        ↓
   Update all UI
        ↓
   Hide indicator
```

## State Management

Uses simple **setState** pattern:

```dart
class _HomeScreenState extends State<HomeScreen> {
  // Customer data
  late Customer _customer;
  
  // Loading states
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  // Pagination
  String? _transactionsCursor;
  bool _hasMoreTransactions = true;
  
  // Current data
  List<Transaction> _transactions = [];
  List<CreditCard> _cards = [];
  List<Invoice> _unpaidInvoices = [];
  
  // Methods
  Future<void> _loadInitialTransactions() async {
    // Load first page
  }
  
  Future<void> _loadMoreTransactions() async {
    // Load next page with cursor
  }
  
  @override
  void setState(() {
    // Update UI
  });
}
```

## Error Handling

All services use try-catch with user-friendly error messages:

```dart
try {
  // API call
  final response = await http.get(...);
  
  if (response.statusCode == 200) {
    // Parse and return data
  } else {
    throw Exception('Failed to load data');
  }
} catch (e) {
  throw Exception('Error: $e');
}
```

## API Integration Pattern

All services follow this pattern:

```dart
static Future<DataType> methodName() async {
  try {
    final response = await http.get(
      Uri.parse(AppConfig.endpoint),
      headers: {'Content-Type': 'application/json'},
    ).timeout(AppConfig.apiTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DataType.fromJson(data);
    } else {
      throw Exception('Error: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error: $e');
  }
}
```

## Pagination Strategy

Uses **keyset pagination** with cursor tokens:

```dart
// First request - no cursor
GET /api/v1/transactions?customer_id=123&limit=15

// Response includes next_cursor
{
  "transactions": [...],
  "next_cursor": "opaque_token_xyz",
  "has_more": true
}

// Next request - with cursor
GET /api/v1/transactions?customer_id=123&limit=15&cursor=opaque_token_xyz
```

Benefits:
- ✅ Efficient pagination
- ✅ No offset issues
- ✅ Opaque tokens (flexible backend)
- ✅ Works with real-time data

## Widget Hierarchy

```
MyApp (Root)
├── MaterialApp
├── Theme Configuration
└── Navigation
    ├── LoginScreen
    │   └── SpaceBackground
    │   └── LoginForm
    │
    └── HomeScreen
        ├── SpaceBackground
        ├── AppBar
        ├── TabBar
        │   ├── Overview Tab
        │   ├── Transactions Tab
        │   │   ├── RefreshIndicator
        │   │   ├── ListView
        │   │   └── TransactionItem (repeated)
        │   │
        │   └── Cards Tab
        │       ├── CreditCard widgets
        │       ├── Invoice cards
        │       └── Invoice detail modals
        │
        └── Modals
            ├── PaymentInputSheet
            └── InvoiceDetailsSheet
```

## Responsive Design

Uses Media Query for responsive layouts:

```dart
double screenWidth = MediaQuery.of(context).size.width;
bool isMobile = screenWidth < 600;
bool isTablet = screenWidth >= 600 && screenWidth < 900;
bool isDesktop = screenWidth >= 900;

// Adjust UI based on screen size
```

## Best Practices Implemented

✅ **Layered Architecture** - Clean separation of concerns
✅ **Error Handling** - Comprehensive try-catch blocks
✅ **State Management** - Clear state management pattern
✅ **Null Safety** - Full null safety implementation
✅ **Type Safety** - Strong typing throughout
✅ **Memory Management** - Proper dispose of resources
✅ **Code Reusability** - Shared services and widgets
✅ **Configuration** - Centralized configuration
✅ **Documentation** - Inline comments
✅ **Responsive Design** - Mobile-first approach

## Performance Considerations

- **Lazy Loading**: Load data only when needed
- **Pagination**: Only 15 items per page
- **Cursor-based**: Efficient keyset pagination
- **Caching**: Reduce redundant API calls
- **Service Worker**: PWA offline support
- **Image Optimization**: Responsive images

## Security Considerations

- Token-based authentication
- HTTPS-ready for production
- Input validation
- Error messages without sensitive data
- No hardcoded credentials
- CORS support

## Testing Strategy

Manual testing checklist:
- [ ] Login with valid/invalid credentials
- [ ] Navigation between tabs
- [ ] Infinite scroll loading
- [ ] Pull-to-refresh
- [ ] Invoice payment flow
- [ ] Error scenarios
- [ ] Responsive design on different devices

---

**Clean, maintainable, production-ready architecture!** 🏗️

