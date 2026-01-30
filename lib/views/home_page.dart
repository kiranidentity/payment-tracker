import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure google_fonts is available
import '../viewmodels/transaction_viewmodel.dart';
import '../models/entity_model.dart';
import '../theme/app_theme.dart';
import 'entity_mapping_page.dart';
import 'transaction_history_page.dart';
import 'help_page.dart'; // NEW

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _filterStatus = 'All'; // 'All', 'Paid', 'Pending'
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<TransactionViewModel>(context, listen: false).loadTransactions()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<TransactionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final entities = viewModel.entities;
          
          // Apply Filters
          final filteredEntities = entities.where((e) {
            final received = viewModel.getEntityTotal(e.id);
            final expected = e.monthlyLimit ?? 0.0;
            final isPaid = expected > 0 && received >= expected;
            
            if (_filterStatus == 'Paid') return isPaid;
            if (_filterStatus == 'Pending') return !isPaid;
            return true; 
          }).toList();

          final unmappedNames = viewModel.getUnmappedNames();
          final hasTransactions = viewModel.transactions.isNotEmpty || viewModel.importLogs.isNotEmpty;

          // STATE 1: ZERO STATE (Brand new user, no data)
          if (!hasTransactions && entities.isEmpty) {
             return _buildZeroState(context, viewModel);
          }

          // STATE 2: SETUP STATE (No entities yet)
          // Setup state code...
          if (entities.isEmpty && hasTransactions) {
             return _buildSetupState(context, viewModel, unmappedNames, entities);
          }

          // STATE 3: NORMAL DASHBOARD
          return Column(
            children: [
              // DARK GRADIENT HEADER (Replaces Summary Card + Month Selector)
              _buildDarkHeader(context, viewModel),
              
              // NEW: Filter Chips
              _buildFilterChips(context),

              // Smart Alert for new unmapped names
              _buildUnmappedAlert(context, viewModel),
              
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  itemCount: filteredEntities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12), // Spacing between rows
                  itemBuilder: (context, index) {
                    final entity = filteredEntities[index];
                    return _buildCleanStudentRow(context, entity, viewModel);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleImport(context, Provider.of<TransactionViewModel>(context, listen: false)),
        tooltip: 'Import PDF',
        icon: const Icon(Icons.upload_file),
        label: const Text('Import Statement'),
        backgroundColor: AppTheme.primary,
        elevation: 4,
        shape: const StadiumBorder(), // FORCE PILL SHAPE
        isExtended: true,
      ),
    );
  }

  // --- NEW HEADER DESIGN ---
  Widget _buildDarkHeader(BuildContext context, TransactionViewModel viewModel) {
    final date = DateTime(viewModel.selectedYear, viewModel.selectedMonth);
    
    // Calculate total received
    double totalReceived = viewModel.totalReceivedCurrentMonth;
    int pendingCount = 0;
    for (var e in viewModel.entities) {
       final received = viewModel.getEntityTotal(e.id);
       final expected = e.monthlyLimit ?? 0.0;
       if (received < expected) pendingCount++;
    }

    // Adaptive top padding
    final topPadding = MediaQuery.of(context).padding.top + 24;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark, // Deep Indigo
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)], // Deep 900 -> 800
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: App Title + Help Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Tracker',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpPage())),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.help_outline, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Row 2: CENTERED Month Selector (Prominent navigation)
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

          const SizedBox(height: 24),
          
          // Row 3: Total Amount (Centered)
          Center(
            child: Column(
              children: [
                const Text(
                  'TOTAL COLLECTED',
                  style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${NumberFormat('#,##,##0').format(totalReceived)}',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 40, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                    if (pendingCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Text(
                            '$pendingCount Due', 
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Row 4: Health Bar
          _buildHealthBar(context, totalReceived, viewModel.totalExpectedMonthly),
        ],
      ),
    );
  }


  // --- NEW LIST ROW DESIGN ---
  Widget _buildCleanStudentRow(BuildContext context, EntityModel entity, TransactionViewModel viewModel) {
    final received = viewModel.getEntityTotal(entity.id);
    final expected = entity.monthlyLimit ?? 0.0;
    
    // Status Logic
    bool isPaid = expected > 0 && received >= expected;
    bool isPartial = expected > 0 && received > 0 && received < expected;
    bool isPending = expected > 0 && received == 0;
    bool isOverpaid = received > expected;

    Color statusColor = AppTheme.textSub;
    String statusText = "Zero";
    // IconData? actionIcon; // Unused for now

    if (isPaid) {
      statusColor = AppTheme.accent; // Green
      statusText = "Paid";
    } else if (isPartial) {
      statusColor = Colors.orange;
      statusText = "Partial";
    } else if (isPending) {
      statusColor = AppTheme.error; // Red
      statusText = "Due";
    }
    
    if (isOverpaid) {
       statusText = "Review";
       statusColor = Colors.blue; 
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar (Initials)
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  entity.name.isNotEmpty ? entity.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textMain),
                ),
              ),
              const SizedBox(width: 16),
              
              // Name & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${received.toStringAsFixed(0)} / ${expected.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13, 
                        color: isPaid ? AppTheme.accent : AppTheme.textSub,
                        fontWeight: isPaid ? FontWeight.w600 : FontWeight.normal
                      ),
                    ),
                  ],
                ),
              ),

              // Action Button (Pill)
              if (isOverpaid)
                 InkWell(
                   onTap: () => _showExcessReviewDialog(context, viewModel, entity, received, expected),
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.blue.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: const Row(
                       children: [
                          Icon(Icons.rate_review, size: 14, color: Colors.blue),
                          SizedBox(width: 6),
                          Text("Review", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                       ],
                     ),
                   ),
                 )
              else
                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      // border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                 ),
            ],
          ),
          
          // Progress Bar (Slim, only if not fully paid)
          if (!isPaid && !isOverpaid && expected > 0)
            Padding(
               padding: const EdgeInsets.only(top: 12),
               child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (received / expected).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade100,
                    color: statusColor,
                    minHeight: 4,
                  ),
               ),
            ),
        ],
      ),
    );
  }

  // --- REBUILT HELPERS (Cleaned up from old code) ---

  Future<void> _handleImport(BuildContext context, TransactionViewModel viewModel) async {
    // Show Recent Imports Dialog to check for dupes
    if (viewModel.importLogs.isNotEmpty) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recent Imports', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Check if you've already imported this file:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: viewModel.importLogs.take(3).length,
                    itemBuilder: (context, index) {
                      final log = viewModel.importLogs[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history, size: 18, color: Colors.grey),
                        title: Text(DateFormat('MMM d, h:mm a').format(log.timestamp), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${log.transactionCount} credits found'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Proceed
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Import New'),
            ),
          ],
        ),
      );
      
      if (proceed != true) return;
    }

    final count = await viewModel.importPdf();
    if (context.mounted) {
      if (count == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error importing PDF. Please try again.')),
        );
      } else if (count == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No received transactions found in this statement.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Success! Found $count received payments. Unmapped ones are ready for review.'),
            backgroundColor: AppTheme.accent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildZeroState(BuildContext context, TransactionViewModel viewModel) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.upload_file, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text('No Data Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Import your statement to start tracking.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _handleImport(context, viewModel),
              icon: const Icon(Icons.upload_file),
              label: const Text('Import PDF Statement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSetupState(BuildContext context, TransactionViewModel viewModel, List<String> unmappedNames, List<EntityModel> entities) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          const Text(
            'Setup Required', 
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textMain),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'We found ${unmappedNames.length} new people in your statement.\nMap them to clients to start tracking.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSub, fontSize: 16),
          ),
          const SizedBox(height: 40),
          ...unmappedNames.map((name) => _buildMappingTile(context, viewModel, name, entities, isSetupMode: true)),
          
          if (unmappedNames.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                     children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 60),
                        SizedBox(height: 16),
                        Text("All items processed!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     ],
                  ),
                ),
              ),
        ],
      );
  }

  Widget _buildUnmappedAlert(BuildContext context, TransactionViewModel viewModel) {
    final unmappedNames = viewModel.getUnmappedNames();
    if (unmappedNames.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
             Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EntityMappingPage()),
              );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${unmappedNames.length} unmapped senders found.",
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.amber.shade900, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Uses the existing _buildMappingTile logic but styled simpler if needed
  Widget _buildMappingTile(BuildContext context, TransactionViewModel viewModel, String unmappedName, List<EntityModel> entities, {bool isSetupMode = false}) {
     final relatedTxs = viewModel.getRecentTransactionsForName(unmappedName);
     
     return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: isSetupMode ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0,2))] : [],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(unmappedName, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text("Found ${relatedTxs.length} payments", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: OutlinedButton(
            onPressed: () => _showQuickMapMenu(context, viewModel, unmappedName, entities),
            child: const Text("Map"),
          ),
        ),
     );
  }

  void _showQuickMapMenu(BuildContext context, TransactionViewModel viewModel, String unmappedName, List<EntityModel> entities) {
      showModalBottomSheet(
        context: context, 
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Map '$unmappedName' to...", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.add, color: AppTheme.primary),
                  title: const Text("Create New Client", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddStudentDialog(context, viewModel, unmappedName);
                  },
                ),
                const Divider(),
                ...entities.map((e) => ListTile(
                   title: Text(e.name),
                   onTap: () {
                     viewModel.mapSenderToEntity(unmappedName, e.id);
                     Navigator.pop(context);
                   },
                )),
              ],
            ),
          );
        }
      );
  }

  void _showAddStudentDialog(BuildContext context, TransactionViewModel viewModel, String senderName) {
    final controller = TextEditingController();
    final feeController = TextEditingController(); // NEW
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Client Name', hintText: 'e.g. John Doe'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feeController,
              decoration: const InputDecoration(labelText: 'Monthly Fee (₹)', hintText: 'Optional'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                 double? fee = double.tryParse(feeController.text);
                 await viewModel.addEntity(controller.text, limit: fee);
                 
                 final newEntity = viewModel.entities.firstWhere((e) => e.name == controller.text);
                 await viewModel.mapSenderToEntity(senderName, newEntity.id);
                 
                 // If fee was provided, we should probably treat this mapping as a Strict Rule too?
                 // Let's call the helper if fee exists
                 if (fee != null && fee > 0) {
                   await viewModel.addStrictAutoMapRule(fee, senderName, newEntity.id);
                 }

                 if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExcessReviewDialog(BuildContext context, TransactionViewModel viewModel, EntityModel entity, double received, double expected) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Review Payment'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Text('Received ₹${received.toStringAsFixed(0)} (Fee: ₹$expected)', style: const TextStyle(color: Colors.grey)),
             const SizedBox(height: 16),
             _buildReviewOption(context, 'Bonus', 'Keep extra in this month', Icons.card_giftcard, Colors.purple, () => viewModel.handleExcessPayment(entity.id, 'BONUS')),
             _buildReviewOption(context, 'Back Pay', 'Cover previous month', Icons.history, Colors.orange, () => viewModel.handleExcessPayment(entity.id, 'ARREARS')),
             _buildReviewOption(context, 'Advance', ' carry forward to next month', Icons.event_repeat, Colors.green, () => viewModel.handleExcessPayment(entity.id, 'ADVANCE')),
           ],
         ),
       ),
     );
  }

  Widget _buildReviewOption(BuildContext context, String title, String sub, IconData icon, Color color, Future<void> Function() onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      onTap: () async {
        await onTap();
        if (context.mounted) Navigator.pop(context);
      },
    );
  }

  void _showLegendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Icons.check_circle, AppTheme.accent, "Paid", "Full fee received."),
            const SizedBox(height: 12),
            _buildLegendItem(Icons.warning_amber_rounded, Colors.orange, "Partial", "Received less than expected."),
            const SizedBox(height: 12),
            _buildLegendItem(Icons.cancel, AppTheme.error, "Due", "No fees received yet."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String title, String desc) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        )
      ],
    );
  }
  Widget _buildFilterChips(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(24, 24, 0, 0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('All', _filterStatus == 'All'),
          const SizedBox(width: 12),
          _buildChip('Pending', _filterStatus == 'Pending'),
          const SizedBox(width: 12),
          _buildChip('Paid', _filterStatus == 'Paid'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _filterStatus = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryDark : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryDark.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHealthBar(BuildContext context, double current, double total) {
    double progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(
              "Progress", 
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)
             ),
             Text(
              "Goal: ₹${NumberFormat('#,##,##0').format(total)}",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)
             ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.black.withOpacity(0.2),
            color: AppTheme.accent, // Teal
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
