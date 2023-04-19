import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LonelyDatabase {
  late final Future<Database> database;

  LonelyDatabase() {
    database = _initDatabase();
  }

  Future<Database> _initDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    final database = openDatabase(
      join(await getDatabasesPath(), 'lonely.db'),
      onCreate: (db, version) {
        return db.execute('''
CREATE TABLE IF NOT EXISTS transactions
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
      },
      version: 1,
    );
    return database;
  }

  static const transactionsTable = 'transactions';

  void insertTransaction(Map<String, Object?> values) async {
    final db = await database;
    await db.insert(
      transactionsTable,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryTransaction() async {
    final db = await database;
    return await db.query(transactionsTable);
  }
}
