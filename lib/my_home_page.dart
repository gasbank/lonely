import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'lonely_model.dart';
import 'settings_widget.dart';
import 'package:provider/provider.dart';
import 'account_list_widget.dart';
import 'history_screen.dart';
import 'portfolio_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print('initState(): MyHomePage');
    }

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
      Scaffold(
        appBar: AppBar(title: const Text('설정')),
        body: const SettingsWidget(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Consumer<LonelyModel>(
          builder: (context, model, child) {
            return Center(
                child: _widgetOptions.elementAt(model.selectedScreenIndex));
          },
        ),
      ),
      bottomNavigationBar: Consumer<LonelyModel>(
        builder: (context, model, child) {
          return BottomNavigationBar(
            //showSelectedLabels: false,
            //showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.summarize),
                label: '포트폴리오',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.reorder),
                label: '매매 기록',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance),
                label: '계좌 관리',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: '설정',
              ),
            ],
            currentIndex: model.selectedScreenIndex,
            selectedItemColor: Theme.of(context).colorScheme.primaryContainer,
            onTap: model.setSelectedScreenIndex,
          );
        },
      ),
    );
  }
}
