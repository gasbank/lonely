import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely_flutter/database.dart';
import 'package:lonely_flutter/lonely_model.dart';
import 'package:provider/provider.dart';

import 'inventory_widget.dart';
import 'item_widget.dart';
import 'transaction.dart';

class NewTransactionWidget extends StatefulWidget {
  final TextEditingController stockIdController;

  const NewTransactionWidget({super.key, required this.stockIdController});

  @override
  State<StatefulWidget> createState() => _NewTransactionWidgetState();
}

class _NewTransactionWidgetState extends State<NewTransactionWidget> {
  final _priceController = TextEditingController();
  final _countController = TextEditingController();
  int? _accountId;

  void _showSimpleMessage(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  Future<int> _stockSum(String stockId, TransactionType transactionType,
      LonelyModel model) async {
    final sum = model.transactions
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
      final buySum =
          await _stockSum(transaction.stockId, TransactionType.buy, model);
      final sellSum =
          await _stockSum(transaction.stockId, TransactionType.sell, model);
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

  void onPress(TransactionType transactionType, LonelyModel model) async {
    if (widget.stockIdController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _countController.text.isEmpty ||
        _accountId == null) {
      showSimpleError('칸을 모두 채우세요.');
      return;
    }

    final price = int.tryParse(_priceController.text) ?? 0;
    final count = int.tryParse(_countController.text) ?? 0;

    if (price <= 0) {
      showSimpleError('단가가 이상하네요...');
      return;
    }

    if (count <= 0) {
      showSimpleError('수량이 이상하네요...');
      return;
    }

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
    _priceController.text = '';
    _countController.text = '';
  }

  @override
  void dispose() {
    _priceController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (kDebugMode) {
      //print('initState(): NewTransactionWidget');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildAccountDropdown(),
          buildTextField(
              "종목코드", widget.stockIdController, TextInputAction.next),
          buildTextField("단가", _priceController, TextInputAction.next),
          buildTextField("수량", _countController, TextInputAction.done),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: Consumer<LonelyModel>(
              builder: (context, model, child) {
                return OutlinedButton(
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.redAccent),
                  ),
                  onPressed: () {
                    onPress(TransactionType.buy, model);
                  },
                  child: const Text('매수'),
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<LonelyModel>(
              builder: (context, model, child) {
                return OutlinedButton(
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.blueAccent),
                  ),
                  onPressed: () {
                    onPress(TransactionType.sell, model);
                  },
                  child: const Text('매도'),
                );
              },
            ),
          ),
        ],
      ),
    ]);
  }

  Consumer<Object?> buildAccountDropdown() {
    return Consumer<LonelyModel>(
      builder: (context, model, child) {
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
          value: _accountId ??
              (model.accounts.isNotEmpty ? model.accounts.first.id : null),
        );
      },
    );
  }

  Flexible buildTextField(String? hintText, TextEditingController? controller,
      TextInputAction action) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hintText,
              contentPadding: const EdgeInsets.all(10.0)),
          autocorrect: false,
          textInputAction: action,
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
