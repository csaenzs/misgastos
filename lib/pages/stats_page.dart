import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:gastos_compartidos/theme/colors.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';

class StatsPage extends StatefulWidget {
  final ExpenseModel model;
  final Function callback;

  const StatsPage({Key? key, required this.model, required this.callback}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late Map<String, double> categoryTotals;
  late Map<String, Map<String, double>> categoryDetails; // Para almacenar el gasto, presupuesto y saldo restante.
  late Map<String, double> userTotals;
  late Map<String, double> pieData = {}; // Inicialización con un mapa vacío.
  late List<String> users;
  final ScreenshotController _screenShotController = ScreenshotController();
  late TabController _controller;
  late double totalGastosInforme;

  bool isLoading = true; // Nueva variable para indicar si los datos están cargando

  @override
  void initState() {
    super.initState();
    _controller = TabController(vsync: this, length: 13, initialIndex: DateTime.now().month - 1);
    pieData = {}; // Asigna un valor predeterminado inicial.
    _loadData(); // Llamar al método que carga los datos
  }

  void _loadData() async {
    // Mostrar el indicador de carga antes de iniciar el proceso.
    setState(() {
      isLoading = true;
    });

    // Cargar los valores iniciales del modelo.
    await widget.model.setInitValues();

    // Calcular los totales por categoría y usuario según el mes seleccionado.
    categoryTotals = widget.model.calculateCategoryShare(month: _controller.index + 1);
    userTotals = widget.model.calculateUserShare(month: _controller.index + 1);
    pieData = categoryTotals.isEmpty ? {"No data": 1} : categoryTotals;

    // Agrega esta línea para calcular el total de los gastos
    totalGastosInforme = categoryTotals.values.fold(0.0, (sum, value) => sum + value);

    // Obtener los presupuestos y calcular el saldo restante por categoría.
    categoryDetails = {};
    for (String category in categoryTotals.keys) {
      double budget = await widget.model.getBudget(category, (_controller.index + 1).toString());
      double totalExpense = categoryTotals[category]!;
      double remainingBudget = budget - totalExpense;

      categoryDetails[category] = {
        "totalExpense": totalExpense,
        "budget": budget,
        "remaining": remainingBudget,
      };
    }

    // Ocultar el indicador de carga y mostrar los datos en la vista.
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grey.withOpacity(0.05),
      body: isLoading ? Center(child: CircularProgressIndicator()) : getBody(),
    );
  }

  Widget getBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator()); // Muestra un indicador de carga mientras los datos se cargan.
    }
    Map<String, String> months = {
      "1": "Ene",
      "2": "Feb",
      "3": "Mar",
      "4": "Abr",
      "5": "May",
      "6": "Jun",
      "7": "Jul",
      "8": "Ago",
      "9": "Sep",
      "10": "Oct",
      "11": "Nov",
      "12": "Dic",
      "13": "Todos"
    };

    return Column(
      children: [
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
              colors: myColors[1],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 50, right: 20, left: 20, bottom: 15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Total Gastos: COP ${NumberFormat('#,##0', 'es_CO').format(totalGastosInforme)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                    SizedBox(
                      height: 18,
                      width: 30,
                      child: IconButton(
                        padding: EdgeInsets.all(0),
                        icon: const Icon(Icons.share),
                        onPressed: _takeScreenShot,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        widget.model.getUsers.isEmpty || widget.model.getCategories.isEmpty
            ? Column(
                children: [
                  const SizedBox(height: 30),
                  Text(
                    widget.model.getUsers.isEmpty ? "No se han agregado Personas" : "No se han agregado categorías",
                    style: const TextStyle(fontSize: 21),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.callback(2);
                    },
                    child: const Text("Ir a configuración"),
                  ),
                ],
              )
            : Expanded(
                child: SingleChildScrollView(
                  child: Screenshot(
                    controller: _screenShotController,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: <Widget>[
                          Column(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.black38, width: 1.5)),
                                ),
                                child: TabBar(
                                  controller: _controller,
                                  onTap: _updateMonthTab,
                                  labelColor: Colors.blue,
                                  unselectedLabelColor: Colors.black,
                                  isScrollable: true,
                                  tabs: List.generate(
                                    months.length,
                                    (i) => Tab(
                                      child: Text(
                                        months.values.toList()[i],
                                        style: const TextStyle(fontSize: 17),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(padding: EdgeInsets.all(1)),
                              // Si `pieData` está vacío, mostramos un mensaje en lugar del gráfico.
                              Container(
                                child: pieData.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          children: const [
                                            Icon(Icons.info, size: 50, color: Colors.blue),
                                            SizedBox(height: 10),
                                            Text(
                                              'No hay datos disponibles para mostrar en el informe.',
                                              style: TextStyle(fontSize: 18),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : PieChart(
                                        dataMap: pieData,
                                        animationDuration: const Duration(milliseconds: 800),
                                        chartLegendSpacing: 10,
                                        chartRadius: MediaQuery.of(context).size.width / 2,
                                        initialAngleInDegree: 0,
                                        chartType: ChartType.disc,
                                        ringStrokeWidth: 20,
                                        legendOptions: const LegendOptions(
                                          showLegendsInRow: false,
                                          legendPosition: LegendPosition.right,
                                          showLegends: true,
                                          legendTextStyle: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        chartValuesOptions: const ChartValuesOptions(
                                          showChartValueBackground: false,
                                          showChartValues: true,
                                          showChartValuesInPercentage: true,
                                          showChartValuesOutside: false,
                                        ),
                                      ),
                              ),
                              makeStatCard("Gastos por Categoría", Colors.pink, MaterialCommunityIcons.chart_bar, categoryDetails),
                              makeStatCard("Gastos por Persona", Colors.orange, MaterialIcons.account_circle, userTotals),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  void _updateMonthTab(int v) {
    widget.model.setCurrentMonth((v + 1).toString());
    setState(() {
      _loadData();
    });
  }

  void _takeScreenShot() async {
    final imageFile = await _screenShotController.capture();
    if (imageFile != null) {
      await ImageGallerySaver.saveImage(imageFile, name: "test_screenshot");
      String tempPath = (await getTemporaryDirectory()).path;
      File file = File('$tempPath/image.jpg');
      await file.writeAsBytes(imageFile);
      await Share.shareXFiles([XFile(file.path)], text: 'Compartiendo archivo');
    }
  }

  Widget makeStatCard(String cardType, MaterialColor color, IconData icon, Map<String, dynamic> displayData) {
    final formatCurrency = NumberFormat('#,##0', 'es_CO');
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Card(
        elevation: 5.0,
        child: Container(
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: grey.withOpacity(0.01),
                spreadRadius: 10,
                blurRadius: 3,
              ),
            ],
          ),
          width: double.infinity,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 5),
                child: Row(
                  children: [
                    Icon(icon),
                    const SizedBox(width: 10),
                    Text(
                      cardType,
                      style: TextStyle(
                        fontSize: 20,
                        color: color.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 3.0, height: 15),
              Padding(
                padding: const EdgeInsets.all(7),
                child: Column(
                  children: displayData.entries.map((entry) {
                    if (entry.value is Map<String, double>) {
                      // Para la sección de "Gastos por Categoría" con presupuesto y saldo.
                      final data = entry.value as Map<String, double>;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Gasto: COP ${formatCurrency.format(data['totalExpense']!)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Presup: COP ${formatCurrency.format(data['budget']!)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Saldo: COP ${formatCurrency.format(data['remaining']!)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const Divider(thickness: 0.8, indent: 5, endIndent: 5),
                        ],
                      );
                    } else {
                      // Para otras secciones (como "Gastos por Persona").
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "COP ${formatCurrency.format(entry.value)}",
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Divider(thickness: 0.8, indent: 5, endIndent: 5),
                        ],
                      );
                    }
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
