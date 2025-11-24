# 🔌 API Reference

Complete reference for all API endpoints used by AstroBank Kids.

## Base Configuration

```dart
// File: lib/config/app_config.dart
static const String apiBaseUrl = 'http://localhost:3000';
static const String apiVersion = 'v1';
static const Duration apiTimeout = Duration(seconds: 30);
```

Update `apiBaseUrl` to your production server before deploying.

## Authentication Endpoints

### Login
**POST** `/api/v1/auth/login`

Authenticates a user with email and password.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password"
}
```

**Response (200 OK):**
```json
{
  "token": "jwt_token_string",
  "customer_id": "customer_123",
  "customer": {
    "customer_id": "customer_123",
    "alias": "John Doe",
    "name": "John Michael Doe",
    "email": "john@example.com",
    "balance": "5000.50",
    "birthdate": "1990-01-15",
    "gender": "M",
    "avatar_url": "https://..."
  }
}
```

**Error Response (401 Unauthorized):**
```json
{
  "error": "Invalid credentials",
  "message": "Email or password is incorrect"
}
```

**Implementation:** `lib/services/auth_service.dart`

---

## Customer Endpoints

### Get Customer Profile
**GET** `/api/v1/customers/{customer_id}`

Retrieves complete customer profile information.

**Parameters:**
| Name | Type | Location | Required |
|------|------|----------|----------|
| customer_id | string | path | ✅ Yes |

**Response (200 OK):**
```json
{
  "customer_id": "customer_123",
  "alias": "John Doe",
  "name": "John Michael Doe",
  "email": "john@example.com",
  "balance": "5000.50",
  "birthdate": "1990-01-15",
  "gender": "M",
  "avatar_url": "https://cdn.example.com/avatars/..."
}
```

**Implementation:** `lib/services/customer_service.dart`

**Usage in App:**
```dart
Future<void> _refreshCustomerData() async {
  final customer = await CustomerService.getCustomerProfile(_customer.customerId);
  setState(() => _customer = customer);
}
```

---

## Transaction Endpoints

### Get Transactions (Paginated)
**GET** `/api/v1/transactions`

Retrieves transactions with keyset pagination using opaque cursor tokens.

**Query Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| customer_id | string | ✅ Yes | Filter by customer |
| banker_key | string | ❌ No | Filter by banker |
| from_date | string | ❌ No | Start date (YYYY-MM-DD) |
| to_date | string | ❌ No | End date (YYYY-MM-DD) |
| cursor | string | ❌ No | Opaque cursor for pagination |
| limit | integer | ❌ No | Items per page (default: 15) |

**Response (200 OK):**
```json
{
  "transactions": [
    {
      "id": "txn_123",
      "type": "credit",
      "nature": "salary",
      "title": "Monthly Salary",
      "description": "Salary deposit",
      "date": "2025-11-22",
      "value": "5000.00",
      "banker_alias": "Main Bank",
      "customer_alias": "John Doe"
    }
  ],
  "next_cursor": "opaque_token_xyz_or_null",
  "has_more": true
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "Customer not found",
  "message": "The specified customer_id does not exist"
}
```

**Pagination Flow:**
```
// First request (no cursor)
GET /api/v1/transactions?customer_id=123&limit=15

// Response includes next_cursor
{
  "transactions": [...15 items...],
  "next_cursor": "opaque_token_123",
  "has_more": true
}

// Next request (with cursor)
GET /api/v1/transactions?customer_id=123&cursor=opaque_token_123&limit=15
```

**Implementation:** `lib/services/transaction_service.dart`

**Usage in App:**
```dart
Future<void> _loadInitialTransactions() async {
  final result = await TransactionService.getTransactionsPaginated(
    customerId: _customer.customerId,
  );
  setState(() {
    _transactions = result['transactions'];
    _transactionsCursor = result['next_cursor'];
    _hasMoreTransactions = result['has_more'];
  });
}
```

---

## Credit Card Endpoints

### Get Customer Credit Cards
**GET** `/api/v1/customers/{customer_id}/credit-cards`

Retrieves all credit cards for a customer.

**Parameters:**
| Name | Type | Location | Required |
|------|------|----------|----------|
| customer_id | string | path | ✅ Yes |

**Response (200 OK):**
```json
{
  "cards": [
    {
      "card_id": "card_456",
      "card_number": "****1234",
      "card_type": "visa",
      "expiration_date": "12/26",
      "limit_amount": "10000.00",
      "available_limit": "5600.50",
      "status": "active",
      "virtual": false
    }
  ]
}
```

**Implementation:** `lib/services/card_service.dart`

---

## Invoice Endpoints

### Get Card Invoices
**GET** `/api/v1/credit-cards/{card_id}/invoices`

Retrieves invoices for a specific credit card with date filtering.

**Parameters:**
| Name | Type | Location | Required | Description |
|------|------|----------|----------|-------------|
| card_id | string | path | ✅ Yes | Credit card ID |
| from_date | string | query | ❌ No | Start date (YYYY-MM-DD) |
| to_date | string | query | ❌ No | End date (YYYY-MM-DD) |

**Response (200 OK):**
```json
{
  "invoices": [
    {
      "id": "inv_789",
      "closing_date": "2025-11-20",
      "due_date": "2025-12-05",
      "total_amount": "1500.00",
      "paid_amount": "0.00",
      "status": "unpaid"
    }
  ]
}
```

**Implementation:** `lib/services/card_service.dart`

---

### Get Invoice Items
**GET** `/api/v1/invoices/{invoice_id}/items`

Retrieves all line items for an invoice, including charges and interest.

**Parameters:**
| Name | Type | Location | Required |
|------|------|----------|----------|
| invoice_id | string | path | ✅ Yes |

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "item_001",
      "posting_date": "2025-11-15",
      "title": "Purchase at Supermarket",
      "description": "Grocery shopping",
      "category": "groceries",
      "type": "charge",
      "amount": "150.00"
    },
    {
      "id": "item_002",
      "posting_date": "2025-11-20",
      "title": "Interest Charge",
      "description": "Monthly interest",
      "category": "interest",
      "type": "interest",
      "amount": "25.00"
    }
  ]
}
```

**Item Types:**
- `charge` - Regular purchase
- `interest` - Interest charges
- `fee` - Service fees
- `payment` - Payment received

**Implementation:** `lib/services/card_service.dart`

**Usage in App (Interest Calculation):**
```dart
Future<double> _calculateInvoiceInterest(String invoiceId) async {
  final items = await CardService.getInvoiceItems(invoiceId);
  return items
    .where((item) => item.type == 'interest')
    .fold(0.0, (sum, item) => sum + double.parse(item.amount));
}
```

---

## Payment Endpoints

### Record Invoice Payment
**POST** `/api/v1/invoices/{invoice_id}/payments`

Records a payment against an invoice. Updates invoice paid amount, customer balance, and card available limit.

**Parameters:**
| Name | Type | Location | Required |
|------|------|----------|----------|
| invoice_id | string | path | ✅ Yes |

**Request Body:**
```json
{
  "amount": 150.50
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Payment recorded successfully",
  "payment": {
    "id": "pmt_123",
    "invoice_id": "inv_789",
    "amount": "150.50",
    "date": "2025-11-22",
    "method": "credit_card"
  },
  "invoice": {
    "id": "inv_789",
    "closing_date": "2025-11-20",
    "due_date": "2025-12-05",
    "total_amount": "1500.00",
    "paid_amount": "150.50",
    "status": "unpaid"
  }
}
```

**Validation:**
- Amount must be greater than 0
- Amount cannot exceed invoice unpaid balance
- Customer must have sufficient balance

**Error Response (400 Bad Request):**
```json
{
  "error": "Insufficient balance",
  "message": "Payment amount exceeds available balance"
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "Invoice not found",
  "message": "The specified invoice_id does not exist"
}
```

**Implementation:** `lib/services/card_service.dart`

**Usage in App:**
```dart
Future<void> _processPayment(Invoice invoice, double amount) async {
  try {
    final result = await CardService.recordInvoicePayment(
      invoice.id,
      amount: amount,
    );
    
    // Refresh data
    await _refreshCustomerData();
    await _loadUnpaidInvoicesForCard(_selectedCard!);
    
    showSnackBar('Payment successful!');
  } catch (e) {
    showSnackBar('Payment failed: $e');
  }
}
```

**Payment Validation Flow:**
```
User enters amount
        ↓
Check: currentBalance > 0?
  NO  → Show "No balance" error
  YES ↓
Check: amount > currentBalance?
  YES → Show confirmation dialog, adjust to balance
  NO  ↓
Check: amount > invoiceUnpaidAmount?
  YES → Show confirmation dialog, adjust to invoice amount
  NO  ↓
Process payment
        ↓
Success → Refresh all data
```

---

## Common Response Codes

| Code | Meaning | Cause |
|------|---------|-------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid parameters or validation failure |
| 401 | Unauthorized | Invalid token or credentials |
| 404 | Not Found | Resource not found |
| 500 | Server Error | Internal server error |

---

## Error Handling

All API calls wrap errors in try-catch blocks:

```dart
try {
  final response = await http.get(...);
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    throw Exception('HTTP ${response.statusCode}');
  }
} catch (e) {
  throw Exception('API Error: $e');
}
```

---

## Rate Limiting

**Recommended:**
- Limit API calls to 10-20 per second per customer
- Implement exponential backoff for retries
- Cache frequently accessed data (customer profile, cards)

**In App:**
- Only load when needed (lazy loading)
- Pagination prevents loading too much data
- Pull-to-refresh throttled (user action required)

---

## Authentication

All API calls (except login) should include authentication:

**Token Usage:**
```dart
final response = await http.get(
  Uri.parse(url),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
```

---

## CORS Requirements

For web/PWA deployment, API server must support CORS:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

---

## API Implementation Files

| Endpoint | File | Class | Method |
|----------|------|-------|--------|
| `/auth/login` | `auth_service.dart` | `AuthService` | `login()` |
| `/customers/{id}` | `customer_service.dart` | `CustomerService` | `getCustomerProfile()` |
| `/transactions` | `transaction_service.dart` | `TransactionService` | `getTransactionsPaginated()` |
| `/customers/{id}/credit-cards` | `card_service.dart` | `CardService` | `getCustomerCards()` |
| `/credit-cards/{id}/invoices` | `card_service.dart` | `CardService` | `getCardInvoices()` |
| `/invoices/{id}/items` | `card_service.dart` | `CardService` | `getInvoiceItems()` |
| `/invoices/{id}/payments` | `card_service.dart` | `CardService` | `recordInvoicePayment()` |

---

## Testing API Endpoints

Use **Postman** or **cURL** to test endpoints:

```bash
# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Get Customer
curl -X GET http://localhost:3000/api/v1/customers/customer_123 \
  -H "Authorization: Bearer token"

# Get Transactions
curl -X GET "http://localhost:3000/api/v1/transactions?customer_id=123&limit=15" \
  -H "Authorization: Bearer token"
```

---

**API Integration complete and tested!** ✅

