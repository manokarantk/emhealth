import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> with SingleTickerProviderStateMixin {
  // Separate data for each tab
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> creditTransactions = [];
  List<Map<String, dynamic>> debitTransactions = [];
  
  // Loading states for each tab
  bool isLoadingAll = true;
  bool isLoadingCredit = true;
  bool isLoadingDebit = true;
  
  // Error states for each tab
  String? errorMessageAll;
  String? errorMessageCredit;
  String? errorMessageDebit;
  
  Map<String, dynamic>? walletData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load data for the first tab (All) initially
    _loadWalletHistory('all');
    
    // Listen for tab changes to call API on every switch
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    // Call API for the selected tab on every switch
    print('🔄 Tab switched to index: $index');
    switch (index) {
      case 0: // All tab
        print('🔄 Loading All transactions...');
        _loadWalletHistory('all');
        break;
      case 1: // Credit tab
        print('🔄 Loading Credit transactions...');
        _loadWalletHistory('CREDIT');
        break;
      case 2: // Debit tab
        print('🔄 Loading Debit transactions...');
        _loadWalletHistory('DEBIT');
        break;
    }
  }

  Future<void> _loadWalletHistory(String type) async {
    print('🔄 _loadWalletHistory called with type: $type');
    try {
      // Set loading state for the specific type
      setState(() {
        switch (type) {
          case 'all':
            isLoadingAll = true;
            errorMessageAll = null;
            break;
          case 'CREDIT':
            isLoadingCredit = true;
            errorMessageCredit = null;
            break;
          case 'DEBIT':
            isLoadingDebit = true;
            errorMessageDebit = null;
            break;
        }
      });

      final apiService = ApiService();
      final result = await apiService.getMobileWallet(
        page: 1, 
        limit: 50,
        type: type == 'all' ? null : type,
      );

      if (result['success'] && mounted) {
        final data = result['data'];
        final transactionsList = List<Map<String, dynamic>>.from(data['transactions']['data'] ?? []);
        
        setState(() {
          // Store wallet data from the first successful call
          if (walletData == null) {
            walletData = data;
          }
          
          // Update the appropriate transactions list
          switch (type) {
            case 'all':
              allTransactions = transactionsList;
              isLoadingAll = false;
              break;
            case 'CREDIT':
              creditTransactions = transactionsList;
              isLoadingCredit = false;
              break;
            case 'DEBIT':
              debitTransactions = transactionsList;
              isLoadingDebit = false;
              break;
          }
        });
      } else {
        setState(() {
          switch (type) {
            case 'all':
              errorMessageAll = result['message'] ?? 'Failed to load wallet history';
              isLoadingAll = false;
              break;
            case 'CREDIT':
              errorMessageCredit = result['message'] ?? 'Failed to load credit transactions';
              isLoadingCredit = false;
              break;
            case 'DEBIT':
              errorMessageDebit = result['message'] ?? 'Failed to load debit transactions';
              isLoadingDebit = false;
              break;
          }
        });
      }
    } catch (e) {
      setState(() {
        switch (type) {
          case 'all':
            errorMessageAll = 'Network error occurred';
            isLoadingAll = false;
            break;
          case 'CREDIT':
            errorMessageCredit = 'Network error occurred';
            isLoadingCredit = false;
            break;
          case 'DEBIT':
            errorMessageDebit = 'Network error occurred';
            isLoadingDebit = false;
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        title: const Text(
          'Wallet History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar Section
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primaryBlue,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.primaryBlue,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Credit'),
                Tab(text: 'Debit'),
              ],
            ),
          ),
          // Error Messages for each tab
          if (_getCurrentErrorMessage() != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getCurrentErrorMessage()!,
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _retryCurrentTab(),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Transactions List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Transactions Tab
                _buildTransactionsTab('all'),
                // Credit Transactions Tab
                _buildTransactionsTab('CREDIT'),
                // Debit Transactions Tab
                _buildTransactionsTab('DEBIT'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(String type) {
    // Get the appropriate data and loading state
    List<Map<String, dynamic>> transactions;
    bool isLoading;
    String? errorMessage;
    
    switch (type) {
      case 'all':
        transactions = allTransactions;
        isLoading = isLoadingAll;
        errorMessage = errorMessageAll;
        break;
      case 'CREDIT':
        transactions = creditTransactions;
        isLoading = isLoadingCredit;
        errorMessage = errorMessageCredit;
        break;
      case 'DEBIT':
        transactions = debitTransactions;
        isLoading = isLoadingDebit;
        errorMessage = errorMessageDebit;
        break;
      default:
        transactions = [];
        isLoading = false;
        errorMessage = null;
    }

    // Show loading state
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading transactions...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Transactions',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadWalletHistory(type),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryBlue,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    // Show transactions list
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    // Map API transaction data to UI fields with null safety
    final transactionType = (transaction['transaction_type'] ?? transaction['type'] ?? 'debit')?.toString() ?? 'debit';
    final isCredit = transactionType.toLowerCase() == 'credit';
    
    // Handle amount as either string or number with null safety
    final amountRaw = transaction['amount'] ?? transaction['transaction_amount'] ?? 0.0;
    final amount = amountRaw is String 
        ? double.tryParse(amountRaw) ?? 0.0 
        : (amountRaw is num ? amountRaw.toDouble() : 0.0);
    final amountText = isCredit ? '+₹${amount.toStringAsFixed(2)}' : '-₹${amount.toStringAsFixed(2)}';
    
    // Format date and time with null safety
    final createdAt = transaction['created_at'] ?? transaction['date'];
    String dateTimeText = '';
    if (createdAt != null && createdAt.toString().isNotEmpty) {
      try {
        final dateTime = DateTime.parse(createdAt.toString());
        dateTimeText = '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        dateTimeText = '${transaction['date']?.toString() ?? ''} at ${transaction['time']?.toString() ?? ''}';
      }
    } else {
      dateTimeText = '${transaction['date']?.toString() ?? ''} at ${transaction['time']?.toString() ?? ''}';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (transaction['description'] ?? transaction['transaction_description'] ?? 'Transaction')?.toString() ?? 'Transaction',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateTimeText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transactionType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        _getMethodIcon((transaction['method'] ?? transaction['payment_method'] ?? 'Wallet')?.toString() ?? 'Wallet'),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          (transaction['method'] ?? transaction['payment_method'] ?? 'Wallet')?.toString() ?? 'Wallet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'ID: ${(transaction['id'] ?? transaction['transaction_id'] ?? 'N/A')?.toString() ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Transactions Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMethodIcon(String? method) {
    final methodStr = method?.toLowerCase() ?? '';
    switch (methodStr) {
      case 'upi':
        return Icons.phone_android;
      case 'net banking':
        return Icons.account_balance;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'bonus':
        return Icons.card_giftcard;
      default:
        return Icons.payment;
    }
  }

  String? _getCurrentErrorMessage() {
    switch (_tabController.index) {
      case 0:
        return errorMessageAll;
      case 1:
        return errorMessageCredit;
      case 2:
        return errorMessageDebit;
      default:
        return null;
    }
  }

  void _retryCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _loadWalletHistory('all');
        break;
      case 1:
        _loadWalletHistory('CREDIT');
        break;
      case 2:
        _loadWalletHistory('DEBIT');
        break;
    }
  }
} 