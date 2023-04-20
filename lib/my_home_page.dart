import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database.dart';
import 'inventory_widget.dart';
import 'item_widget.dart';
import 'new_transaction_widget.dart';
import 'transaction_history_widget.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key,
        required this.title,
        required this.database});

  final String title;
  final LonelyDatabase database;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _transactionList = <Transaction>[];
  final _itemList = <Item>[];
  Map<String, Item> _itemMap = {};

  @override void initState() {
    loadTransactions();
    super.initState();
  }

  void loadTransactions() async {
    final transactions = await widget.database.queryTransaction();
    final transactionList =
    transactions.map((e) => Transaction.fromMap(e)).toList();

    if (kDebugMode) {
      print('${transactionList.length} transaction(s) loaded.');
    }

    setState(() {
      _transactionList.addAll(transactionList);
    });
  }

  int stockSum(String stockId, TransactionType transactionType) {
    return _transactionList
        .where(
            (e) => e.stockId == stockId && e.transactionType == transactionType)
        .map((e) => e.count)
        .fold(0, (a, b) => a + b);
  }

  Future<bool> onNewTransaction(Transaction transaction) async {
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

    final insertedId = await widget.database.insertTransaction(transaction.toMap());
    transaction.id = insertedId;

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
}
