import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:intl/intl.dart';

class ExpenseModel extends Model {
  final CollectionReference _expensesCollection = FirebaseFirestore.instance.collection('expenses');
  final CollectionReference _incomesCollection = FirebaseFirestore.instance.collection('incomes');
  final CollectionReference _appDataCollection = FirebaseFirestore.instance.collection('app_data');
  final CollectionReference _budgetsCollection = FirebaseFirestore.instance.collection('budgets');

  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _incomes = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _accounts = [];
  List<String> _users = [];
  String _currentMonth = '1';
  Map<String, Map<String, double>> _budgetCache = {};

  // Getters
  List<Map<String, dynamic>> get getExpenses => _expenses;
  List<Map<String, dynamic>> get getIncomes => _incomes;
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
      await createAppDataIfNotExists();

      final results = await Future.wait([
        _appDataCollection.doc('app_data').get(),
        _expensesCollection.get(),
        _incomesCollection.get(),
      ]);

      final appDataSnapshot = results[0] as DocumentSnapshot;
      final expensesSnapshot = results[1] as QuerySnapshot;
      final incomesSnapshot = results[2] as QuerySnapshot;

      if (appDataSnapshot.exists) {
        final data = appDataSnapshot.data() as Map<String, dynamic>;
        _users = List<String>.from(data['users'] ?? []);
        _categories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
        _incomeCategories = List<Map<String, dynamic>>.from(data['incomeCategories'] ?? []);
        _accounts = List<Map<String, dynamic>>.from(data['accounts'] ?? []);
        _currentMonth = data['currentMonth'] ?? '1';
      } else {
        _users = [];
        _categories = [];
        _incomeCategories = [];
        _accounts = [];
        _currentMonth = '1';
      }

      _expenses = expensesSnapshot.docs.map((e) {
        var data = Map<String, dynamic>.from(e.data() as Map<String, dynamic>);
        data['id'] = e.id;
        return data;
      }).toList();

      _incomes = incomesSnapshot.docs.map((e) {
        var data = Map<String, dynamic>.from(e.data() as Map<String, dynamic>);
        data['id'] = e.id;
        return data;
      }).toList();

      notifyListeners();
    } catch (e) {
      print("Error al inicializar valores: $e");
    }
  }

  Future<Map<String, double>> getAllBudgetsForMonth(String month) async {
    try {
      month = month.padLeft(2, '0');
      
      if (_budgetCache.containsKey(month)) {
        return _budgetCache[month]!;
      }

      Map<String, double> budgets = {};
      
      QuerySnapshot snapshot = await _budgetsCollection
          .where('month', isEqualTo: month)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        budgets[data['category']] = data['amount'] is int 
            ? (data['amount'] as int).toDouble() 
            : data['amount'];
      }

      for (var category in _categories) {
        String categoryName = category['name'];
        if (!budgets.containsKey(categoryName)) {
          budgets[categoryName] = 0.0;
        }
      }

      _budgetCache[month] = budgets;
      
      return budgets;
    } catch (e) {
      print("Error al obtener los presupuestos del mes: $e");
      return {};
    }
  }

    // Agregar estos métodos en la clase ExpenseModel

Future<List<Map<String, dynamic>>> getLatestRecords({
    required bool isIncome,
    required String month,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = isIncome ? _incomesCollection : _expensesCollection;
      
      query = query.orderBy('date', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();
      List<Map<String, dynamic>> records = snapshot.docs.map((doc) {
        var data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id;
        return data;
      }).toList();

      if (month != 'all') {
        records = records.where((record) {
          String recordMonth = record['date'].split('-')[1];
          return recordMonth == month;
        }).toList();
      }

      records.sort((a, b) {
        DateTime dateA = _parseDate(a['date']);
        DateTime dateB = _parseDate(b['date']);
        return dateB.compareTo(dateA);
      });

      return records.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      // Convertir fecha del formato "dd-MM-yyyy" a DateTime
      List<String> parts = dateStr.split('-');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
      return DateTime.now(); // Fecha por defecto si hay error
    } catch (e) {
      print("Error parsing date: $e");
      return DateTime.now();
    }
  }

    // Método para obtener el último documento para paginación
Future<DocumentSnapshot?> getLastDocument(List<Map<String, dynamic>> records, bool isIncome) async {
    if (records.isEmpty) return null;
    
    // Ordenar los records por fecha para asegurar que obtenemos el último correcto
    records.sort((a, b) {
      DateTime dateA = _parseDate(a['date']);
      DateTime dateB = _parseDate(b['date']);
      return dateB.compareTo(dateA);
    });
    
    String lastId = records.last['id'];
    CollectionReference collection = isIncome ? _incomesCollection : _expensesCollection;
    
    return await collection.doc(lastId).get();
  }

void addExpense(Map<String, dynamic> newExpenseEntry) async {
    try {
      String category = newExpenseEntry['category'];
      double amount = double.tryParse(newExpenseEntry['amount']) ?? 0.0;

      if (amount <= 0) {
        print("Error: El monto ingresado no es válido.");
        return;
      }

      // Obtenemos la información del presupuesto (para tenerla actualizada)
      double budget = await getBudget(category, _currentMonth);
      double totalExpenses = calculateTotalExpenseForCategory(category, _currentMonth);
      double remainingBudget = budget - totalExpenses;

      // Registramos el gasto sin importar si excede el presupuesto
      DocumentReference docRef = await _expensesCollection.add(newExpenseEntry);
      newExpenseEntry['id'] = docRef.id;
      _expenses.insert(0, newExpenseEntry);

      notifyListeners();
    } catch (e) {
      print("Error al agregar un nuevo gasto: $e");
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      if (expenseId.isNotEmpty) {
        await _expensesCollection.doc(expenseId).delete();
        _expenses.removeWhere((expense) => expense['id'] == expenseId);
        notifyListeners();
      }
    } catch (e) {
      print("Error al eliminar el gasto: $e");
    }
  }

  void addIncome(Map<String, dynamic> newIncomeEntry) async {
    try {
      DocumentReference docRef = await _incomesCollection.add(newIncomeEntry);
      newIncomeEntry['id'] = docRef.id;
      _incomes.insert(0, newIncomeEntry);
      notifyListeners();
    } catch (e) {
      print("Error al agregar un nuevo ingreso: $e");
    }
  }

  Future<void> deleteIncome(String incomeId) async {
    try {
      if (incomeId.isNotEmpty) {
        await _incomesCollection.doc(incomeId).delete();
        _incomes.removeWhere((income) => income['id'] == incomeId);
        notifyListeners();
      }
    } catch (e) {
      print("Error al eliminar el ingreso: $e");
    }
  }

  Future<void> setAccounts(List<Map<String, dynamic>> accountList) async {
    try {
      await createAppDataIfNotExists();
      _accounts = accountList;
      await _appDataCollection.doc('app_data').update({'accounts': _accounts});
      notifyListeners();
    } catch (e) {
      print("Error al configurar las cuentas: $e");
    }
  }

  Future<void> deleteAccount(String accountName) async {
    try {
      _accounts.removeWhere((account) => account['name'] == accountName);
      await _appDataCollection.doc('app_data').update({'accounts': _accounts});
      notifyListeners();
    } catch (e) {
      print("Error al eliminar la cuenta: $e");
    }
  }

  Future<void> setIncomeCategories(List<Map<String, dynamic>> categoryList) async {
    try {
      await createAppDataIfNotExists();
      _incomeCategories = categoryList;
      await _appDataCollection.doc('app_data').update({'incomeCategories': _incomeCategories});
      notifyListeners();
    } catch (e) {
      print("Error al configurar las categorías de ingresos: $e");
    }
  }

  Map<String, double> calculateIncomeCategoryShare({int? month}) {
    Map<String, double> incomeCategoryShare = {};
    List<Map<String, dynamic>> filteredIncomes = _filterIncomesByMonth(month);

    for (var income in filteredIncomes) {
      String category = income['category'] ?? 'Other';
      double amount = _convertToDouble(income['amount']);

      if (incomeCategoryShare.containsKey(category)) {
        incomeCategoryShare[category] = incomeCategoryShare[category]! + amount;
      } else {
        incomeCategoryShare[category] = amount;
      }
    }

    return incomeCategoryShare;
  }

  List<Map<String, dynamic>> _filterIncomesByMonth(int? month) {
    if (month == null || month == 13) {
      return _incomes;
    }
    return _incomes.where((income) {
      final date = income['date'] ?? '';
      final parts = date.split('-');
      if (parts.length >= 2) {
        final incomeMonth = int.tryParse(parts[1]);
        return incomeMonth == month;
      }
      return false;
    }).toList();
  }

  Future<void> setBudget(String category, String month, double amount) async {
    try {
      month = month.padLeft(2, '0');
      String documentId = '$category-$month';

      await _budgetsCollection.doc(documentId).set({
        'category': category,
        'month': month,
        'amount': amount,
      });

      if (_budgetCache.containsKey(month)) {
        _budgetCache[month]![category] = amount;
      }

      notifyListeners();
    } catch (e) {
      print("Error al establecer el presupuesto: $e");
      throw e;
    }
  }

  Future<double> getBudget(String category, String month) async {
    try {
      month = month.padLeft(2, '0');

      if (_budgetCache.containsKey(month) && _budgetCache[month]!.containsKey(category)) {
        return _budgetCache[month]![category] ?? 0.0;
      }

      String documentId = '$category-$month';
      DocumentSnapshot snapshot = await _budgetsCollection.doc(documentId).get();

      if (snapshot.exists) {
        double amount = snapshot['amount'] is int 
            ? (snapshot['amount'] as int).toDouble() 
            : snapshot['amount'];
        
        if (!_budgetCache.containsKey(month)) {
          _budgetCache[month] = {};
        }
        _budgetCache[month]![category] = amount;
        
        return amount;
      }
      return 0.0;
    } catch (e) {
      print("Error al obtener el presupuesto: $e");
      return 0.0;
    }
  }

  Future<double> getRemainingBudget(String category, String month) async {
    double budget = await getBudget(category, month);
    double totalExpenses = calculateTotalExpenseForCategory(category, month);
    return budget - totalExpenses;
  }

  double calculateTotalExpenseForCategory(String category, String month) {
    String formattedMonth = month.padLeft(2, '0');
    return _expenses
        .where((expense) =>
            expense['category'] == category &&
            _getMonthFromDateString(expense['date']) == formattedMonth)
        .fold(0.0, (sum, expense) => sum + _convertToDouble(expense['amount']));
  }

  String _getMonthFromDateString(String date) {
    try {
      DateTime parsedDate = DateFormat('dd-MM-yyyy').parse(date);
      return parsedDate.month.toString().padLeft(2, '0');
    } catch (e) {
      print("Error al parsear la fecha: $e");
      return '';
    }
  }

  Future<void> createAppDataIfNotExists() async {
    DocumentSnapshot doc = await _appDataCollection.doc('app_data').get();
    if (!doc.exists) {
      await _appDataCollection.doc('app_data').set({
        'users': [],
        'categories': [],
        'incomeCategories': [],
        'accounts': [],
        'currentMonth': '1',
      });
    } else {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> updates = {};

      if (!data.containsKey('incomeCategories')) updates['incomeCategories'] = [];
      if (!data.containsKey('categories')) updates['categories'] = [];
      if (!data.containsKey('accounts')) updates['accounts'] = [];
      if (!data.containsKey('users')) updates['users'] = [];
      if (!data.containsKey('currentMonth')) updates['currentMonth'] = '1';

      if (updates.isNotEmpty) {
        await _appDataCollection.doc('app_data').update(updates);
      }
    }
  }

  double _convertToDouble(dynamic value) {
    try {
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    } catch (e) {
      print("Error al convertir a double: $e");
      return 0.0;
    }
  }

  void setCurrentMonth(String month) async {
    _currentMonth = month.padLeft(2, '0');
    _budgetCache.clear();
    await _appDataCollection.doc('app_data').update({'currentMonth': _currentMonth});
    notifyListeners();
  }

  Future<void> setUsers(List<String> userList) async {
    try {
      await createAppDataIfNotExists();
      _users = userList;
      await _appDataCollection.doc('app_data').update({'users': _users});
      notifyListeners();
    } catch (e) {
      print("Error al configurar la lista de Personas: $e");
    }
  }

  Future<void> setCategories(List<Map<String, dynamic>> categoryList) async {
    try {
      await createAppDataIfNotExists();
      _categories = categoryList;
      await _appDataCollection.doc('app_data').update({'categories': _categories});
      notifyListeners();
    } catch (e) {
      print("Error al configurar la lista de categorías: $e");
    }
  }

  Future<DocumentSnapshot> getAppDataSnapshot() async {
    return await _appDataCollection.doc('app_data').get();
  }

  Future<List<Map<String, dynamic>>> getBudgetsForMonth(String month) async {
    try {
      QuerySnapshot snapshot = await _budgetsCollection.where('month', isEqualTo: month).get();
      return snapshot.docs.map((e) => e.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error al obtener los presupuestos del mes: $e");
      return [];
    }
  }

Map<String, double> calculateCategoryShare({int? month}) {
    Map<String, double> categoryShare = {};
    List<Map<String, dynamic>> filteredExpenses = _filterExpensesByMonth(month);

    for (var expense in filteredExpenses) {
      String category = expense['category'] ?? 'Other';
      double amount = _convertToDouble(expense['amount']);

      if (categoryShare.containsKey(category)) {
        categoryShare[category] = categoryShare[category]! + amount;
      } else {
        categoryShare[category] = amount;
      }
    }

    return categoryShare;
  }

  Map<String, double> calculateUserShare({int? month}) {
    Map<String, double> userShare = {};
    List<Map<String, dynamic>> filteredExpenses = _filterExpensesByMonth(month);

    for (var user in _users) {
      userShare[user] = 0.0;
    }

    for (var expense in filteredExpenses) {
      String user = expense['person'] ?? 'Unknown';
      double amount = _convertToDouble(expense['amount']);

      if (userShare.containsKey(user)) {
        userShare[user] = userShare[user]! + amount;
      }
    }

    return userShare;
  }

  List<Map<String, dynamic>> _filterExpensesByMonth(int? month) {
    if (month == null || month == 13) {
      return _expenses;
    }

    return _expenses.where((expense) {
      final date = expense['date'] ?? '';
      final parts = date.split('-');
      if (parts.length >= 2) {
        final expenseMonth = int.tryParse(parts[1]);
        return expenseMonth == month;
      }
      return false;
    }).toList();
  }

  Future<List<String>> getMonthsWithBudgets() async {
    try {
      QuerySnapshot snapshot = await _budgetsCollection.get();
      Set<String> months = {};

      for (var document in snapshot.docs) {
        String month = document['month'];
        months.add(month);
      }

      return months.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    } catch (e) {
      print("Error al obtener los meses con presupuestos: $e");
      return [];
    }
  }
}