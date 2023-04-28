import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database.dart';
import 'inventory_widget.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NewPortfolioState();
}

class _NewPortfolioState extends State<PortfolioScreen> {
  final _stockIdController = TextEditingController();

  @override
  void dispose() {
    _stockIdController.dispose();
    super.dispose();
  }

  void showSimpleMessage(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return InventoryWidget(
      onStockSelected: (selectedStockId) {
        if (_stockIdController.text == selectedStockId) {
          _stockIdController.text = '';
        } else {
          _stockIdController.text = selectedStockId;
        }
      },
    );
  }
}
