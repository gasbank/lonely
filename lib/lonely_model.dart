import 'dart:collection';

import 'package:flutter/foundation.dart';
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

  final _db = LonelyDatabase();

  LonelyModel() {
    _loadAccounts();
  }

  void setStock(Stock stock) {
    _stocks[stock.stockId] = stock;
    notifyListeners();
  }

  void addAccount(String name) {
    final account = Account(id: 0, name: name);
    _accounts.add(account);
    notifyListeners();

    _addAccountToDb(account);
  }

  void _addAccountToDb(Account account) async {
    final insertedId = await _db.insertAccount(account.toMap());
    if (kDebugMode) {
      print('New account DB ID: $insertedId');
    }
  }

  void _loadAccounts() async {
    final accounts = await _db.queryAccount();

    if (kDebugMode) {
      print('${accounts.length} account(s) loaded from database.');
    }

    _accounts.clear();
    _accounts.addAll(accounts.map((e) => Account.fromMap(e)));
    notifyListeners();
  }
}
