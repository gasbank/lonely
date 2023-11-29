import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'model/lonely_model.dart';
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

Widget _createPage(String title, Widget widget) {
  return PageWidget(
    child: Scaffold(
      //appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: widget,
      ),
    ),
  );
}

class _MyHomePageState extends State<MyHomePage> {
  late final List<Widget> _pages;
  late final PageController _pageController;
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print('initState(): MyHomePage');
    }

    _pages = <Widget>[
      _createPage('포트폴리오', const PortfolioScreen()),
      _createPage('기록', const HistoryScreen()),
      _createPage('계좌', const AccountListWidget()),
      _createPage('설정', SettingsWidget(_packageInfo)),
    ];

    _pageController = PageController(
        initialPage: context.read<LonelyModel>().selectedScreenIndex);

    context.read<LonelyModel>().pageController = _pageController;

    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _pages,
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
                label: '기록',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance),
                label: '계좌',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: '설정',
              ),
            ],
            currentIndex: model.selectedScreenIndex,
            selectedItemColor: Theme.of(context).colorScheme.primaryContainer,
            onTap: (selectedPageIndex) {
              model.selectedPageIndex = selectedPageIndex;
            },
          );
        },
      ),
    );
  }
}

class PageWidget extends StatefulWidget {
  final Widget child;

  const PageWidget({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => _PageWidgetState();
}

class _PageWidgetState extends State<PageWidget>
    with AutomaticKeepAliveClientMixin<PageWidget> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
