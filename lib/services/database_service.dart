import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/entity_model.dart';
import '../models/import_log_model.dart'; 

class DatabaseService {
  static const String transactionBoxName = 'transactions';
  static const String entityBoxName = 'entities';
  static const String settingsBoxName = 'settings'; // For ignored list
  static const String importLogBoxName = 'import_logs';

  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Box<TransactionModel>? _transactionBox;
  Box<EntityModel>? _entityBox;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(EntityModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ImportLogModelAdapter());
    }
    
    _transactionBox = await Hive.openBox<TransactionModel>(transactionBoxName);
    _entityBox = await Hive.openBox<EntityModel>(entityBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox<ImportLogModel>(importLogBoxName);
  }

  // Transaction Operations
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionBox!.put(transaction.id, transaction);
  }

  List<TransactionModel> getAllTransactions() {
    return _transactionBox!.values.toList();
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionBox!.delete(id);
  }
  
  Future<void> clearAllTransactions() async {
    await _transactionBox!.clear();
  }

  // Entity Operations
  Future<void> addEntity(EntityModel entity) async {
    await _entityBox!.put(entity.id, entity);
  }

  List<EntityModel> getAllEntities() {
    return _entityBox!.values.toList();
  }
  
  EntityModel? getEntity(String id) {
    return _entityBox!.get(id);
  }
  
  Future<void> updateEntity(EntityModel entity) async {
    await entity.save();
  }

  Future<void> deleteEntity(String id) async {
    await _entityBox!.delete(id);
  }

  // --- Import Logs ---
  List<ImportLogModel> getImportLogs() {
    final box = Hive.box<ImportLogModel>(importLogBoxName);
    return box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addImportLog(ImportLogModel log) async {
    final box = Hive.box<ImportLogModel>(importLogBoxName);
    await box.add(log);
  }

  // --- Settings (Ignored Aliases) ---
  List<String> getIgnoredAliases() {
    final box = Hive.box(settingsBoxName);
    return List<String>.from(box.get('ignored_aliases', defaultValue: <String>[]));
  }

  Future<void> saveIgnoredAliases(List<String> aliases) async {
    final box = Hive.box(settingsBoxName);
    await box.put('ignored_aliases', aliases);
  }

  // --- Intro Status ---
  bool hasSeenIntro() {
    final box = Hive.box(settingsBoxName);
    return box.get('seen_intro', defaultValue: false);
  }

  Future<void> markIntroSeen() async {
    final box = Hive.box(settingsBoxName);
    await box.put('seen_intro', true);
  }

  Future<void> resetIntro() async {
    final box = Hive.box(settingsBoxName);
    await box.put('seen_intro', false);
  }
}
