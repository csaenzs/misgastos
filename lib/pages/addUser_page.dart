import 'package:flutter/material.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:scoped_model/scoped_model.dart';

class AddUserCat extends StatefulWidget {
  final BuildContext context;
  final int type; // 0 = Personas, 1 = Categorías de gastos, 2 = Categorías de ingresos, 3 = Cuentas

  const AddUserCat({Key? key, required this.context, required this.type}) : super(key: key);

  @override
  _AddUserCatState createState() => _AddUserCatState();
}

class _AddUserCatState extends State<AddUserCat> {
  late ExpenseModel model;
  late List<String> _userList;
  bool isUser = false;
  final TextEditingController userController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isUser = widget.type == 0;
    model = ScopedModel.of<ExpenseModel>(widget.context, rebuildOnChange: true);

    if (widget.type == 0) {
      _userList = model.getUsers;
    } else if (widget.type == 1) {
      _userList = model.getCategories.map((e) => e['name'] as String).toList();
    } else if (widget.type == 2) {
      _userList = model.getIncomeCategories.map((e) => e['name'] as String).toList();
    } else {
      _userList = model.getAccounts.map((e) => e['name'] as String).toList();
    }
  }

  @override
  void dispose() {
    userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUser ? "Personas" : widget.type == 1 ? "Categorías de Gastos" : widget.type == 2 ? "Categorías de Ingresos" : "Cuentas",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
          onPressed: () async {
            final name = userController.text.trim();
            if (name.isNotEmpty) {
              setState(() {
                _userList.add(name);
              });

              if (isUser) {
                await model.setUsers(_userList);
              } else if (widget.type == 1) {
                await model.setCategories(_userList.map((n) => {'name': n}).toList());
              } else if (widget.type == 2) {
                await model.setIncomeCategories(_userList.map((n) => {'name': n}).toList());
              } else {
                await model.setAccounts(_userList.map((n) => {'name': n}).toList());
              }

              await model.setInitValues(); // Recargar desde Hive
              userController.clear();

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => AddUserCat(context: context, type: widget.type),
                ),
              );
            }
          },
          ),
          const SizedBox(width: 20)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: showUserDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _userList.length,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                  child: Icon(
                    isUser ? Icons.person_outline : Icons.category_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  _userList[index],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _userList.removeAt(index);
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void showUserDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text('Nuevo ${_getLabel()}:'),
          content: TextFormField(
            controller: userController,
            decoration: InputDecoration(
              hintText: 'Nombre del ${_getLabel()}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.secondary),
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Aceptar'),
              onPressed: () async {
                final name = userController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _userList.add(name);
                  });

                  if (isUser) {
                    await model.setUsers(_userList);
                  } else if (widget.type == 1) {
                    await model.setCategories(_userList.map((n) => {'name': n}).toList());
                  } else if (widget.type == 2) {
                    await model.setIncomeCategories(_userList.map((n) => {'name': n}).toList());
                  } else {
                    await model.setAccounts(_userList.map((n) => {'name': n}).toList());
                  }

                  await model.setInitValues();
                }
                userController.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getLabel() {
    return isUser
        ? "Persona"
        : widget.type == 1
            ? "Categoría de gasto"
            : widget.type == 2
                ? "Categoría de ingreso"
                : "Cuenta";
  }
}
