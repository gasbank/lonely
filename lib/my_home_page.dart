import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely_flutter/account_list_widget.dart';
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
      const MyStatefulWidget(),
      AccountListWidget(),
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
          items: const [
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

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          color: Colors.black12,
          child: Stack(
            children: <Widget>[
              AnimatedPositioned(
                width: 100,
                height: 100,
                top: selected ? 0.0 : 100.0,
                left: selected ? 0.0 : 100.0,
                duration: const Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selected = !selected;
                    });
                  },
                  child: Container(
                    color: Colors.blue,
                    child: Center(child: Image.network('https://storage.googleapis.com/dartlang-pub--pub-images/flame/1.7.3/gen/190x190/logo.webp')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
