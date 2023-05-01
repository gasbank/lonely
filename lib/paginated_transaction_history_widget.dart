import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'fetch_util.dart';
import 'package:provider/provider.dart';
import 'number_format_util.dart';
import 'lonely_model.dart';
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
  ColumnSize.S,
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
            model.transactions.reversed.toList(),
            context,
            textStyle,
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

  _TransactionDataTableSource(this.transactions, this.context, this.textStyle);

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
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => transactions.length;

  @override
  int get selectedRowCount => 0;
}
