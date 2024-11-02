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
  late Map<String, Map<String, double>> categoryDetails;
  late Map<String, double> incomeCategoryTotals;
  late Map<String, double> pieData = {};
  final ScreenshotController _screenShotController = ScreenshotController();
  late TabController _controller;
  late double totalGastosInforme;
  late double totalIngresosInforme;
  late double balanceInforme;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = TabController(vsync: this, length: 13, initialIndex: DateTime.now().month - 1);
    pieData = {};
    _loadData();
  }

void _loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      await widget.model.setInitValues();

      // Cargar datos en paralelo
      final results = await Future.wait([
        Future(() => widget.model.calculateCategoryShare(month: _controller.index + 1)),
        Future(() => widget.model.calculateIncomeCategoryShare(month: _controller.index + 1)),
      ]);

      categoryTotals = results[0];
      incomeCategoryTotals = results[1];
      pieData = categoryTotals.isEmpty ? {"No data": 1} : categoryTotals;

      totalGastosInforme = categoryTotals.values.fold(0.0, (sum, value) => sum + value);
      totalIngresosInforme = incomeCategoryTotals.values.fold(0.0, (sum, value) => sum + value);
      balanceInforme = totalIngresosInforme - totalGastosInforme;

      // Cargar detalles de categorías
      categoryDetails = {};
      await Future.wait(
        categoryTotals.keys.map((category) async {
          double budget = await widget.model.getBudget(category, (_controller.index + 1).toString());
          double totalExpense = categoryTotals[category]!;
          categoryDetails[category] = {
            "totalExpense": totalExpense,
            "budget": budget,
            "remaining": budget - totalExpense,
          };
        }),
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
      body: isLoading 
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: const [
                          Text(
                            "Resumen Financiero",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Cargando información...",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : getBody(),
    );
  }

  Widget getBody() {
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
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Resumen Financiero",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.share, color: Colors.white, size: 22),
                  onPressed: _takeScreenShot,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.arrow_upward,
                                    color: Colors.white.withOpacity(0.7), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "Ingresos",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "COP ${NumberFormat('#,##0', 'es_CO').format(totalIngresosInforme)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.arrow_downward,
                                    color: Colors.white.withOpacity(0.7), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "Gastos",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "COP ${NumberFormat('#,##0', 'es_CO').format(totalGastosInforme)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        balanceInforme >= 0 
                            ? Icons.account_balance_wallet 
                            : Icons.warning,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Balance: COP ${NumberFormat('#,##0', 'es_CO').format(balanceInforme)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
                              makeStatCard("Ingresos por Categoría", Colors.orange, MaterialIcons.account_circle, incomeCategoryTotals),
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

    // Agregar este método en la clase
    Widget _buildAmountColumn(String title, double amount, IconData icon, Color iconColor) {
      return Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "COP ${NumberFormat('#,##0', 'es_CO').format(amount)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
}
