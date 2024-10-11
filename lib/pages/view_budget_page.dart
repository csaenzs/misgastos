import 'package:flutter/material.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:intl/intl.dart';

class ViewBudgetPage extends StatefulWidget {
  final ExpenseModel model;
  final String month;

  const ViewBudgetPage({Key? key, required this.model, required this.month}) : super(key: key);

  @override
  _ViewBudgetPageState createState() => _ViewBudgetPageState();
}

class _ViewBudgetPageState extends State<ViewBudgetPage> {
  late Future<List<Map<String, dynamic>>> _budgetData;

  @override
  void initState() {
    super.initState();
    _budgetData = widget.model.getBudgetsForMonth(widget.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondary,
        title: Text('Presupuesto para ${getMonthName(int.parse(widget.month))}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _budgetData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay presupuestos registrados para este mes.'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final budget = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      title: Text(budget['category'], style: const TextStyle(fontSize: 18)),
                      subtitle: Text(
                        'Presupuesto: COP ${NumberFormat("#,##0", "es_CO").format(budget['amount'])}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }

  String getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}