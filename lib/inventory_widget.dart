import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'account_filter_widget.dart';
import 'package:provider/provider.dart';
import 'database.dart';
import 'item_widget.dart';
import 'lonely_model.dart';
import 'transaction.dart';

class InventoryWidget extends StatefulWidget {
  final Function(String) onStockSelected;

  InventoryWidget({super.key, required this.onStockSelected}) {
    if (kDebugMode) {
      print('InventoryWidget()');
    }
  }

  @override
  State<StatefulWidget> createState() => _InventoryWidgetState();
}

// TODO 현재가 조회 시마다 반복 호출되는데... 호출 빈도에 비해 계산량이 많다.
Map<String, Item> createItemMap(
    Iterable<Transaction> transactionList, Map<String, Stock> stockMap) {
  if (kDebugMode) {
    //print('createItemMap: ${transactionList.length} transactions(s), ${stockMap.length} stock(s)');
  }
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
  final Set<int> selects = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LonelyModel>(
      builder: (context, model, child) {
        final transactions = selects.isNotEmpty
            ? model.transactions
                .where((e) => e.accountId == selects.first)
                .toList()
            : model.transactions;
        final orderedItems = createItemMap(transactions, model.stocks)
            .values
            .sortedBy((e) => model.getStock(e.stockId)?.inventoryOrder ?? 0)
            .where((e) => e.count > 0)
            .toList();

        return Column(
          children: [
            AccountFilterWidget(
              accounts: model.accounts,
              selects:
                  model.accounts.map((e) => selects.contains(e.id)).toList(),
              onSelected: (index) {
                setState(() {
                  if (selects.contains(model.accounts[index].id)) {
                    selects.remove(model.accounts[index].id);
                  } else {
                    selects.clear();
                    selects.add(model.accounts[index].id!);
                  }
                });
              },
            ),
            Expanded(
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final movingItem = orderedItems[oldIndex];
                    if (kDebugMode) {
                      print(
                          'Moving ${movingItem.stockName} from index $oldIndex to $newIndex');
                    }
                    orderedItems.removeAt(oldIndex);
                    if (oldIndex > newIndex) {
                      orderedItems.insert(newIndex, movingItem);
                    } else if (oldIndex < newIndex) {
                      orderedItems.insert(newIndex - 1, movingItem);
                    }

                    for (int i = 0; i < orderedItems.length; i++) {
                      model.updateStocksInventoryOrder(
                          orderedItems[i].stockId, i);
                    }
                  });
                },
                children: [
                  for (var i = 0; i < orderedItems.length; i++) ...[
                    selects.isEmpty
                        ? ReorderableDragStartListener(
                            key: Key(orderedItems[i].stockId),
                            index: i,
                            child: buildItemWidget(orderedItems[i]),
                          )
                        : buildItemWidget(orderedItems[i])
                  ]
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  InkWell buildItemWidget(Item item) => InkWell(
        key: Key(item.stockId),
        onTap: () => widget.onStockSelected(item.stockId),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: ItemWidget(
            item: item,
          ),
        ),
      );
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
