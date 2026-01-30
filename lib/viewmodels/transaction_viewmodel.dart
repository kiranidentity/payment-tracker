import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/pdf_parser_service.dart';
import '../models/transaction_model.dart';
import '../models/entity_model.dart';

import '../models/import_log_model.dart';
import 'package:intl/intl.dart';

class TransactionViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final PdfParserService _pdfService = PdfParserService();

  List<TransactionModel> _transactions = [];
  List<EntityModel> _entities = [];
  List<String> _ignoredAliases = []; // NEW: Ignore list
  List<ImportLogModel> _importLogs = []; // NEW: Import history
  bool _isLoading = false;
  
  // Monthly Filter
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Added: Helper to finding entity name for a transaction
  String? getEntityName(String? entityId) {
    if (entityId == null) return null;
    try {
      return _entities.firstWhere((e) => e.id == entityId).name;
    } catch (_) {
      return null;
    }
  }

  List<TransactionModel> get transactions {
    return _transactions.where((tx) => 
      tx.date.month == _selectedMonth && 
      tx.date.year == _selectedYear &&
      tx.isCredit // Only show Received amounts
    ).toList();
  }
  
  List<EntityModel> get entities => _entities;
  
  bool get isLoading => _isLoading;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  // Get transactions for a specific entity in the selected month
  List<TransactionModel> getTransactionsForEntity(String entityId) {
    return _transactions.where((tx) => 
      tx.entityId == entityId && 
      tx.isCredit &&
      tx.date.month == _selectedMonth &&
      tx.date.year == _selectedYear
    ).toList()..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  void setMonth(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();
  }
  
  bool get canGoNext {
    // START: Relaxed Navigation Logic (User Request)
    // Allow navigation up to the current real-time month, even if data is old.
    final now = DateTime.now();
    final currentRealMonth = DateTime(now.year, now.month);
    
    // Check if current view is before the real-time current month
    if (_selectedYear < currentRealMonth.year) return true;
    if (_selectedYear == currentRealMonth.year && _selectedMonth < currentRealMonth.month) return true;

    // Strict Mode Fallback (Prevent future navigation beyond real-time)
    return false;

    /* 
    // OLD STRICT LOGIC (Restricted to Latest Transaction Date)
    if (_transactions.isEmpty) return false;
    final latestTx = _transactions.cast<TransactionModel?>().firstWhere(
      (tx) => tx!.isCredit, 
      orElse: () => null
    );
    if (latestTx == null) return false;
    final limitDate = DateTime(latestTx.date.year, latestTx.date.month);
    if (_selectedYear < limitDate.year) return true;
    if (_selectedYear == limitDate.year && _selectedMonth < limitDate.month) return true;
    return false; 
    */
  }

  bool get canGoPrevious {
    if (_transactions.isEmpty) return false;
    
    // Strict Mode: Limit is the Oldest Transaction Date
    final oldestTx = _transactions.cast<TransactionModel?>().lastWhere(
      (tx) => tx!.isCredit, 
      orElse: () => null
    );
    
    if (oldestTx == null) return false;
    
    final limitDate = DateTime(oldestTx.date.year, oldestTx.date.month);

    if (_selectedYear > limitDate.year) return true;
    if (_selectedYear == limitDate.year && _selectedMonth > limitDate.month) return true;
    
    return false;
  }

  void nextMonth() {
    if (!canGoNext) return;
    
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    notifyListeners();
  }

  void previousMonth() {
    if (!canGoPrevious) return;
    
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();
    
    _transactions = _dbService.getAllTransactions();
    _entities = _dbService.getAllEntities();
    _ignoredAliases = _dbService.getIgnoredAliases(); // Load ignored
    _importLogs = _dbService.getImportLogs(); // Load logs
    
    // Sort by date descending
    
    // Sort by date descending
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    
    _isLoading = false;
    notifyListeners();
  }

  Future<int> importPdf() async {
    print("DEBUG: TransactionViewModel.importPdf called");
    _isLoading = true;
    notifyListeners();

    try {
      List<TransactionModel> newTransactions = await _pdfService.pickAndParsePdf();
      
      for (var tx in newTransactions) {
        // Auto-map based on Aliases (Name OR Amount)
        // 1. Check if ignored
        if (_ignoredAliases.contains(tx.sender)) {
           continue; // Skip ignored senders effectively (or we can add them but mark as ignored? Better to just not auto-map and maybe hide from unmapped list)
           // Actually, we should save them to DB but they won't show up in "Unmapped" list if check is there.
        }

        final otherParty = tx.isCredit ? tx.sender : tx.receiver;
        for (var entity in _entities) {
          bool matchFound = false;

          // 1. Check Aliases (Names & Strict Rules)
          for (var alias in entity.aliases) {
            if (alias.startsWith("rule:")) {
              // strict rule: "rule:500.0:Rahul"
              try {
                final parts = alias.split(':');
                 // Ensure valid rule
                if (parts.length >= 3) {
                  final ruleAmount = double.tryParse(parts[1]);
                  // Re-join rest in case name has colons
                  final ruleSender = parts.sublist(2).join(':'); 
                  
                  if (ruleAmount != null && 
                      (tx.amount - ruleAmount).abs() < 0.01 && 
                      ruleSender == otherParty) {
                    matchFound = true;
                    break;
                  }
                }
              } catch (_) {}
            } else {
              // Normal name alias
              if (alias == otherParty) {
                matchFound = true;
                break;
              }
            }
          }

          if (matchFound) {
            tx.entityId = entity.id;
            break; 
          }
          
          // 2. Legacy Amount Match (Low Priority)
          // Only if no strict/name match found yet
          if (entity.amountAliases.contains(tx.amount)) {
            tx.entityId = entity.id;
            break;
          }
        }
        await _dbService.addTransaction(tx);
      }
      
      // Log the import
      if (newTransactions.isNotEmpty) {
        final creditCount = newTransactions.where((t) => t.isCredit).length;
        final log = ImportLogModel(
          fileName: 'Imported on ${DateTime.now().toString()}', // We don't have filename easily from this method, generic for now
          timestamp: DateTime.now(),
          transactionCount: creditCount,
          status: 'Success',
        );
        await _dbService.addImportLog(log);
      }
      
      if (newTransactions.isNotEmpty) {
        // Sort new transactions to find the latest date
        newTransactions.sort((a, b) => b.date.compareTo(a.date));
        final latestDate = newTransactions.first.date;
        _selectedMonth = latestDate.month;
        _selectedYear = latestDate.year;
      }
      
      await loadTransactions();
      await loadTransactions();
      // Return only CREDIT count as requested
      return newTransactions.where((t) => t.isCredit).length;
      
    } catch (e) {
      debugPrint("Error importing PDF: $e");
      return -1; // Error code
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> clearAll() async {
    await _dbService.clearAllTransactions();
    // Also clear logs? Maybe not.
    await loadTransactions();
  }

  // NEW: Ignore a sender
  Future<void> ignoreSender(String senderName) async {
    if (!_ignoredAliases.contains(senderName)) {
      _ignoredAliases.add(senderName);
      await _dbService.saveIgnoredAliases(_ignoredAliases);
      notifyListeners();
    }
  }

  // NEW: Helper to get recent transactions for ANY specific name (from full history)
  // This fixes the issue where unmapped list showed no amounts if tx was in different month
  List<TransactionModel> getRecentTransactionsForName(String name) {
    return _transactions
        .where((tx) => (tx.isCredit ? tx.sender : tx.receiver) == name)
        .take(5) // Take last 5
        .toList();
  }

  List<ImportLogModel> get importLogs => _importLogs;
  
  double get totalReceivedCurrentMonth {
    return transactions
        .fold(0.0, (sum, item) => sum + item.amount);
  }
  
  double getEntityTotal(String entityId) {
    return transactions
        .where((tx) => tx.entityId == entityId)
        .fold(0.0, (sum, item) => sum + (item.mappedAmount ?? item.amount));
  }
  
  // NEW: Total Expected Fees for Visualization
  double get totalExpectedMonthly {
    return _entities.fold(0.0, (sum, e) => sum + (e.monthlyLimit ?? 0.0));
  }
  
  // Entity Management
  Future<void> addEntity(String name, {double? limit}) async {
    final newEntity = EntityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      monthlyLimit: limit,
      aliases: [], // We can't know aliases yet, mapping happens next
    );
     // IF limit is provided, we should probably add it as a strict amount rule? 
     // No, strict amount rules need a Sender Name. 
     // But wait, if we are creating this from a specific Unmapped Sender (which is usually the case),
     // we could pass that sender name too?
     // For now, let's just stick to setting the Limit. The mapping logic usually follows immediately.
     
    await _dbService.addEntity(newEntity);
    await loadTransactions(); // Refresh entities list
  }



  // Unified Method: Sets Monthly Limit AND attempts to set Amount Alias
  Future<void> updateClientFee(String entityId, double amount) async {
    final entity = _entities.firstWhere((e) => e.id == entityId);
    
    // 1. Check for collisions (Is this amount used by any OTHER entity?)
    bool isUnique = !_entities.any((e) => e.id != entityId && e.amountAliases.contains(amount));
    
    // 2. Prepare new aliases list
    List<double> newAmountAliases = List.from(entity.amountAliases);
    
    if (isUnique) {
      // If unique, we can safely AUTO-MAP this amount
      if (!newAmountAliases.contains(amount)) {
        newAmountAliases.add(amount);
      }
    } else {
      // If NOT unique (Collision), do NOT auto-map. 
      // Reliance falls back to Name Mapping (Sender Name) which is safer.
      // We also remove it if it was previously there to prevent bugs.
      newAmountAliases.remove(amount);
    }

    final updatedEntity = EntityModel(
      id: entity.id,
      name: entity.name,
      monthlyLimit: amount, // ALWAYS set the limit (Goal)
      aliases: entity.aliases,
      amountAliases: newAmountAliases,
    );
    
    await _dbService.addEntity(updatedEntity);
    await loadTransactions();
  }



  // Strict Auto-Map Rule: Amount + Sender
  Future<void> addStrictAutoMapRule(double amount, String sender, String entityId) async {
    final entity = _entities.firstWhere((e) => e.id == entityId);
    
    // Format: "rule:500.0:Rahul"
    // Encode properly to avoid delimiter issues? Simple replace for now.
    // Let's use a JSON-like structure but simple string is easier for Hive list.
    // "rule:<amount>:<sender>"
    final ruleString = "rule:$amount:$sender";

    if (!entity.aliases.contains(ruleString)) {
      entity.aliases.add(ruleString);
      await entity.save();
    }
    
    // Retro-active Application
    final relevantTxs = _transactions.where((tx) => 
      tx.amount == amount && 
      (tx.isCredit ? tx.sender : tx.receiver) == sender &&
      (tx.entityId == null || tx.entityId!.isEmpty)
    );
    
    for (var tx in relevantTxs) {
      tx.entityId = entityId;
      await tx.save(); 
    }
    
    notifyListeners();
  }
  
  // Retro-fitted mapAmount logic (Redirect to Strict if sender provided? No, keep separate for now if needed, but user wants strict)
  // Deprecating loose amount mapping in favor of strict or manual.
  // Actually, let's keep it but maybe unused. 
  // I will replace mapAmountToEntity with a version that defaults sender to * if not provided?
  // But for now, let's just stick to adding the new method.

  Future<void> mapSenderToEntity(String senderName, String entityId) async {
    // 1. Find the entity
    final entity = _entities.firstWhere((e) => e.id == entityId);
    
    // 2. Add sender alias to entity if not exists
    if (!entity.aliases.contains(senderName)) {
      entity.aliases.add(senderName);
      await entity.save();
    }
    
    // 3. Update all existing transactions with this sender
    // We update _transactions list directly but we also need to save each modified transaction to DB
    final relevantTxs = _transactions.where((tx) => 
      (tx.isCredit ? tx.sender : tx.receiver) == senderName
    );
    
    for (var tx in relevantTxs) {
      tx.entityId = entityId;
      await tx.save(); 
    }
    
    notifyListeners();
  }

  // Delete Entity and safe unmap
  Future<void> deleteEntity(String entityId) async {
    // 1. Unmap transactions
    final linkedTxs = _transactions.where((tx) => tx.entityId == entityId);
    for (var tx in linkedTxs) {
      tx.entityId = null;
      await tx.save();
    }
    
    // 2. Delete the entity
    await _dbService.deleteEntity(entityId);
    
    // 3. Refresh
    await loadTransactions();
    await loadTransactions();
  }

  // Manually Unmap a specific transaction (Handle "Teacher Friend" scenario)
  Future<void> unmapTransaction(TransactionModel tx) async {
    tx.entityId = null;
    tx.mappedAmount = null; // Reset mapped amount too
    
    // If it was a manual transaction, we might want to delete it instead?
    // But usually unmapping just removes the link. If it's manual, the user probably 
    // wants it gone if it's "not a fee", or they can delete it manually from history.
    await tx.save();
    notifyListeners();
  }

  // NEW: Add a manual payment record
  Future<void> addManualPayment(String entityId, double amount, String description) async {
    final newTx = TransactionModel(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime(selectedYear, selectedMonth, DateTime.now().day),
      amount: amount,
      description: description,
      sender: 'Manual Entry',
      receiver: 'Me',
      isCredit: true,
      entityId: entityId,
    );

    await _dbService.addTransaction(newTx);
    await loadTransactions();
  }

  // Update Partial Mapping Amount
  Future<void> updateTransactionSplit(TransactionModel tx, double feeAmount) async {
    // If feeAmount is same as full amount, just set null to save space
    if ((feeAmount - tx.amount).abs() < 0.01) {
      tx.mappedAmount = null;
    } else {
      tx.mappedAmount = feeAmount;
    }
    await tx.save();
    notifyListeners();
  }

  // NEW: Intelligent "Fill the Bucket" Logic
  // Caps the total received amount for an entity to its Monthly Fee
  // Returns the amount that was "shaved off" (the excess)
  Future<double> capEntityPaymentsToLimit(String entityId) async {
    final entity = _entities.firstWhere((e) => e.id == entityId);
    final limit = entity.monthlyLimit;
    if (limit == null) return 0.0;

    // Get all credits for this entity in current month
    final entityTxs = _transactions.where((tx) => 
      tx.entityId == entityId && 
      tx.isCredit &&
      tx.date.month == _selectedMonth &&
      tx.date.year == _selectedYear
    ).toList();
    
    // Sort oldest first
    entityTxs.sort((a, b) => a.date.compareTo(b.date));

    double currentTotal = 0.0;
    double shavedAmount = 0.0;
    
    for (var tx in entityTxs) {
      double remainingSpace = limit - currentTotal;
      double originalAmount = tx.amount;
      
      // If mappedAmount is set, use that as the "current" effective amount 
      // but strictly we should probably reset and recalculate to ensure correctness.
      // Let's assume we are recalculating from scratch aka "Best Fit".
      
      if (remainingSpace <= 0) {
        // Bucket is full, map this entire transaction to 0
        if (tx.mappedAmount != 0.0) {
           shavedAmount += (tx.mappedAmount ?? tx.amount);
           tx.mappedAmount = 0.0;
           await tx.save();
        } else {
           // Already 0, means it was already shaved? Or just 0. 
           // If it was 0, shaved amount from THIS run is 0 for this tx.
        }
      } else {
        // We have space.
        if (originalAmount <= remainingSpace) {
          // Fits entirely.
          if (tx.mappedAmount != null) {
            tx.mappedAmount = null; 
            await tx.save();
          }
          currentTotal += originalAmount;
        } else {
          // Fits partially.
          double useAmount = remainingSpace;
          double splitExcess = originalAmount - useAmount;
          
          if (tx.mappedAmount != useAmount) {
             tx.mappedAmount = useAmount;
             await tx.save();
             shavedAmount += splitExcess;
          }
          currentTotal += useAmount;
        }
      }
    }
    notifyListeners();
    return shavedAmount;
  }

  // Remove an Alias (Unmap logic)
  Future<void> removeAlias(String entityId, String alias) async {
    final entity = _entities.firstWhere((e) => e.id == entityId);
    
    // 1. Remove from entity's alias list
    if (entity.aliases.contains(alias)) {
      entity.aliases.remove(alias);
      await entity.save();
    }

    // 2. Unmap all corresponding transactions
    final affectedTxs = _transactions.where((tx) => 
      tx.entityId == entityId && 
      tx.sender == alias // Unmap only transactions from this specific alias
    ).toList();

    for (var tx in affectedTxs) {
      tx.entityId = null;
      tx.mappedAmount = null;
      await tx.save();
    }

    notifyListeners();
  }

  // Handle Excess Payment Distribution
  Future<void> handleExcessPayment(String entityId, String action) async {
    final entity = _entities.firstWhere((e) => e.id == entityId);
    
    // 1. Calculate Excess BEFORE capping (for verification)
    // Actually, let's just use the cap function to do the heavy lifting and tell us what it removed.
    // Wait, if we cap first, we lose the 'Bonus' option (keep full).
    // So 'Bonus' action should just do nothing (or mark reviewed).
    
    if (action == 'BONUS') {
      // Do nothing, just keep it as Overpaid/Bonus.
      return; 
    }

    // 2. For Advance/Arrears, we MUST cap the current month first.
    // We need to calculate how much to move.
    // Simplest way: Calculate (Total - Limit)
    double totalReceived = getEntityTotal(entityId);
    double limit = entity.monthlyLimit ?? 0;
    double excess = totalReceived - limit;
    
    if (excess <= 0) return;

    // Cap the current month
    await capEntityPaymentsToLimit(entityId);
    
    // 3. Create the new transaction
    DateTime newDate;
    String desc;
    
    final currentMonthDate = DateTime(_selectedYear, _selectedMonth);
    
    if (action == 'ADVANCE') {
      // Next Month
      newDate = DateTime(_selectedYear, _selectedMonth + 1, 1);
      desc = "Advance from ${DateFormat('MMMM').format(currentMonthDate)}";
    } else { // ARREARS
      // Previous Month
      newDate = DateTime(_selectedYear, _selectedMonth - 1, 1);
      desc = "Arrears paid in ${DateFormat('MMMM').format(currentMonthDate)}";
    }

    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: newDate,
      amount: excess,
      description: desc,
      sender: entity.aliases.firstOrNull ?? entity.name, // Best effort sender name
      receiver: "Me",
      isCredit: true,
      entityId: entity.id,
      mappedAmount: null, // Full amount counts for that month
    );

    await _dbService.addTransaction(newTx);
    await loadTransactions(); // Refresh
  }

  /// Returns a list of unique names (senders/receivers) that are NOT yet mapped to an entity
  List<String> getUnmappedNames() {
    final Set<String> mappedNames = {};
    for (var e in _entities) {
      mappedNames.addAll(e.aliases);
    }
    
    final Set<String> allNames = {};
    for (var tx in _transactions) {
      if (!tx.isCredit) continue; // Strictly Money In
      final name = tx.sender; 
      
      // Skip if Ignored
      if (_ignoredAliases.contains(name)) continue;

      allNames.add(name);
    }
    
    return allNames.difference(mappedNames).toList()..sort();
  }

  // Get list of Ignored Senders
  List<String> getIgnoredSenders() {
    // We only care about ignored names that actually appear in the current transaction list
    // akin to how getUnmappedNames works.
    final Set<String> ignoredInCurrentView = {};
    for (var tx in _transactions) {
      if (!tx.isCredit) continue;
      if (_ignoredAliases.contains(tx.sender)) {
        ignoredInCurrentView.add(tx.sender);
      }
    }
    return ignoredInCurrentView.toList()..sort();
  }

  // Un-ignore a sender (Restore to Inbox)
  Future<void> unignoreSender(String senderName) async {
    if (_ignoredAliases.contains(senderName)) {
      _ignoredAliases.remove(senderName);
      await _dbService.saveIgnoredAliases(_ignoredAliases);
      notifyListeners();
    }
  }
}
