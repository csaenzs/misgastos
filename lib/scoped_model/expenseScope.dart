import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scoped_model/scoped_model.dart';

class ExpenseModel extends Model {
  final CollectionReference _expensesCollection = FirebaseFirestore.instance.collection('expenses');
  final CollectionReference _appDataCollection = FirebaseFirestore.instance.collection('app_data');

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
  void setInitValues() async {
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

      // Verificar datos cargados
      //print("Usuarios cargados: $_users");
      //print("Categorías cargadas: $_categories");
      //print("Gastos cargados: $_expenses");

      notifyListeners();
    } catch (e) {
      print("Error al inicializar valores: $e");
    }
  }

  // Método para agregar un nuevo gasto
  void addExpense(Map<String, dynamic> newExpenseEntry) async {
    try {
      DocumentReference docRef = await _expensesCollection.add(newExpenseEntry);
      String expenseId = docRef.id; // Obtener el ID generado por Firestore
      newExpenseEntry['id'] = expenseId; // Asignar el ID al gasto
      _expenses.insert(0, newExpenseEntry); // Insertar en la lista con el ID asignado
      notifyListeners();
    } catch (e) {
      print("Error al agregar un nuevo gasto: $e");
    }
  }

  // Método para eliminar un gasto según su índice
  void deleteExpense(int index) async {
    try {
      String expenseId = _expenses[index]['id'] ?? '';
      if (expenseId.isNotEmpty) {
        await _expensesCollection.doc(expenseId).delete();
      }
      _expenses.removeAt(index);
      notifyListeners();
    } catch (e) {
      print("Error al eliminar el gasto: $e");
    }
  }

  // Método para editar un gasto existente
  void editExpense(int index, Map<String, dynamic> updatedExpenseEntry) async {
    try {
      String expenseId = _expenses[index]['id'] ?? '';
      if (expenseId.isNotEmpty) {
        await _expensesCollection.doc(expenseId).update(updatedExpenseEntry);
      }
      _expenses[index] = updatedExpenseEntry;
      notifyListeners();
    } catch (e) {
      print("Error al editar el gasto: $e");
    }
  }

  // Método para configurar la lista de usuarios
  Future<void> setUsers(List<String> userList) async {
    try {
      await createAppDataIfNotExists(); // Asegurarse de que `app_data` exista antes de actualizar

      _users = userList;
      await _appDataCollection.doc('app_data').update({'users': _users});
      notifyListeners();
    } catch (e) {
      print("Error al configurar la lista de usuarios: $e");
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

  // Método para restablecer todos los datos
  void resetAll() async {
    _categories = [];
    _users = [];
    _expenses = [];
    await _appDataCollection.doc('app_data').delete();
    await _expensesCollection.get().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs) {
        ds.reference.delete();
      }
    });
    notifyListeners();
  }

  // Método para cargar nuevos datos desde una importación
  void newDataLoaded(List<String> users, List<Map<String, dynamic>> categories, List<Map<String, dynamic>> expenses) {
    _users = users;
    _categories = categories;
    _expenses = expenses;
    notifyListeners();
  }

  // Método para establecer el mes actual
  void setCurrentMonth(String month) async {
    _currentMonth = month;
    await _appDataCollection.doc('app_data').update({'currentMonth': _currentMonth});
    notifyListeners();
  }

  // Método para obtener el snapshot de `app_data`
  Future<DocumentSnapshot> getAppDataSnapshot() async {
    return await _appDataCollection.doc('app_data').get();
  }

  // Método para crear el documento `app_data` si no existe
  Future<void> createAppDataIfNotExists() async {
    DocumentSnapshot doc = await _appDataCollection.doc('app_data').get();
    if (!doc.exists) {
      await _appDataCollection.doc('app_data').set({
        'users': [],
        'categories': [],
        'currentMonth': '1',
      });
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

    //print("Datos de categoría calculados: $categoryShare");
    return categoryShare;
  }

  // Método para calcular la participación de los gastos por usuario con filtrado por mes
  Map<String, double> calculateUserShare({int? month}) {
    Map<String, double> userShare = {};
    List<Map<String, dynamic>> filteredExpenses = _filterExpensesByMonth(month);

    for (var user in _users) {
      userShare[user] = 0.0;  // Inicializar el valor del usuario en 0.0
    }

    for (var expense in filteredExpenses) {
      String user = expense['person'] ?? 'Unknown';
      double amount = _convertToDouble(expense['amount']);

      if (userShare.containsKey(user)) {
        userShare[user] = userShare[user]! + amount;
      }
    }

    //print("Datos de gastos por usuario calculados: $userShare");
    return userShare;
  }

  // Método para calcular la participación de los gastos por usuario y deuda (si aplica)
  Map<String, Map<String, double>> calculateShares({int? month}) {
    Map<String, Map<String, double>> shares = {};
    List<Map<String, dynamic>> filteredExpenses = _filterExpensesByMonth(month);

    for (var user in _users) {
      shares[user] = {
        "Gastos Totales": 0.0,
        "Deuda Total": 0.0,
        "Deuda Neta": 0.0,
      };
    }

    for (var expense in filteredExpenses) {
      String user = expense['person'] ?? 'Unknown';
      double amount = _convertToDouble(expense['amount']);

      if (shares.containsKey(user)) {
        shares[user]!["Gastos Totales"] = shares[user]!["Gastos Totales"]! + amount;
      }
    }

    //print("Datos de participación de gastos calculados: $shares");
    return shares;
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
}