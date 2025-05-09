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
  String _selectedMonth = '';

@override
void initState() {
  super.initState();
  _selectedMonth = widget.month.padLeft(2, '0'); // 👈 Importante aquí también
  _loadBudgetData();
}

void _loadBudgetData() async {
  await widget.model.setInitValues();
  final monthNormalized = _selectedMonth.padLeft(2, '0');
  setState(() {
    _budgetData = widget.model.getBudgetsForMonth(monthNormalized);
  });
}

  void _onMonthSelected(String newMonth) {
    setState(() {
      _selectedMonth = newMonth;
    });
    _loadBudgetData(); // 🔁 recarga presupuesto cuando cambia de mes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondary,
        title: Text(
          'Presupuesto para ${getMonthName(int.parse(_selectedMonth))}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildMonthSlider(),
          Expanded(child: _buildBudgetList()),
        ],
      ),
    );
  }

  Widget _buildMonthSlider() {
    List<String> availableMonths = widget.model.getAllMonthsFromBudgets();

    if (availableMonths.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay presupuestos registrados.'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: availableMonths.map((month) {
          bool isSelected = _selectedMonth == month;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? primary : Colors.grey.shade300,
                foregroundColor: isSelected ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () => _onMonthSelected(month),
              child: Text(
                getMonthName(int.parse(month)),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBudgetList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _budgetData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No hay presupuestos registrados para este mes.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final budget = snapshot.data![index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary.withOpacity(0.2),
                        child: Icon(Icons.category, color: primary),
                      ),
                      title: Text(
                        budget['category'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Presupuesto: COP ${NumberFormat("#,##0", "es_CO").format(budget['amount'])}',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: secondary, size: 18),
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
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
