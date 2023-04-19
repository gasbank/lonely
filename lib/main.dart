import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely_flutter/item_widget.dart';
import 'package:lonely_flutter/new_transaction_widget.dart';
import 'package:lonely_flutter/inventory_widget.dart';
import 'package:lonely_flutter/transaction_history_widget.dart';

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
  final _transactionList = <Transaction>[];
  final _itemList = <Item>[];
  Map<String, Item> _itemMap = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            InventoryWidget(itemList: _itemList),
            NewTransactionWidget(onNewTransaction: onNewTransaction),
            FittedBox(
                child: TransactionHistoryWidget(
                    transactionList: _transactionList)),
          ],
        ),
      ),
    );
  }

  int stockSum(String stockId, TransactionType transactionType) {
    return _transactionList
        .where(
            (e) => e.stockId == stockId && e.transactionType == transactionType)
        .map((e) => e.count)
        .fold(0, (a, b) => a + b);
  }

  bool onNewTransaction(Transaction transaction) {
    if (kDebugMode) {
      print('new transaction entry!');
      print(transaction);
    }

    final item = _itemMap[transaction.stockId];

    if (transaction.transactionType == TransactionType.sell) {
      final buySum = stockSum(transaction.stockId, TransactionType.buy);
      final sellSum = stockSum(transaction.stockId, TransactionType.sell);
      if (buySum - sellSum < transaction.count) {
        showSimpleError('가진 것보다 더 팔 수는 없죠.');
        return false;
      }

      if (item != null) {
        transaction.earn = ((transaction.price - item.accumPrice / item.count) *
                transaction.count)
            .round();
      }
    }

    setState(() {
      _transactionList.add(transaction);
      _itemMap = createItemMap();
    });

    return true;
  }

  void showSimpleError(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  Map<String, Item> createItemMap() {
    final newItemMap = <String, Item>{};

    for (var e in _transactionList) {
      if (e.stockId.isEmpty || e.count <= 0 || e.price <= 0) {
        if (kDebugMode) {
          print('invalid transaction');
        }
        continue;
      }

      final item = newItemMap[e.stockId] ?? Item(e.stockId);

      if (e.transactionType == TransactionType.buy) {
        item.accumPrice += e.count * e.price;
        item.count += e.count;

        item.accumBuyPrice += e.count * e.price;
        item.accumBuyCount += e.count;
      } else if (e.transactionType == TransactionType.sell) {
        item.accumPrice -= (e.count * (item.accumPrice / item.count)).round();
        item.count -= e.count;

        item.accumSellPrice += e.count * e.price;
        item.accumSellCount += e.count;
        item.accumEarn += e.earn ?? 0;
      }

      newItemMap[e.stockId] = item;
    }

    return newItemMap;
  }
}
