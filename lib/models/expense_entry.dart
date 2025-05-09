import 'package:hive/hive.dart';

part 'expense_entry.g.dart';

@HiveType(typeId: 0)
class ExpenseEntry extends HiveObject {
  @HiveField(0)
  String item;

  @HiveField(1)
  String category;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String person;

  @HiveField(5)
  String account;

  ExpenseEntry({
    required this.item,
    required this.category,
    required this.amount,
    required this.date,
    required this.person,
    required this.account,
  });
}
