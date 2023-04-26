import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely_flutter/lonely_model.dart';
import 'package:provider/provider.dart';

import 'database.dart';
import 'inventory_widget.dart';

class PortfolioScreen extends StatefulWidget {
  PortfolioScreen({super.key, required this.database}) {
    if (kDebugMode) {
      print('PortfolioScreen()');
    }
  }

  final LonelyDatabase database;

  @override
  State<StatefulWidget> createState() => _NewPortfolioState();
}

class _NewPortfolioState extends State<PortfolioScreen> {
  final _stockIdController = TextEditingController();

  void showSimpleMessage(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LonelyModel>(
      builder: (context, model, child) => InventoryWidget(
        orderedItems: createItemMap(model.transactions, model.stocks)
            .values
            .sortedBy((e) => e.listOrder)
            .where((e) => e.count > 0)
            .toList(),
        onStockSelected: (selectedStockId) {
          if (_stockIdController.text == selectedStockId) {
            _stockIdController.text = '';
          } else {
            _stockIdController.text = selectedStockId;
          }
        },
      ),
    );
  }
}
