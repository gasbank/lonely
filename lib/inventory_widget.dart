import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'database.dart';
import 'item_widget.dart';
import 'transaction.dart';

class InventoryWidget extends StatefulWidget {
  final List<Item> orderedItems;
  final Function(String) onStockSelected;

  InventoryWidget(
      {super.key, required this.orderedItems, required this.onStockSelected}) {
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
  List<Item> orderedItems = [];

  @override
  void initState() {
    super.initState();
    orderedItems = widget.orderedItems.toList();
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final movingItem = orderedItems[oldIndex];
          if (kDebugMode) {
            print('Moving ${movingItem.stockName} from index $oldIndex to $newIndex');
          }
          orderedItems.removeAt(oldIndex);
          if (oldIndex > newIndex) {
            orderedItems.insert(newIndex, movingItem);
          } else if (oldIndex < newIndex) {
            orderedItems.insert(newIndex - 1, movingItem);
          }
        });
      },
      children: orderedItems
          .map((e) => InkWell(
                key: Key(e.stockId),
                onTap: () => widget.onStockSelected(e.stockId),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ItemWidget(
                    item: e,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

extension MyIterable<E> on Iterable<E> {
  Iterable<E> sortedBy(Comparable Function(E e) key) =>
      toList()..sort((a, b) => key(a).compareTo(key(b)));

  Iterable<E> stableSortedBy(Comparable Function(E e) key) {
    final copy = toList();
    mergeSort(copy, compare: (a, b) => key(a).compareTo(key(b)));
    return copy;
  }
}
