import 'package:flutter/material.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';
import 'package:intl/intl.dart';

class BudgetListPage extends StatefulWidget {
  final ExpenseModel model;
  final String currentMonth;

  const BudgetListPage({
    Key? key,
    required this.model,
    required this.currentMonth,
  }) : super(key: key);

  @override
  _BudgetListPageState createState() => _BudgetListPageState();
}

class _BudgetListPageState extends State<BudgetListPage> {
  Map<String, double> _currentBudgets = {};
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'es_CO');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentBudgets();
  }

  Future<void> _loadCurrentBudgets() async {
    setState(() {
      _isLoading = true;
    });

    Map<String, double> budgets = {};
    final List<Map<String, dynamic>> budgetsList = 
        await widget.model.getBudgetsForMonth(widget.currentMonth);
    
    for (var budget in budgetsList) {
      budgets[budget['category']] = budget['amount'] is int 
          ? (budget['amount'] as int).toDouble() 
          : budget['amount'];
    }

    for (var category in widget.model.getCategories) {
      String categoryName = category['name'];
      if (!budgets.containsKey(categoryName)) {
        budgets[categoryName] = 0.0;
      }
    }

    if (mounted) {
      setState(() {
        _currentBudgets = budgets;
        _isLoading = false;
      });
    }
  }

  double _calculateTotalBudget() {
    return _currentBudgets.values.fold(0, (sum, amount) => sum + amount);
  }

  void _showBudgetEditModal(String category, double currentBudget) {
    double amount = 0.0;
    bool isAdding = true;
    final TextEditingController _amountController = TextEditingController();
    
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: Text(
                'Editar Presupuesto', 
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Presupuesto actual: \$ ${_currencyFormat.format(currentBudget)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Agregar'),
                              icon: Icon(Icons.add),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Restar'),
                              icon: Icon(Icons.remove),
                            ),
                          ],
                          selected: {isAdding},
                          onSelectionChanged: (Set<bool> newSelection) {
                            setState(() {
                              isAdding = newSelection.first;
                              _amountController.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isAdding ? 'Monto a agregar' : 'Monto a restar',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    onChanged: (value) {
                      String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (numericValue.isNotEmpty) {
                        amount = double.tryParse(numericValue) ?? 0.0;
                        String formattedValue = _currencyFormat.format(double.parse(numericValue));
                        _amountController.value = TextEditingValue(
                          text: formattedValue,
                          selection: TextSelection.collapsed(offset: formattedValue.length),
                        );
                      } else {
                        amount = 0.0;
                      }
                    },
                  ),
                ],
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
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Guardar'),
                  onPressed: () async {
                    if (amount > 0) {
                      if (!isAdding && amount > currentBudget) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El monto a restar no puede ser mayor al presupuesto actual'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      double updatedBudget = isAdding 
                          ? currentBudget + amount 
                          : currentBudget - amount;

                      await widget.model.setBudget(
                        category,
                        widget.currentMonth,
                        updatedBudget,
                      );

                      Navigator.of(context).pop();
                      await _loadCurrentBudgets();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAdding 
                                ? 'Presupuesto aumentado correctamente' 
                                : 'Presupuesto reducido correctamente'
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBudgetList(),
          ),
        ],
      ),
    );
  }

Widget _buildHeader() {
    double totalBudget = _calculateTotalBudget();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 40, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Presupuestos ${getMonthName(int.parse(widget.currentMonth))}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Presupuesto Total",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    "\$ ${_currencyFormat.format(totalBudget)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 4),
            child: Text(
              "Toca una categoría para modificar su presupuesto",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList() {
    return Container(
      color: Colors.grey[100],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.model.getCategories.length,
        itemBuilder: (context, index) {
          String categoryName = widget.model.getCategories[index]['name'];
          double budget = _currentBudgets[categoryName] ?? 0.0;
          
          return Card(
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: () => _showBudgetEditModal(categoryName, budget),
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 24,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$ ${_currencyFormat.format(budget)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}