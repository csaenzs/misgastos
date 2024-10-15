import 'package:flutter/material.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:scoped_model/scoped_model.dart';

class AddUserCat extends StatefulWidget {
  final BuildContext context;
  final int type; // type 0 significa lista de Personas, type 1 significa categorías de gastos, type 2 significa categorías de ingresos, type 3 significa cuentas

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
    // Verificamos que se obtenga el modelo correctamente
    model = ScopedModel.of<ExpenseModel>(widget.context, rebuildOnChange: true);
    // Usar `map` para asegurarse de que los valores se obtengan correctamente como String
    if (widget.type == 0) {
      _userList = model.getUsers;
    } else if (widget.type == 1) {
      _userList = model.getCategories.map((e) => e['name'] as String).toList();
    } else if (widget.type == 2) {
      _userList = model.getIncomeCategories.map((e) => e['name'] as String).toList(); // Categorías de ingresos
    } else {
      _userList = model.getAccounts.map((e) => e['name'] as String).toList(); // Cuentas
    }
    print('Lista inicializada: $_userList');
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
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () async {
              try {
                if (isUser) {
                  print('Guardando Personas: $_userList');
                  await model.setUsers(_userList); // Añadimos await para esperar la operación
                } else if (widget.type == 1) {
                  print('Guardando categorías: ${_userList.map((name) => {'name': name}).toList()}');
                  await model.setCategories(_userList.map((name) => {'name': name}).toList()); // Guardar categorías de gastos
                } else if (widget.type == 2) {
                  print('Guardando categorías de ingresos: ${_userList.map((name) => {'name': name}).toList()}');
                  await model.setIncomeCategories(_userList.map((name) => {'name': name}).toList()); // Guardar categorías de ingresos
                } else {
                  print('Guardando cuentas: ${_userList.map((name) => {'name': name}).toList()}');
                  await model.setAccounts(_userList.map((name) => {'name': name}).toList()); // Guardar cuentas
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isUser ? "Personas" : widget.type == 1 ? "Categorías de gastos" : widget.type == 2 ? "Categorías de ingresos" : "Cuentas"} guardados exitosamente en Firestore'),
                  ),
                );
                await _printFirestoreData();
                Navigator.pop(context);
              } catch (e) {
                print('Error al guardar en Firestore: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar ${isUser ? "Personas" : widget.type == 1 ? "Categorías de gastos" : widget.type == 2 ? "Categorías de ingresos" : "Cuentas"} en Firestore'),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
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
                    _updateModelList();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text('Ingresar nuevo ${isUser ? "Persona" : widget.type == 1 ? "categoría de gasto" : widget.type == 2 ? "categoría de ingreso" : "cuenta"}:'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextFormField(
                  controller: userController,
                  decoration: InputDecoration(
                    hintText: 'Nombre del ${isUser ? "Persona" : widget.type == 1 ? "categoría de gasto" : widget.type == 2 ? "categoría de ingreso" : "cuenta"}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  if (userController.text.trim().isNotEmpty) {
                    _userList.add(userController.text.trim());
                    userController.clear();
                  }
                });
                _updateModelList();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateModelList() async {
    try {
      if (isUser) {
        await model.setUsers(_userList);
        print('Personas actualizados en Firestore: $_userList');
      } else if (widget.type == 1) {
        await model.setCategories(_userList.map((name) => {'name': name}).toList());
        print('Categorías actualizadas en Firestore: $_userList');
      } else if (widget.type == 2) {
        await model.setIncomeCategories(_userList.map((name) => {'name': name}).toList());
        print('Categorías de ingresos actualizadas en Firestore: $_userList');
      } else {
        await model.setAccounts(_userList.map((name) => {'name': name}).toList());
        print('Cuentas actualizadas en Firestore: $_userList');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isUser ? "Personas" : widget.type == 1 ? "Categorías de gastos" : widget.type == 2 ? "Categorías de ingresos" : "Cuentas"} actualizados exitosamente en Firestore'),
        ),
      );
      await _printFirestoreData();
    } catch (e) {
      print('Error al actualizar el modelo en Firestore: $e');
    }
  }

  Future<void> _printFirestoreData() async {
    try {
      final snapshot = await model.getAppDataSnapshot();
      if (snapshot.exists) {
        print('Documento `app_data` en Firestore: ${snapshot.data()}');
      } else {
        print('El documento `app_data` no existe en Firestore.');
      }
    } catch (e) {
      print('Error al obtener los datos de Firestore: $e');
    }
  }
}
