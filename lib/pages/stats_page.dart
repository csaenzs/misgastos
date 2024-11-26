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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grey.withOpacity(0.05),
      body: isLoading 
          ? _buildLoadingState()
          : getBody(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
    );
  }

Widget getBody() {
    return Column(
      children: [
        _buildHeader(),
        if (widget.model.getUsers.isEmpty || widget.model.getCategories.isEmpty)
          _buildEmptyState()
        else
          Expanded(
            child: SingleChildScrollView(
              child: Screenshot(
                controller: _screenShotController,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildMonthSelector(),
                      if (categoryTotals.isEmpty && incomeCategoryTotals.isEmpty)
                        _buildNoTransactionsMessage()
                      else
                        Column(
                          children: [
                            if (categoryTotals.isEmpty)
                              _buildNoExpensesMessage()
                            else
                              _buildExpensesCategories(),
                            if (incomeCategoryTotals.isEmpty)
                              _buildNoIncomesMessage()
                            else
                              _buildIncomeCategories(),
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

  Widget _buildNoTransactionsMessage() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '📅',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              '¡No hay movimientos en ${_getCurrentMonth()}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Registra tus ingresos y gastos para comenzar a ver las estadísticas de este mes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoExpensesMessage() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '💰',
              style: TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 12),
            Text(
              '¡Sin gastos registrados en ${_getCurrentMonth()}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tus gastos para mantener un mejor control de tus finanzas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoIncomesMessage() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '💸',
              style: TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 12),
            Text(
              '¡Sin ingresos registrados en ${_getCurrentMonth()}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tus ingresos para tener un panorama completo de tus finanzas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentMonth() {
    Map<int, String> months = {
      1: "Enero", 2: "Febrero", 3: "Marzo",
      4: "Abril", 5: "Mayo", 6: "Junio",
      7: "Julio", 8: "Agosto", 9: "Septiembre",
      10: "Octubre", 11: "Noviembre", 12: "Diciembre",
      13: "todo el año"
    };
    return months[_controller.index + 1] ?? "";
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _takeScreenShot,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFinancialSummaryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildFinancialSummaryItem(
                "Ingresos",
                totalIngresosInforme,
                Icons.arrow_upward,
                Colors.green.shade300,
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 15),
              ),
              _buildFinancialSummaryItem(
                "Gastos",
                totalGastosInforme,
                Icons.arrow_downward,
                Colors.red.shade300,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white24, height: 1),
          ),
          _buildBalanceSection(),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryItem(
    String title,
    double amount,
    IconData icon,
    Color iconColor,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              NumberFormat.currency(
                symbol: 'COP ',
                decimalDigits: 0,
                locale: 'es_CO',
              ).format(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildBalanceSection() {
    final isPositive = balanceInforme >= 0;
    String emoji;
    String message;
    Color statusColor;

    if (isPositive) {
      if (balanceInforme > totalGastosInforme * 0.5) {
        emoji = '🤑';
        message = '¡Excelente! Estás ahorrando mucho';
        statusColor = Colors.green.shade300;
      } else {
        emoji = '😊';
        message = '¡Bien! Tu balance es positivo';
        statusColor = Colors.green.shade300;
      }
    } else {
      if (balanceInforme.abs() > totalIngresosInforme * 0.5) {
        emoji = '😱';
        message = '¡Cuidado! Tus gastos superan bastante tus ingresos';
        statusColor = Colors.orange;
      } else {
        emoji = '😰';
        message = '¡Atención! Tus gastos superan tus ingresos';
        statusColor = Colors.orange;
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 10),
            Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          NumberFormat.currency(
            symbol: 'COP ',
            decimalDigits: 0,
            locale: 'es_CO',
          ).format(balanceInforme.abs()),
          style: TextStyle(
            color: statusColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          widget.model.getUsers.isEmpty 
              ? "No se han agregado Personas" 
              : "No se han agregado categorías",
          style: const TextStyle(fontSize: 21),
        ),
        TextButton(
          onPressed: () => widget.callback(2),
          child: const Text("Ir a configuración"),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    Map<String, String> months = {
      "1": "Enero", "2": "Febrero", "3": "Marzo",
      "4": "Abril", "5": "Mayo", "6": "Junio",
      "7": "Julio", "8": "Agosto", "9": "Septiembre",
      "10": "Octubre", "11": "Noviembre", "12": "Diciembre",
      "13": "Todo el año"
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: TabBar(
        controller: _controller,
        onTap: _updateMonthTab,
        labelColor: Colors.green.shade700,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.green.shade700,
        isScrollable: true,
        tabs: months.values.map((month) => Tab(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              month,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildEmptyDataMessage() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '📊',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡No hay datos disponibles para este período!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tus primeros movimientos para ver las estadísticas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesCategories() {
    if (categoryDetails.isEmpty) return const SizedBox.shrink();
    
    return _buildCategoryCard(
      "Gastos por Categoría",
      categoryDetails,
      MaterialCommunityIcons.chart_bar,
      Colors.red.shade700,
    );
  }

  Widget _buildIncomeCategories() {
    if (incomeCategoryTotals.isEmpty) return const SizedBox.shrink();

    return _buildCategoryCard(
      "Ingresos por Categoría",
      incomeCategoryTotals,
      MaterialIcons.account_balance_wallet,
      Colors.green.shade700,
    );
  }

  Widget _buildCategoryCard(
    String title,
    Map<String, dynamic> data,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final entry = data.entries.elementAt(index);
              return _buildCategoryItem(entry);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(MapEntry<String, dynamic> entry) {
    final formatCurrency = NumberFormat.currency(
      symbol: 'COP ',
      decimalDigits: 0,
      locale: 'es_CO',
    );

    if (entry.value is Map<String, double>) {
      final data = entry.value as Map<String, double>;
      double percentUsed = 0.0;
      String emoji;
      String message;
      
      if (data['budget'] != null && data['budget']! > 0) {
        percentUsed = (data['totalExpense']! / data['budget']! * 100);
      }

      // Determinar emoji y mensaje según el porcentaje usado
      if (percentUsed > 100) {
        emoji = '😱';
        message = '¡Te has pasado del presupuesto!';
      } else if (percentUsed > 80) {
        emoji = '😰';
        message = '¡Cuidado! Estás cerca del límite';
      } else if (percentUsed > 50) {
        emoji = '😊';
        message = 'Vas bien, pero mantén el control';
      } else {
        emoji = '🤑';
        message = '¡Excelente manejo del presupuesto!';
      }
      
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentUsed.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _getPercentageColor(percentUsed),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: _getPercentageColor(percentUsed),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (percentUsed / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getPercentageColor(percentUsed),
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Has gastado: ${formatCurrency.format(data['totalExpense'])}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'de ${formatCurrency.format(data['budget'])}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Para ingresos
    return ListTile(
      leading: Text(
        '💰',
        style: TextStyle(fontSize: 20),
      ),
      title: Text(entry.key),
      trailing: Text(
        formatCurrency.format(entry.value),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage > 100) return Colors.red;
    if (percentage > 80) return Colors.orange;
    return Colors.green;
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
      await ImageGallerySaver.saveImage(imageFile, name: "informe_financiero");
      String tempPath = (await getTemporaryDirectory()).path;
      File file = File('$tempPath/informe_financiero.jpg');
      await file.writeAsBytes(imageFile);
      await Share.shareXFiles([XFile(file.path)], text: 'Informe Financiero');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}