import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String sender; // UPI ID or Name

  @HiveField(5)
  final String receiver; // UPI ID or Name

  @HiveField(6)
  final bool isCredit; // true if money came IN, false if money went OUT

  @HiveField(7)
  String? entityId; // Manually mapped category/entity

  @HiveField(8)
  double? mappedAmount; // If set, only this portion counts as the fee. Null = full amount.

  TransactionModel({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.sender,
    required this.receiver,
    required this.isCredit,
    this.entityId,
    this.mappedAmount,
  });

  // Helper to sanitize names (remove newlines and extra spaces) for display
  String get cleanSender => sender.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  String get cleanReceiver => receiver.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}
