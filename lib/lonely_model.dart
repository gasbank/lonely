import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'database.dart';
import 'excel_importer.dart';
import 'fetch_util.dart';
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
  int _selectedScreenIndex = 0;

  Transaction? _editingTransaction;

  UnmodifiableMapView<String, Stock> get stocks => UnmodifiableMapView(_stocks);

  UnmodifiableListView<Account> get accounts => UnmodifiableListView(_accounts);

  UnmodifiableListView<Transaction> get transactions => UnmodifiableListView(_transactions);

  Transaction? get editingTransaction => _editingTransaction;

  int get selectedScreenIndex => _selectedScreenIndex;

  final _db = LonelyDatabase();

  final _stockTxtLoader = StockTxtLoader();

  get stockTxtLoader => _stockTxtLoader;

  LonelyModel() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      await _loadAccounts();
      await _loadStocks();
      await _loadTransactions();
      await _stockTxtLoader.load();
    } catch (e) {
      print(e);
    }
  }

  Future<void> closeAndReplaceDatabase(File? newDb) async {
    await _db.closeAndReloadDatabase(newDb);
    await _loadAll();
  }

  Future<int> setStock(Stock s) async {
    // 이번에 들어온 Stock 정보에 이름이 있고, DB에 기록된 적이 없을 때만 기록
    if (s.name.isNotEmpty && (getStock(s.stockId)?.name.isEmpty ?? true)) {
      s.id = await _db.insertStock(s.toMap());
    }

    final oldStock = _stocks[s.stockId];
    if (oldStock != null) {
      // 달라지는 것 없음 (아마도?)
    } else {
      // 첫 항목이면 새로 등록
      _stocks[s.stockId] = s;
      notifyListeners();
    }

    return s.id ?? 0;
  }

  Stock? getStock(String stockId) {
    stockId = stockIdAlternatives[stockId] ?? stockId;

    return _stocks[stockId];
  }

  Future<int?> addTransaction(Transaction transaction) async {
    final insertedDbId = await _db.insertTransaction(transaction.toMap());
    transaction.id = insertedDbId;
    _transactions.add(transaction);
    notifyListeners();

    return insertedDbId;
  }

  Future<int> removeTransaction(List<int> idList) async {
    final removedCount = await _db.removeTransaction(idList);
    _transactions.removeWhere((e) => idList.contains(e.id));
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

    final removedIndex = _accounts.indexWhere((e) => e.id == updateDbId);
    _accounts.removeWhere((e) => e.id == updateDbId);
    final updatedAccount = Account(id: updateDbId, name: name);
    _accounts.insert(removedIndex, updatedAccount);
    notifyListeners();

    return _updateAccountToDb(updateDbId, updatedAccount);
  }

  Future<int> _addAccountToDb(Account account) async {
    final insertedId = await _db.insertAccount(account.toMap());
    if (kDebugMode) {
      print('New account DB ID: $insertedId');
    }
    return insertedId;
  }

  Future<int> _updateAccountToDb(int id, Account account) async {
    final updateCount = await _db.updateAccount(id, account.toMap());
    if (kDebugMode) {
      print('Updated account DB raw count: $updateCount');
    }
    return updateCount;
  }

  Future<void> _loadAccounts() async {
    final accounts = await _db.queryAccounts();

    if (kDebugMode) {
      print('${accounts.length} account(s) loaded from database.');
    }

    _accounts.clear();
    _accounts.addAll(accounts.map((e) => Account.fromMap(e)));
    notifyListeners();
  }

  Future<void> _loadStocks() async {
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

  Future<void> _loadTransactions() async {
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

  Future<List<int>> removeAccount(List<int> idList) async {
    final removedCount = await _db.removeAccount(idList);

    _accounts.removeWhere((e) => idList.contains(e.id));
    _transactions.where((e) => idList.contains(e.accountId)).forEach((e) {
      e.accountId = null;
    });

    notifyListeners();

    return removedCount;
  }

  void setEditingTransaction(Transaction? transaction) {
    _editingTransaction = transaction;
    notifyListeners();
  }

  Future<int> updateTransaction(int id, Transaction transaction) async {
    final count = await _db.updateTransaction(id, transaction.toMap());

    transaction.id = id;
    final removeIndex = _transactions.indexWhere((e) => e.id == id);
    _transactions.removeAt(removeIndex);
    _transactions.insert(removeIndex, transaction);
    notifyListeners();

    return count;
  }

  void setSelectedScreenIndex(int index) {
    _selectedScreenIndex = index;
    notifyListeners();
  }

  Future<int?> removeTransactionWhereNullAccountId() async {
    _transactions.removeWhere((e) => e.accountId == null);
    final count = await _db.removeTransactionWhereNullAccountId();
    notifyListeners();

    return count;
  }
}
