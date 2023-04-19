import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely_flutter/new_buy_sell.dart';

import 'buy_sell_history.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lonely',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MyHomePage(title: '고독한 투자자'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final _buySellHistoryEntryList = <BuySellHistoryEntry>[];

  void _incrementCounter() {
    setState(() {
      _counter++;

      _buySellHistoryEntryList.add(const BuySellHistoryEntry(
        stockId: "003030",
        stockName: "종목2",
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            NewBuySellEntry(onNewEntry: onNewBuySell),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Column(
              children: _buySellHistoryEntryList,
            ),
            const BuySellHistoryEntry(stockId: "123456", stockName: "종목1"),
            const BuySellHistoryEntry(
              stockId: "003030",
              stockName: "종목2",
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: '값을 증가시켜 봅니다~',
        child: const Icon(Icons.add),
      ),
    );
  }


  onNewBuySell(NewBuySell newBuySell) {
    if (kDebugMode) {
      print('new buy sell entry!');
      print(newBuySell);
    }
  }
}
