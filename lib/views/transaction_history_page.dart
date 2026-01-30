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
      // Remove AppBar, we will build a custom header in the body
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
            
            return amountMatch || name.contains(query) || desc.contains(query);
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
                    final otherParty = tx.isCredit ? tx.sender : tx.receiver;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          )
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tx.isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), // Soft Green / Soft Red
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: tx.isCredit ? const Color(0xFF166534) : const Color(0xFF991B1B), // Dark Green / Dark Red
                            size: 20,
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
    final date = DateTime(viewModel.selectedYear, viewModel.selectedMonth);
    // Adaptive top padding
    final topPadding = MediaQuery.of(context).padding.top + 16;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AppBar-like Row
          Row(
            children: [
              IconButton( // Back Button
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Transaction History',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton( // Delete Action
                icon: const Icon(Icons.delete_forever, color: Colors.white70),
                tooltip: 'Clear All Data',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
          
          const SizedBox(height: 24),
          
          // Month Selector (White/Transparent Style on Dark BG)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: viewModel.canGoPrevious ? viewModel.previousMonth : null, 
                icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 28),
                tooltip: 'Previous Month',
              ),
              const SizedBox(width: 16),
              Text(
                DateFormat('MMMM yyyy').format(date),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: viewModel.canGoNext ? viewModel.nextMonth : null,
                icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 28),
                tooltip: 'Next Month',
              ),
            ],
          ),
        ],
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
                
                // 4. Strict rule if fee is provided
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

  Widget _buildMonthSelector(TransactionViewModel viewModel) {
    final date = DateTime(viewModel.selectedYear, viewModel.selectedMonth);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: viewModel.canGoPrevious ? viewModel.previousMonth : null,
            tooltip: 'Previous Month',
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              disabledBackgroundColor: Colors.grey.shade50,
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
            tooltip: 'Next Month',
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
