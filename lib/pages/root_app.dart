import 'package:flutter/material.dart';
import 'package:gastos_compartidos/pages/home_page.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';

class RootApp extends StatefulWidget {
  @override
  _RootAppState createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  final ExpenseModel model = ExpenseModel(); // Inicializamos el modelo aquí

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomePage(model: model), // Pasamos el modelo a `HomePage`
    );
  }
}
