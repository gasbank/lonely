import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lonely_model.dart';
import 'new_transaction_widget.dart';
import 'transaction_history_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NewHistoryState();
}

class _NewHistoryState extends State<HistoryScreen> {
  final _stockIdController = TextEditingController();
  final _priceController = TextEditingController();
  final _countController = TextEditingController();

  @override
  void dispose() {
    _stockIdController.dispose();
    _priceController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Consumer<LonelyModel>(
          builder: (context, model, child) {
            return NewTransactionWidget(
              stockIdController: _stockIdController,
              priceController: _priceController,
              countController: _countController,
              editingTransaction: model.editingTransaction,
              stockIdEnabled: true,
            );
          },
        ),
        TransactionHistoryWidget(
          stockIdController: _stockIdController,
        ),
      ],
    );
  }
}
