import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely_flutter/lonely_model.dart';
import 'package:provider/provider.dart';

enum TransactionType {
  buy,
  sell,
}

class Transaction {
  Transaction(
      {required this.stockId,
      required this.price,
      required this.count,
      required this.transactionType,
      required this.dateTime,
      required this.accountId});

  Transaction.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    stockId = map['stockId'];
    price = map['price'];
    count = map['count'];
    transactionType = map['transactionType'] == 0
        ? TransactionType.buy
        : TransactionType.sell;
    dateTime = DateTime.parse(map['dateTime']);
    earn = map['earn'];
    accountId = map['accountId'];
  }

  int? id;
  late final String stockId;
  late final int price;
  late final int count;
  late final TransactionType transactionType;
  late final DateTime dateTime;
  int? earn;
  int? accountId;

  Map<String, dynamic> toMap() {
    return {
      'stockId': stockId,
      'price': price,
      'count': count,
      'transactionType': transactionType == TransactionType.buy
          ? 0
          : transactionType == TransactionType.sell
              ? 1
              : -1,
      'dateTime': dateTime.toIso8601String(),
      'earn': earn,
      'accountId': accountId,
    };
  }
}

class NewTransactionWidget extends StatefulWidget {
  final Future<bool> Function(Transaction transaction) onNewTransaction;
  final TextEditingController stockIdController;

  const NewTransactionWidget(
      {super.key,
      required this.onNewTransaction,
      required this.stockIdController});

  @override
  State<StatefulWidget> createState() => _NewTransactionWidgetState();
}

class _NewTransactionWidgetState extends State<NewTransactionWidget> {
  final _priceController = TextEditingController();
  final _countController = TextEditingController();
  int? _accountId;

  void onPress(TransactionType transactionType) async {
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

    if (await widget.onNewTransaction(Transaction(
        transactionType: transactionType,
        count: count,
        price: price,
        stockId: widget.stockIdController.text,
        dateTime: DateTime.now(),
        accountId: _accountId))) {
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
            child: OutlinedButton(
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.redAccent),
              ),
              onPressed: () {
                onPress(TransactionType.buy);
              },
              child: const Text('매수'),
            ),
          ),
          Expanded(
            child: OutlinedButton(
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.blueAccent),
              ),
              onPressed: () {
                onPress(TransactionType.sell);
              },
              child: const Text('매도'),
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
          value: _accountId,
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
