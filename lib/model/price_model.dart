import 'dart:collection';

import 'package:flutter/material.dart';

class Price {
  final String stockId;
  final int? price;

  Price({required this.stockId, required this.price});
}

class PriceModel extends ChangeNotifier {
  final _prices = <String, Price>{};
  double? _usdKrw;

  UnmodifiableMapView<String, Price> get prices => UnmodifiableMapView(_prices);

  void setPrice(String stockId, int? price) {
    _prices[stockId] = Price(stockId: stockId, price: price);
    notifyListeners();
  }

  void setUsdKrw(double? value) {
    _usdKrw = value;
    notifyListeners();
  }

  double? getUsdKrw() {
    return _usdKrw;
  }
}