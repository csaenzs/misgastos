import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:table_calendar/table_calendar.dart';

class NewEntryPage extends StatefulWidget {
  final Function callback;
  final BuildContext context;
  final int index;

  const NewEntryPage({Key? key, required this.callback, required this.context, this.index = -999}) : super(key: key);

  @override
  _NewEntryPageState createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController _itemEditor = TextEditingController();
  TextEditingController _personEditor = TextEditingController();
  TextEditingController _amountEditor = TextEditingController();
  TextEditingController _dateEditor = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  TextEditingController _categoryEditor = TextEditingController();

  ExpenseModel? model;
  List<String> _users = [];
  bool _isAmountExceeding = false;

  // Variables relacionadas al presupuesto
  String _selectedCategory = '';
  double _budgetAmount = 0.0;
  double _remainingBudget = 0.0;

  @override
  void initState() {
    super.initState();
    model = ScopedModel.of(widget.context);
    _users = model!.getUsers;

    // Inicializar los valores si estamos editando un registro existente
    if (widget.index != -999) {
      Map<String, dynamic> expense = model!.getExpenses[widget.index];
      _itemEditor.text = expense['item'];
      _personEditor.text = expense['person'];
      _amountEditor.text = expense['amount'];
      _categoryEditor.text = expense['category'];
      _dateEditor.text = expense['date'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        title: const Text('Nuevo Gasto'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: myColors[1],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  autovalidateMode: AutovalidateMode.disabled,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.shopping_cart_outlined),
                    hintText: '¿En qué gastaste el dinero?',
                    labelText: 'Descripción del Gasto',
                  ),
                  controller: _itemEditor,
                  validator: (value) => value!.isEmpty ? "Campo requerido *" : null,
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  value: _personEditor.text.isNotEmpty ? _personEditor.text : null,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person_outline),
                    hintText: 'Gasto realizado por',
                    labelText: 'Gasto realizado por',
                  ),
                  items: _users.map((String user) {
                    return DropdownMenuItem<String>(
                      value: user,
                      child: Text(user),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _personEditor.text = value ?? '';
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? "Campo requerido *" : null,
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.category),
                    hintText: 'Categoría del gasto',
                    labelText: 'Categoría',
                  ),
                  items: model!.getCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['name'],
                      child: Text(category['name']),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null && value.isNotEmpty) {
                      _selectedCategory = value;
                      await _loadRemainingBudget();
                      setState(() {});
                    }
                  },
                  validator: (value) => value == null || value.isEmpty ? "Campo requerido *" : null,
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _amountEditor,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    hintText: '¿Cuánto dinero se gastó?',
                    labelText: "Monto",
                    errorText: _isAmountExceeding ? 'El gasto excede el presupuesto disponible' : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isAmountExceeding = (double.tryParse(value) ?? 0.0) > _remainingBudget;
                    });
                  },
                  validator: (val) {
                    if (val!.isEmpty) return "Campo requerido *";
                    if (double.tryParse(val) == null) {
                      return "Ingresa un número válido";
                    }
                    if (_isAmountExceeding) {
                      return "El monto excede el presupuesto disponible";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _dateEditor,
                  readOnly: true,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.event),
                    hintText: 'Selecciona la fecha',
                    labelText: 'Fecha',
                  ),
                  onTap: () => _showDatePicker(context),
                  validator: (value) => value!.isEmpty ? "Campo requerido *" : null,
                ),
                const SizedBox(height: 20),
                if (_selectedCategory.isNotEmpty) _buildBudgetInfoCard(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: clearForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Guardar y añadir otro",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        bool saved = await saveRecordWithBudgetCheck();
                        if (saved) {
                          widget.callback(0); // Ir a la página de log
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Guardar",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Mostrar el calendario en un modal ajustado
  void _showDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecciona la fecha',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TableCalendar(
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  focusedDay: DateTime.now(),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _dateEditor.text = DateFormat('yyyy-MM-dd').format(selectedDay);
                    });
                    Navigator.of(context).pop(); // Cierra el modal después de seleccionar la fecha
                  },
                  calendarFormat: CalendarFormat.month,
                  locale: 'es_ES', // Configura el idioma del calendario a español
                  availableCalendarFormats: const {CalendarFormat.month: 'Mensual'},
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false, // Oculta el botón de formato
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  child: const Text('Cerrar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadRemainingBudget() async {
    try {
      String selectedMonth = DateFormat('MM').format(DateFormat('yyyy-MM-dd').parse(_dateEditor.text));
      double budget = await model!.getBudget(_selectedCategory, selectedMonth);
      double totalExpenses = model!.calculateTotalExpenseForCategory(_selectedCategory, selectedMonth);

      setState(() {
        _budgetAmount = budget;
        _remainingBudget = budget - totalExpenses;
        _isAmountExceeding = (double.tryParse(_amountEditor.text) ?? 0.0) > _remainingBudget;
      });

      print("Presupuesto obtenido para $_selectedCategory en mes $selectedMonth: $_budgetAmount");
      print("Gastos totales para $_selectedCategory en mes $selectedMonth: $totalExpenses");
      print("Saldo restante para $_selectedCategory en mes $selectedMonth: $_remainingBudget");
    } catch (e) {
      print("Error al cargar el presupuesto: $e");
    }
  }

  Future<bool> saveRecordWithBudgetCheck() async {
    await _loadRemainingBudget();
    if (formKey.currentState!.validate()) {
      double amount = double.tryParse(_amountEditor.text) ?? 0.0;

      if (amount > _remainingBudget) {
        print("Error: El gasto excede el presupuesto disponible. Presupuesto: $_budgetAmount, Gastos: ${_budgetAmount - _remainingBudget}, Resto: $_remainingBudget");
        return false;
      }

      Map<String, dynamic> data = {
        "date": DateFormat('dd-MM-yyyy').format(DateFormat('yyyy-MM-dd').parse(_dateEditor.text)),
        "person": _personEditor.text,
        "item": _itemEditor.text,
        "category": _selectedCategory,
        "amount": _amountEditor.text,
      };
      model!.addExpense(data);
      return true;
    }
    return false;
  }

  void clearForm() async {
    await saveRecordWithBudgetCheck();
    formKey.currentState!.reset();
    _itemEditor.clear();
    _amountEditor.clear();
    setState(() {});
  }

  Widget _buildBudgetInfoCard() {
    return Card(
      elevation: 5.0,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: grey.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presupuesto: COP ${NumberFormat('#,##0.00', 'es_CO').format(_budgetAmount)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Saldo Restante: COP ${NumberFormat('#,##0.00', 'es_CO').format(_remainingBudget)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
