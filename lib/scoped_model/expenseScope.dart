import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:intl/intl.dart';

class ExpenseModel extends Model {
  final CollectionReference _expensesCollection = FirebaseFirestore.instance.collection('expenses');
  final CollectionReference _appDataCollection = FirebaseFirestore.instance.collection('app_data');
  final CollectionReference _budgetsCollection = FirebaseFirestore.instance.collection('budgets');

  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _categories = [];
  List<String> _users = [];
  String _currentMonth = '1';  // Inicializar el mes actual como enero (1)

  // Getters para los datos
  List<Map<String, dynamic>> get getExpenses => _expenses;
  List<Map<String, dynamic>> get getCategories => _categories;
  List<String> get getUsers => _users;
  String get getCurrentMonth => _currentMonth;

  ExpenseModel() {
    setInitValues();
  }

  // Método para inicializar valores desde Firestore
  Future<void> setInitValues() async {
    try {
      await createAppDataIfNotExists();  // Crear el documento si no existe

      DocumentSnapshot snapshot = await _appDataCollection.doc('app_data').get();
      if (snapshot.exists) {
        _users = List<String>.from(snapshot['users'] ?? []);
        _categories = List<Map<String, dynamic>>.from(snapshot['categories'] ?? []);
        _currentMonth = snapshot['currentMonth'] ?? '1';
      } else {
        _users = [];
        _categories = [];
        _currentMonth = '1';
      }

      QuerySnapshot expensesSnapshot = await _expensesCollection.get();
      if (expensesSnapshot.docs.isNotEmpty) {
        _expenses = expensesSnapshot.docs
            .map((e) => Map<String, dynamic>.from(e.data() as Map<String, dynamic>))
            .toList();
      } else {
        _expenses = [];
      }

      notifyListeners();
    } catch (e) {
      print("Error al inicializar valores: $e");
    }
  }

void addExpense(Map<String, dynamic> newExpenseEntry) async {
  try {
    String category = newExpenseEntry['category'];
    double amount = double.tryParse(newExpenseEntry['amount']) ?? 0.0;

    // Verificar que el monto sea válido
    if (amount <= 0) {
      print("Error: El monto ingresado no es válido.");
      return;
    }

    // Obtener el presupuesto actual y calcular los gastos actuales
    double budget = await getBudget(category, getCurrentMonth); // Obteniendo el presupuesto actual
    double totalExpenses = calculateTotalExpenseForCategory(category, getCurrentMonth); // Calculando los gastos actuales

    double remainingBudget = budget - totalExpenses;

    // Verificar los valores de presupuesto, gastos, y saldo restante
    print("Presupuesto para $category en mes $_currentMonth: $budget");
    print("Gastos totales para $category en mes $_currentMonth: $totalExpenses");
    print("Saldo restante para $category en mes $_currentMonth: $remainingBudget");

    // Realizar la validación de presupuesto con valores actualizados
    if (amount > remainingBudget) {
      print("Error: El gasto excede el presupuesto disponible. Presupuesto: $budget, Gastos: $totalExpenses, Resto: $remainingBudget");
      return;
    }

    // Si el gasto no excede el presupuesto, entonces agrega el gasto
    DocumentReference docRef = await _expensesCollection.add(newExpenseEntry);
    String expenseId = docRef.id; // Obtener el ID generado por Firestore
    newExpenseEntry['id'] = expenseId; // Asignar el ID al gasto
    _expenses.insert(0, newExpenseEntry); // Insertar en la lista con el ID asignado

    print("Gasto agregado correctamente con ID: $expenseId");

    notifyListeners();
  } catch (e) {
    print("Error al agregar un nuevo gasto: $e");
  }
}


  // Método para establecer el presupuesto de una categoría
  Future<void> setBudget(String category, String month, double amount) async {
    try {
      // Definir el ID del documento de presupuesto correctamente formateado
      String documentId = '$category-$month';

      // Utilizar la referencia correcta a la colección budgets
      await _budgetsCollection.doc(documentId).set({
        'category': category,
        'month': month,
        'amount': amount,
      });

      print("Presupuesto guardado: $category-$month -> $amount");
      notifyListeners();
    } catch (e) {
      print("Error al establecer el presupuesto: $e");
    }
  }

  Future<double> getBudget(String category, String month) async {
    try {
      String formattedMonth = month.padLeft(2, '0'); // Asegúrate de que el mes sea siempre de dos dígitos
      String documentId = '$category-$formattedMonth';

      // Consulta el presupuesto correspondiente
      DocumentSnapshot snapshot = await _budgetsCollection.doc(documentId).get();

      if (snapshot.exists) {
        double amount = snapshot['amount'] is int ? (snapshot['amount'] as int).toDouble() : snapshot['amount'];
        print("Presupuesto encontrado para $documentId: $amount");
        return amount;
      } else {
        print("No se encontró presupuesto para $documentId");
        return 0.0; // Si no hay presupuesto, devolver 0
      }
    } catch (e) {
      print("Error al obtener el presupuesto: $e");
      return 0.0;
    }
  }

  // Método para obtener el presupuesto restante de una categoría en un mes
  Future<double> getRemainingBudget(String category, String month) async {
    double budget = await getBudget(category, month);
    double totalExpenses = _expenses
        .where((expense) =>
            expense['category'] == category &&
            _getMonthFromDateString(expense['date']) == month)
        .fold(0.0, (sum, expense) => sum + _convertToDouble(expense['amount']));
    double remaining = budget - totalExpenses;
    print("Presupuesto obtenido para $category: $budget");
    print("Gastos totales para $category: $totalExpenses");
    print("Saldo restante para $category: $remaining");
    return remaining;
  }

  // Método para calcular el total de los gastos para una categoría y un mes específico
  double calculateTotalExpenseForCategory(String category, String month) {
    String formattedMonth = month.padLeft(2, '0'); // Asegúrate de que el mes tenga siempre dos dígitos

    return _expenses
        .where((expense) =>
            expense['category'] == category &&
            _getMonthFromDateString(expense['date']) == formattedMonth)
        .fold(0.0, (sum, expense) => sum + _convertToDouble(expense['amount']));
  }

  // Método para obtener el mes de una fecha en formato "dd-MM-yyyy"
  String _getMonthFromDateString(String date) {
    try {
      DateTime parsedDate = DateFormat('dd-MM-yyyy').parse(date);
      return parsedDate.month.toString();
    } catch (e) {
      print("Error al parsear la fecha: $e");
      return '';
    }
  }

  // Método para crear el documento `app_data` si no existe
  Future<void> createAppDataIfNotExists() async {
    DocumentSnapshot doc = await _appDataCollection.doc('app_data').get();
    if (!doc.exists) {
      // Crea el documento app_data sin incluir referencias a otras colecciones
      await _appDataCollection.doc('app_data').set({
        'users': [],
        'categories': [],
        'currentMonth': '1',
      });
    }
  }

  // Método para convertir a double los valores de amount
  double _convertToDouble(dynamic value) {
    try {
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is double) {
        return value;
      } else {
        return 0.0; // Valor predeterminado para datos no numéricos
      }
    } catch (e) {
      print("Error al convertir a double: $e");
      return 0.0;
    }
  }

  // Método para establecer el mes actual
  void setCurrentMonth(String month) async {
    _currentMonth = month.padLeft(2, '0'); // Asegúrate de que siempre sea de dos dígitos
    await _appDataCollection.doc('app_data').update({'currentMonth': _currentMonth});
    notifyListeners();
  }

  // Método para configurar la lista de Personas
  Future<void> setUsers(List<String> userList) async {
    try {
      await createAppDataIfNotExists(); // Asegurarse de que `app_data` exista antes de actualizar

      _users = userList;
      await _appDataCollection.doc('app_data').update({'users': _users});
      notifyListeners();
    } catch (e) {
      print("Error al configurar la lista de Personas: $e");
    }
  }

  // Método para configurar la lista de categorías
  Future<void> setCategories(List<Map<String, dynamic>> categoryList) async {
    try {
      await createAppDataIfNotExists(); // Asegurarse de que `app_data` exista antes de actualizar

      _categories = categoryList;
      await _appDataCollection.doc('app_data').update({'categories': _categories});
      notifyListeners();
    } catch (e) {
      print("Error al configurar la lista de categorías: $e");
    }
  }

  // Método para obtener el snapshot de `app_data`
  Future<DocumentSnapshot> getAppDataSnapshot() async {
    return await _appDataCollection.doc('app_data').get();
  }

  // Método para obtener todos los presupuestos para un mes específico
  Future<List<Map<String, dynamic>>> getBudgetsForMonth(String month) async {
    try {
      QuerySnapshot snapshot = await _budgetsCollection.where('month', isEqualTo: month).get();
      return snapshot.docs.map((e) => e.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error al obtener los presupuestos del mes: $e");
      return [];
    }
  }

  // Método para calcular la participación de los gastos por categoría con filtrado por mes
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

  // Método para calcular la participación de los gastos por Persona con filtrado por mes
  Map<String, double> calculateUserShare({int? month}) {
    Map<String, double> userShare = {};
    List<Map<String, dynamic>> filteredExpenses = _filterExpensesByMonth(month);

    for (var user in _users) {
      userShare[user] = 0.0;  // Inicializar el valor del Persona en 0.0
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

  // Método para filtrar los gastos por el mes especificado
  List<Map<String, dynamic>> _filterExpensesByMonth(int? month) {
    if (month == null || month == 13) {
      // Si no se pasa mes o se selecciona "Todos", no se filtra por mes
      return _expenses;
    } else {
      // Filtra los gastos por el mes especificado (formato dd-mm-yyyy)
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
  }
}
