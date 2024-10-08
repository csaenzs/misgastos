import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:select_form_field/select_form_field.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:scoped_model/scoped_model.dart';

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
  TextEditingController _dateEditor = TextEditingController(text: DateTime.now().toString());
  TextEditingController _categoryEditor = TextEditingController();
  TextEditingController _selectedUserAmountController = TextEditingController();

  Map<String, String> shareList = {};
  ExpenseModel? model;
  List<String> _users = [];
  bool showError = false;

  @override
  void initState() {
    super.initState();
    model = ScopedModel.of(widget.context);
    _users = model!.getUsers;
    shareList = {for (var u in model!.getUsers) u: "0.00"};

    // Inicializar los valores si estamos editando un registro existente
    if (widget.index != -999) {
      Map<String, dynamic> expense = model!.getExpenses[widget.index];
      _itemEditor.text = expense['item'];
      _personEditor.text = expense['person'];
      _amountEditor.text = expense['amount'];
      _categoryEditor.text = expense['category'];
      _dateEditor.text = expense['date'];
      shareList = Map<String, String>.from(expense['shareBy']);
    }

    // Inicializar el monto del usuario seleccionado
    _selectedUserAmountController.text = _amountEditor.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondary,
        title: const Text('Nuevo Gasto'),
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
                SelectFormField(
                  type: SelectFormFieldType.dropdown,
                  controller: _personEditor,
                  icon: const Icon(Icons.person_outline),
                  hintText: 'Gasto realizado por',
                  labelText: 'Gasto realizado por',
                  items: _users
                      .map((e) => {"value": e, "label": e})
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList(),
                  onChanged: (value) {
                    // Mostrar solo el usuario seleccionado en el campo de monto
                    setState(() {
                      _selectedUserAmountController.text = _amountEditor.text;
                    });
                  },
                  validator: (value) => value!.isEmpty ? "Campo requerido *" : null,
                ),
                const SizedBox(height: 9),
                TextFormField(
                  autovalidateMode: AutovalidateMode.disabled,
                  keyboardType: TextInputType.number,
                  controller: _amountEditor,
                  onChanged: (value) {
                    setState(() {
                      _selectedUserAmountController.text = value; // Actualizar el monto al usuario seleccionado
                    });
                  },
                  decoration: const InputDecoration(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    hintText: '¿Cuánto dinero se gastó?',
                    labelText: "Monto",
                  ),
                  validator: (val) {
                    if (val!.isEmpty) return "Campo requerido *";
                    if (double.tryParse(val) == null) {
                      return "Ingresa un número válido";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 9),
                TextFormField(
                  autovalidateMode: AutovalidateMode.disabled,
                  keyboardType: TextInputType.number,
                  controller: _selectedUserAmountController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.money),
                    hintText: 'Monto para el usuario seleccionado',
                    labelText: 'Monto asignado',
                  ),
                ),
                const SizedBox(height: 9),
                DateTimePicker(
                  controller: _dateEditor,
                  type: DateTimePickerType.date,
                  dateMask: 'd MMM, yyyy',
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  icon: const Icon(Icons.event),
                  dateLabelText: 'Fecha',
                  validator: (value) => value!.isEmpty ? "Campo requerido *" : null,
                ),
                const SizedBox(height: 9),
                SelectFormField(
                  type: SelectFormFieldType.dropdown,
                  controller: _categoryEditor,
                  icon: const Icon(Icons.category),
                  hintText: 'Categoría del gasto',
                  labelText: 'Categoría',
                  items: model!.getCategories
                      .map((e) => {"value": e['name'], "label": e['name']})
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList(),
                  validator: (value) => value!.isEmpty ? "Campo requerido *" : null,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: clearForm,
              child: const Text(
                "Guardar y añadir otro",
                style: TextStyle(fontSize: 18, color: Colors.deepPurple),
              ),
            ),
            TextButton(
              onPressed: () {
                bool saved = saveRecord();
                if (saved) {
                  widget.callback(0); // Ir a la página de log
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "Guardar",
                style: TextStyle(fontSize: 18, color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para guardar el registro del gasto en Firebase
  bool saveRecord() {
    if (formKey.currentState!.validate()) {
      Map<String, dynamic> data = {
        "date": DateFormat('dd-MM-yyyy').format(DateFormat('yyyy-MM-dd').parse(_dateEditor.text)),
        "person": _personEditor.text,
        "item": _itemEditor.text,
        "category": _categoryEditor.text,
        "amount": _amountEditor.text,
        "shareBy": { _personEditor.text: _selectedUserAmountController.text } // Asignar monto solo al usuario seleccionado
      };
      model!.addExpense(data); // Llamada al método de Firestore para guardar el gasto
      return true;
    }
    return false;
  }

  // Función para limpiar el formulario
  void clearForm() {
    bool saved = saveRecord();
    if (!saved) return;
    formKey.currentState!.reset();
    _itemEditor.clear();
    _amountEditor.clear();
    _selectedUserAmountController.clear();
    setState(() {});
  }
}
