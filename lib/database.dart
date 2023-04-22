import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const transactionsTable = 'transactions';
const stocksTable = 'stocks';

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

void _createTransactionsTableV1(Batch batch) {
  batch.execute('''
CREATE TABLE IF NOT EXISTS $transactionsTable
(
  id              INTEGER PRIMARY KEY,
  stockId         TEXT    NOT NULL,
  price           INTEGER NOT NULL,
  count           INTEGER NOT NULL,
  transactionType INTEGER NOT NULL,
  dateTime        DATETIME,
  earn            INTEGER
);
''');
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

Future<Database> _initDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'lonely.db'),
    onCreate: (db, version) async {
      final batch = db.batch();
      _createTransactionsTableV1(batch);
      _createStocksTableV1(batch);
      await batch.commit();
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      final batch = db.batch();
      if (oldVersion == 1) {
        _createStocksTableV1(batch);
      }
      await batch.commit();
    },
    version: 2,
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
