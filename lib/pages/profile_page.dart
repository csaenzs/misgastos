import 'package:flutter/material.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animations/animations.dart';
import 'package:flutter/gestures.dart';
import 'package:gastos_compartidos/pages/addUser_page.dart';

class ProfilePage extends StatefulWidget {
  final ExpenseModel model;

  const ProfilePage({Key? key, required this.model}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController userController = TextEditingController();
  TextEditingController categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializar los controladores con datos del modelo
    userController.text = widget.model.getUsers.join(',');
    categoryController.text = widget.model.getCategories.map((e) => e['name']).join(',');
  }

  @override
  void dispose() {
    userController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: grey.withOpacity(0.05),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height - 56, // Altura de la barra de navegación inferior
        child: getBody(),
      ),
    );
  }

  Widget getBody() {
    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: white,
            boxShadow: [
              BoxShadow(
                color: grey.withOpacity(0.01),
                spreadRadius: 10,
                blurRadius: 3,
              ),
            ],
            gradient: LinearGradient(
              colors: myColors[2],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.0, 2.0],
              tileMode: TileMode.clamp,
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.only(top: 50, right: 20, left: 20, bottom: 25),
            child: Row(
              children: <Widget>[],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Column(
          children: [
            Image.asset(
              "assets/images/budget.png",
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 13),
            Text(
              "Gestor de Gastos Compartidos",
              style: TextStyle(
                fontSize: 25,
                color: myColors[2][0],
              ),
            ),
            const Text(
              "v 0.1.2",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 13),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildOpenContainer(context, "Personas", Icons.person_outline, 0),
              const Divider(indent: 30, thickness: 1.0, height: 15),
              const SizedBox(height: 10),
              _buildOpenContainer(context, "Categorías", Icons.category_outlined, 1),
            ],
          ),
        ),
        Expanded(child: Container()),
        Column(
          children: [
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  const TextSpan(
                    text: 'Copyright \u00a9',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " 2024, "),
                  TextSpan(
                    text: 'Cristian Sáenz',
                    style: TextStyle(color: Colors.blueAccent.shade700),
                    recognizer: TapGestureRecognizer()..onTap = _launchURL,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
          ],
        ),
      ],
    );
  }

  Widget _buildOpenContainer(BuildContext context, String title, IconData icon, int type) {
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      openElevation: 0,
      middleColor: Colors.transparent,
      openColor: Colors.transparent,
      closedColor: Colors.transparent,
      closedBuilder: (_, __) => Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 21),
          ),
        ],
      ),
      openBuilder: (_, __) => AddUserCat(context: context, type: type),
    );
  }

  void _launchURL() async {
    const _url = 'https://github.com';
    if (!await launchUrl(Uri.parse(_url))) throw 'No se pudo iniciar $_url';
  }
}
