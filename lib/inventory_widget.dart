import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database.dart';
import 'item_widget.dart';

class InventoryWidget extends StatefulWidget {
  final Map<String, Item> itemMap;
  final LonelyDatabase database;
  final Map<String, Stock> stockMap;
  final Function(String) onStockSelected;

  InventoryWidget(
      {super.key,
      required this.itemMap,
      required this.database,
      required this.stockMap,
      required this.onStockSelected}) {
    if (kDebugMode) {
      //print('InventoryWidget()');
    }
  }

  @override
  State<StatefulWidget> createState() => _InventoryWidgetState();
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
    return ReorderableListView(
      onReorder: (oldIndex, newIndex) {},
      children: widget.itemMap.values
          .where((e) => e.count > 0)
          .map((e) => InkWell(key: Key(e.stockId),
                onTap: () => widget.onStockSelected(e.stockId),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ItemWidget(
                    item: e,
                    database: widget.database,
                    stockMap: widget.stockMap,
                  ),
                ),
              ))
          .toList(),
    );
  }
}
