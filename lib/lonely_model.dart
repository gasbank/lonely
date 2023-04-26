import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'database.dart';
import 'transaction.dart';

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
  final _accounts = <Account>[];
  final _transactions = <Transaction>[];

  Map<String, Stock> get stocks => UnmodifiableMapView(_stocks);

  List<Account> get accounts => UnmodifiableListView(_accounts);

  List<Transaction> get transactions => UnmodifiableListView(_transactions);

  final _db = LonelyDatabase();

  LonelyModel() {
    _loadAccounts();
    _loadStocks();
    _loadTransactions();
  }

  Future<int> setStock(Stock s) async {
    // 이번에 들어온 Stock 정보에 이름이 있고, DB에 기록된 적이 없을 때만 기록
    if (s.name.isNotEmpty && (getStock(s.stockId)?.name.isEmpty ?? true)) {
      s.id = await _db.insertStock(s.toMap());
    }

    final oldStock = _stocks[s.stockId];
    if (oldStock != null) {
      // 기존 항목 있다면 가격만 업데이트
      oldStock.closePrice = s.closePrice;
    } else {
      // 첫 항목이면 새로 등록
      _stocks[s.stockId] = s;
    }
    notifyListeners();

    return s.id ?? 0;
  }

  Stock? getStock(String stockId) {
    return _stocks[stockId];
  }

  Future<int?> addTransaction(Transaction transaction) async {
    final insertedDbId = await _db.insertTransaction(transaction.toMap());
    transaction.id = insertedDbId;
    _transactions.add(transaction);
    notifyListeners();

    return insertedDbId;
  }

  Future<int> removeTransaction(List<int> dbIdList) async {
    final removedCount = await _db.removeTransaction(dbIdList);
    _transactions.removeWhere((e) => dbIdList.contains(e.id));
    notifyListeners();

    return removedCount;
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
    final account =
        _accounts.singleWhere((e) => e.name == name, orElse: Account.empty);
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
    final accounts = await _db.queryAccounts();

    if (kDebugMode) {
      print('${accounts.length} account(s) loaded from database.');
    }

    _accounts.clear();
    _accounts.addAll(accounts.map((e) => Account.fromMap(e)));
    notifyListeners();
  }

  void _loadStocks() async {
    final stocks = await _db.queryStocks();

    if (kDebugMode) {
      print('${stocks.length} stocks(s) loaded from database.');
    }

    _stocks.clear();
    for (var stock in stocks.map((e) => Stock.fromMap(e))) {
      _stocks[stock.stockId] = stock;
    }
    notifyListeners();
  }

  void _loadTransactions() async {
    final transactions = await _db.queryTransactions();

    if (kDebugMode) {
      print('${transactions.length} transactions(s) loaded from database.');
    }

    _transactions.clear();
    _transactions.addAll(transactions.map((e) => Transaction.fromMap(e)));
    notifyListeners();
  }

  Account getAccount(int? accountId) {
    if (accountId == null) {
      return Account.empty();
    }

    return _accounts.singleWhere((e) => e.id == accountId,
        orElse: Account.empty);
  }

  Future<int> updateStocksInventoryOrder(
      String stockId, int inventoryOrder) async {
    _stocks[stockId]?.inventoryOrder = inventoryOrder;
    return await _db.updateStocksInventoryOrder(stockId, inventoryOrder);
  }
}
