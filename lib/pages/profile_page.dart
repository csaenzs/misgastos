import 'package:flutter/material.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:gastos_compartidos/pages/addUser_page.dart';
import 'package:gastos_compartidos/pages/view_budget_page.dart';
import 'package:dropdown_search/dropdown_search.dart';

class ProfilePage extends StatefulWidget {
  final ExpenseModel model;

  const ProfilePage({Key? key, required this.model}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _selectedMonth = DateTime.now().month.toString(); // Mes actual

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildOptions()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Perfil de Usuario",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Selecciona el mes en el cual vas a organizar tus gastos y presupuesto",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              itemBuilder: (context, index) {
                String month = (index + 1).toString();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMonth = month;
                    });
                    widget.model.setCurrentMonth(month);
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: _selectedMonth == month
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedMonth == month
                            ? Colors.deepPurple
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      getMonthAbbreviation(int.parse(month)),
                      style: TextStyle(
                        color: _selectedMonth == month
                            ? Colors.deepPurple
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildOptionTile(
            context, "Crear Presupuesto", Icons.add_chart, _showCreateBudgetModal),
        _buildOptionTile(context, "Ver Presupuesto", Icons.pie_chart,
            _navigateToViewBudgetPage),
        _buildOptionTile(
            context, "Personas", Icons.person_outline, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddUserCat(context: context, type: 0),
            ),
          );
        }),
        _buildOptionTile(
            context, "Categorías de Gastos", Icons.category_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddUserCat(context: context, type: 1),
            ),
          );
        }),
        _buildOptionTile(
            context, "Categorías de Ingresos", Icons.monetization_on_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddUserCat(context: context, type: 2),
            ),
          );
        }),
        _buildOptionTile(
            context, "Cuentas", Icons.account_balance_wallet_outlined, () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddUserCat(context: context, type: 3), // type 3 para cuentas
                ),
            );
        }),
      ],
    );
  }

  Widget _buildOptionTile(
      BuildContext context, String title, IconData icon, Function onTap) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.deepPurpleAccent),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        onTap: () => onTap(),
      ),
    );
  }

  void _showCreateBudgetModal() async {
    // Obtén la lista actualizada de categorías desde el modelo
    await widget.model.setInitValues(); // Esto actualiza la lista de categorías

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String _selectedCategory = '';
        double _budgetAmount = 0.0;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: Text(
                  'Crear Presupuesto para ${getMonthName(int.parse(_selectedMonth))}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    DropdownSearch<String>(
                      items: widget.model.getCategories
                          .map((category) => category['name'] as String)
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value ?? '';
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Seleccionar Categoría',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      popupProps: PopupProps.dialog(
                        showSearchBox: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Monto del Presupuesto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        _budgetAmount = double.tryParse(value) ?? 0.0;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Guardar'),
                  onPressed: () async {
                    if (_selectedCategory.isNotEmpty && _budgetAmount > 0) {
                      await widget.model.setBudget(
                          _selectedCategory, _selectedMonth, _budgetAmount);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Presupuesto guardado correctamente'),
                      ));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateAccountModal() {
    String newAccount = '';
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text('Crear Cuenta'),
          content: TextFormField(
            decoration: InputDecoration(
              labelText: 'Nombre de la Cuenta',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              newAccount = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text('Guardar'),
              onPressed: () async {
                if (newAccount.isNotEmpty) {
                  List<Map<String, dynamic>> updatedAccounts =
                      List.from(widget.model.getAccounts)
                        ..add({'name': newAccount});
                  await widget.model.setAccounts(updatedAccounts);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Cuenta guardada correctamente'),
                  ));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToViewBudgetPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewBudgetPage(model: widget.model, month: _selectedMonth),
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

  String getMonthAbbreviation(int month) {
    const monthsAbbreviation = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return monthsAbbreviation[month - 1];
  }
}
