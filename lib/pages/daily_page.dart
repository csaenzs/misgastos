import 'package:flutter/material.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:gastos_compartidos/pages/newentry_page.dart'; // Asegúrate de que la ruta es correcta
import 'package:animations/animations.dart';

class DailyPage extends StatelessWidget {
  final ExpenseModel model;
  final Function callback;

  const DailyPage({Key? key, required this.model, required this.callback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    List<Map<String, dynamic>> _expenses = model.getExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gastos",
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: myColors[0][1], // Color del AppBar
      ),
      body: Column(
        children: [
          model.getExpenses.isEmpty
              ? noExpenseDefault(context)
              : Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(13),
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
        backgroundColor: Colors.blue, // Cambiado a color azul
        tooltip: 'Agregar nuevo gasto',
      ),
    );
  }

  // Mensaje por defecto cuando no hay gastos
  Column noExpenseDefault(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Text(
          "No se encontraron registros de gastos",
          style: TextStyle(fontSize: 21),
        ),
        TextButton(
          child: const Text("Agregar nuevos registros"),
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
    );
  }

  // Diseño de la lista de gastos
  Column makeRecordTile(Size size, Map<String, dynamic> record) {
    return Column(
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
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  record['person'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  "COP ${record['amount']}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
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
        const Padding(
          padding: EdgeInsets.only(left: 10, top: 8, right: 10),
          child: Divider(
            indent: 0,
            thickness: 0.8,
          ),
        ),
      ],
    );
  }
}
