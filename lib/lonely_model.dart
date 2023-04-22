import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:lonely_flutter/database.dart';

class Account {
  final int id;
  final String name;

  Account({required this.id, required this.name});

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(id: map['id'], name: map['name']);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}

class LonelyModel extends ChangeNotifier {
  final _stocks = <String, Stock>{};
  Map<String, Stock> get stocks => UnmodifiableMapView(_stocks);

  final _accounts = <Account>[];
  List<Account> get accounts => UnmodifiableListView(_accounts);

  setStock(Stock stock) {
    _stocks[stock.stockId] = stock;
    notifyListeners();
  }

  addAccount(String name) {
    _accounts.add(Account(id: 0, name: name));
    notifyListeners();
  }
}
