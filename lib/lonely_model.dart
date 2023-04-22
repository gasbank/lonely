import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:lonely_flutter/database.dart';

class LonelyModel extends ChangeNotifier {
  final _stocks = <String, Stock>{};
  Map<String, Stock> get stocks => UnmodifiableMapView(_stocks);

  setStock(Stock stock) {
    _stocks[stock.stockId] = stock;
    notifyListeners();
  }
}
