import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';

Future<String> importData(String filePath) async {
  try {
    final status = await Permission.storage.request();
    if (!status.isGranted) return "Permiso denegado para acceder a archivos.";

    final file = File(filePath);
    if (!file.existsSync()) return "Archivo no encontrado.";

    final jsonContent = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonContent);

    final expenseBox = Hive.box<ExpenseEntry>('expenses');
    final incomeBox = Hive.box<IncomeEntry>('incomes');
    final settingsBox = Hive.box('settings');
    final budgetsBox = Hive.box('budgets');

    // Cargar Expenses
    for (var exp in data["expenses"]) {
      expenseBox.add(ExpenseEntry.fromMap(Map<String, dynamic>.from(exp)));
    }

    // Cargar Incomes
    for (var inc in data["incomes"]) {
      incomeBox.add(IncomeEntry.fromMap(Map<String, dynamic>.from(inc)));
    }

    // Configuración
    settingsBox.put('categories', data["categories"] ?? []);
    settingsBox.put('incomeCategories', data["incomeCategories"] ?? []);
    settingsBox.put('accounts', data["accounts"] ?? []);
    settingsBox.put('users', data["users"] ?? []);

    // Presupuestos
    for (var budget in data["budgets"]) {
      final month = budget["month"].toString().padLeft(2, '0');
      final category = budget["category"];
      final amount = double.tryParse(budget["amount"].toString()) ?? 0.0;
      budgetsBox.put('presupuesto_${month}_$category', amount);
    }

    return "✅ Importación completada correctamente.";
  } catch (e) {
    return "❌ Error en la importación: $e";
  }
}
