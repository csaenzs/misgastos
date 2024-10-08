import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:gastos_compartidos/pages/root_app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado correctamente');
  } catch (e) {
    print('Error al inicializar Firebase: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ExpenseModel myExpenseModel = ExpenseModel();

  @override
  Widget build(BuildContext context) {
    return ScopedModel<ExpenseModel>(
      model: myExpenseModel,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RootApp(), // Cargar `RootApp` como vista inicial
      ),
    );
  }
}
