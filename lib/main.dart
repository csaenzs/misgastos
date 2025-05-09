import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'scoped_model/expenseScope.dart';
import 'models/expense_entry.dart';
import 'models/income_entry.dart';
import 'pages/root_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseEntryAdapter());
  Hive.registerAdapter(IncomeEntryAdapter());

  await Hive.openBox<ExpenseEntry>('expenses');
  await Hive.openBox<IncomeEntry>('incomes');
  await Hive.openBox('settings');
  await Hive.openBox('budgets');

  limpiarPresupuestosMalGuardados(); // 🧹 Ejecuta limpieza de claves mal formateadas

  final ExpenseModel myExpenseModel = ExpenseModel();
  await myExpenseModel.setInitValues(); // 🔧 Espera la carga de Hive
  myExpenseModel.migrarPresupuestosConFormatoIncorrecto();

  runApp(MyApp(myExpenseModel));
}

void limpiarPresupuestosMalGuardados() {
  final box = Hive.box('budgets');
  final keysToFix = box.keys.where((k) => k.toString().startsWith('presupuesto_5_')).toList();

  for (var oldKey in keysToFix) {
    final parts = oldKey.toString().split('_');
    if (parts.length >= 3) {
      final category = parts.sublist(2).join('_');
      final amount = box.get(oldKey);
      final newKey = 'presupuesto_05_$category';
      box.put(newKey, amount); // copiar al nuevo formato
      box.delete(oldKey);      // eliminar el anterior
    }
  }
}

class MyApp extends StatelessWidget {
  final ExpenseModel myExpenseModel;

  const MyApp(this.myExpenseModel, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedModel<ExpenseModel>(
      model: myExpenseModel,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RootApp(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}
