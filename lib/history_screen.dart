import 'package:flutter/material.dart';
import 'package:lonely/paginated_transaction_history_widget.dart';
import 'package:provider/provider.dart';
import 'model/lonely_model.dart';
import 'new_transaction_widget.dart';

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
    return Column(
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
        Expanded(
          child: PaginatedTransactionHistoryWidget(
            stockIdController: _stockIdController,
          ),
        ),
      ],
    );
  }
}
