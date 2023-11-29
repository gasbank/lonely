import 'package:flutter/material.dart';

import 'model/lonely_model.dart';

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
    return ToggleButtons(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      isSelected: selects,
      //selectedColor: Colors.red,
      //selectedBorderColor: Colors.blue,
      onPressed: onSelected,
      children: accounts.map((e) => Text(e.name)).toList(),
    );
  }
}
