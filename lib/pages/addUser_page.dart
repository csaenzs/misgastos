import 'package:flutter/material.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:scoped_model/scoped_model.dart';

class AddUserCat extends StatefulWidget {
  final BuildContext context;
  final int type; // type 0 significa lista de usuarios y type 1 significa categoría

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
    _userList = isUser ? model.getUsers : model.getCategories.map((e) => e['name'] as String).toList();
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
        title: Text(isUser ? "Usuarios" : "Categorías"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              try {
                if (isUser) {
                  print('Guardando usuarios: $_userList');
                  await model.setUsers(_userList); // Añadimos await para esperar la operación
                } else {
                  print('Guardando categorías: ${_userList.map((name) => {'name': name}).toList()}');
                  await model.setCategories(_userList.map((name) => {'name': name}).toList()); // Añadimos await para esperar la operación
                }
                // Mostramos un mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isUser ? "Usuarios" : "Categorías"} guardados exitosamente en Firestore'),
                  ),
                );
                // Confirmar que los cambios se reflejan en Firestore
                await _printFirestoreData();
                Navigator.pop(context);
              } catch (e) {
                print('Error al guardar en Firestore: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar ${isUser ? "usuarios" : "categorías"} en Firestore'),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 20)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUserDialog,
        child: const Icon(Icons.add),
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: _userList.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: isUser ? const Icon(Icons.person_outline) : const Icon(Icons.category_outlined),
              title: Text(_userList[index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  setState(() {
                    _userList.removeAt(index);
                  });
                  // Actualizar la lista en el modelo después de eliminar
                  _updateModelList();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // Método para mostrar un diálogo y agregar un nuevo usuario o categoría
  void showUserDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ingresar nuevo ${isUser ? "usuario" : "categoría"}:'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextFormField(
                  controller: userController,
                  decoration: InputDecoration(
                    hintText: 'Nombre del ${isUser ? "usuario" : "categoría"}',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  if (userController.text.trim().isNotEmpty) {
                    _userList.add(userController.text.trim());
                    userController.clear();
                  }
                });
                // Actualizar la lista en el modelo después de agregar un nuevo elemento
                _updateModelList();
              },
            ),
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Método para actualizar el modelo con la lista actualizada
  void _updateModelList() async {
    try {
      if (isUser) {
        await model.setUsers(_userList);
        print('Usuarios actualizados en Firestore: $_userList');
      } else {
        await model.setCategories(_userList.map((name) => {'name': name}).toList());
        print('Categorías actualizadas en Firestore: $_userList');
      }
      // Mostrar un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isUser ? "Usuarios" : "Categorías"} actualizados exitosamente en Firestore'),
        ),
      );
      // Confirmar que los cambios se reflejan en Firestore
      await _printFirestoreData();
    } catch (e) {
      print('Error al actualizar el modelo en Firestore: $e');
    }
  }

  // Método para imprimir los datos actuales de Firestore
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
