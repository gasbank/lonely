import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely_flutter/fetch_util.dart';
import 'database.dart';
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

  // Item 보여지는 순서는 여기서 관리하지 말고 Stock.inventoryOrder 이용한다.

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

  factory KrStock.fromJsonY(Map<String, dynamic> json) {
    final meta = json['chart']['result'][0]['meta'];
    final closePrice = meta['regularMarketPrice'] as double;
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
            closePrice: s.closePrice)
        .toMap());
  }

  return null;
}

class ItemWidget extends StatefulWidget {
  final Item item;
  final bool isBalanceVisible;

  const ItemWidget({
    super.key,
    required this.item,
    required this.isBalanceVisible,
  });

  @override
  State<StatefulWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  late final Stream<KrStock?> _stockStream;
  late final LonelyModel _model;

  @override
  void initState() {
    super.initState();

    _model = context.read<LonelyModel>();

    _stockStream = onceAndPeriodic(const Duration(seconds: 5), () {
      final fetchFuture = fetchStockInfo(widget.item.stockId);
      saveToModel(fetchFuture);
      return fetchFuture;
    });
  }

  void saveToModel(Future<KrStock?> fetchFuture) async {
    final krStock = await fetchFuture;
    if (krStock != null) {
      _model.setStock(Stock(
          id: 0,
          stockId: krStock.itemCode,
          name: krStock.stockName,
          closePrice: krStock.closePrice));
    }
  }

  Widget buildWidget(Item item, LonelyModel model) {
    final stock = model.stocks[item.stockId];

    final currentBalanceStr = (stock != null && stock.closePrice != null)
        ? priceDataToDisplayTruncated(
            stock.stockId, (stock.closePrice! * widget.item.count).toDouble())
        : '---';

    final percentStr = (stock != null && stock.closePrice != null)
        ? '${formatThousandsStr(((stock.closePrice! / item.avgPrice() - 1) * 100).toStringAsFixed(2))}%'
        : '---%';

    final diffPriceStr = (stock != null && stock.closePrice != null)
        ? priceDataToDisplayTruncated(
            item.stockId, item.diffPrice(stock.closePrice!))
        : '---';

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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              percentStr,
              style:
                  DefaultTextStyle.of(context).style.apply(fontWeightDelta: 0),
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
