import 'package:flutter/material.dart';
import 'package:lonely/account_filter_widget.dart';
import 'package:lonely/database.dart';
import 'package:lonely/fetch_util.dart';
import 'package:lonely/inventory_widget.dart';
import 'package:lonely/item_widget.dart';
import 'package:lonely/model/lonely_model.dart';
import 'package:lonely/transaction.dart';
import 'package:provider/provider.dart';

enum RealizedProfitMarketFilter { domestic, foreign }

int realizedProfitTotalEarn(Iterable<Item> items) {
  return items.fold(0, (sum, item) => sum + item.accumEarn);
}

List<Item> buildRealizedProfitItems(
  Iterable<Transaction> transactions,
  Map<String, Stock> stocks,
{
  RealizedProfitMarketFilter? marketFilter,
}) {
  var items = createItemMap(transactions, stocks).values.toList();
  if (marketFilter != null) {
    items = items
        .where((item) => marketFilter == RealizedProfitMarketFilter.domestic
            ? isKoreanStock(item.stockId)
            : !isKoreanStock(item.stockId))
        .toList();
  }
  items.sort((a, b) {
    final earnComp = b.accumEarn.compareTo(a.accumEarn);
    if (earnComp != 0) {
      return earnComp;
    }

    final nameA = a.stockName.isNotEmpty ? a.stockName : a.stockId;
    final nameB = b.stockName.isNotEmpty ? b.stockName : b.stockId;
    return nameA.compareTo(nameB);
  });
  return items;
}

class RealizedProfitScreen extends StatelessWidget {
  const RealizedProfitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RealizedProfitScreenBody();
  }
}

class _RealizedProfitScreenBody extends StatefulWidget {
  const _RealizedProfitScreenBody();

  @override
  State<_RealizedProfitScreenBody> createState() =>
      _RealizedProfitScreenBodyState();
}

class _RealizedProfitScreenBodyState extends State<_RealizedProfitScreenBody> {
  RealizedProfitMarketFilter? _marketFilter;

  void _toggleMarketFilter(RealizedProfitMarketFilter nextFilter) {
    setState(() {
      if (_marketFilter == nextFilter) {
        _marketFilter = null;
      } else {
        _marketFilter = nextFilter;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LonelyModel>(builder: (context, model, child) {
      final items = buildRealizedProfitItems(
        model.accountFilteredTransactions,
        model.stocks,
        marketFilter: _marketFilter,
      );
      final totalEarn = realizedProfitTotalEarn(items);

      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SharedAccountFilterWidget(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LabeledToggleFilterWidget(
              selects: [
                _marketFilter == RealizedProfitMarketFilter.domestic,
                _marketFilter == RealizedProfitMarketFilter.foreign,
              ],
              onSelected: (index) => _toggleMarketFilter(
                index == 0
                    ? RealizedProfitMarketFilter.domestic
                    : RealizedProfitMarketFilter.foreign,
              ),
              children: const [
                Text('국내'),
                Text('해외'),
              ],
            ),
          ),
          if (_marketFilter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Center(
                child: Column(
                  children: [
                    const Text('총 수익'),
                    Text(
                      key: const Key('realized-profit-total-earn'),
                      priceDataToDisplayTruncatedInt(
                        _marketFilter == RealizedProfitMarketFilter.domestic
                            ? '005930'
                            : 'TSLA',
                        totalEarn,
                      ),
                      style: TextStyle(
                        color: totalEarn > 0
                            ? Colors.redAccent
                            : totalEarn < 0
                                ? Colors.blueAccent
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final stock = model.getStock(item.stockId);
                final stockName = stock?.name ?? item.stockName;
                final earnText =
                    priceDataToDisplayTruncatedInt(item.stockId, item.accumEarn);
                final earnColor = item.accumEarn > 0
                    ? Colors.redAccent
                    : item.accumEarn < 0
                        ? Colors.blueAccent
                        : null;
                final displayName =
                    stockName.isNotEmpty ? stockName : item.stockId;

                return ListTile(
                  leading: StockCircleAvatar(
                    stockId: item.stockId,
                    label: displayName,
                  ),
                  title: Text(displayName),
                  trailing: Text(
                    earnText,
                    style: TextStyle(color: earnColor),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
