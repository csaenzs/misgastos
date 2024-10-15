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
  List<String> _accounts = [];
  String? _selectedAccount;
  String? _selectedPerson;
  String? _selectedCategory;
  bool _isAmountExceeding = false;

  // Variables relacionadas al presupuesto
  double _budgetAmount = 0.0;
  double _remainingBudget = 0.0;
  bool _isIncome = false;

  @override
  void initState() {
    super.initState();
    model = ScopedModel.of(widget.context);
    _users = model!.getUsers;
    _accounts = model!.getAccounts.map((e) => e['name'] as String).toList();

    if (widget.index != -999) {
      Map<String, dynamic> entry = _isIncome ? model!.getIncomes[widget.index] : model!.getExpenses[widget.index];
      _itemEditor.text = entry['item'];
      _personEditor.text = entry['person'];
      _amountEditor.text = entry['amount'];
      _categoryEditor.text = entry['category'];
      _dateEditor.text = entry['date'];
      _selectedAccount = entry['account'] ?? '';
      _selectedPerson = entry['person'] ?? '';
      _selectedCategory = entry['category'] ?? '';
      _isIncome = entry['isIncome'] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        title: const Text('Nuevo Registro'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Gasto"),
                    Switch(
                      value: _isIncome,
                      onChanged: (value) {
                        setState(() {
                          _isIncome = value;
                          _selectedCategory = null;
                        });
                      },
                    ),
                    const Text("Ingreso"),
                  ],
                ),
                const SizedBox(height: 9),
                TextFormField(
                  autovalidateMode: AutovalidateMode.disabled,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.shopping_cart_outlined),
                    hintText: '¿En qué gastaste o recibiste el dinero?',
                    labelText: 'Descripción',
                  ),
                  controller: _itemEditor,
                  validator: (value) => value!.isEmpty ? "Campo requerido *" : null,
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  value: _selectedPerson,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person_outline),
                    hintText: 'Realizado por',
                    labelText: 'Realizado por',
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'Agregar nuevo',
                      child: Text('Agregar nuevo'),
                    ),
                    ..._users.map((String user) => DropdownMenuItem<String>(
                          value: user,
                          child: Text(user),
                        )),
                  ],
                  onChanged: (value) {
                    if (value == 'Agregar nuevo') {
                      _showAddDialog('Persona', (newValue) {
                        setState(() {
                          _users = [..._users, newValue];
                          model!.setUsers(_users);
                          _selectedPerson = newValue;
                        });
                      });
                    } else {
                      setState(() {
                        _selectedPerson = value;
                      });
                    }
                  },
                  validator: (value) => value == null || value.isEmpty ? "Campo requerido *" : null,
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  value: (_selectedCategory != null &&
                          model != null &&
                          (_isIncome ? model!.getIncomeCategories : model!.getCategories)
                              .any((cat) => cat['name'] == _selectedCategory))
                      ? _selectedCategory
                      : null,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.category),
                    hintText: 'Categoría',
                    labelText: 'Categoría',
                  ),
                  items: _isIncome
                      ? model!.getIncomeCategories
                          .map((category) => DropdownMenuItem<String>(
                                value: category['name'],
                                child: Text(category['name']),
                              ))
                          .toList()
                      : model!.getCategories
                          .map((category) => DropdownMenuItem<String>(
                                value: category['name'],
                                child: Text(category['name']),
                              ))
                          .toList(),
                  onChanged: (value) async {
                    if (value != null && value.isNotEmpty) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      await _loadRemainingBudget();
                    }
                  },
                  validator: (value) => value == null || value.isEmpty ? "Campo requerido *" : null,
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  value: _selectedAccount,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.account_balance),
                    hintText: 'Cuenta',
                    labelText: 'Cuenta',
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'Agregar nueva',
                      child: Text('Agregar nueva'),
                    ),
                    ..._accounts.map((String account) => DropdownMenuItem<String>(
                          value: account,
                          child: Text(account),
                        )),
                  ],
                  onChanged: (value) {
                    if (value == 'Agregar nueva') {
                      _showAddDialog('Cuenta', (newValue) {
                        setState(() {
                          _accounts = [..._accounts, newValue];
                          model!.setAccounts([...model!.getAccounts, {'name': newValue}]);
                          _selectedAccount = newValue;
                        });
                      });
                    } else {
                      setState(() {
                        _selectedAccount = value;
                      });
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
                    hintText: _isIncome ? '¿Cuánto dinero se recibió?' : '¿Cuánto dinero se gastó?',
                    labelText: "Monto",
                    errorText: _isAmountExceeding ? 'El gasto excede el presupuesto disponible' : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isAmountExceeding = !_isIncome && (double.tryParse(value) ?? 0.0) > _remainingBudget;
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
                if (!_isIncome && _selectedCategory != null && _selectedCategory!.isNotEmpty) _buildBudgetInfoCard(),
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
                          widget.callback(0);
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

  // Método para mostrar un diálogo para agregar un nuevo elemento (Persona o Cuenta)
  void _showAddDialog(String type, Function(String) onAdd) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar nueva $type'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Ingrese el nombre de la nueva $type'),
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Agregar'),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onAdd(controller.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadRemainingBudget() async {
    if (_isIncome) {
      return;
    }
    try {
      String selectedMonth = DateFormat('MM').format(DateFormat('yyyy-MM-dd').parse(_dateEditor.text));
      double budget = await model!.getBudget(_selectedCategory!, selectedMonth);
      double totalExpenses = model!.calculateTotalExpenseForCategory(_selectedCategory!, selectedMonth);

      setState(() {
        _budgetAmount = budget;
        _remainingBudget = budget - totalExpenses;
        _isAmountExceeding = (double.tryParse(_amountEditor.text) ?? 0.0) > _remainingBudget;
      });
    } catch (e) {
      print("Error al cargar el presupuesto: $e");
    }
  }

  Future<void> _showDatePicker(BuildContext context) async {
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
                    Navigator.of(context).pop();
                  },
                  calendarFormat: CalendarFormat.month,
                  locale: 'es_ES',
                  availableCalendarFormats: const {CalendarFormat.month: 'Mensual'},
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
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

  Future<bool> saveRecordWithBudgetCheck() async {
    await _loadRemainingBudget();
    if (formKey.currentState!.validate()) {
      double amount = double.tryParse(_amountEditor.text) ?? 0.0;

      if (!_isIncome && amount > _remainingBudget) {
        return false;
      }

      Map<String, dynamic> data = {
        "date": DateFormat('dd-MM-yyyy').format(DateFormat('yyyy-MM-dd').parse(_dateEditor.text)),
        "person": _selectedPerson ?? '',
        "item": _itemEditor.text,
        "category": _selectedCategory ?? '',
        "amount": _amountEditor.text,
        "account": _selectedAccount ?? '',
        "isIncome": _isIncome,
      };
      if (_isIncome) {
        model!.addIncome(data);
      } else {
        model!.addExpense(data);
      }
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