import 'package:flutter/material.dart';
import 'package:gastos_compartidos/pages/daily_page.dart';
import 'package:gastos_compartidos/pages/stats_page.dart';
import 'package:gastos_compartidos/pages/profile_page.dart';
import 'package:gastos_compartidos/scoped_model/expenseScope.dart';

class HomePage extends StatefulWidget {
  final ExpenseModel model;

  const HomePage({Key? key, required this.model}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      DailyPage(model: widget.model, callback: _navigateToPage),
      StatsPage(model: widget.model, callback: _navigateToPage),
      ProfilePage(model: widget.model),
    ];

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Gastos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Informes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToPage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
