// lib/utils/export_utils.dart

import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';

class ExportUtils {
  static Future<String> exportData() async {
    try {
      final expenses = Hive.box<ExpenseEntry>('expenses').values.toList();
      final incomes = Hive.box<IncomeEntry>('incomes').values.toList();
      final settingsBox = Hive.box('settings');
      final budgetsBox = Hive.box('budgets');

      final data = {
        "expenses": expenses.map((e) => e.toMap()).toList(),
        "incomes": incomes.map((i) => i.toMap()).toList(),
        "categories": settingsBox.get('categories', defaultValue: []),
        "incomeCategories": settingsBox.get('incomeCategories', defaultValue: []),
        "accounts": settingsBox.get('accounts', defaultValue: []),
        "users": settingsBox.get('users', defaultValue: []),
        "budgets": budgetsBox.keys.map((key) {
          final parts = key.toString().split('_');
          if (parts.length >= 3) {
            return {
              "month": parts[1],
              "category": parts.sublist(2).join('_'),
              "amount": budgetsBox.get(key)
            };
          }
          return null;
        }).where((e) => e != null).toList(),
      };

      final jsonContent = jsonEncode(data);


      final status = await Permission.manageExternalStorage.request();

      if (!status.isGranted) {
        openAppSettings(); // Esto abrirá la configuración para otorgar permisos
        return "Permiso denegado. Por favor, habilita el permiso en Configuración.";
      }

      final directory = await getExternalStorageDirectory();
      final filePath = "${directory!.path}/backup_misgastos.json";
      final file = File(filePath);
      await file.writeAsString(jsonContent);

      return "Exportación exitosa. Archivo guardado en: $filePath";
    } catch (e) {
      return "❌ Error en la exportación: $e";
    }
  }
}
