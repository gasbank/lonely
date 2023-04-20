import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database.dart';
import 'inventory_widget.dart';
import 'item_widget.dart';
import 'new_transaction_widget.dart';
import 'transaction_history_widget.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.database});

  final String title;
  final LonelyDatabase database;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

Map<String, Item> createItemMap(List<Transaction> transactionList) {
  final itemMap = <String, Item>{};

  for (var e in transactionList) {
    if (e.stockId.isEmpty || e.count <= 0 || e.price <= 0) {
      if (kDebugMode) {
        print('invalid transaction');
      }
      continue;
    }

    final item = itemMap[e.stockId] ?? Item(e.stockId);

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

    itemMap[e.stockId] = item;
  }

  return itemMap;
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Transaction>> _transactionList;

  @override
  void initState() {
    super.initState();
    _transactionList = loadTransactions();
  }

  Future<List<Transaction>> loadTransactions() async {
    final transactions = await widget.database.queryTransaction();

    if (kDebugMode) {
      print('${transactions.length} transaction(s) loaded from database.');
    }

    return transactions.map((e) => Transaction.fromMap(e)).toList();
  }

  Future<int> stockSum(String stockId, TransactionType transactionType) async {
    final sum = (await _transactionList)
        .where(
            (e) => e.stockId == stockId && e.transactionType == transactionType)
        .map((e) => e.count)
        .fold(0, (a, b) => a + b);
    return sum;
  }

  Future<bool> onNewTransaction(Transaction transaction) async {
    if (kDebugMode) {
      print('new transaction entry!');
      print(transaction);
    }

    final item = (createItemMap(await _transactionList))[transaction.stockId];

    if (transaction.transactionType == TransactionType.sell) {
      final buySum = await stockSum(transaction.stockId, TransactionType.buy);
      final sellSum = await stockSum(transaction.stockId, TransactionType.sell);
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

    final insertedId =
        await widget.database.insertTransaction(transaction.toMap());
    transaction.id = insertedId;

    final transactionList = await _transactionList;

    setState(() {
      transactionList.add(transaction);
    });

    return true;
  }

  void onRemoveTransaction(Set<int> dbIdSet) async {
    final count = await widget.database.removeTransaction(dbIdSet.toList());
    showSimpleError('기록 $count개가 지워졌다~');
    final transactionList = await _transactionList;
    setState(() {
      transactionList.removeWhere((e) => dbIdSet.contains(e.id));
    });
  }

  void showSimpleError(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Center(
          child: ListView(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder(
                future: _transactionList,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return InventoryWidget(
                        itemMap: createItemMap(snapshot.data!));
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              NewTransactionWidget(onNewTransaction: onNewTransaction),
              FutureBuilder(
                future: _transactionList,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return FittedBox(
                        child: TransactionHistoryWidget(
                            onRemoveTransaction: onRemoveTransaction,
                            transactionList: snapshot.data!));
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              FutureBuilder(
                future: _transactionList,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('${snapshot.data!.length} transaction(s)');
                  } else {
                    return const Text('---');
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
