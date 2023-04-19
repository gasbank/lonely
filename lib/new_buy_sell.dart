import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum BuySell {
  buy, sell,
}

class NewBuySell {
  NewBuySell({required this.stockId, required this.price, required this.count, required this.buySell});
  final String stockId;
  final int price;
  final int count;
  final BuySell buySell;
}

class NewBuySellEntry extends StatefulWidget {
  const NewBuySellEntry({super.key, required this.onNewEntry});

  final Function(NewBuySell newBuySell) onNewEntry;

  @override
  State<StatefulWidget> createState()  => _NewBuySellEntryState();
}

class _NewBuySellEntryState extends State<NewBuySellEntry> {
  final TextEditingController _stockIdController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _countController = TextEditingController();

  void onPress(BuySell buySell) {
    widget.onNewEntry(NewBuySell(buySell: buySell, count: int.tryParse(_countController.text) ?? 0, price: int.tryParse(_priceController.text) ?? 0, stockId: _stockIdController.text));
    clearTextFields();
  }

  void clearTextFields() {
    _stockIdController.text = '';
    _priceController.text = '';
    _countController.text = '';
  }

  @override void dispose() {
    _stockIdController.dispose();
    _priceController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: TextField(
                    controller: _stockIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '종목코드',
                        contentPadding: EdgeInsets.all(10.0)),
                    autocorrect: false,
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '단가',
                        contentPadding: EdgeInsets.all(10.0)),
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: TextField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '수량',
                        contentPadding: EdgeInsets.all(10.0)),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: OutlinedButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
                  ),
                  onPressed: () { onPress(BuySell.buy); },
                  child: const Text('매수'),
                ),
              ),
              Flexible(
                child: OutlinedButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
                  ),
                  onPressed: () { onPress(BuySell.sell); },
                  child: const Text('매도'),
                ),
              ),
            ],
          ),
        ]);
  }
}
