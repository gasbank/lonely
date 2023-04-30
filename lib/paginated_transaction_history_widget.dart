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

class _PaginatedTransactionHistoryWidgetState
    extends State<PaginatedTransactionHistoryWidget> {
  late final _TransactionDataTableSource _transactionDataTableSource;

  @override
  void initState() {
    super.initState();

    _transactionDataTableSource = _TransactionDataTableSource(
      context.read<LonelyModel>().transactions.reversed.toList(),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LonelyModel>(
      builder: (context, model, child) {
        return PaginatedDataTable(
          showCheckboxColumn: false,
          headingRowHeight: 30,
          dataRowHeight: 30,
          columnSpacing: 30,
          rowsPerPage: 40,
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
          source: _transactionDataTableSource,
        );
      },
    );
  }
}

class _TransactionDataTableSource extends DataTableSource {
  final List<Transaction> transactions;
  final BuildContext context;

  _TransactionDataTableSource(this.transactions, this.context);

  @override
  DataRow? getRow(int index) {
    final tx = transactions[index];
    final model = context.read<LonelyModel>();
    final stock = model.getStock(tx.stockId);
    final account = model.getAccount(tx.accountId);

    return DataRow.byIndex(
      index: index,
      cells: _dataCellListFromTransaction(
          tx, stock?.name ?? '? ${tx.stockId} ?', account.name),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => transactions.length;

  @override
  int get selectedRowCount => 0;
}
