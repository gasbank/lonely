import 'package:flutter/material.dart';

import 'item_widget.dart';

class InventoryWidget extends StatefulWidget {
  const InventoryWidget({super.key, required this.itemList});

  final List<Item> itemList;

  @override
  State<StatefulWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          widget.itemList.map((e) => ItemWidget(item: e)).toList(),
    );
  }
}
