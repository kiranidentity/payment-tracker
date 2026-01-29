import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../models/entity_model.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';


class EntityMappingPage extends StatefulWidget {
  const EntityMappingPage({super.key});

  @override
  State<EntityMappingPage> createState() => _EntityMappingPageState();
}

class _EntityMappingPageState extends State<EntityMappingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Clients'),
        elevation: 0,
      ),
      body: Consumer<TransactionViewModel>(
        builder: (context, viewModel, child) {
                 // ... ListView logic ...
          final unmappedNames = viewModel.getUnmappedNames();
          final entities = viewModel.entities;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildAddEntitySection(viewModel),
              const Divider(height: 32),
              
              if (entities.isNotEmpty) ...[
                const Text(
                  'Mapped Clients (This Month)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...entities.map((e) => Container(
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
                      tilePadding: const EdgeInsets.all(16),
                      title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Monthly Fee: ${e.monthlyLimit != null ? '₹${e.monthlyLimit!.toStringAsFixed(0)}' : 'Not Set'}'),
                        ],
                      ),
                      // isThreeLine: true, // Removed, handled by ExpansionTile spacing
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               Text(
                                '₹${viewModel.getEntityTotal(e.id).toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                              ),
                              if (e.monthlyLimit != null && e.monthlyLimit! > 0)
                                Text(
                                  ' / ${e.monthlyLimit!.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14, color: Colors.grey),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          // Collapsed Actions (Edit/Delete - kept in header?) 
                          // No, ExpansionTile acts as the trigger. We can move actions to children or keep them here if careful.
                          // Keeping minimal actions in header, expanded has details.
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            tooltip: 'Edit Client',
                            onPressed: () => _showEditEntityDialog(context, viewModel, e),
                          ),
                        ],
                      ),
                      children: [
                        const Divider(height: 1),
                        
                        // Mapped Aliases Section
                        if (e.aliases.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Mapped Names:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: e.aliases.map((alias) => Chip(
                                    label: Text(alias, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.indigo.shade50,
                                    deleteIcon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                    onDeleted: () {
                                       viewModel.removeAlias(e.id, alias);
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('Unmapped Name. Transactions moved to Unmapped.')),
                                       );
                                    },
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                        if (e.aliases.isNotEmpty) const Divider(height: 1),

                        // List of Transactions for this Entity
                        ...viewModel.getTransactionsForEntity(e.id).map((tx) {
                           return ListTile(
                             dense: true,
                             contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                             leading: Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey.shade400),
                             title: Text(
                               "${DateFormat('dd MMM').format(tx.date)} - ${tx.sender}",
                               style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                             ),
                             subtitle: tx.mappedAmount != null 
                              ? Text("Full: ₹${tx.amount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 11))
                              : null,
                             trailing: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Text(
                                   "₹${(tx.mappedAmount ?? tx.amount).toStringAsFixed(0)}",
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                 ),
                                 const SizedBox(width: 12),
                                 IconButton(
                                   icon: const Icon(Icons.link_off, color: Colors.orange, size: 18),
                                   tooltip: 'Unmap this transaction',
                                   onPressed: () {
                                     viewModel.unmapTransaction(tx);
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(content: Text('Transaction unmapped')),
                                     );
                                   },
                                 )
                               ],
                             ),
                           );
                        }),
                        if (viewModel.getTransactionsForEntity(e.id).isEmpty)
                           const Padding(
                             padding: EdgeInsets.all(16.0),
                             child: Text("No transactions this month.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                           ),
                        
                        // Footer Actions
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16, right: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6366F1), size: 18),
                                  label: const Text("Add Auto-Map Rule", style: TextStyle(color: Color(0xFF6366F1))),
                                  onPressed: () => _showAddAmountDialog(context, viewModel, e),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                                  label: Text("Delete Client", style: TextStyle(color: Colors.red.shade400)),
                                  onPressed: () => _confirmDelete(context, viewModel, e),
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ))),
                const Divider(height: 32),
              ],

              const Text(
                'Unmapped Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'These are parents/people who paid you. Map them to a Client to track their payments.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                ),
              ),
              const SizedBox(height: 8),
              if (unmappedNames.isEmpty)
                const Text('All transaction names are mapped!'),
              ...unmappedNames.map((name) => _buildMappingTile(context, viewModel, name, entities)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddEntitySection(TransactionViewModel viewModel) {
    final TextEditingController controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create New Client',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Client Name (e.g., Rahul)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  viewModel.addEntity(controller.text);
                  controller.clear();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ],
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
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(unmappedName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Recent: $amountsStr${relatedTxs.length == 3 ? '...' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (actionId) {
                  if (actionId == '__ignore__') {
                    viewModel.ignoreSender(unmappedName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ignored "$unmappedName"')),
                    );
                  } else {
                    viewModel.mapSenderToEntity(unmappedName, actionId);
                  }
                },
                itemBuilder: (context) {
                  final List<PopupMenuEntry<String>> items = [];
                  
                  // Option 1: Ignore
                  items.add(
                    const PopupMenuItem(
                      value: '__ignore__',
                      child: Row(
                        children: [
                           Icon(Icons.visibility_off, color: Colors.grey, size: 20),
                           SizedBox(width: 8),
                           Text('Ignore Sender', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                  items.add(const PopupMenuDivider());

                  // Option 2: Entities
                  if (entities.isEmpty) {
                     items.add(const PopupMenuItem(enabled: false, child: Text('No students created yet')));
                  } else {
                     items.addAll(entities.map((e) => PopupMenuItem(
                      value: e.id,
                      child: Text(e.name),
                    )));
                  }
                  
                  return items;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Map to', style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: Colors.indigo.shade700, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  void _showAddAmountDialog(BuildContext context, TransactionViewModel viewModel, EntityModel entity) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Auto-Map Amount for ${entity.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Any future transaction with this EXACT amount will be automatically assigned to this client.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (e.g., 500)',
                prefixText: '₹',
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
              final amount = double.tryParse(controller.text);
              if (amount != null) {
                viewModel.mapAmountToEntity(amount, entity.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added rule: ₹$amount -> ${entity.name}')),
                );
              }
            },
            child: const Text('Add Auto-Map'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, TransactionViewModel viewModel, EntityModel entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${entity.name}"?'),
        content: const Text(
          'Transactions mapped to this student will NOT be deleted.\n\nThey will simply become "Unmapped" again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              viewModel.deleteEntity(entity.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${entity.name}"')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  void _showEditEntityDialog(BuildContext context, TransactionViewModel viewModel, EntityModel entity) {
    final nameController = TextEditingController(text: entity.name);
    final limitController = TextEditingController(text: entity.monthlyLimit?.toStringAsFixed(0) ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Client Name', border: OutlineInputBorder()),
              enabled: false, // Name editing complicated due to aliases? No, just name. But let's keep it simple for now as user asked for limit.
            ),
            const SizedBox(height: 16),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Fee (₹)',
                hintText: 'e.g. 2000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(limitController.text);
              if (amount != null) {
                 await viewModel.updateClientFee(entity.id, amount);
                 if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
