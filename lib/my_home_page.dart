import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely_flutter/lonely_model.dart';
import 'package:lonely_flutter/portfolio_widget.dart';
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
      //print('initState(): MyHomePage');
    }
    super.initState();
    _widgetOptions = <Widget>[
      PortfolioWidget(database: widget.database),
      const Text(
        '매매 기록',
        style: optionStyle,
      ),
      const Text(
        '계좌 목록',
        style: optionStyle,
      ),
    ];
  }


  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LonelyModel(),
      child: Scaffold(
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Center(child: _widgetOptions.elementAt(_selectedIndex)),
        ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.feed),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Accounts',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
