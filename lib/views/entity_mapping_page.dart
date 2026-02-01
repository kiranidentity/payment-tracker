import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../models/entity_model.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'widgets/unified_header.dart';
import 'widgets/contextual_help_button.dart';
// import 'widgets/global_app_bar.dart';


class EntityMappingPage extends StatefulWidget {
  const EntityMappingPage({super.key});

  @override
  State<EntityMappingPage> createState() => _EntityMappingPageState();
}

class _EntityMappingPageState extends State<EntityMappingPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await Provider.of<TransactionViewModel>(context, listen: false).loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionViewModel>(
      builder: (context, viewModel, child) {
        final unmappedNames = viewModel.getUnmappedNames();
        final ignoredNames = viewModel.getIgnoredSenders();
        
        // Filter Entities based on Search
        final allEntities = viewModel.entities;
        final filteredEntities = _searchQuery.isEmpty 
            ? allEntities 
            : allEntities.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        final inboxCount = unmappedNames.length;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppTheme.background,
            floatingActionButton: FloatingActionButton.extended(
               onPressed: () => _showAddEntityDialog(context, viewModel),
               icon: const Icon(Icons.person_add),
               label: const Text("New Client"),
               backgroundColor: AppTheme.primary,
            ),
            body: Column(
              children: [
                UnifiedGradientHeader(
                  title: 'Manage Clients',
                  subtitle: "${allEntities.length} active clients",
                  canGoBack: false,
                  useSafePadding: true, // Immersive status bar
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _refreshData,
                    tooltip: "Refresh Data",
                  ),
                  bottomContent: TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      const Tab(text: 'My Clients'),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Unmapped'),
                            if (inboxCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white24, // Subtle badge background
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$inboxCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const Tab(text: 'Ignored'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
              children: [
                // TAB 1: Clients List with Search
                Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      color: AppTheme.background,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search clients...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),

                    Expanded(
                      child: filteredEntities.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    allEntities.isEmpty ? "No clients yet." : "No matching clients found.", 
                                    style: const TextStyle(color: Colors.grey)
                                  ),
                                  if (allEntities.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: const Text("Tap the + button to add one.", style: TextStyle(color: Colors.grey)),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Bottom padding for FAB
                            itemCount: filteredEntities.length,
                            itemBuilder: (context, index) {
                              return _buildClientCard(context, viewModel, filteredEntities[index]);
                            },
                          ),
                    ),
                  ],
                ),

                // TAB 2: Inbox (Unmapped)
                ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (unmappedNames.isEmpty)
                       Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 60, color: Colors.green.shade300),
                              const SizedBox(height: 16),
                              const Text(
                                "All Clear!",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "No unknown senders found.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.indigo.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Map these senders to a Client to track their payments automatically.',
                                style: TextStyle(color: Colors.indigo.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...unmappedNames.map((name) => _buildMappingTile(context, viewModel, name, allEntities)),
                    ]
                  ],
                ),
                
                // TAB 3: Ignored (Restore)
                ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (ignoredNames.isEmpty)
                       Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Icon(Icons.visibility_off_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text(
                                "No Ignored Senders",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Senders you ignore will appear here.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      const Text(
                        "Ignored Senders",
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "These senders are hidden from the Unmapped list. Restore them if you want to map them.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ...ignoredNames.map((name) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey),
                            ),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text("Un-ignore"),
                            onPressed: () {
                              viewModel.unignoreSender(name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Restored "$name" to Unmapped list')),
                              );
                            },
                          ),
                        ),
                      )),
                    ]
                    ], // End List children
                  ), // End ListView
                ], // End TabBarView children
              ), // End TabBarView
            ), // End Expanded
          ],
        ),
      ),
    ); 
  },
 );
}

  // Extracted Client Card Widget
  Widget _buildClientCard(BuildContext context, TransactionViewModel viewModel, EntityModel e) {
     final feeText = e.monthlyLimit != null ? '₹${e.monthlyLimit!.toStringAsFixed(0)}' : 'No Fee Set';
     final feeColor = e.monthlyLimit != null ? const Color(0xFF1E293B) : Colors.grey;

     return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
               child: Text(
                  e.name.isNotEmpty ? e.name[0].toUpperCase() : 'C',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo.shade700),
                ),
            ),
            title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(
              "$feeText/month",
               style: TextStyle(fontSize: 13, color: feeColor, fontWeight: FontWeight.w500),
            ),
            children: [
              const Divider(height: 1),
              
              // Mapped Aliases Section (Cleaned up)
              Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text("MAPPED SENDERS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                     const SizedBox(height: 8),
                     if (e.aliases.isEmpty)
                        const Text("No senders linked yet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13))
                     else
                       Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: e.aliases.map((alias) {
                          String label = alias;
                          bool isRule = false;
                          if (alias.startsWith("rule:")) {
                            isRule = true;
                            try {
                              final parts = alias.split(':');
                              if (parts.length >= 3) {
                                label = "₹${parts[1]} from ${parts.sublist(2).join(':')}";
                              }
                            } catch (_) {}
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isRule ? Colors.purple.shade50 : Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isRule ? Colors.purple.shade100 : Colors.indigo.shade100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isRule ? Icons.bolt : Icons.link, size: 14, color: isRule ? Colors.purple : Colors.indigo),
                                const SizedBox(width: 6),
                                Text(label, style: TextStyle(fontSize: 12, color: isRule ? Colors.purple.shade900 : Colors.indigo.shade900)),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                     viewModel.removeAlias(e.id, alias);
                                  },
                                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                   ],
                 ),
              ),

              const Divider(height: 1),

              // Footer Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text("Edit Details"),
                        onPressed: () => _showEditEntityDialog(context, viewModel, e),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text("Link Sender"),
                        onPressed: () => _showAddAmountDialog(context, viewModel, e),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                        label: Text("Delete", style: TextStyle(color: Colors.red.shade400)),
                        onPressed: () => _confirmDelete(context, viewModel, e),
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
  }

  // --- NEW DIALOG for FAB ---
  void _showAddEntityDialog(BuildContext context, TransactionViewModel viewModel) {
    final TextEditingController controller = TextEditingController();
    final TextEditingController feeController = TextEditingController(); 
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Client Name',
                hintText: 'e.g. Rahul',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Fee (₹)',
                hintText: 'e.g. 2000', 
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                double? limit = double.tryParse(feeController.text);
                viewModel.addEntity(controller.text, limit: limit);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added Client: ${controller.text}')),
                );
              }
            },
            child: const Text('Add Client'),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingTile(
    BuildContext context, 
    TransactionViewModel viewModel, 
    String unmappedName, 
    List<EntityModel> entities
  ) {
          
          // Get recent transactions for this unmapped name to show context
          final relatedTxs = viewModel.getRecentTransactionsForName(unmappedName);
          final amountsStr = relatedTxs.map((t) => '₹${t.amount.toStringAsFixed(0)} (${DateFormat('MMM d').format(t.date)})').join(', ');

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
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
            child: InkWell(
              onTap: () => _showSenderHistoryDialog(context, viewModel, unmappedName, entities),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40, 
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        unmappedName.isNotEmpty ? unmappedName[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    // Name & Details (Expanded)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unmappedName.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' '), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Recent: $amountsStr${relatedTxs.length == 3 ? '...' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 4),

                    // Actions
                    // Ignore Button (Compact Icon)
                    IconButton(
                        onPressed: () => _confirmIgnoreSender(context, viewModel, unmappedName),
                        icon: const Icon(Icons.visibility_off_outlined, color: Colors.grey, size: 20),
                        tooltip: "Ignore Sender",
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                    ),
                    
                    const SizedBox(width: 8),

                    // Map Button (Compact)
                    ElevatedButton(
                      onPressed: () => _showQuickMapMenu(context, viewModel, unmappedName, entities),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32), // Compact height and auto width
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Map", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  void _showSenderHistoryDialog(BuildContext context, TransactionViewModel viewModel, String senderName, List<EntityModel> entities) {
    final allTxs = viewModel.getAllTransactionsForName(senderName);
    final totalReceived = allTxs.fold(0.0, (sum, tx) => sum + tx.amount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              "Total Received: ₹${totalReceived.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 14, color: AppTheme.primary),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: allTxs.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final tx = allTxs[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.call_received, size: 16, color: Colors.green),
                title: Text(
                  "₹${tx.amount.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(tx.date),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close history
              _showQuickMapMenu(context, viewModel, senderName, entities); // Open map menu
            },
            child: const Text("Map to Client"),
          ),
        ],
      ),
    );
  }

  void _showQuickMapMenu(BuildContext context, TransactionViewModel viewModel, String unmappedName, List<EntityModel> entities) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Map "$unmappedName" to...'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entities.isEmpty)
                const ListTile(
                  title: Text('No students created yet'),
                  enabled: false,
                )
              else
                ...entities.map((entity) => ListTile(
                  title: Text(entity.name),
                  onTap: () {
                    Navigator.pop(context); // Close dialog

                    // Smart Check: Does this transaction amount match the expected fee?
                    // We grab the LATEST transaction amount for this sender to check.
                    final relatedTxs = viewModel.getRecentTransactionsForName(unmappedName);
                    final latestTx = relatedTxs.firstOrNull;
                    final txAmount = latestTx?.amount ?? 0.0;
                    final expectedFee = entity.monthlyLimit;

                    if (expectedFee != null && (txAmount - expectedFee).abs() > 0.01) {
                      // CONFLICT: Received Amount != Fee
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Amount Mismatch"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("You are mapping '$unmappedName' to '${entity.name}'."),
                              const SizedBox(height: 12),
                              Text("• Received: ₹${txAmount.toStringAsFixed(0)}"),
                              Text("• Expected Fee: ₹${expectedFee.toStringAsFixed(0)}"),
                              const SizedBox(height: 16),
                              const Text("Do you want to update the Monthly Fee to match this new amount?"),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                // Option 1: Just Map (One-off surplus/shortage)
                                viewModel.mapSenderToEntity(unmappedName, entity.id);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Mapped "$unmappedName" to ${entity.name}')),
                                );
                              },
                              child: const Text("No, Keep Previous Fee"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Option 2: Update Fee & Add Rule
                                viewModel.updateClientFee(entity.id, txAmount);
                                viewModel.addStrictAutoMapRule(txAmount, unmappedName, entity.id);
                                viewModel.mapSenderToEntity(unmappedName, entity.id); // Ensure name is also mapped
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Updated Fee to ₹${txAmount.toStringAsFixed(0)} & Mapped "$unmappedName"')),
                                );
                              },
                              child: const Text("Yes, Update Fee & Rule"),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // No Conflict or No Fee Set
                      // If No Fee Set -> Ask to set it (Implicitly "Yes" to update fee)
                      if (expectedFee == null) {
                         viewModel.updateClientFee(entity.id, txAmount);
                         viewModel.addStrictAutoMapRule(txAmount, unmappedName, entity.id);
                      }
                      
                      viewModel.mapSenderToEntity(unmappedName, entity.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mapped "$unmappedName" to ${entity.name}')),
                      );
                    }
                  },
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddAmountDialog(BuildContext context, TransactionViewModel viewModel, EntityModel entity) {
    final amountController = TextEditingController();
    final senderController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Link Another Sender to ${entity.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Link a specific Sender & Amount combination to this client (e.g. Spouse paying fees).',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (e.g., 500)',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: senderController,
              decoration: const InputDecoration(
                labelText: 'Sender Name (e.g., Rahul)',
                hintText: 'Must match exactly',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              final sender = senderController.text.trim();
              
              if (amount != null && sender.isNotEmpty) {
                viewModel.addStrictAutoMapRule(amount, sender, entity.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added Rule: ₹$amount from $sender -> ${entity.name}')),
                );
              } else if (sender.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sender Name is required for strict mapping.')),
                );
              }
            },
            child: const Text('Add Rule'),
          ),
        ],
      ),
    );
  }

  // --- HELPERS (Restore/Delete) ---
  void _confirmIgnoreSender(BuildContext context, TransactionViewModel viewModel, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ignore Sender?'),
        content: Text('Transactions from "$name" will be hidden from the unmapped list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              viewModel.ignoreSender(name);
              Navigator.pop(context);
            },
            child: const Text('Ignore'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, TransactionViewModel viewModel, EntityModel entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${entity.name}?'),
        content: const Text('All mapped transactions will be moved back to Unmapped. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              viewModel.deleteEntity(entity.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditEntityDialog(BuildContext context, TransactionViewModel viewModel, EntityModel entity) {
    final controller = TextEditingController(text: entity.name);
    final feeController = TextEditingController(text: entity.monthlyLimit?.toStringAsFixed(0) ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Client Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feeController,
              decoration: const InputDecoration(labelText: 'Monthly Fee (₹)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                 final limit = double.tryParse(feeController.text);
                 viewModel.updateEntity(entity.id, controller.text, limit);
                 Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

}
