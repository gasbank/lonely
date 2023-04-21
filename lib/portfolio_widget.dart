import 'package:flutter/material.dart';

import 'database.dart';
import 'inventory_widget.dart';
import 'my_home_page.dart';
import 'new_transaction_widget.dart';
import 'transaction_history_widget.dart';

class PortfolioContext {
  final LonelyDatabase database;
  final Future<List<Transaction>> transactionList;
  final Future<Map<String, Stock>> stockMap;
  final Future<bool> Function(Transaction transaction) onNewTransaction;
  final Function(Set<int> dbIdSet) onRemoveTransaction;

  const PortfolioContext(
      {required this.database,
      required this.transactionList,
      required this.stockMap,
      required this.onNewTransaction,
      required this.onRemoveTransaction});
}

class PortfolioWidget extends StatefulWidget {
  const PortfolioWidget({super.key, required this.portfolioContext});

  final PortfolioContext portfolioContext;

  @override
  State<StatefulWidget> createState() => _NewPortfolioState();
}

class _NewPortfolioState extends State<PortfolioWidget> {
  @override
  Widget build(BuildContext context) {
    final inventoryBuilder = FutureBuilder(
      future: widget.portfolioContext.stockMap,
      builder: (context, stockMap) {
        return FutureBuilder(
          future: widget.portfolioContext.transactionList,
          builder: (context, transactionList) {
            if (stockMap.hasData && transactionList.hasData) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: InventoryWidget(
                  itemMap: createItemMap(transactionList.data!, stockMap.data!),
                  database: widget.portfolioContext.database,
                  stockMap: widget.portfolioContext.stockMap,
                ),
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        );
      },
    );

    return Center(
      child: ListView(
        //mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          inventoryBuilder,
          NewTransactionWidget(
              onNewTransaction: widget.portfolioContext.onNewTransaction),
          FutureBuilder(
            future: widget.portfolioContext.transactionList,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return FittedBox(
                    child: TransactionHistoryWidget(
                  onRemoveTransaction:
                      widget.portfolioContext.onRemoveTransaction,
                  transactionList: snapshot.data!,
                  stockMap: widget.portfolioContext.stockMap,
                ));
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
          FutureBuilder(
            future: widget.portfolioContext.transactionList,
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
    );
  }
}
