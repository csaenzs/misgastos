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

// IMPORTANTE: Esta clase debe estar antes que todas las demás clases
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) => false;
}

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
  late Map<String, double> accountTotals = {};
  late double _totalAnnualIncome;
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
        Future(() => widget.model.calculateAccountTotals(month: _controller.index + 1)),
      ]);

      categoryTotals = results[0];
      incomeCategoryTotals = results[1];
      accountTotals = results[2];
      pieData = categoryTotals.isEmpty ? {"No data": 1} : categoryTotals;

      totalGastosInforme = categoryTotals.values.fold(0.0, (sum, value) => sum + value);
      totalIngresosInforme = incomeCategoryTotals.values.fold(0.0, (sum, value) => sum + value);
      balanceInforme = totalIngresosInforme - totalGastosInforme;

      if (_controller.index == 12) {
        _totalAnnualIncome = widget.model.getIncomes
            .map((income) => income.amount)
            .fold(0.0, (sum, amount) => sum + amount);
      } else {
        _totalAnnualIncome = totalIngresosInforme * 12;
      }

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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.green.shade700,
              flexibleSpace: _buildHeader(),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _controller,
                  onTap: _updateMonthTab,
                  labelColor: Colors.green.shade700,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: Colors.green.shade700,
                  isScrollable: true,
                  tabs: _buildMonthTabs(),
                ),
              ),
              pinned: true,
              floating: false,
            ),
          ];
        },
        body: isLoading 
            ? _buildLoadingState()
            : _buildMainContent(),
      ),
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
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Screenshot(
        controller: _screenShotController,
        child: Column(
          children: [
            _buildFinancialSummary(),
            const SizedBox(height: 8),
            if (categoryTotals.isEmpty && incomeCategoryTotals.isEmpty)
              _buildNoTransactionsMessage()
            else
              Column(
                children: [
                  if (categoryTotals.isNotEmpty) 
                    _buildExpensesCategories(),
                  if (incomeCategoryTotals.isNotEmpty)
                    _buildIncomeCategories(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ... [Continuará con el resto de los métodos]

  List<Widget> _buildMonthTabs() {
    Map<String, String> months = {
      "1": "Enero", "2": "Febrero", "3": "Marzo",
      "4": "Abril", "5": "Mayo", "6": "Junio",
      "7": "Julio", "8": "Agosto", "9": "Septiembre",
      "10": "Octubre", "11": "Noviembre", "12": "Diciembre",
      "13": "Todo el año"
    };

    return months.values.map((month) => Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          month,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    )).toList();
  }

  Widget _buildHeader() {
    return FlexibleSpaceBar(
      background: Container(
        color: Colors.green.shade700,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Resumen Financiero",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _takeScreenShot,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildFinancialItem(
                    "Ingresos",
                    totalIngresosInforme,
                    Icons.arrow_upward,
                    Colors.green.shade400,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildFinancialItem(
                    "Gastos",
                    totalGastosInforme,
                    Icons.arrow_downward,
                    Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildCompactBalance(),
          ),
          if (accountTotals.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildCompactAccounts(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String title, double amount, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            NumberFormat.currency(
              symbol: 'COP ',
              decimalDigits: 0,
              locale: 'es_CO',
            ).format(amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBalance() {
    final isPositive = balanceInforme >= 0;
    String emoji = isPositive ? '🤑' : '😰';
    Color statusColor = isPositive ? Colors.green.shade400 : Colors.orange;

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPositive ? '¡Balance Positivo!' : '¡Atención!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Text(
                NumberFormat.currency(
                  symbol: 'COP ',
                  decimalDigits: 0,
                  locale: 'es_CO',
                ).format(balanceInforme.abs()),
                style: TextStyle(
                  fontSize: 13,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance,
              color: Colors.grey.shade600,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              "Cuentas",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: accountTotals.length,
            itemBuilder: (context, index) {
              final entry = accountTotals.entries.elementAt(index);
              final isPositive = entry.value >= 0;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPositive ? '💰' : '💸',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        symbol: 'COP ',
                        decimalDigits: 0,
                        locale: 'es_CO',
                      ).format(entry.value.abs()),
                      style: TextStyle(
                        color: isPositive ? Colors.green.shade600 : Colors.orange.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesCategories() {
    if (categoryDetails.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: [
        if (_controller.index == 12) 
          _buildYearlyOverview(),
        _buildCategoryList("Gastos por Categoría", categoryDetails, Colors.red.shade700),
      ],
    );
  }

  Widget _buildIncomeCategories() {
    if (incomeCategoryTotals.isEmpty) return const SizedBox.shrink();
    
    return _buildCategoryList(
      "Ingresos por Categoría",
      Map.fromEntries(
        incomeCategoryTotals.entries.map(
          (e) => MapEntry(e.key, {"totalExpense": e.value, "budget": 0.0}),
        ),
      ),
      Colors.green.shade700,
    );
  }

  Widget _buildCategoryList(String title, Map<String, dynamic> data, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(MaterialCommunityIcons.chart_bar, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = data.entries.elementAt(index);
              return _buildOptimizedCategoryItem(entry);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoTransactionsMessage() {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('📅', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              '¡No hay movimientos en ${_getCurrentMonth()}!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tus ingresos y gastos para comenzar a ver las estadísticas',
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

  Widget _buildOptimizedCategoryItem(MapEntry<String, dynamic> entry) {
    final formatCurrency = NumberFormat.currency(
      symbol: 'COP ',
      decimalDigits: 0,
      locale: 'es_CO',
    );
    final bool isYearlyView = _controller.index == 12;

    if (entry.value is Map<String, double>) {
      final data = entry.value as Map<String, double>;
      final double totalExpense = data['totalExpense'] ?? 0.0;

      if (isYearlyView) {
        return _buildYearlyCategoryItem(entry.key, totalExpense, formatCurrency);
      }

      return _buildMonthlyCategoryItem(entry.key, data, formatCurrency);
    }

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      leading: const Text('💰', style: TextStyle(fontSize: 16)),
      title: Text(
        entry.key,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Text(
        formatCurrency.format(entry.value),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildYearlyCategoryItem(String category, double totalExpense, NumberFormat formatCurrency) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                formatCurrency.format(totalExpense),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getMonthlyAverage(totalExpense),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${((totalExpense / _totalAnnualIncome) * 100).toStringAsFixed(1)}% del total',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCategoryItem(String category, Map<String, double> data, NumberFormat formatCurrency) {
    final double totalExpense = data['totalExpense'] ?? 0.0;
    final double budget = data['budget'] ?? 0.0;
    double percentUsed = budget > 0 ? (totalExpense / budget * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    _getPercentageEmoji(percentUsed),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${percentUsed.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getPercentageColor(percentUsed),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (budget > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percentUsed / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_getPercentageColor(percentUsed)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatCurrency.format(totalExpense),
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  'de ${formatCurrency.format(budget)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              formatCurrency.format(totalExpense),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
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

  Color _getPercentageColor(double percentage) {
    if (percentage > 100) return Colors.red.shade400;
    if (percentage > 80) return Colors.orange.shade400;
    return Colors.green.shade400;
  }

  String _getPercentageEmoji(double percentage) {
    if (percentage > 100) return '😱';
    if (percentage > 80) return '😰';
    if (percentage > 50) return '😊';
    return '🤑';
  }

  String _getMonthlyAverage(double totalAmount) {
    double monthlyAverage = totalAmount / 12;
    return 'Promedio: ${NumberFormat.currency(
      symbol: 'COP ',
      decimalDigits: 0,
      locale: 'es_CO',
    ).format(monthlyAverage)}/mes';
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

  Widget _buildYearlyOverview() {
    double expensePercentage = (totalGastosInforme / _totalAnnualIncome) * 100;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  _getPercentageEmoji(expensePercentage),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Balance Anual',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getYearlyMessage(expensePercentage),
                        style: TextStyle(
                          fontSize: 13,
                          color: _getPercentageColor(expensePercentage),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (expensePercentage / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_getPercentageColor(expensePercentage)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingresos totales',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        symbol: 'COP ',
                        decimalDigits: 0,
                        locale: 'es_CO',
                      ).format(_totalAnnualIncome),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Gastos totales',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        symbol: 'COP ',
                        decimalDigits: 0,
                        locale: 'es_CO',
                      ).format(totalGastosInforme),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getYearlyMessage(double percentage) {
    if (percentage > 100) {
      return 'Gastos superan ingresos en ${(percentage - 100).toStringAsFixed(1)}%';
    } else if (percentage > 80) {
      return 'Gastos altos: ${percentage.toStringAsFixed(1)}% de ingresos';
    } else if (percentage > 50) {
      return 'Gastos moderados: ${percentage.toStringAsFixed(1)}% de ingresos';
    } else {
      return 'Excelente control: ${percentage.toStringAsFixed(1)}% de ingresos';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

