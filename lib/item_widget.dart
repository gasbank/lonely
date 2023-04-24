import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lonely_flutter/database.dart';
import 'package:provider/provider.dart';
import 'lonely_model.dart';
import 'number_format_util.dart';

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

  factory KrStock.fromJsonN(Map<String, dynamic> json) {
    final closePrice =
        int.tryParse((json['closePrice'] as String).replaceAll(',', ''))!;
    return KrStock(
        itemCode: json['itemCode'],
        stockName: json['stockName'],
        closePrice: closePrice);
  }

  factory KrStock.fromJsonD(Map<String, dynamic> json) {
    // tradePrice: 1000.0일 때도 있고 1000일 때도 있더라~
    final closePrice = json['tradePrice'].toDouble().round();
    return KrStock(
        itemCode: (json['symbolCode'] as String).substring(1),
        stockName: json['name'],
        closePrice: closePrice);
  }
}

Future<int?> writeKrStockToDb(
    Future<KrStock?> stock, LonelyDatabase database) async {
  final s = await stock;

  if (s != null &&
      s.stockName.isNotEmpty &&
      (await database.queryStockName(s.itemCode)) == null) {
    return await database.insertStock(
        Stock(id: 0, stockId: s.itemCode, name: s.stockName, closePrice: s.closePrice).toMap());
  }

  return null;
}

class ItemWidget extends StatefulWidget {
  final Item item;
  final LonelyDatabase database;
  final Future<Map<String, Stock>> stockMap;

  ItemWidget(
      {super.key,
      required this.item,
      required this.database,
      required this.stockMap}) {
    if (kDebugMode) {
      //print('ItemWidget()');
    }
  }

  @override
  State<StatefulWidget> createState() => _ItemWidgetState();
}

Future<KrStock?> fetchKrStockN(String stockId) async {
  if (stockId.length != 6) {
    return null;
  }

  try {
    final response = await http
        .get(Uri.parse('https://m.stock.naver.com/api/stock/$stockId/basic'));
    if (response.statusCode == 200) {
      return KrStock.fromJsonN(jsonDecode(response.body));
    } else if ((response.statusCode == 409)) {
      return null;
    } else {
      throw Exception('failed to http get');
    }
  } on SocketException catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  } on http.ClientException catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  }
}

Future<KrStock?> fetchKrStockD(String stockId) async {
  if (stockId.length != 6) {
    return null;
  }

  try {
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
  } on SocketException catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  } on http.ClientException catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  }
}

class _ItemWidgetState extends State<ItemWidget> {
  late final Stream<KrStock?> _stockStream;
  late final LonelyModel _model;

  @override void initState() {
    super.initState();

    _model = context.read<LonelyModel>();

    _stockStream = onceAndPeriodic(const Duration(seconds: 5), () {
      final fetchFuture = Random().nextInt(2) == 0
          ? fetchKrStockD(widget.item.stockId)
          : fetchKrStockN(widget.item.stockId);
      saveToModel(fetchFuture);
      return fetchFuture;
    });
  }

  void saveToModel(Future<KrStock?> fetchFuture) async {
    final krStock = await fetchFuture;
    if (krStock != null) {
      _model.setStock(Stock(id: 0, stockId: krStock.itemCode, name: krStock.stockName, closePrice: krStock.closePrice));
    }
  }

  Widget buildWidget(Item item, LonelyModel model) {
    final stock = model.stocks[item.stockId];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(
                      '${stock?.name ?? '---'} ${formatThousands(widget.item.count)}주'),
                ),
                const SizedBox(
                  width: 4,
                ),
                Text(item.stockId,
                    style: DefaultTextStyle.of(context)
                        .style
                        .apply(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            Text(
            stock != null
                    ? formatThousands(stock.closePrice * widget.item.count)
                    : '---',
                style: DefaultTextStyle.of(context)
                    .style
                    .apply(fontSizeFactor: 1.8)),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(stock != null
                ? '${formatThousandsStr(((stock.closePrice / item.avgPrice() - 1) * 100).toStringAsFixed(2))}%'
                : '---%'),
            Text(stock != null
                ? formatThousandsStr(
                    item.diffPrice(stock.closePrice).toStringAsFixed(0))
                : '---'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KrStock?>(
      stream: _stockStream,
      builder: (_, __) {
        return Consumer<LonelyModel>(
          builder: (context, lonelyModel, child) {
            return buildWidget(widget.item, lonelyModel);
          },
        );
      }
    );
  }
}

Stream<T> onceAndPeriodic<T>(
    Duration period, Future<T> Function() computation) async* {
  yield await computation();
  yield* Stream.periodic(period).asyncMap((e) => computation());
}
