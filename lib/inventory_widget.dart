import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database.dart';
import 'item_widget.dart';

class InventoryWidget extends StatefulWidget {
  final Map<String, Item> itemMap;
  final LonelyDatabase database;
  final Future<Map<String, Stock>> stockMap;

  const InventoryWidget(
      {super.key,
      required this.itemMap,
      required this.database,
      required this.stockMap});

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
    return Column(
      children: widget.itemMap.values
          .map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ItemWidget(
                  item: e,
                  database: widget.database,
                  stockMap: widget.stockMap,
                ),
          ))
          .toList(),
    );
  }
}
