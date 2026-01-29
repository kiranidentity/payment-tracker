import 'package:hive/hive.dart';

part 'entity_model.g.dart';

@HiveType(typeId: 1)
class EntityModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double? monthlyLimit; // Expected monthly spend/earning

  @HiveField(3)
  final List<String> aliases; // List of UPI IDs/Names that verify to this entity
  
  @HiveField(4)
  final List<double> amountAliases; // List of amounts that verify to this entity

  EntityModel({
    required this.id,
    required this.name,
    this.monthlyLimit,
    this.aliases = const [],
    this.amountAliases = const [],
  });
}
