import 'package:flutter/widgets.dart';

class BuySellHistoryEntry extends StatefulWidget {
  const BuySellHistoryEntry({super.key, required this.stockId, required this.stockName});

  final String stockId;
  final String stockName;

  @override
  State<StatefulWidget> createState()  => _BuySellHistoryEntryState();
}

class _BuySellHistoryEntryState extends State<BuySellHistoryEntry> {
  int _price = 498000;

  @override
  Widget build(BuildContext context) {

    return Column(
        children: <Widget>[
          const Text(
            '뭐지 아깐 왜 안됐던거야? 호오라~~111',
          ),
          Text(
            '${widget.stockName} (${widget.stockId})',
          ),
          Text(
            '$_price',
          ),
        ]);
  }
}
