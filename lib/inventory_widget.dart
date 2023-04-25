import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'account_list_widget.dart';
import 'database.dart';
import 'item_widget.dart';
import 'lonely_model.dart';
import 'transaction.dart';

class InventoryWidget extends StatefulWidget {
  final Function(String) onStockSelected;

  InventoryWidget({super.key, required this.onStockSelected}) {
    if (kDebugMode) {
      //print('InventoryWidget()');
    }
  }

  @override
  State<StatefulWidget> createState() => _InventoryWidgetState();
}

Map<String, Item> createItemMap(
    List<Transaction> transactionList, Map<String, Stock> stockMap) {
  final itemMap = <String, Item>{};

  for (var e in transactionList) {
    if (e.stockId.isEmpty || e.count <= 0 || e.price <= 0) {
      if (kDebugMode) {
        print('invalid transaction');
      }
      continue;
    }

    final item = itemMap[e.stockId] ?? Item(e.stockId);

    if (item.stockName.isEmpty) {
      item.stockName = stockMap[e.stockId]?.name ?? '';
    }

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

class _InventoryWidgetState extends State<InventoryWidget> {
  @override
  void initState() {
    if (kDebugMode) {
      //print('initState(): InventoryWidget');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LonelyModel>(
      builder: (context, model, child) {
        return ReorderableListView(
          onReorder: (oldIndex, newIndex) {},
          children: createItemMap(model.transactions, model.stocks)
              .values
              .sortedBy((e) => e.stockId)
              .where((e) => e.count > 0)
              .map((e) => InkWell(
                    key: Key(e.stockId),
                    onTap: () => widget.onStockSelected(e.stockId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      child: ItemWidget(
                        item: e,
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
