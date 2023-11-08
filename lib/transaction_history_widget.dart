import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'fetch_util.dart';
import 'package:provider/provider.dart';
import 'number_format_util.dart';
import 'lonely_model.dart';
import 'transaction.dart';

class TransactionHistoryWidget extends StatefulWidget {
  final TextEditingController stockIdController;

  const TransactionHistoryWidget({
    super.key,
    required this.stockIdController,
  });

  @override
  State<StatefulWidget> createState() => _TransactionHistoryState();
}

const _transactionIconMap = {
  TransactionType.buy: '🔸',
  TransactionType.sell: '🔹',
  TransactionType.splitIn: '⤵️️',
  TransactionType.splitOut: '⤴️️',
  TransactionType.transferIn: '↘️',
  TransactionType.transferOut: '↗️',
};

List<DataCell> _dataCellListFromTransaction(
    Transaction t, String stockName, String accountName) {
  return <DataCell>[
    DataCell(Text(t.dateTime.toIso8601String().substring(2, 10))),
    DataCell(ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 40),
        child: Text(
          accountName,
          overflow: TextOverflow.ellipsis,
        ))),
    DataCell(Text('${_transactionIconMap[t.transactionType]}$stockName')),
    DataCell(Text(priceDataToDisplay(t.stockId, t.price))),
    DataCell(Text(formatThousands(t.count))),
    DataCell(Text(t.transactionType == TransactionType.sell
        ? (t.earn != null ? priceDataToDisplay(t.stockId, t.earn!) : '???')
        : '')),
  ];
}

class _TransactionHistoryState extends State<TransactionHistoryWidget> {
  final selectedSet = <int>{};

  void _showSimpleError(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  DataRow _dataRowFromTransaction(Transaction e, LonelyModel model) {
    final stock = model.getStock(e.stockId);
    final account = model.getAccount(e.accountId);

    return DataRow(
      cells: _dataCellListFromTransaction(
          e, stock?.name ?? '? ${e.stockId} ?', account.name),
      selected: selectedSet.contains(e.id),
      color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Theme.of(context).colorScheme.primary.withOpacity(0.22);
        }
        return null; // Use the default value.
      }),
      onSelectChanged: (value) {
        if (kDebugMode) {
          //print(value);
        }
        if (e.id != null) {
          setState(() {
            if (value ?? false) {
              selectedSet.clear();
              selectedSet.add(e.id!);
              widget.stockIdController.text = e.stockId;
              model.setEditingTransaction(e);
            } else {
              selectedSet.remove(e.id!);
              /*if (widget.stockIdController.text == e.stockId) {
                widget.stockIdController.text = '';
              }*/
              model.setEditingTransaction(null);
            }
          });
        }
      },
      onLongPress: () {
        if (selectedSet.isEmpty) {
          _showSimpleError('하나 이상 선택하고 롱 탭하세요.');
          return;
        }

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('확인'),
                  content: Text('선택한 매매 기록 ${selectedSet.length}건을 모두 지울까요?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'Cancel'),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, 'OK');
                        removeSelectedTransaction(model);
                      },
                      child: const Text('삭제'),
                    ),
                  ],
                ),
            barrierDismissible: true);
      },
    );
  }

  void removeSelectedTransaction(LonelyModel model) {
    model.removeTransaction(selectedSet.toList());

    if (selectedSet.contains(model.editingTransaction?.id)) {
      model.setEditingTransaction(null);
    }

    setState(() {
      selectedSet.clear();
    });
  }

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      //print('initState(): TransactionHistoryWidget');
    }

    final editingTransaction = context.read<LonelyModel>().editingTransaction;
    if (editingTransaction != null) {
      selectedSet.add(editingTransaction.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LonelyModel>(
      builder: (context, model, child) {
        final dataRowList = model.transactions.reversed
            .map((e) => _dataRowFromTransaction(e, model))
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            return DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 30,
              dataRowMinHeight: 30,
              columnSpacing: 30,
              columns: const [
                DataColumn(
                  label: Text(
                    '날짜',
                  ),
                ),
                DataColumn(
                  label: Text(
                    '계좌',
                  ),
                ),
                DataColumn(
                  label: Text(
                    '종목명',
                  ),
                ),
                DataColumn(
                  label: Text(
                    '단가',
                  ),
                ),
                DataColumn(
                  label: Text(
                    '수량',
                  ),
                ),
                DataColumn(
                  label: Text(
                    '수익',
                  ),
                ),
              ],
              rows: dataRowList,
            );
          },
        );
      },
    );
  }
}
