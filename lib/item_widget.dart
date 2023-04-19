import 'package:flutter/material.dart';
import 'package:lonely_flutter/transaction_widget.dart';

class Item {
  Item(this.stockId, this.stockName, this.count, this.avgPrice);

  final String stockId;
  final String stockName;
  final int count;
  final int avgPrice;
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
