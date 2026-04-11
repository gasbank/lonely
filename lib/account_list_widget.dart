import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/lonely_model.dart';

class AccountListWidget extends StatefulWidget {
  const AccountListWidget({super.key});

  @override
  State<AccountListWidget> createState() => _AccountListWidgetState();
}

class _AccountListWidgetState extends State<AccountListWidget> {
  final _accountNameController = TextEditingController();
  int? _selectedAccountId;

  @override
  void dispose() {
    _accountNameController.dispose();
    super.dispose();
  }

  void _showSimpleError(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  void _toggleSelection(Account account) {
    setState(() {
      if (_selectedAccountId == account.id) {
        _selectedAccountId = null;
        _accountNameController.clear();
      } else {
        _selectedAccountId = account.id;
        _accountNameController.text = account.name;
      }
    });
  }

  Future<void> _showRemoveDialog(LonelyModel model, Account account) async {
    if (account.id != null && _selectedAccountId != account.id) {
      _toggleSelection(account);
    }

    if (_selectedAccountId == null) {
      _showSimpleError('계좌를 선택한 뒤 길게 누르세요.');
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('확인'),
        content: Text('선택한 계좌 \'${account.name}\'를 지울까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'OK');
              removeSelectedAccount(model);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    LonelyModel model,
    Account account,
    int index,
  ) {
    final isSelected = _selectedAccountId == account.id;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      key: ValueKey(account.id),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.55)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleSelection(account),
          onLongPress: () => _showRemoveDialog(model, account),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(account.name),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.read<LonelyModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Column(
      children: [
        Row(
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: TextField(
                  controller: _accountNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '계좌명',
                    contentPadding: EdgeInsets.all(4.0),
                  ),
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ),
            _buildAddOrUpdateButton(model, scaffoldMessenger),
          ],
        ),
        Expanded(
          child: Consumer<LonelyModel>(
            builder: (context, model, child) {
              if (_selectedAccountId != null &&
                  !model.accounts.any((e) => e.id == _selectedAccountId)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _selectedAccountId = null;
                    _accountNameController.clear();
                  });
                });
              }

              if (model.accounts.isEmpty) {
                return const Center(child: Text('계좌가 없습니다.'));
              }

              return ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: model.accounts.length,
                onReorder: (oldIndex, newIndex) async {
                  await model.reorderAccounts(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final account = model.accounts[index];
                  return _buildAccountTile(context, model, account, index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddOrUpdateButton(
      LonelyModel model, ScaffoldMessengerState scaffoldMessenger) {
    return TextButton(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(Colors.redAccent),
      ),
      onPressed: () async {
        final accountName = _accountNameController.text.trim();
        if (accountName.isEmpty) {
          scaffoldMessenger
              .showSnackBar(const SnackBar(content: Text('계좌명을 입력하세요~')));
          return;
        }

        final updateDbId = _selectedAccountId;

        if (updateDbId != null) {
          if (await model.updateAccount(updateDbId, accountName) <= 0) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('겹치는 계좌명입니다.')),
            );
          }
        } else {
          if ((await model.addAccount(accountName))! > 0) {
            _accountNameController.clear();
          } else {
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('겹치는 계좌명입니다.')),
            );
          }
        }
      },
      child: _selectedAccountId == null ? const Text('추가') : const Text('변경'),
    );
  }

  Future<void> removeSelectedAccount(LonelyModel model) async {
    final selectedAccountId = _selectedAccountId;
    if (selectedAccountId == null) {
      return;
    }

    await model.removeAccount([selectedAccountId]);
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAccountId = null;
      _accountNameController.clear();
    });
  }
}
