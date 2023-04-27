import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'database.dart';
import 'new_transaction_widget.dart';
import 'transaction.dart';
import 'transaction_history_widget.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({super.key, required this.database}) {
    if (kDebugMode) {
      print('HistoryScreen()');
    }
  }

  final LonelyDatabase database;

  @override
  State<StatefulWidget> createState() => _NewHistoryState();
}

class _NewHistoryState extends State<HistoryScreen> {
  final _stockIdController = TextEditingController();

  Future<List<Transaction>> loadTransactions() async {
    final transactions = await widget.database.queryTransactions();

    if (kDebugMode) {
      print('${transactions.length} transaction(s) loaded from database.');
    }

    return transactions.map((e) => Transaction.fromMap(e)).toList();
  }

  Future<Map<String, Stock>> loadStocks() async {
    final stocks = await widget.database.queryStocks();

    if (kDebugMode) {
      print('${stocks.length} stock(s) loaded from database.');
    }

    final stockList = stocks.map((e) => Stock.fromMap(e)).toList();

    final m = <String, Stock>{};
    for (var s in stockList) {
      m[s.stockId] = s;
    }

    return m;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        NewTransactionWidget(
          stockIdController: _stockIdController,
        ),
        TransactionHistoryWidget(
          stockIdController: _stockIdController,
        ),
      ],
    );
  }
}
