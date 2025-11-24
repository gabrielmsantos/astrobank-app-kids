# ✨ Features Documentation

Detailed guide to all features implemented in AstroBank Kids.

## Table of Contents
1. [Authentication](#-authentication)
2. [Dashboard](#-dashboard)
3. [Transactions](#-transactions)
4. [Credit Cards](#-credit-cards)
5. [Invoices](#-invoices)
6. [Invoice Payments](#-invoice-payments)
7. [Data Refresh](#-data-refresh)

---

## 🔐 Authentication

### Login Screen
Secure customer authentication with email and password.

**Features:**
- Email input validation
- Password input (masked)
- Loading indicator during authentication
- Error messages for invalid credentials
- Automatic customer data loading on success

**UI Elements:**
- Text input fields with Material Design
- Submit button with loading state
- Error message display
- Space-themed background

**Implementation:**
```dart
// File: lib/screens/login_screen.dart
// Service: lib/services/auth_service.dart

Future<void> _handleLogin() async {
  final result = await AuthService.login(
    email: emailController.text,
    password: passwordController.text,
  );
  
  if (result['success']) {
    // Navigate to HomeScreen
  }
}
```

**Error Handling:**
- Invalid email format
- Incorrect password
- Network errors
- Server errors

---

## 🏠 Dashboard

### Main Balance Card
Displays customer's account overview with quick actions.

**Features:**
- Customer name (alias) with cartoonish font styling
- Current balance display
- Spendable amount (matches available card limit)
- AstroBank logo avatar
- Reload button to refresh all data
- Settings/profile access

**UI Design:**
- Teal to Indigo gradient background
- Glassmorphism effect (blur/opacity)
- Large, readable typography
- Jersey 25 font for username
- Space background integration

**Gradient Options Available:**
- Option 1: Purple to Dark Blue
- Option 2: Deep Space Purple to Navy
- Option 3: Teal to Indigo (Current)
- Option 4: Slate to Bright Blue
- Option 5: Mint to Purple

**Logo:**
- AstroBank logo mini (astrobank-logo-mini.png)
- Circular clipped design
- 110x110 pixels
- Covers entire circular avatar

**Reload Button:**
Refreshes all application data:
- Customer profile & balance
- All transactions (resets cursor)
- Credit cards
- Unpaid invoices
- Paid invoices

```dart
Future<void> _refreshAllData() async {
  await _refreshCustomerData();
  await _loadInitialTransactions();
  await _loadCards();
  if (_selectedCard != null) {
    await Future.wait([
      _loadUnpaidInvoicesForCard(_selectedCard!),
      _loadInvoicesForCard(_selectedCard!),
    ]);
  }
}
```

---

## 📊 Transactions

### Overview
Complete transaction history with infinite scroll pagination.

**Features:**
- View all customer transactions
- Infinite scroll (loads 15 items per page)
- Pull-to-refresh functionality
- Keyset-based pagination for efficiency
- Real-time pagination state
- Reload button in panel header

**Transaction Information Displayed:**
- Transaction type (credit/debit)
- Description/title
- Amount (with formatting)
- Date (formatted)
- Category/nature
- Banker/customer alias

**Pagination System:**
```
First Load: 0 items → Load 15
           ↓ (show 15)
Scroll to bottom → Load next 15 with cursor
           ↓ (show 30)
Repeat until no more data
```

**Reload Button:**
- Located in transactions panel header
- Resets pagination cursor
- Reloads transactions from beginning
- Shows loading indicator

**Implementation:**
```dart
// File: lib/screens/home_screen.dart
// Service: lib/services/transaction_service.dart

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

Future<void> _loadMoreTransactions() async {
  if (!_hasMoreTransactions || _transactionsCursor == null) return;
  
  final result = await TransactionService.getTransactionsPaginated(
    customerId: _customer.customerId,
    cursor: _transactionsCursor,
  );
  setState(() {
    _transactions.addAll(result['transactions']);
    _transactionsCursor = result['next_cursor'];
    _hasMoreTransactions = result['has_more'];
  });
}
```

**UI Components:**
- ListView for transaction list
- TransactionItem widget for each item
- ScrollController for infinite scroll detection
- RefreshIndicator for pull-to-refresh
- Loading indicator at bottom when fetching more

---

## 💳 Credit Cards

### Card Management
View and manage customer's credit cards.

**Features:**
- Display all credit cards
- Card details (number, type, expiry)
- Available credit limit
- Card status (active/inactive)
- Virtual/Physical indicator
- Card selection
- Invoice history per card

**Card Information:**
- Masked card number (****1234)
- Card type (Visa, Mastercard, etc.)
- Expiration date
- Total limit amount
- Available limit
- Status indicator
- Virtual/Physical badge

**Card Selection:**
- Click card to select
- Highlights selected card
- Updates invoice display for selected card
- Persists selection during session

**Implementation:**
```dart
// File: lib/screens/home_screen.dart
// Service: lib/services/card_service.dart

Future<void> _loadCards() async {
  final cards = await CardService.getCustomerCards(
    _customer.customerId,
  );
  setState(() {
    _cards = cards;
    if (cards.isNotEmpty && _selectedCard == null) {
      _selectedCard = cards.first;
    }
  });
}
```

---

## 📋 Invoices

### Invoice Display
View invoices and invoice details for selected card.

**Features:**
- Two invoice categories:
  - **Unpaid Invoices** - Highlight pending payments
  - **Paid Invoices** - Archive of completed invoices
- Month/year display
- Total amount due
- **Interest charges** - Sum of all interest items
- Paid/unpaid amounts
- Due dates
- Status badges
- Invoice detail expansion
- "View Items" button for line items

**Invoice Card Design:**
- Unpaid: Blue/cyan gradient background
- Paid: Dark slate blue gradient (improved visibility)
- Colored borders and shadows
- Due date highlighting
- Amount display in prominent font

**Status Indicator:**
- **Unpaid**: Red due date text, white amounts
- **Paid**: Green badge with checkmark
  - Badge color: AppColors.successGreen
  - Icon: check_circle
  - Text: "PAID"

**Interest Display:**
```
Invoice Card:
Due:       10/11/2025
Total:     $26.17
Interest:  $3.17  ← Shown in orange if > 0
Paid:      $26.17
Unpaid:    $0.00
```

**Interest Calculation:**
```dart
Future<double> _calculateInvoiceInterest(String invoiceId) async {
  final items = await CardService.getInvoiceItems(invoiceId);
  return items
    .where((item) => item.type == 'interest')
    .fold(0.0, (sum, item) => sum + double.parse(item.amount));
}
```

**Implementation:**
```dart
// File: lib/screens/home_screen.dart

Future<void> _loadUnpaidInvoicesForCard(CreditCard card) async {
  final result = await CardService.getCardInvoices(
    card.cardId,
    fromDate: '2025-01-01',
    toDate: '2025-12-31',
  );
  setState(() {
    _unpaidInvoices = result['invoices']
      .where((inv) => inv.status.toLowerCase() == 'unpaid')
      .toList();
  });
}
```

---

## 💰 Invoice Payments

### Payment System
Easy-to-use invoice payment with numeric keypad.

**Features:**
- Numeric keypad interface (familiar banking UI)
- Custom amount entry
- "Pay Full Amount" button
- Smart validation
- Real-time balance checking
- Auto-refresh after payment
- Success/error feedback

### Numeric Keypad
**Design:**
- 3x4 grid layout
- Buttons 0-9
- Backspace button (←)
- No decimal button (removed)
- "Pay Full Amount" quick action
- "Pay Now" confirmation

**Input Handling:**
```
User types: 1 2 5 . 5 0
            ↓ (stored as cents)
         125500 cents
            ↓ (display)
         $1,255.00

Backspace: removes last digit
Leading zeros: automatically removed
Max amount: no limit (validated by backend)
```

**Implementation:**
```dart
void _addDigit(String digit) {
  int newValue = (_amountCents * 10) + int.parse(digit);
  if (newValue > 999999999) return; // 99,999,999.99 max
  
  setState(() {
    _amountCents = newValue;
    _updateDisplay();
  });
}

void _backspace() {
  setState(() {
    _amountCents = _amountCents ~/ 10;
    _updateDisplay();
  });
}

void _updateDisplay() {
  final dollars = _amountCents / 100;
  _amountDisplay = dollars.toStringAsFixed(2);
}
```

### Payment Validation

**Validation Chain:**
1. **Balance Check**: `if (currentBalance <= 0) → Show "No balance" error`
2. **Sufficient Balance**: `if (amount > currentBalance) → Show dialog, offer adjustment`
3. **Invoice Limit**: `if (amount > invoiceUnpaidAmount) → Show dialog, offer adjustment`
4. **Process Payment**: Call API and refresh data

**Validation Flow:**
```dart
Future<void> _processPayment(Invoice invoice, double amount) async {
  // Check 1: Balance available?
  if (currentBalance <= 0) {
    showSnackBar('No balance');
    return;
  }
  
  // Check 2: Exceeds balance?
  if (amount > currentBalance) {
    bool confirmed = await showAdjustmentDialog(
      'Insufficient Balance',
      'Adjust to available balance?',
      currentBalance,
    );
    if (!confirmed) return;
    amount = currentBalance;
  }
  
  // Check 3: Exceeds invoice?
  if (amount > invoiceUnpaidAmount) {
    bool confirmed = await showAdjustmentDialog(
      'Payment Exceeds Invoice',
      'Adjust to invoice amount?',
      invoiceUnpaidAmount,
    );
    if (!confirmed) return;
    amount = invoiceUnpaidAmount;
  }
  
  // Process payment
  await CardService.recordInvoicePayment(invoice.id, amount: amount);
  
  // Refresh all data
  await _refreshAllData();
}
```

**Dialog Examples:**

**Insufficient Balance Dialog:**
```
┌─────────────────────────────────┐
│ Insufficient Balance             │
├─────────────────────────────────┤
│                                 │
│ Your available balance is        │
│ lower than the payment amount.   │
│                                 │
│ Available: $1,000.00             │
│ Payment: $1,500.00               │
│                                 │
│ Adjust to available balance?     │
│                                 │
│ [Cancel]  [Adjust to $1,000]     │
└─────────────────────────────────┘
```

**Payment Exceeds Invoice Dialog:**
```
┌─────────────────────────────────┐
│ Payment Exceeds Invoice          │
├─────────────────────────────────┤
│                                 │
│ Payment amount is greater than   │
│ the invoice balance.             │
│                                 │
│ Invoice Balance: $500.00          │
│ Payment: $750.00                 │
│                                 │
│ Adjust to invoice amount?        │
│                                 │
│ [Cancel]  [Adjust to $500]       │
└─────────────────────────────────┘
```

### Payment Modal
```
┌─────────────────────────────────┐
│ Invoice Payment                  │
│                                 │
│ Invoice: OCT25                  │
│ Amount Due: $1,500.00           │
│                                 │
│ ┌───────────────────────────┐  │
│ │    $125.50                │  │ ← Amount input
│ └───────────────────────────┘  │
│                                 │
│ [1] [2] [3]                     │
│ [4] [5] [6]                     │
│ [7] [8] [9]                     │
│ [0] [←] [Pay Full]              │
│                                 │
│ ┌─────────────────────────────┐ │
│ │    [Pay Now]                │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Post-Payment
**On Success:**
1. Show success snackbar
2. Close payment modal
3. Refresh:
   - Customer balance
   - All transactions
   - Invoice list
4. Update UI with new amounts

**On Error:**
1. Show error snackbar with message
2. Keep payment modal open
3. Allow retry

---

## 🔄 Data Refresh

### Pull-to-Refresh
Swipe down to reload all data.

**Functionality:**
- Smooth refresh indicator animation
- Loads all data simultaneously
- Updates UI when complete
- Shows success/error message

**Data Refreshed:**
- Customer profile & balance
- All transactions (resets pagination)
- Credit cards
- Unpaid invoices (all months)
- Paid invoices (all months)

**Implementation:**
```dart
RefreshIndicator(
  onRefresh: () async {
    await _refreshAllData();
  },
  child: ListView(...),
)
```

### Manual Reload (Reload Button)

**Main Card Reload Button:**
- Reloads ALL data in app
- Shows success snackbar
- Provides user feedback

**Transaction Panel Reload Button:**
- Reloads transactions only
- Resets pagination cursor
- Loads from beginning

**Implementation:**
```dart
GestureDetector(
  onTap: () async {
    await _refreshAllData();
  },
  child: Container(
    // Button styling
  ),
)
```

---

## 🎨 UI Features

### Responsive Design
- Mobile (< 600px): Full-width, stacked layout
- Tablet (600-900px): Adjusted padding
- Desktop (> 900px): Optimized spacing

### Animations
- Tab transitions
- Loading indicators
- Refresh animations
- Modal slide-up
- Smooth scrolling

### Accessibility
- Large touch targets (48px minimum)
- Clear contrast ratios
- Semantic HTML/widgets
- Readable fonts
- Error messages clear and helpful

---

**All features thoroughly tested and production-ready!** ✅

