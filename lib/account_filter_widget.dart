import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/lonely_model.dart';

class LabeledToggleFilterWidget extends StatelessWidget {
  final List<Widget> children;
  final List<bool> selects;
  final void Function(int) onSelected;

  const LabeledToggleFilterWidget({
    super.key,
    required this.children,
    required this.selects,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      isSelected: selects,
      onPressed: onSelected,
      children: children,
    );
  }
}

class AccountFilterWidget extends StatelessWidget {
  final List<Account> accounts;
  final List<bool> selects;
  final void Function(int) onSelected;

  const AccountFilterWidget(
      {super.key,
      required this.accounts,
      required this.selects,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return LabeledToggleFilterWidget(
      selects: selects,
      onSelected: onSelected,
      children: accounts.map((e) => Text(e.name)).toList(),
    );
  }
}

class SharedAccountFilterWidget extends StatelessWidget {
  const SharedAccountFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LonelyModel>(builder: (context, model, child) {
      return AccountFilterWidget(
        accounts: model.accounts,
        selects: model.accounts
            .map((account) => account.id == model.selectedAccountFilterId)
            .toList(),
        onSelected: (index) {
          final accountId = model.accounts[index].id;
          if (accountId != null) {
            model.toggleSelectedAccountFilter(accountId);
          }
        },
      );
    });
  }
}
