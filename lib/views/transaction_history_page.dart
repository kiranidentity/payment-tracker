import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import 'widgets/unified_header.dart';
// import 'widgets/global_app_bar.dart'; // Removed for immersive look
import 'widgets/month_navigation_header.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showTip = true; 

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      // No AppBar -> Immersive Header
      body: Consumer<TransactionViewModel>(
        builder: (context, viewModel, child) {
          
          // Filter Logic
          final filteredTransactions = viewModel.transactions.where((tx) {
            final query = _searchQuery.toLowerCase();
            if (query.isEmpty) return true;
            
            final name = (tx.isCredit ? tx.sender : tx.receiver).toLowerCase();
            final desc = tx.description.toLowerCase();
            
            bool amountMatch = false;
            final searchNum = double.tryParse(query);
            if (searchNum != null) {
              amountMatch = (tx.amount - searchNum).abs() < 0.01;
            }

            return name.contains(query) || desc.contains(query) || amountMatch;
          }).toList();

          return Column(
            children: [
              // --- PREMIUM GRADIENT HEADER (Matches Dashboard) ---
              _buildGradientHeader(context, viewModel),
              
              if (_showTip)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                       const Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                       const SizedBox(width: 8),
                       const Expanded(
                         child: Text(
                           "Tip: Tap the 3-dot menu on any transaction to Unmap it or Edit the fee amount.",
                           style: TextStyle(fontSize: 12, color: Colors.brown),
                         ),
                       ),
                       IconButton(
                         icon: const Icon(Icons.close, size: 16, color: Colors.brown),
                         onPressed: () {
                           setState(() {
                             _showTip = false;
                           });
                         },
                       )
                    ],
                  ),
                ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by Amount or Name',
                    hintText: 'e.g. 1500 or Swiggy',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              Expanded(
                child: filteredTransactions.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.calendar_today_outlined,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? 'No results found for "$_searchQuery"'
                                : (viewModel.selectedMonth == DateTime.now().month && viewModel.selectedYear == DateTime.now().year)
                                    ? "No transactions uploaded for the current month."
                                    : 'No transactions in ${DateFormat('MMMM').format(DateTime(viewModel.selectedYear, viewModel.selectedMonth))}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_searchQuery.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                (viewModel.selectedMonth == DateTime.now().month && viewModel.selectedYear == DateTime.now().year)
                                    ? "Did you upload a statement for this month?"
                                    : "Try checking a different month.",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final tx = filteredTransactions[index];
                    final otherParty = tx.isCredit ? tx.cleanSender : tx.cleanReceiver;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            otherParty.isNotEmpty ? otherParty[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                          ),
                        ),

                        title: Text(
                          otherParty,
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${DateFormat('dd MMM, hh:mm a').format(tx.date)}\n${tx.description}",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                              if (tx.entityId != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.link, size: 12, color: AppTheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Mapped to: ${viewModel.getEntityName(tx.entityId)}",
                                         style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                      ),
                                      if (tx.mappedAmount != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.orange.shade200, width: 0.5),
                                          ),
                                          child: Text(
                                            "Fee: ₹${tx.mappedAmount!.toStringAsFixed(0)}",
                                            style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      ]
                                    ],
                                  ),
                                )
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "₹${tx.amount.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: tx.isCredit ? const Color(0xFF166534) : const Color(0xFF1E293B),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                              onSelected: (value) async {
                                if (value == 'map_to_student') {
                                  _showCreateStudentDialog(context, viewModel, tx.isCredit ? tx.sender : tx.receiver, tx.amount);
                                } else if (value == 'unmap') {
                                   await viewModel.unmapTransaction(tx);
                                   if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction Unmapped")));
                                   }
                                } else if (value == 'edit_fee') {
                                   _showEditFeeDialog(context, viewModel, tx);
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  if (tx.entityId == null && tx.isCredit)
                                    const PopupMenuItem<String>(
                                      value: 'map_to_student',
                                      child: Row(children: [Icon(Icons.person_add, size: 18), SizedBox(width: 8), Text('Create Client')]),
                                    ),
                                  
                                  if (tx.entityId != null) ...[
                                     const PopupMenuItem<String>(
                                      value: 'unmap',
                                      child: Row(children: [Icon(Icons.link_off, size: 18), SizedBox(width: 8), Text('Unmap / Not Fee')]),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'edit_fee',
                                      child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit Fee Amount')]),
                                    ),
                                  ]
                                ];
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context, TransactionViewModel viewModel) {
    // Standardize Header
    return UnifiedGradientHeader(
      title: 'Transaction History',
      subtitle: '${viewModel.transactions.length} transactions total',
      canGoBack: true,
      useSafePadding: true, // IMPORTANT: Immersive status bar
      trailing: IconButton( // Delete Action
        icon: const Icon(Icons.delete_forever, color: Colors.white70),
        tooltip: 'Clear All Data',
        onPressed: () {
           showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Clear All Data?'),
              content: const Text('This will delete all transactions and mappings from the database. This action cannot be undone.'),
              actions: [
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                TextButton(
                  child: const Text('Delete All', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    await viewModel.clearAllData();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
           );
        },
      ),
      bottomContent: MonthNavigationHeader(
        currentDate: DateTime(viewModel.selectedYear, viewModel.selectedMonth),
        canGoPrevious: viewModel.canGoPrevious,
        canGoNext: viewModel.canGoNext,
        onPrevious: viewModel.previousMonth,
        onNext: viewModel.nextMonth,
      ),
    );
  }


  void _showCreateStudentDialog(BuildContext context, TransactionViewModel viewModel, String senderName, double transactionAmount) {
    final nameController = TextEditingController();
    final amountController = TextEditingController(text: transactionAmount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Student from Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sender: $senderName', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Student Name'),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'e.g., Student Rahul',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Monthly Fee'),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 1500',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will create the student and automatically map "$senderName" to them.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await viewModel.addEntity(
                  nameController.text, 
                  limit: double.tryParse(amountController.text)
                );
                
                final newEntity = viewModel.entities.firstWhere((e) => e.name == nameController.text);
                
                await viewModel.mapSenderToEntity(senderName, newEntity.id);
                
                double? limit = double.tryParse(amountController.text);
                if (limit != null && limit > 0) {
                  await viewModel.addStrictAutoMapRule(limit, senderName, newEntity.id);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created "${nameController.text}" and mapped "$senderName"')),
                  );
                }
              }
            },
            child: const Text('Create & Map'),
          ),
        ],
      ),
    );
  }

  void _showEditFeeDialog(BuildContext context, TransactionViewModel viewModel, TransactionModel tx) {
    final amountController = TextEditingController(text: (tx.mappedAmount ?? tx.amount).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Fee Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Received: ₹${tx.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('How much is the actual fee?'),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Example: If received 5000 but fee is 1500, enter 1500.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAmount = double.tryParse(amountController.text);
              if (newAmount != null) {
                if (newAmount > tx.amount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fee cannot be greater than total amount')),
                  );
                  return;
                }
                await viewModel.updateTransactionSplit(tx, newAmount);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
