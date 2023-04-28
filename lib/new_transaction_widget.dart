import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'database.dart';
import 'lonely_model.dart';
import 'package:provider/provider.dart';

import 'inventory_widget.dart';
import 'item_widget.dart';
import 'transaction.dart';
import 'transaction_text_field.dart';

class NewTransactionWidget extends StatefulWidget {
  final TextEditingController stockIdController;
  final TextEditingController priceController;
  final TextEditingController countController;
  final Transaction? editingTransaction;
  final bool stockIdEnabled;

  const NewTransactionWidget({
    super.key,
    required this.stockIdController,
    required this.priceController,
    required this.countController,
    required this.editingTransaction,
    required this.stockIdEnabled,
  });

  @override
  State<StatefulWidget> createState() => _NewTransactionWidgetState();
}

class _NewTransactionWidgetState extends State<NewTransactionWidget> {
  int? _accountId;

  void _showSimpleMessage(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  Future<int> _stockSum(String stockId, TransactionType transactionType,
      Iterable<Transaction> transactions) async {
    final sum = transactions
        .where(
            (e) => e.stockId == stockId && e.transactionType == transactionType)
        .map((e) => e.count)
        .fold(0, (a, b) => a + b);
    return sum;
  }

  Future<bool> _onNewTransaction(
      Transaction transaction, LonelyModel model) async {
    if (kDebugMode) {
      print('new transaction entry!');
      print(transaction);
    }

    final item =
        createItemMap(model.transactions, model.stocks)[transaction.stockId];

    if (transaction.transactionType == TransactionType.sell) {
      final buySum = await _stockSum(
          transaction.stockId, TransactionType.buy, model.transactions);
      final sellSum = await _stockSum(
          transaction.stockId, TransactionType.sell, model.transactions);
      if (buySum - sellSum < transaction.count) {
        _showSimpleMessage('가진 것보다 더 팔 수는 없죠.');
        return false;
      }

      if (item != null) {
        transaction.earn = ((transaction.price - item.accumPrice / item.count) *
                transaction.count)
            .round();
      }
    }

    await model.addTransaction(transaction);

    final krStock = fetchKrStockN(transaction.stockId);
    final krStockValue = await krStock;
    final stockName = krStockValue?.stockName ?? '';

    if (krStockValue != null) {
      if ((await model.setStock(Stock(
              id: 0,
              stockId: krStockValue.itemCode,
              name: stockName,
              closePrice: krStockValue.closePrice))) >
          0) {
        _showSimpleMessage('$stockName 종목 첫 매매 축하~~');
      }
    }

    FocusManager.instance.primaryFocus?.unfocus();

    return true;
  }

  Future<bool> _onUpdateTransaction(
      int id, Transaction transaction, LonelyModel model) async {
    if (kDebugMode) {
      print('update transaction entry!');
      print(transaction);
    }

    final transactionsExceptUpdated =
        model.transactions.where((e) => e.id != id);
    final item = createItemMap(
        model.transactions.where((e) => e.id != id), // 편집중인 항목은 빼고 계산
        model.stocks)[transaction.stockId];

    if (transaction.transactionType == TransactionType.sell) {
      final buySum = await _stockSum(
          transaction.stockId, TransactionType.buy, transactionsExceptUpdated);
      final sellSum = await _stockSum(
          transaction.stockId, TransactionType.sell, transactionsExceptUpdated);
      if (buySum - sellSum < transaction.count) {
        _showSimpleMessage('가진 것보다 더 팔 수는 없죠.');
        return false;
      }

      if (item != null) {
        transaction.earn = ((transaction.price - item.accumPrice / item.count) *
                transaction.count)
            .round();
      }
    }

    await model.updateTransaction(id, transaction);

    final krStock = fetchKrStockN(transaction.stockId);
    final krStockValue = await krStock;
    final stockName = krStockValue?.stockName ?? '';

    if (krStockValue != null) {
      if ((await model.setStock(Stock(
              id: 0,
              stockId: krStockValue.itemCode,
              name: stockName,
              closePrice: krStockValue.closePrice))) >
          0) {
        _showSimpleMessage('$stockName 종목 첫 매매 축하~~');
      }
    }

    FocusManager.instance.primaryFocus?.unfocus();

    return true;
  }

  bool _checkInputs() {
    if (widget.stockIdController.text.isEmpty ||
        widget.priceController.text.isEmpty ||
        widget.countController.text.isEmpty ||
        _accountId == null) {
      showSimpleError('칸을 모두 채우세요.');
      return false;
    }

    final price = int.tryParse(widget.priceController.text) ?? 0;
    final count = int.tryParse(widget.countController.text) ?? 0;

    if (price <= 0) {
      showSimpleError('단가가 이상하네요...');
      return false;
    }

    if (count <= 0) {
      showSimpleError('수량이 이상하네요...');
      return false;
    }

    return true;
  }

  void onModifyPress(LonelyModel model) async {
    if (_checkInputs() == false) {
      return;
    }

    final editingTransaction = model.editingTransaction;
    if (editingTransaction == null) {
      return;
    }

    final editingTransactionId = editingTransaction.id;

    if (editingTransactionId == null) {
      if (kDebugMode) {
        print('update transaction entry FAILED - id null');
        print(editingTransaction);
      }
      return;
    }

    final price = int.tryParse(widget.priceController.text) ?? 0;
    final count = int.tryParse(widget.countController.text) ?? 0;

    if (await _onUpdateTransaction(
        editingTransactionId,
        Transaction(
            transactionType: editingTransaction.transactionType,
            count: count,
            price: price,
            stockId: widget.stockIdController.text,
            dateTime: editingTransaction.dateTime,
            accountId: _accountId),
        model)) {
      model.setEditingTransaction(null);
    }
  }

  void onPress(TransactionType transactionType, LonelyModel model) async {
    if (_checkInputs() == false) {
      return;
    }

    final price = int.tryParse(widget.priceController.text) ?? 0;
    final count = int.tryParse(widget.countController.text) ?? 0;

    if (await _onNewTransaction(
        Transaction(
            transactionType: transactionType,
            count: count,
            price: price,
            stockId: widget.stockIdController.text,
            dateTime: DateTime.now(),
            accountId: _accountId),
        model)) {
      clearTextFields();
    }
  }

  void showSimpleError(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  void clearTextFields() {
    widget.stockIdController.text = '';
    widget.priceController.text = '';
    widget.countController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LonelyModel>(
      builder: (context, model, child) {
        final editingTransaction = widget.editingTransaction;
        if (editingTransaction != null) {
          //_accountId = editingTransaction.accountId;
          widget.stockIdController.text = editingTransaction.stockId;
          widget.priceController.text = editingTransaction.price.toString();
          widget.countController.text = editingTransaction.count.toString();
        } else {
          //clearTextFields();
        }

        return Column(children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildAccountDropdown(),
              if (widget.stockIdEnabled) ...[
                buildTextField("종목코드", widget.stockIdController,
                    TextInputAction.next, widget.stockIdEnabled),
              ],
              buildTextField(
                  "단가", widget.priceController, TextInputAction.next, true),
              buildTextField(
                  "수량", widget.countController, TextInputAction.done, true),
            ],
          ),
          Row(
            children: [
              if (editingTransaction == null) ...[
                buildButton('매수', Colors.redAccent,
                    () => onPress(TransactionType.buy, model)),
                buildButton('매도', Colors.blueAccent,
                    () => onPress(TransactionType.sell, model)),
              ] else ...[
                buildButton('편집', Colors.black, () => onModifyPress(model)),
              ]
            ],
          ),
        ]);
      },
    );
  }

  Expanded buildButton(String text, Color color, void Function() onPressed) =>
      Expanded(
        child: Consumer<LonelyModel>(
          builder: (context, model, child) {
            return OutlinedButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(color),
              ),
              onPressed: onPressed,
              child: Text(text),
            );
          },
        ),
      );

  Consumer<Object?> buildAccountDropdown() {
    return Consumer<LonelyModel>(
      builder: (context, model, child) {
        _accountId ??=
            (model.accounts.isNotEmpty ? model.accounts.first.id : null);
        return DropdownButton<int>(
          items: [
            // const DropdownMenuItem(value: 0, child: Text("---")),
            // const DropdownMenuItem(value: 1, child: Text("🔸계좌1")),
            // const DropdownMenuItem(value: 2, child: Text("🔹계좌2")),
            // const DropdownMenuItem(value: 3, child: Text("🔥️계좌3")),
            // const DropdownMenuItem(value: 4, child: Text("✨계좌4")),
            // const DropdownMenuItem(value: 5, child: Text("🍉계좌5")),
            // const DropdownMenuItem(value: 6, child: Text("❤️계좌6")),
            // const DropdownMenuItem(value: 7, child: Text("🎈계좌7")),
            for (var account in model.accounts) ...[
              DropdownMenuItem(value: account.id, child: Text(account.name)),
            ]
          ],
          onChanged: onAccountChanged,
          value: _accountId,
        );
      },
    );
  }

  Flexible buildTextField(String? hintText, TextEditingController? controller,
      TextInputAction action, bool enabled) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: TransactionTextField(
          controller: controller,
          hintText: hintText,
          action: action,
          enabled: enabled,
        ),
      ),
    );
  }

  void onAccountChanged(int? value) {
    setState(() {
      _accountId = value;
    });
  }
}
