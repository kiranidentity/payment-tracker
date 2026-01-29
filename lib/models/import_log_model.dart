import 'package:hive/hive.dart';

part 'import_log_model.g.dart';

@HiveType(typeId: 2)
class ImportLogModel extends HiveObject {
  @HiveField(0)
  final String fileName;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final int transactionCount;

  @HiveField(3)
  final String status; // "Success", "Failed", "Empty"

  ImportLogModel({
    required this.fileName,
    required this.timestamp,
    required this.transactionCount,
    required this.status,
  });
}
