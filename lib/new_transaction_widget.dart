import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'fetch_util.dart';
import 'database.dart';
import 'model/lonely_model.dart';
import 'package:lonely/item_widget.dart';
import 'package:provider/provider.dart';

import 'inventory_widget.dart';
import 'transaction.dart';
import 'transaction_message.dart';
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

Future<int> _stockSum(String stockId, Set<TransactionType> transactionType,
    Iterable<Transaction> transactions) async {
  // 'USD SPDR S&P 500 Trust ETF'와 'SPY'는 동일한 것으로 치자
  String? stockIdAlternative;
  for (final e in stockIdAlternatives.entries) {
    if (e.value == stockId) {
      stockIdAlternative = e.key;
      break;
    }
    if (e.key == stockId) {
      stockIdAlternative = e.value;
      break;
    }
  }

  final sum = transactions
      .where((e) =>
          (e.stockId == stockId || e.stockId == stockIdAlternative) &&
          transactionType.contains(e.transactionType))
      .map((e) => e.count)
      .fold(0, (a, b) => a + b);
  return sum;
}

Future<void> transferStock(
  DateTime dateTime,
  ItemOnAccount itemOnAccount,
  int count, // 음수 지원
  LonelyModel model,
  bool isBatch,
) async {
  if (count == 0) {
    return;
  }

  final item = itemOnAccount.item;

  if (item.count + count < 0) {
    throw Exception('계좌에 있는 것보다 더 꺼낼 수는 없다~');
  }

  final avgPrice = item.count != 0 ? (item.accumPrice / item.count).round() : 0;

  await registerNewTransaction(
    Transaction(
        stockId: item.stockId,
        price: avgPrice,
        count: count.abs(),
        transactionType: count > 0
            ? TransactionType.transferIn
            : TransactionType.transferOut,
        dateTime: dateTime,
        accountId: itemOnAccount.accountId),
    model,
    (_) {},
    isBatch,
  );
}

Future<void> splitStock(
  DateTime dateTime,
  ItemOnAccount itemOnAccount,
  LonelyModel model,
  int splitFactor,
  bool isBatch,
) async {
  final item = itemOnAccount.item;
  final avgPrice = (item.accumPrice / item.count).round();

  await registerNewTransaction(
    Transaction(
        stockId: item.stockId,
        price: avgPrice,
        count: item.count,
        transactionType: TransactionType.splitOut,
        dateTime: dateTime,
        accountId: itemOnAccount.accountId),
    model,
    (_) {},
    isBatch,
  );
  // 일괄 매수
  await registerNewTransaction(
    Transaction(
        stockId: item.stockId,
        price: (avgPrice / splitFactor).round(),
        count: item.count * splitFactor,
        transactionType: TransactionType.splitIn,
        dateTime: dateTime,
        accountId: itemOnAccount.accountId),
    model,
    (_) {},
    isBatch,
  );
}

Future<void> mergeStock(
  DateTime dateTime,
  ItemOnAccount itemOnAccount,
  LonelyModel model,
  int mergeFactor,
  bool isBatch,
) async {
  final item = itemOnAccount.item;
  final avgPrice = (item.accumPrice / item.count).round();

  await registerNewTransaction(
    Transaction(
        stockId: item.stockId,
        price: avgPrice,
        count: item.count,
        transactionType: TransactionType.splitOut,
        dateTime: dateTime,
        accountId: itemOnAccount.accountId),
    model,
    (_) {},
    isBatch,
  );
  // 일괄 매수
  await registerNewTransaction(
    Transaction(
        stockId: item.stockId,
        price: (avgPrice * mergeFactor).round(),
        count: (item.count / mergeFactor).floor(),
        transactionType: TransactionType.splitIn,
        dateTime: dateTime,
        accountId: itemOnAccount.accountId),
    model,
    (_) {},
    isBatch,
  );
}

Future<bool> registerNewTransaction(
  Transaction transaction,
  LonelyModel model,
  void Function(String) onSimpleMessage,
  bool isBatch,
) async {
  // if (kDebugMode) {
  //   print('new transaction entry!');
  //   print(transaction);
  // }

  final itemMap = createItemMap(model.transactions, model.stocks);
  final item = itemMap[transaction.stockId];

  if (transactionTypeOut.contains(transaction.transactionType)) {
    final inSum = await _stockSum(
        transaction.stockId, transactionTypeIn, model.transactions);
    final outSum = await _stockSum(
        transaction.stockId, transactionTypeOut, model.transactions);
    if (inSum - outSum < transaction.count) {
      onSimpleMessage('가진 것보다 더 꺼내갈 수는 없죠?');
      if (kDebugMode) {
        print(
            'stock count exceeded; stock id = ${transaction.stockId}, date = ${transaction.dateTime} inSum=$inSum outSum=$outSum current count = ${inSum - outSum}, but try to out ${transaction.count}');
      }

      return false;
    }

    if (item != null) {
      if (item.count != 0) {
        transaction.earn = ((transaction.price - item.accumPrice / item.count) *
                transaction.count)
            .round();
      } else {
        transaction.earn = null;
      }
    }
  }

  // 일단 로컬 기기에 추가하고,
  await model.addTransaction(transaction);

  // 다른 기기에 항목 추가된 것 알려준다.
  model.publish(TransactionMessageType.addTransaction, transaction);

  if (isBatch == false) {
    final krStock = fetchStockInfo(transaction.stockId);
    final krStockValue = await krStock;
    final stockName = krStockValue?.stockName ?? '';

    if (krStockValue != null) {
      if ((await model.setStock(Stock(
            id: 0,
            stockId: krStockValue.itemCode,
            name: stockName,
          ))) >
          0) {
        onSimpleMessage('$stockName 종목 첫 매매 축하~~');
      }
    }
  }

  FocusManager.instance.primaryFocus?.unfocus();

  return true;
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

    if (transactionTypeOut.contains(transaction.transactionType)) {
      final inSum = await _stockSum(
          transaction.stockId, transactionTypeIn, transactionsExceptUpdated);
      final outSum = await _stockSum(
          transaction.stockId, transactionTypeOut, transactionsExceptUpdated);
      if (inSum - outSum < transaction.count) {
        _showSimpleMessage('가진 것보다 더 꺼내갈 수는 없죠?');
        if (kDebugMode) {
          print(
              'stock count exceeded; current count = ${inSum - outSum}, but try to out ${transaction.count}');
        }
        return false;
      }

      if (item != null) {
        transaction.earn = ((transaction.price - item.accumPrice / item.count) *
                transaction.count)
            .round();
      }
    }

    await model.updateTransaction(id, transaction);
    model.publish(
      TransactionMessageType.updateTransaction,
      {
        'id': id,
        'transaction': transaction,
      },
    );

    final krStock = fetchStockInfo(transaction.stockId);
    final krStockValue = await krStock;
    final stockName = krStockValue?.stockName ?? '';

    if (krStockValue != null) {
      if ((await model.setStock(Stock(
            id: 0,
            stockId: krStockValue.itemCode,
            name: stockName,
          ))) >
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

    final price = double.tryParse(widget.priceController.text) ?? 0;
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

    final stockId = widget.stockIdController.text;
    final price = priceInputToData(stockId, widget.priceController.text);
    final count = int.tryParse(widget.countController.text) ?? 0;

    if (await _onUpdateTransaction(
        editingTransactionId,
        Transaction(
            transactionType: editingTransaction.transactionType,
            count: count,
            price: price,
            stockId: stockId,
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

    final stockId = widget.stockIdController.text;
    final price = priceInputToData(stockId, widget.priceController.text);
    final count = int.tryParse(widget.countController.text) ?? 0;

    if (await registerNewTransaction(
      Transaction(
          transactionType: transactionType,
          count: count,
          price: price,
          stockId: widget.stockIdController.text,
          dateTime: DateTime.now(),
          accountId: _accountId),
      model,
      _showSimpleMessage,
      false,
    )) {
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
          widget.priceController.text = priceDataToInput(
              editingTransaction.stockId, editingTransaction.price);
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
                buildTextField('종목코드', widget.stockIdController,
                    TextInputAction.next, widget.stockIdEnabled, false),
              ],
              buildTextField('단가', widget.priceController, TextInputAction.next,
                  true, true),
              buildTextField('수량', widget.countController, TextInputAction.done,
                  true, true),
            ],
          ),
          Row(
            //mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (editingTransaction == null) ...[
                buildButton('매수', Colors.redAccent,
                    () => onPress(TransactionType.buy, model)),
                buildButton('매도', Colors.blueAccent,
                    () => onPress(TransactionType.sell, model)),
              ] else ...[
                buildButton('편집', Colors.black, () => onModifyPress(model)),
                buildButton('액면분할', Colors.black, () => onSplit(model)),
              ],
              _buildIconButton(const Icon(Icons.filter_alt), Colors.black,
                  () => _onStockIdFilterPressed(model)),
            ],
          ),
        ]);
      },
    );
  }

  void _onStockIdFilterPressed(LonelyModel model) {
    const historyPageIndex = 1;

    if (widget.stockIdController.text.isEmpty) {
      if (model.stockIdHistoryFilter != null) {
        model.stockIdHistoryFilter = null;
        showSnackbar('필터를 끕니다.');
      }
    } else if (model.stockIdHistoryFilter != widget.stockIdController.text) {
      String? alternativeFilter;

      // 미국 주식은 SPY로 검색하면 안되고, USD SPDR S&P 500 Trust ETF 처럼
      // 풀네임으로 검색해야된다.
      if (isKoreanStock(widget.stockIdController.text) == false) {
        for (final e in stockIdAlternatives.entries) {
          if (e.value == widget.stockIdController.text) {
            alternativeFilter = e.key;
            break;
          }
        }
      }

      model.stockIdHistoryFilter =
          alternativeFilter ?? widget.stockIdController.text;
      showSnackbar('${widget.stockIdController.text} 종목으로 필터링합니다.');
    } else if (model.selectedPageIndex == historyPageIndex) {
      // 기록 탭에서는 동일한 항목으로 다시 필터링하려고 하는 행위를
      // 필터를 끄는 행위로 인식한다.
      model.stockIdHistoryFilter = null;
      showSnackbar('필터를 끕니다.');
    }

    model.selectedPageIndex = historyPageIndex; // 기록 페이지(탭)으로 넘어간다.
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // 스낵바
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Expanded buildButton(String text, Color color, void Function() onPressed) =>
      Expanded(
        child: Consumer<LonelyModel>(
          builder: (context, model, child) {
            return TextButton(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all<Color>(color),
              ),
              onPressed: onPressed,
              child: Text(text),
            );
          },
        ),
      );

  Widget _buildIconButton(Icon icon, Color color, void Function() onPressed) =>
      Consumer<LonelyModel>(
        builder: (context, model, child) {
          return IconButton(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(color),
            ),
            onPressed: onPressed,
            icon: icon,
          );
        },
      );

  Consumer<Object?> buildAccountDropdown() {
    return Consumer<LonelyModel>(
      builder: (context, model, child) {
        final selectedAccountExists =
            model.accounts.any((account) => account.id == _accountId);
        if (!selectedAccountExists) {
          _accountId =
              model.accounts.isNotEmpty ? model.accounts.first.id : null;
        }

        return DropdownButton<int>(
          items: [
            // const DropdownMenuItem(value: 0, child: Text('---')),
            // const DropdownMenuItem(value: 1, child: Text('🔸계좌1')),
            // const DropdownMenuItem(value: 2, child: Text('🔹계좌2')),
            // const DropdownMenuItem(value: 3, child: Text('🔥️계좌3')),
            // const DropdownMenuItem(value: 4, child: Text('✨계좌4')),
            // const DropdownMenuItem(value: 5, child: Text('🍉계좌5')),
            // const DropdownMenuItem(value: 6, child: Text('❤️계좌6')),
            // const DropdownMenuItem(value: 7, child: Text('🎈계좌7')),
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
      TextInputAction action, bool enabled, bool numberOnly) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: TransactionTextField(
          controller: controller,
          hintText: hintText,
          action: action,
          enabled: enabled,
          numberOnly: numberOnly,
        ),
      ),
    );
  }

  void onAccountChanged(int? value) {
    setState(() {
      _accountId = value;
    });
  }

  void onSplit(LonelyModel model) {
    final editingTransaction = model.editingTransaction;
    if (editingTransaction == null) return;

    final accountId = editingTransaction.accountId;

    final itemMapOnAccount = createItemMap(
        model.transactions.where((e) => e.accountId == accountId),
        model.stocks);

    final item = itemMapOnAccount[editingTransaction.stockId];
    if (item == null) return;

    final itemOnAccount = ItemOnAccount(item, accountId);

    const splitFactor = 5;

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('액면분할'),
              content: Text(
                  '본 계좌의 \'${item.stockName}\' 종목을 $splitFactor배 액면분할합니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context, 'OK');

                    await splitStock(
                      DateTime.now(),
                      itemOnAccount,
                      model,
                      splitFactor,
                      false,
                    );
                  },
                  child: const Text('실행'),
                ),
              ],
            ),
        barrierDismissible: true);
  }
}
