import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'fetch_util.dart';
import 'package:provider/provider.dart';
import 'number_format_util.dart';
import 'model/lonely_model.dart';
import 'transaction.dart';

class PaginatedTransactionHistoryWidget extends StatefulWidget {
  final TextEditingController stockIdController;

  const PaginatedTransactionHistoryWidget({
    super.key,
    required this.stockIdController,
  });

  @override
  State<StatefulWidget> createState() =>
      _PaginatedTransactionHistoryWidgetState();
}

const _transactionIconMap = {
  TransactionType.buy: '🔸',
  TransactionType.sell: '🔹',
  TransactionType.splitIn: '⤵️️',
  TransactionType.splitOut: '⤴️️',
  TransactionType.transferIn: '↘️',
  TransactionType.transferOut: '↗️',
};

Widget _dataCellText(String text, TextStyle textStyle) {
  return Text(
    text,
    style: textStyle,
    overflow: TextOverflow.ellipsis,
  );
}

const widthRatios = [0.15, 0.10, 0.25, 0.20, 0.10, 0.20];
const columnTexts = ['날짜', '계좌', '종목명', '단가', '수량', '수익'];
const columnSizes = [
  ColumnSize.M,
  ColumnSize.M,
  ColumnSize.L,
  ColumnSize.M,
  ColumnSize.M,
  ColumnSize.M
];

List<DataCell> _dataCellListFromTransaction(
  Transaction t,
  String stockName,
  String accountName,
  TextStyle textStyle,
) {
  return <DataCell>[
    DataCell(_dataCellText(
      t.dateTime.toIso8601String().substring(2, 10),
      textStyle,
    )),
    DataCell(_dataCellText(
      accountName,
      textStyle,
    )),
    DataCell(_dataCellText(
      '${_transactionIconMap[t.transactionType]}$stockName',
      textStyle,
    )),
    DataCell(_dataCellText(
      priceDataToDisplay(t.stockId, t.price),
      textStyle,
    )),
    DataCell(_dataCellText(
      formatThousands(t.count),
      textStyle,
    )),
    DataCell(_dataCellText(
      t.transactionType == TransactionType.sell
          ? (t.earn != null ? priceDataToDisplay(t.stockId, t.earn!) : '???')
          : '',
      textStyle,
    )),
  ];
}

class _PaginatedTransactionHistoryWidgetState
    extends State<PaginatedTransactionHistoryWidget> {
  final selectedSet = <int>{};

  void _showSimpleError(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  void onSelectChanged(LonelyModel model, Transaction e, bool? value) {
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
  }

  void onLongPress(LonelyModel model) {
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
      //print('initState(): PaginatedTransactionHistoryWidget');
    }

    final editingTransaction = context.read<LonelyModel>().editingTransaction;
    if (editingTransaction != null) {
      selectedSet.add(editingTransaction.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        DefaultTextStyle.of(context).style.apply(fontSizeFactor: 0.75);

    const rowHeight = 20.0;

    return Consumer<LonelyModel>(
      builder: (context, model, child) {
        return PaginatedDataTable2(
          showCheckboxColumn: false,
          headingRowHeight: rowHeight,
          dataRowHeight: rowHeight,
          columnSpacing: 0,
          horizontalMargin: 5,
          minWidth: 100,
          autoRowsToHeight: true,
          showFirstLastButtons: true,
          smRatio: 0.5,
          lmRatio: 1.8,
          columns: [
            for (var i = 0; i < columnTexts.length; i++) ...[
              DataColumn2(
                size: columnSizes[i],
                label: _dataCellText(
                  columnTexts[i],
                  textStyle,
                ),
              ),
            ],
          ],
          source: _TransactionDataTableSource(
            model.stockIdFilteredTransactions.reversed.toList(),
            context,
            textStyle,
            (transaction, selected) =>
                onSelectChanged(model, transaction, selected),
            () => onLongPress(model),
            selectedSet,
          ),
        );
      },
    );
  }
}

class _TransactionDataTableSource extends DataTableSource {
  final List<Transaction> transactions;
  final BuildContext context;
  final TextStyle textStyle;
  final Function(Transaction transaction, bool? selected) onSelectChanged;
  final Function() onLongPress;
  final Set<int> selectedSet;

  _TransactionDataTableSource(
    this.transactions,
    this.context,
    this.textStyle,
    this.onSelectChanged,
    this.onLongPress,
    this.selectedSet,
  );

  @override
  DataRow? getRow(int index) {
    final tx = transactions[index];
    final model = context.read<LonelyModel>();
    final stock = model.getStock(tx.stockId);
    final account = model.getAccount(tx.accountId);

    return DataRow.byIndex(
      index: index,
      cells: _dataCellListFromTransaction(
          tx, stock?.name ?? '? ${tx.stockId} ?', account.name, textStyle),
      selected: selectedSet.contains(tx.id),
      onSelectChanged: (value) => onSelectChanged(tx, value),
      onLongPress: () => onLongPress(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => transactions.length;

  @override
  int get selectedRowCount => 0;
}
