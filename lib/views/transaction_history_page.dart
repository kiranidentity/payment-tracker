import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';



class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showTip = true; // Temporary state, later could persist in Hive

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background, 
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All Data',
            onPressed: () {
               showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Data?'),
                  content: const Text('This will delete all transactions and cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Provider.of<TransactionViewModel>(context, listen: false).clearAll();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Consumer<TransactionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.transactions.isEmpty) {
             return const Center(child: Text('No transactions found for this month'));
          }

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
            
            return amountMatch || name.contains(query) || desc.contains(query);
          }).toList();

          return Column(
            children: [
              _buildMonthSelector(viewModel),
              
              if (_showTip)
                Container(
                  margin: const EdgeInsets.all(8.0),
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
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by Amount (e.g., 1500) or Name',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
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
                                : 'No transactions in ${DateFormat('MMMM').format(DateTime(viewModel.selectedYear, viewModel.selectedMonth))}',
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
                                "Try checking a different month.",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final tx = filteredTransactions[index];
                    final otherParty = tx.isCredit ? tx.sender : tx.receiver;

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tx.isCredit ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: tx.isCredit ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),

                      title: Text(
                        otherParty,
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                            if (tx.entityId != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.link, size: 12, color: Colors.indigo),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Mapped to: ${viewModel.getEntityName(tx.entityId)}",
                                       style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold),
                                    ),
                                    if (tx.mappedAmount != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(4),
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
                            '${tx.isCredit ? "+" : "-"} ₹${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tx.isCredit ? Colors.green : Colors.red,
                            ),
                          ),
                          PopupMenuButton<String>(

                            itemBuilder: (context) => [
                              if (tx.entityId == null)
                                const PopupMenuItem(
                                  value: 'create_student',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_add, size: 20),
                                      SizedBox(width: 8),
                                      Text('Create Student'),
                                    ],
                                  ),
                                ),
                              if (tx.entityId != null)
                                const PopupMenuItem(
                                  value: 'unmap',
                                  child: Row(
                                    children: [
                                      Icon(Icons.link_off, size: 20, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Unmap / Not Fee'),
                                    ],
                                  ),
                                ),
                              if (tx.entityId != null)
                                const PopupMenuItem(
                                  value: 'edit_fee',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Edit Fee Amount'),
                                    ],
                                  ),
                                ),
                            ],
                            onSelected: (value) {
                              if (value == 'create_student') {
                                _showCreateStudentDialog(context, viewModel, otherParty);
                              } else if (value == 'unmap') {
                                viewModel.unmapTransaction(tx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaction unmapped')),
                                );
                              } else if (value == 'edit_fee') {
                                _showEditFeeDialog(context, viewModel, tx);
                              }
                            },
                          ),
                        ],
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

  void _showCreateStudentDialog(BuildContext context, TransactionViewModel viewModel, String senderName) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

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
            const Text('Monthly Fee (Optional)'),
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
                // 1. Create Student
                await viewModel.addEntity(
                  nameController.text, 
                  limit: double.tryParse(amountController.text)
                );
                
                // 2. Get the new Entity ID (it was just added, so it's the last one? 
                //    Better to find it by name or ensure addEntity returns it.
                //    For now, let's find by name as names should be unique enough for this user context,
                //    or just refactor addEntity. Refactoring is safer.)
                
                // Converting addEntity to return ID would be best, but for quick fix:
                // Let's find the entity we just created.
                final newEntity = viewModel.entities.firstWhere((e) => e.name == nameController.text);
                
                // 3. Map the sender
                await viewModel.mapSenderToEntity(senderName, newEntity.id);
                
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

  Widget _buildMonthSelector(TransactionViewModel viewModel) {
    // ... existing month selector code ...
    final date = DateTime(viewModel.selectedYear, viewModel.selectedMonth);
    return Container(
      // ...
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: viewModel.canGoPrevious ? viewModel.previousMonth : null,
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              disabledBackgroundColor: Colors.grey.shade50, // Lighter when disabled
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(date),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: viewModel.canGoNext ? viewModel.nextMonth : null,
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              disabledBackgroundColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
