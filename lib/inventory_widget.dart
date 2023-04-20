import 'package:flutter/material.dart';

import 'database.dart';
import 'item_widget.dart';

class InventoryWidget extends StatefulWidget {
  const InventoryWidget(
      {super.key, required this.itemMap, required this.database});

  final Map<String, Item> itemMap;
  final LonelyDatabase database;

  @override
  State<StatefulWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.itemMap.values
          .map((e) => ItemWidget(
                item: e,
                database: widget.database,
              ))
          .toList(),
    );
  }
}
