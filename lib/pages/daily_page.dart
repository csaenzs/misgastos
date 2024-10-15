import 'package:flutter/material.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gastos_compartidos/pages/newentry_page.dart';

class DailyPage extends StatefulWidget {
  final ExpenseModel model;
  final Function callback;

  const DailyPage({Key? key, required this.model, required this.callback}) : super(key: key);

  @override
  _DailyPageState createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChange); // Escucha los cambios en el modelo
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChange);
    super.dispose();
  }

  void _onModelChange() {
    setState(() {}); // Actualiza la vista automáticamente cuando el modelo cambia
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    List<Map<String, dynamic>> _expenses = widget.model.getExpenses;

    // Aplicar filtro por fecha si hay un rango seleccionado
    if (_startDate != null && _endDate != null) {
      _expenses = _expenses.where((expense) {
        DateTime expenseDate = DateFormat('dd-MM-yyyy').parse(expense['date']);
        return expenseDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            expenseDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Aplicar filtro por categoría si hay una categoría seleccionada
    if (_selectedCategory != null && _selectedCategory != 'Todos') {
      _expenses = _expenses.where((expense) => expense['category'] == _selectedCategory).toList();
    }

    // Ordenar los gastos en orden descendente (último primero)
    _expenses.sort((a, b) {
      DateTime dateA = DateFormat('dd-MM-yyyy').parse(a['date']);
      DateTime dateB = DateFormat('dd-MM-yyyy').parse(b['date']);
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterButton(),
          _expenses.isEmpty
              ? Expanded(child: _noExpenseDefault(context))
              : Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _expenses.length,
                    itemBuilder: (context, i) => makeRecordTile(size, _expenses[i]),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navegar a la página para agregar un nuevo gasto
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewEntryPage(
                callback: widget.callback,
                context: context,
              ),
            ),
          );
          // Actualizar los valores después de agregar un nuevo gasto
          widget.model.setInitValues();
        },
        child: const Icon(
          Icons.add,
          color: Colors.white, // Aquí se especifica el color del ícono a blanco
        ),
        backgroundColor: const Color.fromARGB(255, 0, 191, 13),
        tooltip: 'Agregar nuevo gasto',
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: myColors[1],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Gastos Diarios",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Visualiza y edita tus gastos del día",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.filter_alt),
        label: const Text("Aplicar Filtros"),
        onPressed: () {
          _showFilterModal();
        },
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TableCalendar(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.now(),
                  focusedDay: _startDate ?? DateTime.now(),
                  selectedDayPredicate: (day) {
                    if (_startDate != null && _endDate != null) {
                      return day.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                          day.isBefore(_endDate!.add(const Duration(days: 1)));
                    }
                    return false;
                  },
                  onDaySelected: (selectedDay, _) {
                    setState(() {
                      if (_startDate == null || (_startDate != null && _endDate != null)) {
                        _startDate = selectedDay;
                        _endDate = null;
                      } else {
                        _endDate = selectedDay.isAfter(_startDate!) ? selectedDay : _startDate;
                        _startDate = selectedDay.isAfter(_startDate!) ? _startDate : selectedDay;
                      }
                    });
                  },
                  calendarStyle: CalendarStyle(
                    isTodayHighlighted: true,
                    selectedDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text('Seleccionar Categoría'),
                  isExpanded: true,
                  items: [
                    'Todos',
                    ...widget.model.getCategories.map((category) => category['name']),
                  ].map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar el BottomSheet
                    setState(() {}); // Actualizar la pantalla
                  },
                  child: const Text("Aplicar Filtros"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _selectedCategory = 'Todos'; // Restablecer filtros
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Eliminar Filtros"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _noExpenseDefault(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            size: 80,
            color: Color.fromARGB(255, 3, 61, 162),
          ),
          const SizedBox(height: 20),
          const Text(
            "No se encontraron registros de gastos",
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextButton(
            child: const Text(
              "Agregar nuevos registros",
              style: TextStyle(fontSize: 18, color: Colors.blue),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewEntryPage(
                    callback: widget.callback,
                    context: context,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget makeRecordTile(Size size, Map<String, dynamic> record) {
    final formatCurrency = NumberFormat('#,##0', 'es_CO');
    String? expenseId = record['id'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      record['item'],
                      style: TextStyle(
                        fontSize: 17,
                        color: black,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      record['category'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    "COP ${formatCurrency.format(double.parse(record['amount']))}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    record['date'],
                    style: TextStyle(
                      fontSize: 12,
                      color: black.withOpacity(0.5),
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  if (expenseId != null && expenseId.isNotEmpty) {
                    _confirmDeleteExpense(expenseId);
                  } else {
                    print("Error: No se puede eliminar un gasto sin ID.");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteExpense(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Eliminar Gasto"),
          content: const Text("¿Estás seguro de que deseas eliminar este gasto?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Eliminar"),
              onPressed: () {
                widget.model.deleteExpense(id);
                Navigator.of(context).pop();
                widget.model.setInitValues();
              },
            ),
          ],
        );
      },
    );
  }
}
