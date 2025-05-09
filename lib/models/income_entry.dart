import 'package:hive/hive.dart';

part 'income_entry.g.dart';

@HiveType(typeId: 1)
class IncomeEntry extends HiveObject {
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

  IncomeEntry({
    required this.item,
    required this.category,
    required this.amount,
    required this.date,
    required this.person,
    required this.account,
  });

    // ✅ Método para exportar
  Map<String, dynamic> toMap() {
    return {
      'item': item,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'person': person,
      'account': account,
    };
  }

  factory IncomeEntry.fromMap(Map<String, dynamic> map) {
  return IncomeEntry(
    item: map['item'] ?? '',
    category: map['category'] ?? '',
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date']),
    person: map['person'] ?? '',
    account: map['account'] ?? '',
  );
}

}
