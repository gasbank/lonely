import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely_flutter/account_list_widget.dart';
import 'package:lonely_flutter/history_screen.dart';
import 'package:lonely_flutter/lonely_model.dart';
import 'package:lonely_flutter/portfolio_screen.dart';
import 'package:provider/provider.dart';

import 'database.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.database});

  final LonelyDatabase database;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Widget> _widgetOptions;
  int _selectedIndex = 0;

  @override
  void initState() {
    if (kDebugMode) {
      print('initState(): MyHomePage');
    }
    super.initState();
    _widgetOptions = <Widget>[
      Scaffold(
          appBar: AppBar(title: const Text('포트폴리오')),
          body: PortfolioScreen(database: widget.database),),
      Scaffold(
        appBar: AppBar(title: const Text('매매 기록')),
        body: HistoryScreen(database: widget.database),),
      Scaffold(
        appBar: AppBar(title: const Text('계좌 목록')),
        body: AccountListWidget(),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.summarize),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.reorder),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Accounts',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primaryContainer,
        onTap: _onItemTapped,
      ),
    );
  }
}
