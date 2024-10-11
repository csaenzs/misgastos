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
          colors: myColors[1],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Perfil de Usuario",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            dropdownColor: Colors.white,
            value: _selectedMonth,
            iconEnabledColor: Colors.white,
            underline: Container(height: 2, color: Colors.white),
            items: List.generate(12, (index) => '${index + 1}')
                .map((String month) => DropdownMenuItem<String>(
                      value: month,
                      child: Text(
                        getMonthName(int.parse(month)),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ))
                .toList(),
            onChanged: (String? newMonth) {
              if (newMonth != null) {
                setState(() {
                  _selectedMonth = newMonth;
                });
                // Actualizamos el mes en el modelo
                widget.model.setCurrentMonth(newMonth);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildOptionCard(
              context, "Crear Presupuesto", Icons.add_chart, _showCreateBudgetModal),
          _buildOptionCard(context, "Ver Presupuesto", Icons.pie_chart,
              _navigateToViewBudgetPage),
          _buildOptionCard(
              context, "Personas", Icons.person_outline, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddUserCat(context: context, type: 0),
              ),
            );
          }),
          _buildOptionCard(
              context, "Categorías", Icons.category_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddUserCat(context: context, type: 1),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, String title, IconData icon, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blueAccent),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
      return AlertDialog(
        title: Text('Crear Presupuesto para ${getMonthName(int.parse(_selectedMonth))}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    border: OutlineInputBorder(),
                  ),
                ),
                popupProps: PopupProps.dialog(
                  showSearchBox: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto del Presupuesto'),
                onChanged: (value) {
                  _budgetAmount = double.tryParse(value) ?? 0.0;
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Guardar'),
            onPressed: () async {
              if (_selectedCategory.isNotEmpty && _budgetAmount > 0) {
                await widget.model.setBudget(_selectedCategory, _selectedMonth, _budgetAmount);
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
}
