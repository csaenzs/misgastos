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
  DateTime? _selectedDate;
  String? _selectedCategory;
  bool _showIncomes = false; // Variable para alternar entre gastos e ingresos

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
    List<Map<String, dynamic>> records = _showIncomes ? widget.model.getIncomes : widget.model.getExpenses;

    // Aplicar filtro por fecha si hay una fecha seleccionada
    if (_selectedDate != null) {
      records = records.where((record) {
        DateTime recordDate = DateFormat('dd-MM-yyyy').parse(record['date']);
        return isSameDay(recordDate, _selectedDate!);
      }).toList();
    }

    // Aplicar filtro por categoría si hay una categoría seleccionada
    if (_selectedCategory != null && _selectedCategory != 'Todos') {
      records = records.where((record) => record['category'] == _selectedCategory).toList();
    }

    // Ordenar los registros en orden descendente (último primero)
    records.sort((a, b) {
      DateTime dateA = DateFormat('dd-MM-yyyy').parse(a['date']);
      DateTime dateB = DateFormat('dd-MM-yyyy').parse(b['date']);
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildBalanceView(), // Nueva vista para mostrar el balance
          _buildToggleButtons(),
          _buildFilterButtons(),
          records.isEmpty
              ? Expanded(child: _noRecordDefault(context))
              : Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: records.length,
                    itemBuilder: (context, i) => makeRecordTile(size, records[i]),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navegar a la página para agregar un nuevo registro
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewEntryPage(
                callback: widget.callback,
                context: context,
              ),
            ),
          );
          // Actualizar los valores después de agregar un nuevo registro
          widget.model.setInitValues();
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: myColors[2][0], // Usa un color de la lista myColors
        tooltip: 'Agregar nuevo registro',
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
            "Registros Diarios",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Visualiza y edita tus registros diarios",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceView() {
    double totalExpenses = widget.model.getExpenses.fold(
        0.0, (sum, item) => sum + (double.tryParse(item['amount']) ?? 0.0));
    double totalIncomes = widget.model.getIncomes.fold(
        0.0, (sum, item) => sum + (double.tryParse(item['amount']) ?? 0.0));
    double balance = totalIncomes - totalExpenses;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: myColors[1][0],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBalanceColumn("Gastos", totalExpenses, Colors.red),
          _buildBalanceColumn("Ingresos", totalIncomes, Colors.green),
          _buildBalanceColumn("Saldo", balance, balance >= 0 ? Colors.green : Colors.red),
        ],
      ),
    );
  }

  Widget _buildBalanceColumn(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          NumberFormat.currency(locale: 'es_CO', symbol: '').format(amount),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Text(
              "Gastos",
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: !_showIncomes ? Colors.blue : Colors.grey,
              ),
            ),
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
            child: Text(
              "Ingresos",
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _showIncomes ? Colors.blue : Colors.grey,
              ),
            ),
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
              label: const Text("Filtrar por Categoría"),
              onPressed: () {
                _showCategoryFilterModal();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text("Filtrar por Fecha"),
              onPressed: () {
                _showDateFilterModal();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilterModal() {
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
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateModal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: _selectedCategory,
                      hint: const Text('Seleccionar Categoría'),
                      isExpanded: true,
                      items: [
                        'Todos',
                        ...(_showIncomes
                            ? widget.model.getIncomeCategories
                            : widget.model.getCategories)
                            .map((category) => category['name']),
                      ].map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateModal(() {
                          _selectedCategory = value;
                        });
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
                      child: const Text("Aplicar Filtro"),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'Todos'; // Restablecer filtro
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Eliminar Filtro"),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDateFilterModal() {
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
                  focusedDay: _selectedDate ?? DateTime.now(),
                  onDaySelected: (selectedDay, _) {
                    setState(() {
                      _selectedDate = selectedDay;
                    });
                    Navigator.of(context).pop(); // Cierra el modal después de seleccionar la fecha
                  },
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar el BottomSheet
                    setState(() {}); // Actualizar la pantalla
                  },
                  child: const Text("Aplicar Filtro"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null; // Restablecer filtro de fecha
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Eliminar Filtro"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _noRecordDefault(BuildContext context) {
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
            "No se encontraron registros",
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
    String? recordId = record['id'];

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
                  if (recordId != null && recordId.isNotEmpty) {
                    _confirmDeleteRecord(recordId);
                  } else {
                    print("Error: No se puede eliminar un registro sin ID.");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRecord(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Eliminar Registro"),
          content: const Text("¿Estás seguro de que deseas eliminar este registro?"),
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
                if (_showIncomes) {
                  widget.model.deleteIncome(id);
                } else {
                  widget.model.deleteExpense(id);
                }
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
