import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const transactionsTable = 'transactions';
const stocksTable = 'stocks';
const accountsTable = 'accounts';

class Stock {
  final int id;
  final String stockId;
  final String name;
  final int closePrice;

  Stock({required this.id, required this.stockId, required this.name, required this.closePrice});

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(id: map['id'], stockId: map['stockId'], name: map['name'], closePrice: 0);
  }

  Map<String, dynamic> toMap() {
    return {
      'stockId': stockId,
      'name': name,
    };
  }
}

void _createTransactionsTableV2(Batch batch) {
  batch.execute('''
CREATE TABLE IF NOT EXISTS $transactionsTable
(
  id              INTEGER PRIMARY KEY,
  stockId         TEXT    NOT NULL,
  price           INTEGER NOT NULL,
  count           INTEGER NOT NULL,
  transactionType INTEGER NOT NULL,
  dateTime        DATETIME,
  earn            INTEGER,
  accountId       INTEGER,
);
''');
}

void _updateTransactionsTableV1toV2(Batch batch) {
  batch.execute('ALTER TABLE $transactionsTable ADD accountId INTEGER');
}

void _createStocksTableV1(Batch batch) {
  batch.execute('''
CREATE TABLE IF NOT EXISTS $stocksTable
(
  id              INTEGER PRIMARY KEY,
  stockId         TEXT    NOT NULL,
  name            TEXT    NOT NULL
);
''');
}

void _createAccountsTableV1(Batch batch) {
  batch.execute('''
CREATE TABLE IF NOT EXISTS $accountsTable
(
  id              INTEGER PRIMARY KEY,
  name            TEXT    NOT NULL
);
''');
}

Future<Database> _initDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'lonely.db'),
    onCreate: (db, version) async {
      final batch = db.batch();
      _createTransactionsTableV2(batch);
      _createStocksTableV1(batch);
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
      }
      await batch.commit();
    },
    version: 3,
  );
  return database;
}

class LonelyDatabase {
  late final Future<Database> database;

  LonelyDatabase() {
    database = _initDatabase();
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

  Future<String?> queryStockName(String stockId) async {
    final db = await database;
    final result = await db.query(stocksTable,
        where: 'stockId = ?', whereArgs: [stockId], limit: 1);
    if (result.isNotEmpty) {
      return Stock.fromMap(result[0]).name;
    }
    return null;
  }

  Future<int> _insert(String tableName, Map<String, Object?> values) async {
    final db = await database;
    return await db.insert(
      tableName,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryTransaction() async {
    final db = await database;
    return await db.query(transactionsTable);
  }

  Future<List<Map<String, dynamic>>> queryStock() async {
    final db = await database;
    return await db.query(stocksTable);
  }

  Future<List<Map<String, dynamic>>> queryAccount() async {
    final db = await database;
    return await db.query(accountsTable);
  }

  Future<int> removeTransaction(List<int> dbIdSet) async {
    if (dbIdSet.isEmpty) {
      return 0;
    }

    final db = await database;
    return await db.delete(transactionsTable,
        where: 'id IN (${List.filled(dbIdSet.length, '?').join(',')})',
        whereArgs: dbIdSet);
  }
}
