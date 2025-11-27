import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../models/credit_card_model.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';
import '../services/customer_service.dart';
import '../services/transaction_service.dart';
import '../services/card_service.dart';
import '../theme/app_colors.dart';
import '../widgets/space_background.dart';
import '../widgets/transaction_item.dart';
import '../config/app_config.dart';

class HomeScreen extends StatefulWidget {
  final Customer initialCustomer;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.initialCustomer,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Customer _customer;
  late ScrollController _transactionsScrollController;
  
  // Transactions pagination
  List<Transaction> _transactions = [];
  String? _transactionsCursor;
  bool _isLoadingMoreTransactions = false;
  bool _hasMoreTransactions = true;
  bool _isInitialLoadingTransactions = true;
  
  // Cards and Invoices
  List<CreditCard> _cards = [];
  List<Invoice> _invoices = [];
  List<Invoice> _unpaidInvoices = [];
  CreditCard? _selectedCard;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoadingInvoices = false;
  bool _isLoadingUnpaidInvoices = false;
  bool _isLoadingInvoiceItems = false;
  List<InvoiceItem> _currentInvoiceItems = [];
  
  // UI State
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _customer = widget.initialCustomer;
    _transactionsScrollController = ScrollController();
    _transactionsScrollController.addListener(_onTransactionsScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _transactionsScrollController.dispose();
    super.dispose();
  }

  void _onTransactionsScroll() {
    if (!_transactionsScrollController.hasClients) return;
    
    final maxScroll = _transactionsScrollController.position.maxScrollExtent;
    final currentScroll = _transactionsScrollController.position.pixels;
    
    if (currentScroll >= maxScroll - 300) {
      if (!_isLoadingMoreTransactions && _hasMoreTransactions && _transactionsCursor != null) {
        _loadMoreTransactions();
      }
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadInitialTransactions(),
      _loadCards(),
      _refreshCustomerData(),
    ]);
  }

  Future<void> _refreshCustomerData() async {
    try {
      final customerId = _customer.customerId.isEmpty 
          ? AppConfig.defaultCustomerId 
          : _customer.customerId;
      
      final customer = await CustomerService.getCustomerDetails(
        customerId,
        AppConfig.defaultBankId,
      );
      if (mounted) {
        setState(() => _customer = customer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing customer: $e')),
        );
      }
    }
  }

  Future<void> _loadInitialTransactions() async {
    // Allow reload even if already loading once
    setState(() => _isInitialLoadingTransactions = true);
    // Reset cursor when reloading
    _transactionsCursor = null;
    _hasMoreTransactions = true;
    
    try {
      final customerId = _customer.customerId.isEmpty 
          ? AppConfig.defaultCustomerId 
          : _customer.customerId;
      
      final result = await TransactionService.getTransactionsPaginated(
        customerId: customerId,
        limit: 15,
      );

      if (mounted) {
        final transactions = result['transactions'] as List<Transaction>;
        setState(() {
          _transactions = List<Transaction>.from(transactions);
          _transactionsCursor = result['next_cursor'] as String?;
          final hasMore = result['has_more'] as bool? ?? false;
          _hasMoreTransactions = hasMore && _transactionsCursor != null;
          _isInitialLoadingTransactions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoadingTransactions = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMoreTransactions) return;
    if (!_hasMoreTransactions) return;
    if (_transactionsCursor == null) return;

    setState(() => _isLoadingMoreTransactions = true);

    try {
      final customerId = _customer.customerId.isEmpty 
          ? AppConfig.defaultCustomerId 
          : _customer.customerId;
      
      final result = await TransactionService.getTransactionsPaginated(
        customerId: customerId,
        cursor: _transactionsCursor,
        limit: 15,
      );

      if (mounted) {
        final newTransactions = result['transactions'] as List<Transaction>;
        
        if (newTransactions.isEmpty) {
          setState(() {
            _hasMoreTransactions = false;
            _transactionsCursor = null;
            _isLoadingMoreTransactions = false;
          });
        } else {
          setState(() {
            _transactions.addAll(newTransactions);
            _transactionsCursor = result['next_cursor'] as String?;
            final hasMore = result['has_more'] as bool? ?? false;
            _hasMoreTransactions = hasMore && _transactionsCursor != null;
            _isLoadingMoreTransactions = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMoreTransactions = false);
      }
    }
  }

  Future<void> _loadCards() async {
    try {
      final customerId = _customer.customerId.isEmpty 
          ? AppConfig.defaultCustomerId 
          : _customer.customerId;
      
      final cards = await CardService.getCustomerCards(customerId);
      
      if (mounted) {
        setState(() {
          _cards = cards;
          if (cards.isNotEmpty && _selectedCard == null) {
            _selectedCard = cards.first;
            _loadUnpaidInvoicesForCard(_selectedCard!);
            _loadInvoicesForCard(_selectedCard!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cards: $e')),
        );
      }
    }
  }

  Future<void> _loadUnpaidInvoicesForCard(CreditCard card) async {
    if (_isLoadingUnpaidInvoices) return;
    
    setState(() => _isLoadingUnpaidInvoices = true);
    
    try {
      final List<Invoice> allInvoices = [];
      final now = DateTime.now();
      
      // Load invoices from the last 12 months to find all unpaid invoices
      for (int i = 0; i < 12; i++) {
        final targetMonth = now.month - i;
        final targetYear = targetMonth <= 0 ? now.year - 1 : now.year;
        final adjustedMonth = targetMonth <= 0 ? 12 + targetMonth : targetMonth;

        final dateRange = CardService.getMonthDateRange(targetYear, adjustedMonth);

        try {
          final result = await CardService.getCardInvoices(
            card.cardId,
            fromDate: dateRange['from_date'],
            toDate: dateRange['to_date'],
            limit: 20,
          );

          final invoices = result['invoices'] as List<Invoice>;
          allInvoices.addAll(invoices);
        } catch (e) {
          continue;
        }
      }

      // Filter unpaid invoices
      final unpaidInvoices = allInvoices.where((inv) => !inv.isFullyPaid).toList();
      
      // Sort by due date (oldest first)
      unpaidInvoices.sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      if (mounted) {
        setState(() {
          _unpaidInvoices = unpaidInvoices;
          _isLoadingUnpaidInvoices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unpaidInvoices = [];
          _isLoadingUnpaidInvoices = false;
        });
      }
    }
  }

  Future<void> _loadInvoicesForCard(CreditCard card) async {
    if (_isLoadingInvoices) return;
    
    setState(() => _isLoadingInvoices = true);
    
    try {
      final dateRange = CardService.getMonthDateRange(
        _selectedMonth.year,
        _selectedMonth.month,
      );

      final result = await CardService.getCardInvoices(
        card.cardId,
        fromDate: dateRange['from_date'],
        toDate: dateRange['to_date'],
        limit: 20,
      );

      if (mounted) {
        final invoices = result['invoices'] as List<Invoice>;
        setState(() {
          _invoices = invoices;
          _isLoadingInvoices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _invoices = [];
          _isLoadingInvoices = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    try {
      await Future.wait([
        _refreshCustomerData(),
        _loadInitialTransactions(),
        _loadCards(),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data refreshed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing: $e')),
        );
      }
    }
  }

  Future<void> _refreshAllData() async {
    try {
      // Refresh customer data
      await _refreshCustomerData();
      
      // Refresh transactions
      await _loadInitialTransactions();
      
      // Reload cards
      await _loadCards();
      
      // If a card is selected, refresh its invoices
      if (_selectedCard != null) {
        await Future.wait([
          _loadUnpaidInvoicesForCard(_selectedCard!),
          _loadInvoicesForCard(_selectedCard!),
        ]);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data refreshed'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              // Stroke effect - multiple layers for thicker stroke
                              Text(
                                _customer.alias,
                                style: GoogleFonts.jersey25(
                                  color: const Color(0xFF4338CA),
                                  fontSize: 42,
                                  letterSpacing: 1.2,
                                  shadows: const [
                                    Shadow(
                                      offset: Offset(2, 0),
                                      color: Color(0xFF4338CA),
                                    ),
                                    Shadow(
                                      offset: Offset(-2, 0),
                                      color: Color(0xFF4338CA),
                                    ),
                                    Shadow(
                                      offset: Offset(0, 2),
                                      color: Color(0xFF4338CA),
                                    ),
                                    Shadow(
                                      offset: Offset(0, -2),
                                      color: Color(0xFF4338CA),
                                    ),
                                  ],
                                ),
                              ),
                              // Main text (foreground layer)
                              Text(
                                _customer.alias,
                                style: GoogleFonts.jersey25(
                                  color: Colors.white,
                                  fontSize: 42,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: widget.onLogout,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Balance Card
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Balance Card with Avatar
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0D9488), // Teal
                                  const Color(0xFF4338CA), // Indigo
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left side: Avatar, Level Badge, Balance
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Avatar
                                          ClipOval(
                                            child: Image.asset(
                                              'images/astrobank-logo-mini.png',
                                              width: 110,
                                              height: 110,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          // Level Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.shield_outlined,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Level 1 - Star Saver',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Balance Label and Amount
                                          Text(
                                            'Current Balance',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.8),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${_customer.balance}',
                                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Spendable Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Spendable',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '\$${_selectedCard != null ? _selectedCard!.availableLimit : (_cards.isNotEmpty ? _cards.first.availableLimit : '0.00')}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Right side: Card Information
                                    if (_cards.isNotEmpty) ...[
                                      const SizedBox(width: 16),
                                      Container(
                                        width: 160,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Icon(
                                                  Icons.credit_card,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: _getCardStatusColor((_selectedCard ?? _cards.first).status),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    (_selectedCard ?? _cards.first).status,
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              (_selectedCard ?? _cards.first).maskedCardNumber,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Exp: ${(_selectedCard ?? _cards.first).expiryMonth}/${(_selectedCard ?? _cards.first).expiryYear} • ${(_selectedCard ?? _cards.first).typeDisplay}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontSize: 10,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Available: \$${(_selectedCard ?? _cards.first).availableLimit}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.white.withValues(alpha: 0.7),
                                                fontSize: 9,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                // Reload and Settings icons in bottom right
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Reload button
                                      GestureDetector(
                                        onTap: () async {
                                          await _refreshAllData();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.refresh_outlined,
                                            color: Colors.white.withValues(alpha: 0.9),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      // Settings button
                                      GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.settings_outlined,
                                            color: Colors.white.withValues(alpha: 0.9),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tab Content
                          if (_selectedTab == 0) _buildWalletPanel(),
                          if (_selectedTab == 1) _buildActivityPanel(),
                          if (_selectedTab == 2) _buildGoalsPanel(),
                          if (_selectedTab == 3) _buildCardsPanel(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bottom Navigation Bar
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavTab(0, 'My Wallet', Icons.payments_outlined),
              _buildNavTab(1, 'Activity', Icons.rocket_launch_outlined),
              _buildNavTab(2, 'Goals', Icons.flag_outlined),
              _buildNavTab(3, 'Invoices', Icons.credit_card),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'BLOCKED':
        return Colors.red;
      case 'INACTIVE':
      default:
        return Colors.grey;
    }
  }

  Widget _buildNavTab(int index, String label, IconData icon) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryPurple : AppColors.textGray,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? AppColors.primaryPurple : AppColors.textGray,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            if (isActive)
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletPanel() {
    return _buildOverviewPanel();
  }

  Widget _buildActivityPanel() {
    return _buildTransactionsPanel();
  }

  Widget _buildGoalsPanel() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: AppColors.textLightGray,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No goals yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textLightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsPanel() {
    if (_cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.credit_card_off_outlined,
                  color: AppColors.textLightGray,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'No cards',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLightGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final monthInvoices = _invoices.where((inv) {
      try {
        final invDate = DateTime.parse(inv.closingDate);
        return invDate.year == _selectedMonth.year && invDate.month == _selectedMonth.month;
      } catch (e) {
        return false;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unpaid Invoices Section - Always visible
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Unpaid Invoices',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isLoadingUnpaidInvoices)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingUnpaidInvoices)
          const SizedBox(height: 40)
        else if (_unpaidInvoices.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No unpaid invoices',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          )
        else
          ..._unpaidInvoices.map((invoice) => _buildInvoiceCard(invoice, isUnpaid: true)),
        
        // Month Selector and Invoices
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Month Selector
            GestureDetector(
              onTap: () => _showMonthPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getMonthYearLabel(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              'Invoices',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Invoices List
        if (_isLoadingInvoices)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            ),
          )
        else if (monthInvoices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No invoices for ${_getMonthYearLabel()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...monthInvoices.map((invoice) => _buildInvoiceCard(invoice)),
      ],
    );
  }

  Future<double> _calculateInvoiceInterest(String invoiceId) async {
    try {
      final result = await CardService.getInvoiceItems(invoiceId, limit: 100);
      final items = result['items'] as List<InvoiceItem>? ?? [];
      
      double totalInterest = 0;
      for (final item in items) {
        if (item.type.toLowerCase() == 'interest') {
          try {
            totalInterest += double.parse(item.amount);
          } catch (e) {
            continue;
          }
        }
      }
      
      return totalInterest;
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildInvoiceCard(Invoice invoice, {bool isUnpaid = false}) {
    final isUnpaidInvoice = isUnpaid || !invoice.isFullyPaid;
    return FutureBuilder<double>(
      future: _calculateInvoiceInterest(invoice.id),
      builder: (context, snapshot) {
        final totalInterest = snapshot.data ?? 0.0;
        return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUnpaidInvoice 
              ? [
                  const Color(0xFF1E40AF).withValues(alpha: 0.5), // Deep space blue
                  const Color(0xFF0891B2).withValues(alpha: 0.4), // Cyan/teal
                ]
              : [
                  const Color(0xFF2A3F5F).withValues(alpha: 0.8), // Dark slate blue
                  const Color(0xFF1F2937).withValues(alpha: 0.75), // Darker gray-blue
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnpaidInvoice 
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnpaidInvoice 
                ? const Color(0xFF0891B2).withValues(alpha: 0.3) // Cyan shadow
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.monthAbbreviation,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (!isUnpaidInvoice)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PAID',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInvoiceRow('Due:', invoice.formattedDueDate, isUnpaidInvoice ? const Color(0xFFFF6B6B) : Colors.white70, fontSize: 12),
          const SizedBox(height: 4),
          _buildInvoiceRow('Total:', '\$${invoice.totalAmount}', Colors.white, fontSize: 12),
          const SizedBox(height: 4),
          if (totalInterest > 0) ...[
            _buildInvoiceRow('Interest:', '\$${totalInterest.toStringAsFixed(2)}', const Color(0xFFFFA500), fontSize: 12),
            const SizedBox(height: 4),
          ],
          _buildInvoiceRow('Paid:', '\$${invoice.paidAmount}', isUnpaidInvoice ? const Color(0xFFFF6B6B) : Colors.white70, fontSize: 12),
          const SizedBox(height: 4),
          _buildInvoiceRow('Unpaid:', '\$${invoice.unpaidAmount}', isUnpaidInvoice ? const Color(0xFFFF6B6B) : Colors.white70, fontSize: 12),
          if (invoice.fees != null && invoice.fees!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildInvoiceRow('Fees:', '\$${invoice.fees}', const Color(0xFFFFA500), fontSize: 12),
          ],
          const SizedBox(height: 12),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showInvoiceItems(invoice.id),
                  icon: Icon(Icons.receipt_long, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                  label: Text(
                    'View Items',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (isUnpaidInvoice) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handlePayInvoice(invoice),
                    icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                    label: const Text(
                      'Pay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(String label, String value, Color? valueColor, {double fontSize = 11}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: fontSize,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  String _getMonthYearLabel() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    int selectedYear = _selectedMonth.year;
    int selectedMonthIndex = _selectedMonth.month;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                'Select Month',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Year Selection
                    Text(
                      'Year',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left),
                          onPressed: () {
                            setDialogState(() {
                              selectedYear = (selectedYear - 1).clamp(2020, 2030);
                            });
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selectedYear.toString(),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right),
                          onPressed: () {
                            setDialogState(() {
                              selectedYear = (selectedYear + 1).clamp(2020, 2030);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Month Selection
                    Text(
                      'Month',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final isSelected = month == selectedMonthIndex;
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedMonthIndex = month;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primaryPurple 
                                  : AppColors.primaryPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected 
                                    ? AppColors.primaryPurple 
                                    : AppColors.primaryPurple.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                months[index],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isSelected ? Colors.white : AppColors.primaryPurple,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (selectedYear != _selectedMonth.year || selectedMonthIndex != _selectedMonth.month) {
                      setState(() {
                        _selectedMonth = DateTime(selectedYear, selectedMonthIndex);
                      });
                      if (_selectedCard != null) {
                        _loadInvoicesForCard(_selectedCard!);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                  ),
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadInvoiceItems(String invoiceId) async {
    if (_isLoadingInvoiceItems) return;
    
    setState(() {
      _isLoadingInvoiceItems = true;
      _currentInvoiceItems = [];
    });

    try {
      final result = await CardService.getInvoiceItems(
        invoiceId,
        limit: 50,
      );

      if (mounted) {
        final items = result['items'] as List<InvoiceItem>;
        setState(() {
          _currentInvoiceItems = items;
          _isLoadingInvoiceItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentInvoiceItems = [];
          _isLoadingInvoiceItems = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoice items: $e')),
        );
      }
    }
  }

  Future<void> _showInvoiceItems(String invoiceId) async {
    await _loadInvoiceItems(invoiceId);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E40AF).withValues(alpha: 0.95), // Deep space blue
              const Color(0xFF0891B2).withValues(alpha: 0.95), // Cyan/teal
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice Items',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoadingInvoiceItems
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _currentInvoiceItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No items found',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _currentInvoiceItems.length,
                          itemBuilder: (context, index) {
                            final item = _currentInvoiceItems[index];
                            return _buildInvoiceItemCard(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatInvoiceItemAmount(String amount, bool isDebit, bool isCredit) {
    try {
      // Parse the numeric value
      double amountValue = double.parse(amount);
      
      // Get absolute value for display
      final absoluteAmount = amountValue.abs().toStringAsFixed(2);
      
      // Format: Debits (negative) always show as -$XX.XX, Credits (positive) always show as +$XX.XX
      if (isDebit) {
        return '-\$${absoluteAmount}';
      } else if (isCredit) {
        return '+\$${absoluteAmount}';
      } else {
        // Zero amount
        return '\$${absoluteAmount}';
      }
    } catch (e) {
      // Fallback: remove any existing sign and format based on debit/credit
      final cleanAmount = amount.replaceFirst(RegExp(r'^[+-]'), '').trim();
      if (isDebit) {
        return '-\$${cleanAmount}';
      } else if (isCredit) {
        return '+\$${cleanAmount}';
      } else {
        return '\$${cleanAmount}';
      }
    }
  }

  Widget _buildInvoiceItemCard(InvoiceItem item) {
    // Parse the amount to determine if it's a debit (negative) or credit (positive)
    double amountValue;
    try {
      amountValue = double.parse(item.amount);
    } catch (e) {
      amountValue = 0.0;
    }
    
    final isDebit = amountValue < 0; // Debit = negative = money removed from account
    final isCredit = amountValue > 0; // Credit = positive = money added to account
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.formattedPostingDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatInvoiceItemAmount(item.amount, isDebit, isCredit),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDebit 
                  ? const Color(0xFFFF6B6B) // Red for debit (money removed)
                  : const Color(0xFF10B981), // Green for credit (money added)
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayInvoice(Invoice invoice) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentInputSheet(
        invoice: invoice,
        onPayment: (amount) async {
          Navigator.of(context).pop();
          await _processPayment(invoice, amount);
        },
      ),
    );
  }

  Future<void> _processPayment(Invoice invoice, double amount) async {
    if (!mounted) return;

    // Validation 0: Check if current balance is greater than 0
    final currentBalance = double.parse(_customer.balance);
    if (currentBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation 1: Check if amount exceeds current balance
    if (amount > currentBalance) {
      // Show alert and adjust to current balance
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Insufficient Balance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The payment amount (\$${amount.toStringAsFixed(2)}) exceeds your current balance (\$${currentBalance.toStringAsFixed(2)}).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The amount will be adjusted to your current balance: \$${currentBalance.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textGray),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
              ),
              child: const Text('Adjust & Pay'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) return;
      amount = currentBalance;
    }

    // Validation 2: Check if amount exceeds invoice unpaid amount
    final invoiceUnpaidAmount = double.parse(invoice.unpaidAmount);
    if (amount > invoiceUnpaidAmount) {
      // Show alert and adjust to invoice amount
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Payment Exceeds Invoice',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The payment amount (\$${amount.toStringAsFixed(2)}) exceeds the remaining invoice amount (\$${invoiceUnpaidAmount.toStringAsFixed(2)}).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The amount will be adjusted to: \$${invoiceUnpaidAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textGray),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
              ),
              child: const Text('Adjust & Pay'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) return;
      amount = invoiceUnpaidAmount;
    }

    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              'Processing payment...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final result = await CardService.recordInvoicePayment(
        invoice.id,
        amount: amount,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment of \$${amount.toStringAsFixed(2)} processed successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );

          // Refresh customer data (balance) and invoices
          await _refreshCustomerData();
          
          // Refresh invoices
          if (_selectedCard != null) {
            await Future.wait([
              _loadUnpaidInvoicesForCard(_selectedCard!),
              _loadInvoicesForCard(_selectedCard!),
            ]);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOverviewPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Name', _customer.name, Icons.person_outline),
          const Divider(color: AppColors.borderGray, height: 24),
          _buildInfoRow(context, 'Email', _customer.email, Icons.email_outlined),
          const Divider(color: AppColors.borderGray, height: 24),
          _buildInfoRow(
            context,
            'Member Since',
            '2025',
            Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsPanel() {
    if (_isInitialLoadingTransactions) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.textLightGray,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'No transactions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLightGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions (${_transactions.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  color: AppColors.primaryPurple,
                  onPressed: _isInitialLoadingTransactions 
                      ? null 
                      : () async {
                          await _loadInitialTransactions();
                        },
                  tooltip: 'Reload transactions',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGray),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              controller: _transactionsScrollController,
              shrinkWrap: true,
              itemCount: _transactions.length + (_isLoadingMoreTransactions ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _transactions.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryPurple,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }

                return TransactionItem(
                  transaction: _transactions[index],
                  isLast: index == _transactions.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryPurple,
          size: 20,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentInputSheet extends StatefulWidget {
  final Invoice invoice;
  final Function(double) onPayment;

  const _PaymentInputSheet({
    required this.invoice,
    required this.onPayment,
  });

  @override
  State<_PaymentInputSheet> createState() => _PaymentInputSheetState();
}

class _PaymentInputSheetState extends State<_PaymentInputSheet> {
  late double _amount;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amount = 0.0;
    _amountController = TextEditingController(text: '0.00');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    setState(() {
      // Store amount as integer cents internally (e.g., 12550 = $125.50)
      // Extract only digits from controller text
      final digitsOnly = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
      
      // Add new digit
      final newDigits = (digitsOnly + digit).replaceFirst(RegExp(r'^0+'), '');
      
      // Limit to 8 digits (max $999,999.99)
      final limitedDigits = newDigits.length > 8 
          ? newDigits.substring(newDigits.length - 8) 
          : (newDigits.isEmpty ? '0' : newDigits);
      
      // Convert to cents (store as integer)
      int cents = int.parse(limitedDigits);
      
      // Ensure at least 1 cent minimum
      if (cents == 0) {
        _amount = 0.0;
        _amountController.text = '0.00';
      } else {
        _amount = cents / 100.0;
        _amountController.text = _amount.toStringAsFixed(2);
      }
    });
  }

  void _backspace() {
    setState(() {
      // Extract only digits from controller text
      var digitsOnly = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
      
      // Remove last digit
      if (digitsOnly.length > 1) {
        digitsOnly = digitsOnly.substring(0, digitsOnly.length - 1);
      } else {
        digitsOnly = '0';
      }
      
      // Convert to cents and format
      int cents = int.parse(digitsOnly);
      _amount = cents / 100.0;
      _amountController.text = _amount.toStringAsFixed(2);
    });
  }

  void _setFullAmount() {
    setState(() {
      _amount = double.parse(widget.invoice.unpaidAmount);
      _amountController.text = _amount.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Text(
                'Pay Invoice',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Invoice: ${widget.invoice.monthAbbreviation}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 24),

              // Amount Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Amount to Pay',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_amountController.text}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Invoice Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Total Amount',
                      '\$${widget.invoice.totalAmount}',
                      Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Already Paid',
                      '\$${widget.invoice.paidAmount}',
                      Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Remaining',
                      '\$${widget.invoice.unpaidAmount}',
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Action Button - Pay Full
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _setFullAmount,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryPurple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, 
                        color: AppColors.primaryPurple,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pay Full Amount',
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Numeric Keypad
              Column(
                children: [
                  // Row 1: 1, 2, 3
                  Row(
                    children: [
                      _buildKeypadButton('1'),
                      const SizedBox(width: 8),
                      _buildKeypadButton('2'),
                      const SizedBox(width: 8),
                      _buildKeypadButton('3'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 2: 4, 5, 6
                  Row(
                    children: [
                      _buildKeypadButton('4'),
                      const SizedBox(width: 8),
                      _buildKeypadButton('5'),
                      const SizedBox(width: 8),
                      _buildKeypadButton('6'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 3: 7, 8, 9
                  Row(
                    children: [
                      _buildKeypadButton('7'),
                      const SizedBox(width: 8),
                      _buildKeypadButton('8'),
                      const SizedBox(width: 8),
                      _buildKeypadButton('9'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 4: 0, Empty Space, Backspace
                  Row(
                    children: [
                      Expanded(
                        child: _buildKeypadButton('0'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(), // Empty space where decimal was
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildBackspaceButton(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _amount > 0 
                          ? () => widget.onPayment(_amount)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Pay Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String label) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _addDigit(label),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _backspace,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Icon(
                  Icons.backspace_outlined,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, TextStyle? style) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: style?.copyWith(color: AppColors.textGray),
        ),
        Text(
          value,
          style: style?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
