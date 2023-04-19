import 'package:flutter/material.dart';
import 'package:lonely_flutter/transaction_widget.dart';

import 'new_transaction_widget.dart';

class TransactionHistoryWidget extends StatefulWidget {
  const TransactionHistoryWidget({super.key, required this.transactionList});

  final List<Transaction> transactionList;

  @override
  State<StatefulWidget> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistoryWidget> {
  @override
  Widget build(BuildContext context) {
    final dataRowList = widget.transactionList.reversed
        .map((e) => DataRow(cells: <DataCell>[
              DataCell(Text(e.dateTime.toIso8601String().substring(5, 10))),
              DataCell(Text('${e.transactionType == TransactionType.buy ? '🔸' : '🔹'}종목명 ${e.stockId}')),
              DataCell(Text(formatThousands(e.price))),
              DataCell(Text(formatThousands(e.count))),
              DataCell(Text(e.transactionType == TransactionType.buy
                  ? ''
                  : formatThousandsStr(e.earn?.toString() ?? '???'))),
            ]))
        .toList();

    return DataTable(
      headingRowHeight: 30,
      dataRowHeight: 30,
      columns: const <DataColumn>[
        DataColumn(
          label: Expanded(
            child: Text(
              '날짜',
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              '종목명',
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              '단가',
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              '수량',
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              '수익',
            ),
          ),
        ),
      ],
      rows: dataRowList,
    );
  }
}
