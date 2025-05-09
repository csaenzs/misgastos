import 'package:hive/hive.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:intl/intl.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';

class ExpenseModel extends Model {
  List<ExpenseEntry> _expenses = [];
  List<IncomeEntry> _incomes = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _accounts = [];
  List<String> _users = [];
  String _currentMonth = '1';
  Map<String, Map<String, double>> _budgetCache = {};

  List<ExpenseEntry> get getExpenses => _expenses;
  List<IncomeEntry> get getIncomes => _incomes;
  List<Map<String, dynamic>> get getCategories => _categories;
  List<Map<String, dynamic>> get getIncomeCategories => _incomeCategories;
  List<Map<String, dynamic>> get getAccounts => _accounts;
  List<String> get getUsers => _users;
  String get getCurrentMonth => _currentMonth;

  ExpenseModel() {
    setInitValues();
  }

  Future<void> setInitValues() async {
    try {
      final expenseBox = Hive.box<ExpenseEntry>('expenses');
      final incomeBox = Hive.box<IncomeEntry>('incomes');
      final settingsBox = Hive.box('settings');

      _expenses = expenseBox.values.toList();
      _incomes = incomeBox.values.toList();

        final rawCategories = settingsBox.get('categories', defaultValue: []);
        _categories = List<Map<String, dynamic>>.from(
          (rawCategories as List).map((e) => Map<String, dynamic>.from(e))
        );

        final rawIncomeCategories = settingsBox.get('incomeCategories', defaultValue: []);
        _incomeCategories = List<Map<String, dynamic>>.from(
          (rawIncomeCategories as List).map((e) => Map<String, dynamic>.from(e))
        );

        final rawAccounts = settingsBox.get('accounts', defaultValue: []);
        _accounts = List<Map<String, dynamic>>.from(
          (rawAccounts as List).map((e) => Map<String, dynamic>.from(e))
        );
      _users = List<String>.from(settingsBox.get('users', defaultValue: []));
      _currentMonth = settingsBox.get('currentMonth', defaultValue: '1');

      notifyListeners();
    } catch (e) {
      print("Error al inicializar datos Hive: \$e");
    }
  }

  void migrarPresupuestosConFormatoIncorrecto() {
  final box = Hive.box('budgets');
  final keys = box.keys.where((k) => k.toString().startsWith('presupuesto_')).toList();

  for (var oldKey in keys) {
    final parts = oldKey.toString().split('_');
    if (parts.length >= 3) {
      final rawMonth = parts[1];
      final paddedMonth = rawMonth.padLeft(2, '0');
      if (rawMonth != paddedMonth) {
        final category = parts.sublist(2).join('_');
        final newKey = 'presupuesto_${paddedMonth}_$category';
        final amount = box.get(oldKey);
        box.put(newKey, amount);
        box.delete(oldKey);
      }
    }
  }
}


  void addExpense(ExpenseEntry entry) async {
    try {
      var box = Hive.box<ExpenseEntry>('expenses');
      await box.add(entry);
      _expenses.insert(0, entry);
      notifyListeners();
    } catch (e) {
      print("Error al agregar gasto: \$e");
    }
  }

  void deleteExpense(ExpenseEntry entry) async {
    try {
      await entry.delete();
      _expenses.remove(entry);
      notifyListeners();
    } catch (e) {
      print("Error al eliminar gasto: \$e");
    }
  }

  void addIncome(IncomeEntry entry) async {
    try {
      final box = Hive.box<IncomeEntry>('incomes');
      await box.add(entry);
      _incomes.insert(0, entry);
      notifyListeners();
    } catch (e) {
      print("Error al agregar ingreso: \$e");
    }
  }

  void deleteIncome(IncomeEntry entry) async {
    try {
      await entry.delete();
      _incomes.remove(entry);
      notifyListeners();
    } catch (e) {
      print("Error al eliminar ingreso: \$e");
    }
  }

  Map<String, double> calculateCategoryShare({int? month}) {
    Map<String, double> categoryShare = {};

    List<ExpenseEntry> filtered = month == null || month == 13
        ? _expenses
        : _expenses.where((e) => e.date.month == month).toList();

    for (var expense in filtered) {
      String category = expense.category;
      double amount = expense.amount;
      categoryShare[category] = (categoryShare[category] ?? 0) + amount;
    }

    return categoryShare;
  }

  Map<String, double> calculateIncomeCategoryShare({int? month}) {
    Map<String, double> incomeCategoryShare = {};

    List<IncomeEntry> filtered = month == null || month == 13
        ? _incomes
        : _incomes.where((e) => e.date.month == month).toList();

    for (var income in filtered) {
      String category = income.category;
      double amount = income.amount;
      incomeCategoryShare[category] = (incomeCategoryShare[category] ?? 0) + amount;
    }

    return incomeCategoryShare;
  }

  Map<String, double> calculateAccountTotals({required int month}) {
    Map<String, double> totals = {};

    for (var expense in _expenses) {
      if (month == 13 || expense.date.month == month) {
        String account = "Sin cuenta";
        double amount = expense.amount;
        totals[account] = (totals[account] ?? 0) - amount;
      }
    }

    for (var income in _incomes) {
      if (month == 13 || income.date.month == month) {
        String account = "Sin cuenta";
        double amount = income.amount;
        totals[account] = (totals[account] ?? 0) + amount;
      }
    }

    return totals;
  }

  double calculateTotalExpenseForCategory(String category, String month) {
    int monthInt = int.tryParse(month) ?? 0;
    return _expenses
        .where((e) => e.category == category && (monthInt == 0 || e.date.month == monthInt))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

Future<double> getBudget(String category, String month) async {
  try {
    // Normaliza el mes a 2 dígitos (ej: "5" → "05")
    month = month.padLeft(2, '0');

    if (_budgetCache.containsKey(month) && _budgetCache[month]!.containsKey(category)) {
      return _budgetCache[month]![category]!;
    }

    final budgetsBox = Hive.box('budgets');
    String key = 'presupuesto_${month}_$category';
    double amount = budgetsBox.get(key, defaultValue: 0.0);

    _budgetCache[month] ??= {};
    _budgetCache[month]![category] = amount;

    return amount;
  } catch (e) {
    print("Error al obtener el presupuesto: $e");
    return 0.0;
  }
}


Future<void> setBudget(String category, String month, double amount) async {
  try {
    final budgetsBox = Hive.box('budgets');
    final normalizedMonth = month.padLeft(2, '0'); // Asegura formato "05"
    String key = 'presupuesto_${normalizedMonth}_$category';
    await budgetsBox.put(key, amount);

    _budgetCache[normalizedMonth] ??= {};
    _budgetCache[normalizedMonth]![category] = amount;

    notifyListeners();
  } catch (e) {
    print("Error al establecer el presupuesto: $e");
  }
}



  Future<double> getRemainingBudget(String category, String month) async {
    double budget = await getBudget(category, month);
    double totalExpenses = calculateTotalExpenseForCategory(category, month);
    return budget - totalExpenses;
  }

  void setCurrentMonth(String month) {
    _currentMonth = month.padLeft(2, '0');
    Hive.box('settings').put('currentMonth', _currentMonth);
    notifyListeners();
  }

Future<void> setCategories(List<Map<String, dynamic>> categoryList) async {
  try {
    final settingsBox = Hive.box('settings');
    _categories = categoryList;
    await settingsBox.put('categories', categoryList);

    print("Categorías actuales en Hive: ${settingsBox.get('categories')}");

    notifyListeners();
  } catch (e) {
    print("Error al guardar categorías: $e");
  }
}


Future<void> setIncomeCategories(List<Map<String, dynamic>> categoryList) async {
  try {
    final settingsBox = Hive.box('settings');
    _incomeCategories = categoryList;
    await settingsBox.put('incomeCategories', categoryList);
    notifyListeners();
  } catch (e) {
    print("Error al guardar categorías de ingreso: $e");
  }
}

  Future<void> setAccounts(List<Map<String, dynamic>> accountList) async {
    try {
      final settingsBox = Hive.box('settings');
      _accounts = accountList;
      await settingsBox.put('accounts', accountList);
      notifyListeners();
    } catch (e) {
      print("Error al guardar cuentas: \$e");
    }
  }

  Future<void> setUsers(List<String> userList) async {
    try {
      final settingsBox = Hive.box('settings');
      _users = userList;
      await settingsBox.put('users', userList);
      notifyListeners();
    } catch (e) {
      print("Error al guardar usuarios: \$e");
    }
  }

Future<List<Map<String, dynamic>>> getBudgetsForMonth(String month) async {
  try {
    final box = Hive.box('budgets');
    List<Map<String, dynamic>> budgets = [];

    final normalizedMonth = month.padLeft(2, '0'); // Asegura formato "05"

    for (var key in box.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('presupuesto_${normalizedMonth}_')) {
        final parts = keyStr.split('_');
        final category = parts.sublist(2).join('_');
        final amountRaw = box.get(key, defaultValue: 0.0);
        final amount = (amountRaw is String)
            ? double.tryParse(amountRaw) ?? 0.0
            : (amountRaw as num).toDouble();

        budgets.add({
          'category': category,
          'amount': amount,
        });
      }
    }
    return budgets;
  } catch (e) {
    print('❌ Error al obtener presupuestos: $e');
    return [];
  }
}

List<String> getAllMonthsFromBudgets() {
  final box = Hive.box('budgets');
  final keys = box.keys.toList();
  final months = <String>{};

  for (var key in keys) {
    if (key.toString().startsWith('presupuesto_')) {
      final parts = key.toString().split('_');
      if (parts.length >= 3) {
        final monthRaw = parts[1];
        final monthFormatted = monthRaw.padLeft(2, '0');
        months.add(monthFormatted);
      }
    }
  }

  return months.toList()..sort();
}




}
