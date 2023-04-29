import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const transactionsTable = 'transactions';
const stocksTable = 'stocks';
const accountsTable = 'accounts';

class Stock {
  int? id;
  final String stockId;
  final String name;
  int? closePrice;
  int? inventoryOrder;

  Stock(
      {required this.id,
      required this.stockId,
      required this.name,
      this.closePrice,
      this.inventoryOrder});

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      id: map['id'],
      stockId: map['stockId'],
      name: map['name'],
      inventoryOrder: map['inventoryOrder'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stockId': stockId,
      'name': name,
      'inventoryOrder': inventoryOrder,
    };
  }
}

void _createTransactionsTableV3(Batch batch) {
  batch.execute('''
CREATE TABLE IF NOT EXISTS $transactionsTable
(
  id              INTEGER PRIMARY KEY
  ,
  stockId         TEXT    NOT NULL
  ,
  price           INTEGER NOT NULL
  ,
  count           INTEGER NOT NULL
  ,
  transactionType INTEGER NOT NULL
  ,
  dateTime        DATETIME
  ,
  earn            INTEGER
  ,
  accountId       INTEGER
);
''');
}

void _updateTransactionsTableV1toV2(Batch batch) {
  batch.execute('ALTER TABLE $transactionsTable ADD accountId INTEGER;');
}

void _updateTransactionsTableV2toV3(Batch batch) {
  batch.execute('ALTER TABLE $transactionsTable ADD listOrder INTEGER;');
}

void _createStocksTableV1(Batch batch) {
  batch.execute('''
CREATE TABLE IF NOT EXISTS $stocksTable
(
  id              INTEGER PRIMARY KEY
  ,
  stockId         TEXT    NOT NULL
  ,
  name            TEXT    NOT NULL
);
''');
}

void _createStocksTableV2(Batch batch) {
  batch.execute('''
CREATE TABLE IF NOT EXISTS $stocksTable
(
  id              INTEGER PRIMARY KEY
  ,
  stockId         TEXT    NOT NULL
  ,
  name            TEXT    NOT NULL
  ,
  inventoryOrder  INTEGER
);
''');
}

void _updateStocksTableV1toV2(Batch batch) {
  batch.execute('ALTER TABLE $stocksTable ADD inventoryOrder INTEGER;');
}

void _createAccountsTableV1(Batch batch) {
  batch.execute('''
CREATE TABLE IF NOT EXISTS $accountsTable
(
  id              INTEGER PRIMARY KEY
  ,
  name            TEXT    NOT NULL
);
''');
  batch.execute('''
INSERT INTO $accountsTable (name) VALUES ('기본');
''');
}

const String _dbFileName = 'lonely.db';

Future<Database> _initDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();

  final options = OpenDatabaseOptions(
    onCreate: (db, version) async {
      final batch = db.batch();
      _createTransactionsTableV3(batch);
      _createStocksTableV2(batch);
      _createAccountsTableV1(batch);
      await batch.commit();
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      final batch = db.batch();
      if (oldVersion == 1) {
        _createStocksTableV1(batch);
        oldVersion++;
      }
      if (oldVersion == 2) {
        _createAccountsTableV1(batch);
        _updateTransactionsTableV1toV2(batch);
        oldVersion++;
      }
      if (oldVersion == 3) {
        _updateTransactionsTableV2toV3(batch);
        oldVersion++;
      }
      if (oldVersion == 4) {
        _updateStocksTableV1toV2(batch);
        oldVersion++;
      }
      await batch.commit();
    },
    version: 5,
  );

  final dbPath = await getDbPath();
  if (kDebugMode) {
    print('DB path: $dbPath');
  }

  if (Platform.isWindows || Platform.isLinux) {
    return databaseFactoryFfi.openDatabase(dbPath, options: options);
  } else {
    return databaseFactory.openDatabase(dbPath, options: options);
  }
}

Future<String> getDbPath() async {
  if (Platform.isWindows || Platform.isLinux) {
    return join((await getApplicationSupportDirectory()).path, _dbFileName);
  } else {
    return join(await getDatabasesPath(), _dbFileName);
  }
}

class LonelyDatabase {
  late Future<Database> _database;

  LonelyDatabase() {
    _database = _initDatabase();
  }

  Future<void> closeAndReloadDatabase(File? newDbFile) async {
    final db = await _database;
    if (db.isOpen) {
      await db.close();
      final dbPath = await getDbPath();
      if (newDbFile != null) {
        await newDbFile.copy(dbPath);
      } else {
        await File(dbPath).delete();
      }
      _database = _initDatabase();
    }
  }

  Future<int> insertTransaction(Map<String, Object?> values) async {
    return _insert(transactionsTable, values);
  }

  Future<int> insertStock(Map<String, Object?> values) async {
    return _insert(stocksTable, values);
  }

  Future<int> insertAccount(Map<String, Object?> values) async {
    return _insert(accountsTable, values);
  }

  Future<int> updateAccount(int id, Map<String, Object?> values) async {
    return _update(accountsTable, id, values);
  }

  Future<String?> queryStockName(String stockId) async {
    final db = await _database;
    final result = await db.query(stocksTable,
        where: 'stockId = ?', whereArgs: [stockId], limit: 1);
    if (result.isNotEmpty) {
      return Stock.fromMap(result[0]).name;
    }
    return null;
  }

  Future<int> _insert(String tableName, Map<String, Object?> values) async {
    final db = await _database;
    return await db.insert(
      tableName,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> _update(
      String tableName, int id, Map<String, Object?> values) async {
    final db = await _database;
    return await db.update(
      tableName,
      values,
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryTransactions() async {
    final db = await _database;
    return await db.query(transactionsTable);
  }

  Future<List<Map<String, dynamic>>> queryStocks() async {
    final db = await _database;
    return await db.query(stocksTable);
  }

  Future<List<Map<String, dynamic>>> queryAccounts() async {
    final db = await _database;
    return await db.query(accountsTable);
  }

  Future<int> removeTransaction(List<int> idList) async {
    return _removeById(transactionsTable, idList);
  }

  Future<int> _removeById(String tableName, List<int> idList) async {
    if (idList.isEmpty) {
      return 0;
    }

    final db = await _database;
    return await db.delete(tableName,
        where: 'id IN (${List.filled(idList.length, '?').join(',')})',
        whereArgs: idList);
  }

  Future<int> _clearAccountIdFromTransactionTable(
      List<int> accountIdList) async {
    if (accountIdList.isEmpty) {
      return 0;
    }

    final db = await _database;
    return db.update(transactionsTable, {'accountId': null},
        where:
            'accountId IN (${List.filled(accountIdList.length, '?').join(',')})',
        whereArgs: accountIdList);
  }

  Future<int> updateStocksInventoryOrder(
      String stockId, int inventoryOrder) async {
    final db = await _database;
    return await db.update(stocksTable, {'inventoryOrder': inventoryOrder},
        where: 'stockId = ?', whereArgs: [stockId]);
  }

  Future<List<int>> removeAccount(List<int> idList) async {
    return [
      await _removeById(accountsTable, idList),
      await _clearAccountIdFromTransactionTable(idList)
    ];
  }

  Future<int> updateTransaction(int id, Map<String, dynamic> values) async {
    return _update(transactionsTable, id, values);
  }
}
