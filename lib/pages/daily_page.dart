import 'package:flutter/material.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gastos_compartidos/pages/newentry_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<Map<String, dynamic>> _currentRecords = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMoreRecords = true;

  final List<Map<String, dynamic>> _months = [
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
    _loadInitialRecords();
    widget.model.addListener(_onModelChange);
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChange);
    super.dispose();
  }

  void _onModelChange() {
    _loadInitialRecords();
  }

  //Parte 2 - Métodos de carga de registros

Future<void> _loadInitialRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var records = await widget.model.getLatestRecords(
        isIncome: _showIncomes,
        month: _selectedMonth ?? 'all',
        limit: 20,
      );

      if (records.isNotEmpty) {
        _lastDocument = await widget.model.getLastDocument(records, _showIncomes);
        _hasMoreRecords = records.length == 20;
      } else {
        _hasMoreRecords = false;
      }

      setState(() {
        _currentRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMoreRecords = false;
      });
    }
  }

  Future<void> _loadMoreRecords() async {
    if (!_hasMoreRecords || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var newRecords = await widget.model.getLatestRecords(
        isIncome: _showIncomes,
        month: _selectedMonth ?? 'all',
        limit: 20,
        lastDocument: _lastDocument,
      );

      if (newRecords.isNotEmpty) {
        _lastDocument = await widget.model.getLastDocument(newRecords, _showIncomes);
        _hasMoreRecords = newRecords.length == 20;
        
        setState(() {
          _currentRecords.addAll(newRecords);
        });
      } else {
        _hasMoreRecords = false;
      }
    } catch (e) {
      print("Error loading more records: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterRecordsByMonth(List<Map<String, dynamic>> records) {
    if (_selectedMonth == 'all') return records;
    
    return records.where((record) {
      DateTime recordDate = DateFormat('dd-MM-yyyy').parse(record['date']);
      return recordDate.month.toString().padLeft(2, '0') == _selectedMonth;
    }).toList();
  }

  //Parte 3 - Métodos de construcción de la UI:

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
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
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF2E7D32),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _showMonthPickerModal(context),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _months.firstWhere((m) => m['value'] == _selectedMonth)['label'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildBalanceCard(
                    "Gastos",
                    totals['expenses']!,
                    Icons.arrow_downward,
                    cardColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBalanceCard(
                    "Ingresos",
                    totals['incomes']!,
                    Icons.arrow_upward,
                    cardColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBalanceCard(
                    "Saldo",
                    totals['balance']!,
                    totals['balance']! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    cardColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, double amount, IconData icon, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "\$ ${NumberFormat("#,###", "es_CO").format(amount)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  //Parte 4 - Métodos de filtros y toggles

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
                  _loadInitialRecords();
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

  Map<String, double> _calculateFilteredTotals() {
    var filteredExpenses = _filterRecordsByMonth(widget.model.getExpenses);
    var filteredIncomes = _filterRecordsByMonth(widget.model.getIncomes);

    double totalExpenses = filteredExpenses.fold(
      0.0, (sum, item) => sum + (double.tryParse(item['amount']) ?? 0.0));
    double totalIncomes = filteredIncomes.fold(
      0.0, (sum, item) => sum + (double.tryParse(item['amount']) ?? 0.0));
    double balance = totalIncomes - totalExpenses;

    return {
      'expenses': totalExpenses,
      'incomes': totalIncomes,
      'balance': balance,
    };
  }

  //Parte 5 - Modales de filtros

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _months.length,
                  itemBuilder: (context, index) {
                    final month = _months[index];
                    final isSelected = month['value'] == _selectedMonth;
                    return ListTile(
                      title: Text(
                        month['label'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      tileColor: isSelected ? Colors.white.withOpacity(0.1) : null,
                      onTap: () {
                        setState(() {
                          _selectedMonth = month['value'];
                        });
                        Navigator.pop(context);
                        _loadInitialRecords();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
                        Navigator.pop(context);
                        _loadInitialRecords();
                      },
                      child: const Text("Aplicar Filtro"),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'Todos';
                        });
                        Navigator.pop(context);
                        _loadInitialRecords();
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
                  selectedDayPredicate: (day) => _selectedDate != null && isSameDay(day, _selectedDate!),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
                    });
                    Navigator.pop(context);
                    _loadInitialRecords();
                  },
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadInitialRecords();
                  },
                  child: const Text("Aplicar Filtro"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                    });
                    Navigator.pop(context);
                    _loadInitialRecords();
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

//Parte 6 - Método build principal y widgets de visualización

@override
  Widget build(BuildContext context) {
    var records = _currentRecords;    
    // Aplicar filtros si están activos
    if (_selectedDate != null) {
      records = records.where((record) {
        DateTime recordDate = DateFormat('dd-MM-yyyy').parse(record['date']);
        return isSameDay(recordDate, _selectedDate!);
      }).toList();      
    }

    if (_selectedCategory != null && _selectedCategory != 'Todos') {
      records = records.where((record) => record['category'] == _selectedCategory).toList();      
    }
     

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildBalanceView(),
          _buildToggleButtons(),
          _buildFilterButtons(),
          records.isEmpty && !_isLoading
              ? Expanded(child: _noRecordDefault(context))
              : Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!_isLoading && 
                        _hasMoreRecords &&
                        scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                      _loadMoreRecords();
                    }
                    return true;
                  },
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    // Modificamos el itemCount para no mostrar el indicador si no hay más registros
                    itemCount: records.length + (_hasMoreRecords && records.length >= 20 ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == records.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return makeRecordTile(MediaQuery.of(context).size, records[i]);
                    },
                  ),
                ),
              )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewEntryPage(
                callback: widget.callback,
                context: context,
              ),
            ),
          );
          _loadInitialRecords();
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: myColors[2][0],
        tooltip: 'Agregar nuevo registro',
      ),
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
                _loadInitialRecords();
              },
            ),
          ],
        );
      },
    );
  }
}