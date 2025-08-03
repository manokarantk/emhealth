import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String? errorMessage;
  String _selectedFilter = 'All';
  Map<String, dynamic>? walletData;

  @override
  void initState() {
    super.initState();
    _loadWalletHistory();
  }

  Future<void> _loadWalletHistory() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final apiService = ApiService();
      final result = await apiService.getMobileWallet(page: 1, limit: 50);

      if (result['success'] && mounted) {
        final data = result['data'];
        final transactionsList = List<Map<String, dynamic>>.from(data['transactions']['data'] ?? []);
        
        setState(() {
          walletData = data;
          transactions = transactionsList;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load wallet history';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error occurred';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _selectedFilter == 'All' 
        ? transactions 
        : transactions.where((t) => t['type'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Filter: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Credit'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Debit'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Error Message
          if (errorMessage != null)
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
                      errorMessage!,
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadWalletHistory,
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
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading wallet history...'),
                      ],
                    ),
                  )
                : filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Transactions Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
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
} 