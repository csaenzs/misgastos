
// daily_page.dart completo y funcional adaptado a Hive

import 'package:flutter/material.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gastos_compartidos/pages/newentry_page.dart';
import 'package:gastos_compartidos/models/expense_entry.dart';
import 'package:gastos_compartidos/models/income_entry.dart';

class DailyPage extends StatefulWidget {
  final ExpenseModel model;
  final Function callback;

  const DailyPage({Key? key, required this.model, required this.callback}) : super(key: key);

  @override
  _DailyPageState createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  DateTime? _selectedDate;
  String? _selectedCategory;
  String? _selectedMonth;
  bool _showIncomes = false;
  bool _isLoading = true;

  final List<Map<String, String>> _months = [
    {'value': 'all', 'label': 'Todos los meses'},
    {'value': '01', 'label': 'Enero'},
    {'value': '02', 'label': 'Febrero'},
    {'value': '03', 'label': 'Marzo'},
    {'value': '04', 'label': 'Abril'},
    {'value': '05', 'label': 'Mayo'},
    {'value': '06', 'label': 'Junio'},
    {'value': '07', 'label': 'Julio'},
    {'value': '08', 'label': 'Agosto'},
    {'value': '09', 'label': 'Septiembre'},
    {'value': '10', 'label': 'Octubre'},
    {'value': '11', 'label': 'Noviembre'},
    {'value': '12', 'label': 'Diciembre'},
  ];

@override
void initState() {
  super.initState();
  _selectedMonth = 'all';
  widget.model.addListener(_onModelChange); // 👈 importante
}

@override
void dispose() {
  widget.model.removeListener(_onModelChange); // 👈 evitar fugas de memoria
  super.dispose();
}

void _onModelChange() {
  setState(() {}); // 👈 esto sí actualiza cuando el modelo cambia
}



  List<dynamic> _filterRecordsByMonth(List<dynamic> records) {
    if (_selectedMonth == 'all') return records;
    return records.where((record) =>
      DateFormat('MM').format(record.date) == _selectedMonth).toList();
  }

  Map<String, double> _calculateFilteredTotals() {
    final expenses = _filterRecordsByMonth(widget.model.getExpenses);
    final incomes = _filterRecordsByMonth(widget.model.getIncomes);

    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalIncomes = incomes.fold(0.0, (sum, i) => sum + i.amount);
    return {
      'expenses': totalExpenses,
      'incomes': totalIncomes,
      'balance': totalIncomes - totalExpenses,
    };
  }

  @override
  Widget build(BuildContext context) {
    var records = _filterRecordsByMonth(
        _showIncomes ? widget.model.getIncomes : widget.model.getExpenses
      );

    if (_selectedDate != null) {
      records = records.where((r) => isSameDay(r.date, _selectedDate!)).toList();
    }

    if (_selectedCategory != null && _selectedCategory != 'Todos') {
      records = records.where((r) => r.category == _selectedCategory).toList();
    }
    

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildBalanceView(),
          _buildToggleButtons(),
          _buildFilterButtons(),
          Expanded(
            child: records.isEmpty && !_isLoading
              ? _noRecordDefault(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, i) => makeRecordTile(context, records[i]),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewEntryPage(
                context: context,
                callback: (String month) {
                  // actualiza el filtro también
                  _selectedMonth = month;
                  _selectedDate = null;
                },
              ),
            ),
          );
          // ⚠️ Agrega esto DESPUÉS de cerrar la pantalla
          await widget.model.setInitValues();
          setState(() {}); // fuerza reconstrucción con datos frescos
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: myColors[2][0],
      ),
    );
  }

  Widget makeRecordTile(BuildContext context, dynamic entry) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: 'COP ');

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(entry.item),
        subtitle: Text('${entry.category} - ${DateFormat('yyyy-MM-dd').format(entry.date)}'),
        trailing: Text(currency.format(entry.amount),
            style: TextStyle(color: _showIncomes ? Colors.green : Colors.red)),
        onLongPress: () => _confirmDelete(entry),
      ),
    );
  }

  void _confirmDelete(dynamic entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Deseas eliminar este registro?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Eliminar'),
            onPressed: () {
              if (_showIncomes) {
                widget.model.deleteIncome(entry);
              } else {
                widget.model.deleteExpense(entry);
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF2E7D32),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.only(top: 40, bottom: 8, left: 16, right: 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Registros Diarios",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "Visualiza y edita tus registros diarios",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceView() {
    var totals = _calculateFilteredTotals();
    final Color cardColor = const Color(0xFF388E3C).withOpacity(0.3);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF2E7D32)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8, 16.0, 8.0),
        child: Row(
          children: [
            _buildBalanceCard("Gastos", totals['expenses']!, Icons.arrow_downward, cardColor),
            const SizedBox(width: 8),
            _buildBalanceCard("Ingresos", totals['incomes']!, Icons.arrow_upward, cardColor),
            const SizedBox(width: 8),
            _buildBalanceCard(
              "Saldo",
              totals['balance']!,
              totals['balance']! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              cardColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String title, double amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "\$ ${NumberFormat("#,###", "es_CO").format(amount)}",
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Text("Gastos", textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, color: !_showIncomes ? Colors.blue : Colors.grey)),
          ),
          Expanded(
            child: Switch(
              value: _showIncomes,
              onChanged: (value) {
                setState(() {
                  _showIncomes = value;
                });
              },
            ),
          ),
          Expanded(
            child: Text("Ingresos", textAlign: TextAlign.start, style: TextStyle(fontWeight: FontWeight.bold, color: _showIncomes ? Colors.blue : Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.filter_alt),
              label: const Text("Mes"),
              onPressed: () => _showMonthPickerModal(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text("Fecha"),
              onPressed: () => _showDateFilterModal(),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2E7D32),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ListView(
            shrinkWrap: true,
            children: _months.map((month) {
              final isSelected = month['value'] == _selectedMonth;
              return ListTile(
                title: Text(month['label']!, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                tileColor: isSelected ? Colors.white.withOpacity(0.1) : null,
                onTap: () {
                  setState(() {
                    _selectedMonth = month['value'];
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showDateFilterModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return TableCalendar(
          locale: 'es_ES',
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.now(),
          focusedDay: _selectedDate ?? DateTime.now(),
          selectedDayPredicate: (day) => _selectedDate != null && isSameDay(day, _selectedDate!),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
            });
            Navigator.pop(context);
          },
          calendarFormat: CalendarFormat.month,
          headerStyle: const HeaderStyle(formatButtonVisible: false),
        );
      },
    );
  }

  Widget _noRecordDefault(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.info_outline, size: 80, color: Colors.blue),
          SizedBox(height: 20),
          Text("No se encontraron registros", style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
