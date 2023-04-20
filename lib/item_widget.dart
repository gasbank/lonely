import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'transaction_widget.dart';

class Item {
  Item(this.stockId);

  final String stockId;
  String stockName = '';
  int count = 0;
  int accumPrice = 0;
  int accumBuyPrice = 0;
  int accumSellPrice = 0;
  int accumBuyCount = 0;
  int accumSellCount = 0;
  int accumEarn = 0;

  double avgPrice() => count > 0 ? accumPrice / count : 0;

  double diffPrice(int closePrice) => (closePrice - avgPrice()) * count;
}

class KrStock {
  final String itemCode;
  final String stockName;
  final int closePrice;

  KrStock(
      {required this.itemCode,
      required this.stockName,
      required this.closePrice});

  factory KrStock.fromJson(Map<String, dynamic> json) {
    final closePrice =
        int.tryParse((json['closePrice'] as String).replaceAll(',', ''))!;
    return KrStock(
        itemCode: json['itemCode'],
        stockName: json['stockName'],
        closePrice: closePrice);
  }
}

class ItemWidget extends StatefulWidget {
  const ItemWidget({super.key, required this.item});

  final Item item;

  @override
  State<StatefulWidget> createState() => _ItemWidgetState();
}

Future<KrStock?> fetchStock(String stockId) async {
  final response = await http
      .get(Uri.parse('https://m.stock.naver.com/api/stock/$stockId/basic'));
  if (response.statusCode == 200) {
    return KrStock.fromJson(jsonDecode(response.body));
  } else if ((response.statusCode == 409)) {
    return null;
  } else {
    throw Exception('failed to http get');
  }
}

class _ItemWidgetState extends State<ItemWidget> {
  late Future<KrStock?> stock;

  @override
  void initState() {
    super.initState();
    stock = fetchStock(widget.item.stockId);
  }

  Widget buildWidget(Item item, KrStock? stock) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.indigoAccent,
                  ),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(
                  '${stock?.stockName ?? '---'} ${formatThousands(widget.item.count)}주'),
            ),
            Text(
                stock != null
                    ? '${formatThousands(stock.closePrice * widget.item.count)}원'
                    : '---원',
                style: DefaultTextStyle.of(context)
                    .style
                    .apply(fontSizeFactor: 1.8)),
          ],
        ),
        const SizedBox(width: 10),
        Column(
          children: [
            Text(stock != null
                ? '${formatThousandsStr(((stock.closePrice / item.avgPrice() - 1) * 100).toStringAsFixed(1))}%'
                : '---%'),
            Text(stock != null
                ? '${formatThousandsStr(item.diffPrice(stock.closePrice).toStringAsFixed(0))}원'
                : '---원'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: stock,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return buildWidget(widget.item, snapshot.data!);
        } else {
          return buildWidget(widget.item, null);
        }
      },
    );
  }
}
