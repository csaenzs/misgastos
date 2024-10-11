import 'package:flutter/material.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:gastos_compartidos/pages/newentry_page.dart'; // Asegúrate de que la ruta es correcta
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';

class DailyPage extends StatelessWidget {
  final ExpenseModel model;
  final Function callback;

  const DailyPage({Key? key, required this.model, required this.callback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    List<Map<String, dynamic>> _expenses = model.getExpenses;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          model.getExpenses.isEmpty
              ? Expanded(child: noExpenseDefault(context))
              : Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _expenses.length,
                    itemBuilder: (context, i) => OpenContainer(
                      transitionType: ContainerTransitionType.fadeThrough,
                      closedElevation: 0,
                      openElevation: 0,
                      middleColor: Colors.transparent,
                      openColor: Colors.transparent,
                      closedColor: Colors.transparent,
                      closedBuilder: (_, __) => makeRecordTile(size, _expenses[i]),
                      openBuilder: (_, __) => NewEntryPage(
                        callback: callback,
                        context: context,
                        index: i,
                      ),
                    ),
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
                callback: callback,
                context: context,
              ),
            ),
          );
          // Refrescar la página después de agregar un nuevo gasto
          model.setInitValues();
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue, // Color del botón flotante
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

  // Mensaje por defecto cuando no hay gastos
  Widget noExpenseDefault(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            size: 80,
            color: Colors.blueAccent,
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
                    callback: callback,
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

  // Diseño de la lista de gastos
  Widget makeRecordTile(Size size, Map<String, dynamic> record) {
    final formatCurrency = NumberFormat('#,##0', 'es_CO');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
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
                        record['person'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
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
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
