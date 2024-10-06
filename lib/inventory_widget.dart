import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely/number_format_util.dart';
import 'fetch_util.dart';
import 'new_transaction_widget.dart';
import 'account_filter_widget.dart';
import 'package:provider/provider.dart';
import 'database.dart';
import 'item_widget.dart';
import 'model/lonely_model.dart';
import 'model/price_model.dart';
import 'transaction.dart';

class InventoryWidget extends StatefulWidget {
  final Function(String) onStockSelected;
  final PriceModel priceModel;

  InventoryWidget({
    super.key,
    required this.onStockSelected,
    required this.priceModel,
  }) {
    if (kDebugMode) {
      print('InventoryWidget()');
    }
  }

  @override
  State<StatefulWidget> createState() => _InventoryWidgetState();
}

// TODO 현재가 조회 시마다 반복 호출되는데... 호출 빈도에 비해 계산량이 많다.
Map<String, Item> createItemMap(
    Iterable<Transaction> transactionList, Map<String, Stock> stockMap) {
  if (kDebugMode) {
    //print('createItemMap: ${transactionList.length} transactions(s), ${stockMap.length} stock(s)');
  }
  final itemMap = <String, Item>{};

  for (var e in transactionList) {
    final stockId = stockIdAlternatives[e.stockId] ?? e.stockId;

    if (stockId.isEmpty || e.count <= 0 || e.price <= 0) {
      if (kDebugMode) {
        print('invalid transaction');
      }
      continue;
    }

    final item = itemMap[stockId] ?? Item(stockId);

    if (item.stockName.isEmpty) {
      item.stockName = stockMap[stockId]?.name ?? '';
    }

    switch (e.transactionType) {
      case TransactionType.buy:
      case TransactionType.splitIn:
      case TransactionType.transferIn:
        item.accumPrice += e.count * e.price;
        item.count += e.count;

        item.accumBuyPrice += e.count * e.price;
        item.accumBuyCount += e.count;
        break;
      case TransactionType.sell:
      case TransactionType.splitOut:
      case TransactionType.transferOut:
        if (item.count != 0) {
          item.accumPrice -= (e.count * (item.accumPrice / item.count)).round();
        } else {
          if (kDebugMode) {
            print('createItemMap warning: item.count == 0');
          }
        }
        item.count -= e.count;

        item.accumSellPrice += e.count * e.price;
        item.accumSellCount += e.count;
        item.accumEarn += e.earn ?? 0;
        break;
      default:
        throw Exception('unknown transaction type');
    }

    itemMap[stockId] = item;
  }
  return itemMap;
}

class _InventoryWidgetState extends State<InventoryWidget> {
  final Set<int> _selectedAccounts = {};
  final Set<String> _selectedItems = {};
  final _stockIdController = TextEditingController();
  final _priceController = TextEditingController();
  final _countController = TextEditingController();
  bool _isBalanceVisible = false; // 금액 표시 여부
  bool _isOldItemVisible = false; // 과거 항목 표시 여부 (예전 거래했으나 현재 0주 소지한 종목 포함)
  bool _isStockCountVisible = true; // 주식수 표시 여부
  late final Stream<KrStock?> _usdKrwStream;

  @override
  void initState() {
    super.initState();

    _usdKrwStream = onceAndPeriodic(Duration(seconds: 5), () async {
      final fetchFuture = fetchStockInfo('FX_USDKRW');
      saveToModel(fetchFuture);
      return fetchFuture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LonelyModel, PriceModel>(
      builder: (context, model, priceModel, child) {
        final transactions = _selectedAccounts.isNotEmpty
            ? model.transactions
                .where((e) => _selectedAccounts.contains(e.accountId))
                .toList()
            : model.transactions;
        final orderedItems = createItemMap(transactions, model.stocks)
            .values
            .sortedBy((e) => model.getStock(e.stockId)?.inventoryOrder ?? 0)
            .where((e) => _isOldItemVisible || e.count > 0)
            .toList();

        final allowReorder =
            _selectedAccounts.isEmpty && _selectedItems.isEmpty;
        final buildDefaultDragHandles = Platform.isAndroid || Platform.isIOS;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AccountFilterWidget(
                accounts: model.accounts,
                selects: model.accounts
                    .map((e) => _selectedAccounts.contains(e.id))
                    .toList(),
                onSelected: (index) {
                  setState(() {
                    if (_selectedAccounts.contains(model.accounts[index].id)) {
                      _selectedAccounts.remove(model.accounts[index].id);
                    } else {
                      _selectedAccounts.clear();
                      _selectedAccounts.add(model.accounts[index].id!);
                    }
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Spacer(),
                  LabeledCheckbox(
                    label: '주식수',
                    value: _isStockCountVisible,
                    onChanged: (newValue) {
                      setState(() {
                        _isStockCountVisible = newValue;
                      });
                    },
                  ),
                  LabeledCheckbox(
                    label: '과거',
                    value: _isOldItemVisible,
                    onChanged: (newValue) {
                      setState(() {
                        _isOldItemVisible = newValue;
                      });
                    },
                  ),
                  LabeledCheckbox(
                    label: '금액',
                    value: _isBalanceVisible,
                    onChanged: (newValue) {
                      setState(() {
                        _isBalanceVisible = newValue;
                      });
                    },
                  ),
                ],
              ),
            ),
            _buildSummary(orderedItems, model, priceModel),
            _buildUsdKrw(),
            Expanded(
              child: ReorderableListView(
                buildDefaultDragHandles: buildDefaultDragHandles,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final movingItem = orderedItems[oldIndex];
                    if (kDebugMode) {
                      print(
                          'Moving ${movingItem.stockId} from index $oldIndex to $newIndex');
                    }
                    orderedItems.removeAt(oldIndex);
                    if (oldIndex > newIndex) {
                      orderedItems.insert(newIndex, movingItem);
                    } else if (oldIndex < newIndex) {
                      orderedItems.insert(newIndex - 1, movingItem);
                    }

                    for (int i = 0; i < orderedItems.length; i++) {
                      model.updateStocksInventoryOrder(
                          orderedItems[i].stockId, i);
                    }
                  });
                },
                children: [
                  for (var i = 0; i < orderedItems.length; i++) ...[
                    allowReorder && !buildDefaultDragHandles
                        ? ReorderableDragStartListener(
                            key: Key(orderedItems[i].stockId),
                            index: i,
                            child: buildItemWidget(
                                orderedItems[i], model, priceModel),
                          )
                        : buildItemWidget(orderedItems[i], model, priceModel)
                  ]
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  StreamBuilder<KrStock?> _buildUsdKrw() {
    return StreamBuilder<KrStock?>(
        key: Key('FX_USDKRW'),
        stream: _usdKrwStream,
        builder: (_, snapshot) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${snapshot.data?.closePriceDividedBy10000() ?? '?'}원/\$',
                ),
              ],
            ),
          );
        });
  }

  InkWell buildItemWidget(
    Item item,
    LonelyModel model,
    PriceModel priceModel,
  ) {
    if (_selectedItems.contains(item.stockId)) {
      _stockIdController.text = item.stockId;
    }

    return InkWell(
      key: Key(item.stockId),
      onTap: () {
        widget.onStockSelected(item.stockId);

        _priceController.text = '';
        _countController.text = '';

        setState(() {
          if (_selectedItems.contains(item.stockId)) {
            _selectedItems.remove(item.stockId);
          } else {
            _selectedItems.clear();
            _selectedItems.add(item.stockId);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
        child: Column(
          children: [
            ItemWidget(
              item: item,
              isBalanceVisible: _isBalanceVisible,
              isStockCountVisible: _isStockCountVisible,
              model: model,
              priceModel: priceModel,
            ),
            // 선택된 종목은 그 상태에서 바로 매매 항목 추가할 수 있도록 한다.
            if (_selectedItems.contains(item.stockId)) ...[
              NewTransactionWidget(
                stockIdController: _stockIdController,
                priceController: _priceController,
                countController: _countController,
                editingTransaction: null,
                stockIdEnabled: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(
      List<Item> orderedItems, LonelyModel model, PriceModel priceModel) {
    double? totalBalanceInKrw = 0;
    double? totalDiffPriceInKrw = 0;

    for (var i = 0; i < orderedItems.length; i++) {
      final item = orderedItems[i];
      final stockPrice = priceModel.prices[item.stockId];

      if (stockPrice != null) {
        double? balance = (stockPrice.price! * item.count).toDouble();
        double? diffPrice = item.diffPrice(stockPrice.price!);

        if (!isKoreanStock(item.stockId)) {
          if (priceModel.getUsdKrw() != null) {
            balance = balance / 10000.0 * priceModel.getUsdKrw()!;
            diffPrice = diffPrice / 10000.0 * priceModel.getUsdKrw()!;
          } else {
            totalBalanceInKrw = null;
            totalDiffPriceInKrw = null;
            break;
          }
        }

        if (totalBalanceInKrw != null) {
          totalBalanceInKrw += balance;
        }

        if (totalDiffPriceInKrw != null) {
          totalDiffPriceInKrw += diffPrice;
        }
      }
    }

    double? totalPercent;
    if (totalBalanceInKrw != null && totalDiffPriceInKrw != null) {
      // 가격 변화가 없을 경우의 평가액
      final totalOriginalBalance = totalBalanceInKrw - totalDiffPriceInKrw;

      totalPercent = totalOriginalBalance != 0
          ? totalDiffPriceInKrw /
              (totalBalanceInKrw - totalDiffPriceInKrw) *
              100
          : 0;
    }

    final percentStr = totalPercent?.toStringAsFixed(2) ?? '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            key: Key('Summary'),
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isBalanceVisible) ...[
                Text(
                  '평가액 ${formatThousandsStr(totalBalanceInKrw?.round().toString() ?? '?')}원',
                ),
                Text(
                  '평가손익 ${formatThousandsStr(totalDiffPriceInKrw?.round().toString() ?? '?')}원',
                ),
              ],
              Text(
                '평가손익 $percentStr%',
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
            ],
          ),
        ],
      ),
    );
  }

  void saveToModel(Future<KrStock?> fetchFuture) async {
    final krStock = await fetchFuture;
    if (krStock != null) {
      widget.priceModel.setUsdKrw(krStock.closePrice / 10000.0);
    } else {
      widget.priceModel.setUsdKrw(null);
    }
  }
}

extension MyIterable<E> on Iterable<E> {
  Iterable<E> sortedBy(Comparable Function(E e) key) =>
      toList()..sort((a, b) => key(a).compareTo(key(b)));

  Iterable<E> stableSortedBy(Comparable Function(E e) key) {
    final copy = toList();
    mergeSort(copy, compare: (a, b) => key(a).compareTo(key(b)));
    return copy;
  }
}

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Function onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      child: Row(
        children: <Widget>[
          Checkbox(
            value: value,
            onChanged: (bool? newValue) {
              onChanged(newValue);
            },
          ),
          Text(label),
        ],
      ),
    );
  }
}
