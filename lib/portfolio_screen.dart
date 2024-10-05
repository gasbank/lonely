import 'package:flutter/material.dart';
import 'package:lonely/model/price_model.dart';
import 'package:provider/provider.dart';

import 'inventory_widget.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NewPortfolioState();
}

class _NewPortfolioState extends State<PortfolioScreen> {
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
      priceModel: context.read<PriceModel>(),
      onStockSelected: (selectedStockId) {
        //context.read<LonelyModel>().setSelectedScreenIndex(1);
      },
    );
  }
}
