import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'account_list_widget.dart';
import 'history_screen.dart';
import 'portfolio_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

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
        body: const PortfolioScreen(),
      ),
      Scaffold(
        appBar: AppBar(title: const Text('매매 기록')),
        body: const HistoryScreen(),
      ),
      Scaffold(
        appBar: AppBar(title: const Text('계좌 목록')),
        body: const AccountListWidget(),
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
