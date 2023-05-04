import 'dart:async';
import 'package:flutter/material.dart';
import 'fetch_util.dart';
import 'database.dart';
import 'package:provider/provider.dart';
import 'lonely_model.dart';
import 'number_format_util.dart';
import 'price_model.dart';

const unknownPercentStr = '---%';
const unknownPriceStr = '---';

class Item {
  final String stockId;
  String stockName = '';
  int count = 0;
  int accumPrice = 0;
  int accumBuyPrice = 0;
  int accumSellPrice = 0;
  int accumBuyCount = 0;
  int accumSellCount = 0;
  int accumEarn = 0;

  Item(this.stockId);

  // Item 보여지는 순서는 여기서 관리하지 말고 Stock.inventoryOrder 이용한다.

  double avgPrice() => count > 0 ? accumPrice / count : 0;

  double diffPrice(int closePrice) => (closePrice - avgPrice()) * count;
}

class ItemOnAccount {
  final Item item;
  final int? accountId;

  ItemOnAccount(this.item, this.accountId);
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

  factory KrStock.fromJsonY(Map<String, dynamic> json) {
    final meta = json['chart']['result'][0]['meta'];
    final priceNode = meta['regularMarketPrice'];
    if (priceNode == null) {
      throw const FormatException('regularMarketPrice not found');
    }

    final closePrice = priceNode as double;
    return KrStock(
        itemCode: meta['symbol'] as String,
        stockName: meta['symbol'] as String,
        closePrice: (closePrice * 10000).round());
  }
}

Future<int?> writeKrStockToDb(
    Future<KrStock?> stock, LonelyDatabase database) async {
  final s = await stock;

  if (s != null &&
      s.stockName.isNotEmpty &&
      (await database.queryStockName(s.itemCode)) == null) {
    return await database.insertStock(Stock(
      id: 0,
      stockId: s.itemCode,
      name: s.stockName,
    ).toMap());
  }

  return null;
}

class ItemWidget extends StatefulWidget {
  final Item item;
  final bool isBalanceVisible;
  final LonelyModel model;
  final PriceModel priceModel;

  const ItemWidget({
    super.key,
    required this.item,
    required this.isBalanceVisible,
    required this.model,
    required this.priceModel,
  });

  @override
  State<StatefulWidget> createState() => _ItemWidgetState();
}

Color colorFor(String text) {
  var hash = 0;
  for (var i = 0; i < text.length; i++) {
    hash = text.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final finalHash = hash.abs() % (256 * 256 * 256);
  final red = ((finalHash & 0xFF0000) >> 16);
  final blue = ((finalHash & 0xFF00) >> 8);
  final green = ((finalHash & 0xFF));
  final color = Color.fromRGBO(red, green, blue, 1);
  return color;
}

class _ItemWidgetState extends State<ItemWidget> {
  late final Stream<KrStock?> _stockStream;

  @override
  void initState() {
    super.initState();

    _stockStream =
        onceAndPeriodic(Duration(seconds: widget.item.count > 0 ? 5 : 50), () {
      final fetchFuture = fetchStockInfo(widget.item.stockId);
      saveToModel(fetchFuture);
      return fetchFuture;
    });
  }

  void saveToModel(Future<KrStock?> fetchFuture) async {
    final krStock = await fetchFuture;
    if (krStock != null) {
      widget.model.setStock(Stock(
        id: 0,
        stockId: krStock.itemCode,
        name: krStock.stockName,
      ));
      widget.priceModel.setPrice(
        krStock.itemCode,
        krStock.closePrice,
      );
    }
  }

  Widget buildWidget(Item item, LonelyModel model) {
    final stockId = stockIdAlternatives[item.stockId] ?? item.stockId;

    final stock = model.stocks[stockId];
    final stockPrice = widget.priceModel.prices[stockId];

    final stockName = stock?.name ?? '---';

    final currentBalanceStr = (stock != null && stockPrice?.price != null)
        ? priceDataToDisplayTruncated(
            stockId, (stockPrice!.price! * widget.item.count).toDouble())
        : unknownPriceStr;

    final percentStr = (stock != null &&
            stockPrice?.price != null &&
            item.count > 0)
        ? '${formatThousandsStr(((stockPrice!.price! / item.avgPrice() - 1) * 100).toStringAsFixed(2))}%'
        : unknownPercentStr;

    final diffPriceStr = (stock != null && stockPrice?.price != null)
        ? priceDataToDisplayTruncated(
            stockId, item.diffPrice(stockPrice!.price!))
        : unknownPriceStr;

    return Row(
      crossAxisAlignment: widget.isBalanceVisible
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorFor(stockId),
                  child: Text(
                    stockName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                const SizedBox(
                  width: 4,
                ),
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
                Text(stockId,
                    style: DefaultTextStyle.of(context)
                        .style
                        .apply(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            if (widget.isBalanceVisible) ...[
              Text(currentBalanceStr,
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 1.8)),
            ],
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: widget.isBalanceVisible
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.center,
          children: [
            Text(
              percentStr,
              style: percentStr != unknownPercentStr
                  ? DefaultTextStyle.of(context)
                      .style
                      .apply(fontWeightDelta: 0)
                      .apply(
                          color: percentStr[0] == '-'
                              ? Colors.blueAccent
                              : Colors.redAccent)
                  : null,
            ),
            if (widget.isBalanceVisible) ...[
              Text(diffPriceStr),
            ],
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
        });
  }
}

Stream<T> onceAndPeriodic<T>(
    Duration period, Future<T> Function() computation) async* {
  yield await computation();
  yield* Stream.periodic(period).asyncMap((e) => computation());
}
