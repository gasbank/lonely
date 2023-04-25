import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'lonely_model.dart';

class AccountListWidget extends StatefulWidget {
  const AccountListWidget({super.key});

  @override
  State<AccountListWidget> createState() => _AccountListWidgetState();
}

class _AccountListWidgetState extends State<AccountListWidget> {
  final _accountNameController = TextEditingController();
  final _selectedSet = <int>{};

  DataRow _createAccountRow(Account account, Set<int> selectedSet) {
    return DataRow(
      cells: [
        DataCell(Text(account.name)),
        const DataCell(Text('---')),
        const DataCell(Text('---')),
        const DataCell(Text('---')),
      ],
      onSelectChanged: (selected) {
        setState(() {
          if (selected ?? false) {
            selectedSet.clear();
            selectedSet.add(account.id!);
            _accountNameController.text = account.name;
          } else {
            selectedSet.remove(account.id);
            _accountNameController.text = '';
          }
        });
      },
      selected: selectedSet.contains(account.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.read<LonelyModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
                  child: _buildAddOrUpdateButton(model, scaffoldMessenger),
                ),
              ],
            ),
            Consumer<LonelyModel>(
              builder: (context, model, child) {
                return FittedBox(
                  child: DataTable(
                      headingRowHeight: 40,
                      dataRowHeight: 40,
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(label: Text('계좌명')),
                        DataColumn(label: Text('종목 수')),
                        DataColumn(label: Text('자산총계')),
                        DataColumn(label: Text('평가액')),
                      ],
                      rows: model.accounts
                          .sortedBy((e) => e.id ?? 0)
                          .map((e) => _createAccountRow(e, _selectedSet))
                          .toList()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  OutlinedButton _buildAddOrUpdateButton(
      LonelyModel model, ScaffoldMessengerState scaffoldMessenger) {
    return OutlinedButton(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
      ),
      onPressed: () async {
        if (_accountNameController.text.isNotEmpty) {
          final updateDbId =
              _selectedSet.isNotEmpty ? _selectedSet.first : null;

          if (updateDbId != null) {
            await model.updateAccount(updateDbId, _accountNameController.text);
          } else {
            if ((await model.addAccount(_accountNameController.text))! > 0) {
              _accountNameController.text = '';
            } else {
              scaffoldMessenger
                  .showSnackBar(const SnackBar(content: Text('겹치는 계좌명입니다.')));
            }
          }
        } else {
          scaffoldMessenger
              .showSnackBar(const SnackBar(content: Text('계좌명을 입력하세요~')));
        }
      },
      child: _selectedSet.isEmpty ? const Text('추가') : const Text('변경'),
    );
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
