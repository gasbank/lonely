import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lonely_flutter/database.dart';
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

  KrStock({required this.itemCode,
    required this.stockName,
    required this.closePrice});

  factory KrStock.fromJsonN(Map<String, dynamic> json) {
    final closePrice =
    int.tryParse((json['closePrice'] as String).replaceAll(',', ''))!;
    return KrStock(
        itemCode: json['itemCode'],
        stockName: json['stockName'],
        closePrice: closePrice);
  }

  factory KrStock.fromJsonD(Map<String, dynamic> json) {
    final closePrice = json['tradePrice'];
    return KrStock(
        itemCode: (json['symbolCode'] as String).substring(1),
        stockName: json['name'],
        closePrice: closePrice);
  }
}

Future<int?> writeKrStockToDb(Future<KrStock?> stock,
    LonelyDatabase database) async {
  final s = await stock;

  if (s != null &&
      s.stockName.isNotEmpty &&
      (await database.queryStockName(s.itemCode)) == null) {
    return await database.insertStock(
        Stock(id: 0, stockId: s.itemCode, name: s.stockName).toMap());
  }

  return null;
}

class ItemWidget extends StatefulWidget {
  final Item item;
  final LonelyDatabase database;
  final Future<Map<String, Stock>> stockMap;

  const ItemWidget({super.key,
    required this.item,
    required this.database,
    required this.stockMap});

  @override
  State<StatefulWidget> createState() => _ItemWidgetState();
}

Future<KrStock?> fetchKrStockN(String stockId) async {
  final response = await http
      .get(Uri.parse('https://m.stock.naver.com/api/stock/$stockId/basic'));
  if (response.statusCode == 200) {
    return KrStock.fromJsonN(jsonDecode(response.body));
  } else if ((response.statusCode == 409)) {
    return null;
  } else {
    throw Exception('failed to http get');
  }
}

Future<KrStock?> fetchKrStockD(String stockId) async {
  final response = await http.get(
      Uri.parse(
          'https://finance.daum.net/api/quotes/A$stockId?changeStatistics=true&chartSlideImage=true&isMobile=true'),
      headers: {
        'referer': 'https://m.finance.daum.net/',
      });
  if (response.statusCode == 200) {
    return KrStock.fromJsonD(jsonDecode(response.body));
  } else if ((response.statusCode == 409)) {
    // Conflict
    return null;
  } else if ((response.statusCode == 502)) {
    // Bad Gateway
    return null;
  } else {
    throw Exception('failed to http get');
  }
}

class _ItemWidgetState extends State<ItemWidget> {
  late Future<KrStock?> krStock;

  @override
  void initState() {
    super.initState();
    krStock = fetchKrStockN(widget.item.stockId);
    //writeKrStockToDb(krStock, widget.database);
  }

  Widget buildWidget(Item item, KrStock? stock, Map<String, Stock>? stockMap) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(
                  '${item.stockId} ${stock?.stockName ?? stockMap?[item.stockId]?.name ??
                      '---'} ${formatThousands(widget.item.count)}주'),
            ),
            Text(
                stock != null
                    ? '${formatThousands(
                    stock.closePrice * widget.item.count)}원'
                    : '---원',
                style: DefaultTextStyle
                    .of(context)
                    .style
                    .apply(fontSizeFactor: 1.8)),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(stock != null
                ? '${formatThousandsStr(
                ((stock.closePrice / item.avgPrice() - 1) * 100)
                    .toStringAsFixed(2))}%'
                : '---%'),
            Text(stock != null
                ? '${formatThousandsStr(
                item.diffPrice(stock.closePrice).toStringAsFixed(0))}원'
                : '---원'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.stockMap,
      builder: (context, stockMap) {
        return StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 5)).asyncMap((e) =>
          Random().nextInt(2) == 0
              ? fetchKrStockD(widget.item.stockId)
              : fetchKrStockN(widget.item.stockId)),
          builder: (context, krStock) {
            return buildWidget(widget.item, krStock.data, stockMap.data);
          },
        );
      },
    );
  }
}
