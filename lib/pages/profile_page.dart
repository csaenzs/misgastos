import 'package:flutter/material.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:gastos_compartidos/pages/addUser_page.dart';
import 'package:gastos_compartidos/pages/budget_list_page.dart';

class ProfilePage extends StatefulWidget {
  final ExpenseModel model;

  const ProfilePage({Key? key, required this.model}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _selectedMonth = DateTime.now().month.toString();

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
        gradient: const LinearGradient(
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
          context,
          "Presupuestos",
          Icons.account_balance_wallet,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BudgetListPage(
                  model: widget.model,
                  currentMonth: _selectedMonth,
                ),
              ),
            );
          },
        ),
        _buildOptionTile(
          context,
          "Personas",
          Icons.person_outline,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddUserCat(context: context, type: 0),
              ),
            );
          },
        ),
        _buildOptionTile(
          context,
          "Categorías de Gastos",
          Icons.category_outlined,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddUserCat(context: context, type: 1),
              ),
            );
          },
        ),
        _buildOptionTile(
          context,
          "Categorías de Ingresos",
          Icons.monetization_on_outlined,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddUserCat(context: context, type: 2),
              ),
            );
          },
        ),
        _buildOptionTile(
          context,
          "Cuentas",
          Icons.account_balance_outlined,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddUserCat(context: context, type: 3),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOptionTile(
      BuildContext context, String title, IconData icon, Function onTap) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 35,
            color: Colors.deepPurple,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.deepPurple,
          size: 20,
        ),
        onTap: () => onTap(),
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