import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:lonely_flutter/database.dart';

class Account {
  int? id;
  final String name;

  Account({required this.name, this.id});

  factory Account.empty() {
    return Account(id: null, name: '');
  }

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

  Stock? getStock(String stockId) {
    return _stocks[stockId];
  }

  Future<int?> addAccount(String name, {int? updateDbId}) async {
    if (_isDuplicatedAccountName(name)) {
      return null;
    }

    final account = Account(name: name);
    account.id = await _addAccountToDb(account);
    _accounts.add(account);
    notifyListeners();

    return account.id;
  }

  bool _isDuplicatedAccountName(String name) {
    final account = _accounts.singleWhere((e) => e.name == name, orElse: Account.empty);
    return account.id != null && account.id! > 0;
  }

  Future<int> updateAccount(int updateDbId, String name) async {
    if (_isDuplicatedAccountName(name)) {
      return 0;
    }

    if (updateDbId <= 0) {
      return 0;
    }

    _accounts.removeWhere((e) => e.id == updateDbId);
    final updatedAccount = Account(id: updateDbId, name: name);
    _accounts.add(updatedAccount);
    notifyListeners();

    return _updateAccountToDb(updatedAccount);
  }

  Future<int> _addAccountToDb(Account account) async {
    final insertedId = await _db.insertAccount(account.toMap());
    if (kDebugMode) {
      print('New account DB ID: $insertedId');
    }
    return insertedId;
  }

  Future<int> _updateAccountToDb(Account account) async {
    final updateCount = await _db.updateAccount(account.toMap());
    if (kDebugMode) {
      print('Updated account DB raw count: $updateCount');
    }
    return updateCount;
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

  Account getAccount(int? accountId) {
    if (accountId == null) {
      return Account.empty();
    }

    return _accounts.singleWhere((e) => e.id == accountId,
        orElse: Account.empty);
  }
}
