import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'lonely_model.dart';

DataRow createAccountRow(Account account) {
  return DataRow(cells: [
    DataCell(Text(account.name)),
    const DataCell(Text('---')),
    const DataCell(Text('---')),
    const DataCell(Text('---')),
  ]);
}

class AccountListWidget extends StatelessWidget {
  final _accountNameController = TextEditingController();

  AccountListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            Row(
              children: [
                Flexible(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: TextField(
                      controller: _accountNameController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '계좌명',
                          contentPadding: EdgeInsets.all(4.0)),
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ),
                Expanded(
                  child: OutlinedButton(
                    style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.redAccent),
                    ),
                    onPressed: () {
                      if (_accountNameController.text.isNotEmpty) {
                        context
                            .read<LonelyModel>()
                            .addAccount(_accountNameController.text);
                        _accountNameController.text = '';
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('계좌명을 입력하세요~')));
                      }
                    },
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
            Consumer<LonelyModel>(
              builder: (context, model, child) {
                return FittedBox(
                  child: DataTable(
                      headingRowHeight: 40,
                      dataRowHeight: 40,
                      columns: const [
                        DataColumn(label: Text('계좌명')),
                        DataColumn(label: Text('종목 수')),
                        DataColumn(label: Text('자산총계')),
                        DataColumn(label: Text('평가액')),
                      ],
                      rows: model.accounts
                          .map((e) => createAccountRow(e))
                          .toList()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
