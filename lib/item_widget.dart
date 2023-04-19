import 'package:flutter/material.dart';
import 'package:lonely_flutter/transaction_widget.dart';

class Item {
  Item(this.stockId);

  final String stockId;
  String stockName = '';
  int count = 0;
  int avgPrice = 0;
  int accumPrice = 0;
  int accumBuyPrice = 0;
  int accumSellPrice = 0;
  int accumBuyCount = 0;
  int accumSellCount = 0;
  int accumEarn = 0;
}

class ItemWidget extends StatefulWidget {
  const ItemWidget({super.key, required this.item});

  final Item item;

  @override
  State<StatefulWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(widget.item.stockId),
      Text(widget.item.stockName),
      Text('${formatThousands(widget.item.count)}주'),
      Text('${formatThousands(widget.item.avgPrice)}원')
    ]);
  }
}
