import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely_flutter/transaction_widget.dart';

import 'new_transaction_widget.dart';

class TransactionHistoryWidget extends StatefulWidget {

  const TransactionHistoryWidget({super.key, required this.transactionList, required this.onRemoveTransaction});

  final List<Transaction> transactionList;
  final void Function(Set<int> dbIdSet) onRemoveTransaction;

  @override
  State<StatefulWidget> createState() => _TransactionHistoryState();
}

List<DataCell> _dataCellListFromTransaction(Transaction t) {
  return <DataCell>[
    DataCell(Text(t.dateTime.toIso8601String().substring(5, 10))),
    DataCell(Text(
        '${t.transactionType == TransactionType.buy ? '🔸' : '🔹'}종목명 ${t.stockId}')),
    DataCell(Text(formatThousands(t.price))),
    DataCell(Text(formatThousands(t.count))),
    DataCell(Text(t.transactionType == TransactionType.buy
        ? ''
        : formatThousandsStr(t.earn?.toString() ?? '???'))),
  ];
}

class _TransactionHistoryState extends State<TransactionHistoryWidget> {
  final selectedSet = <int>{};

  void showSimpleError(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  DataRow _dataRowFromTransaction(Transaction e) {
    return DataRow(
      cells: _dataCellListFromTransaction(e),
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
          print(value);
        }
        if (e.id != null) {
          setState(() {
            if (value ?? false) {
              selectedSet.add(e.id!);
            } else {
              selectedSet.remove(e.id!);
            }
          });
        }
      },
      onLongPress: () {
        if (selectedSet.isEmpty) {
          showSimpleError('하나 이상 선택하고 롱 탭하세요.');
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
                        removeSelectedTransaction();
                      },
                      child: const Text('삭제'),
                    ),
                  ],
                ),
            barrierDismissible: true);
      },
    );
  }

  void removeSelectedTransaction() async {
    widget.onRemoveTransaction(selectedSet.toSet());

    setState(() {
      selectedSet.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataRowList = widget.transactionList.reversed
        .map((e) => _dataRowFromTransaction(e))
        .toList();

    return DataTable(
      showCheckboxColumn: false,
      headingRowHeight: 30,
      dataRowHeight: 30,
      columns: const <DataColumn>[
        DataColumn(
          label: Text(
            '날짜',
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
  }
}
