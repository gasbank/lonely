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

Widget _dataCellText(String text, double width, TextStyle textStyle) {
  return SizedBox(
    width: width,
    child: Text(
      text,
      style: textStyle,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

const widthRatios = [0.15, 0.10, 0.25, 0.20, 0.10, 0.20];
const columnTexts = ['날짜', '계좌', '종목명', '단가', '수량', '수익'];

List<DataCell> _dataCellListFromTransaction(
  double maxWidth,
  Transaction t,
  String stockName,
  String accountName,
  TextStyle textStyle,
) {
  return <DataCell>[
    DataCell(_dataCellText(
      t.dateTime.toIso8601String().substring(2, 10),
      maxWidth * widthRatios[0],
      textStyle,
    )),
    DataCell(_dataCellText(
      accountName,
      maxWidth * widthRatios[1],
      textStyle,
    )),
    DataCell(_dataCellText(
      '${_transactionIconMap[t.transactionType]}$stockName',
      maxWidth * widthRatios[2],
      textStyle,
    )),
    DataCell(_dataCellText(
      priceDataToDisplay(t.stockId, t.price),
      maxWidth * widthRatios[3],
      textStyle,
    )),
    DataCell(_dataCellText(
      formatThousands(t.count),
      maxWidth * widthRatios[4],
      textStyle,
    )),
    DataCell(_dataCellText(
      t.transactionType == TransactionType.sell
          ? (t.earn != null ? priceDataToDisplay(t.stockId, t.earn!) : '???')
          : '',
      maxWidth * widthRatios[5],
      textStyle,
    )),
  ];
}

class _PaginatedTransactionHistoryWidgetState
    extends State<PaginatedTransactionHistoryWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LonelyModel>(
      builder: (context, model, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final textStyle =
                DefaultTextStyle.of(context).style.apply(fontSizeFactor: 0.8);

            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;
            const rowHeight = 22.0;
            final rowsPerPage = (maxHeight / rowHeight - 1).floor();

            return PaginatedDataTable(
              showCheckboxColumn: false,
              headingRowHeight: rowHeight,
              dataRowHeight: rowHeight,
              columnSpacing: 0,
              horizontalMargin: 0,
              rowsPerPage: rowsPerPage,
              columns: [
                for (var i = 0; i < columnTexts.length; i++) ...[
                  DataColumn(
                    label: _dataCellText(
                      columnTexts[i],
                      maxWidth * widthRatios[i],
                      textStyle,
                    ),
                  ),
                ],
              ],
              source: _TransactionDataTableSource(
                model.transactions.reversed.toList(),
                context,
                constraints.maxWidth,
                textStyle,
              ),
            );
          },
        );
      },
    );
  }
}

class _TransactionDataTableSource extends DataTableSource {
  final List<Transaction> transactions;
  final BuildContext context;
  final double maxWidth;
  final TextStyle textStyle;

  _TransactionDataTableSource(
      this.transactions, this.context, this.maxWidth, this.textStyle);

  @override
  DataRow? getRow(int index) {
    final tx = transactions[index];
    final model = context.read<LonelyModel>();
    final stock = model.getStock(tx.stockId);
    final account = model.getAccount(tx.accountId);

    return DataRow.byIndex(
      index: index,
      cells: _dataCellListFromTransaction(maxWidth, tx,
          stock?.name ?? '? ${tx.stockId} ?', account.name, textStyle),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => transactions.length;

  @override
  int get selectedRowCount => 0;
}
