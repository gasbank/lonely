import 'package:flutter_test/flutter_test.dart';
import 'package:lonely/database.dart';
import 'package:lonely/model/lonely_model.dart';

class FakeLonelyDatabase extends LonelyDatabase {
  final _accounts = <Map<String, dynamic>>[];
  final _stocks = <Map<String, dynamic>>[];
  int _nextAccountId = 1;
  int _nextStockId = 1;

  Map<String, int?> get accountOrderByName {
    return {
      for (final account in _accounts)
        account['name'] as String: account['accountOrder'] as int?,
    };
  }

  Map<String, String> get stockNameById {
    return {
      for (final stock in _stocks)
        stock['stockId'] as String: stock['name'] as String,
    };
  }

  @override
  Future<int> insertAccount(Map<String, Object?> values) async {
    final insertedId = _nextAccountId++;
    _accounts.add({
      'id': insertedId,
      ...values,
    });
    return insertedId;
  }

  @override
  Future<int> updateAccount(int id, Map<String, Object?> values) async {
    final index = _accounts.indexWhere((account) => account['id'] == id);
    if (index < 0) {
      return 0;
    }

    _accounts[index] = {
      ..._accounts[index],
      ...values,
    };
    return 1;
  }

  @override
  Future<void> updateAccountsOrder(Map<int, int> accountOrderById) async {
    for (final entry in accountOrderById.entries) {
      final index =
          _accounts.indexWhere((account) => account['id'] == entry.key);
      if (index >= 0) {
        _accounts[index]['accountOrder'] = entry.value;
      }
    }
  }

  @override
  Future<List<int>> removeAccount(List<int> idList) async {
    final removedBefore = _accounts.length;
    _accounts.removeWhere((account) => idList.contains(account['id']));
    return [removedBefore - _accounts.length, 0];
  }

  @override
  Future<int> insertStock(Map<String, Object?> values) async {
    final insertedId = _nextStockId++;
    _stocks.add({
      'id': insertedId,
      ...values,
    });
    return insertedId;
  }

  @override
  Future<List<Map<String, dynamic>>> queryStocks() async {
    return _stocks.map((stock) => Map<String, dynamic>.from(stock)).toList();
  }

  @override
  Future<int> updateStockName(String stockId, String name) async {
    final index = _stocks.indexWhere((stock) => stock['stockId'] == stockId);
    if (index < 0) {
      return 0;
    }

    _stocks[index] = {
      ..._stocks[index],
      'name': name,
    };
    return 1;
  }
}

void main() {
  group('LonelyModel account order', () {
    test('reorderAccounts persists normalized order', () async {
      final fakeDatabase = FakeLonelyDatabase();
      final model = LonelyModel(database: fakeDatabase);

      await model.addAccount('A');
      await model.addAccount('B');
      await model.addAccount('C');
      await model.reorderAccounts(0, 3);

      expect(
        model.accounts.map((account) => account.name).toList(),
        ['B', 'C', 'A'],
      );
      expect(fakeDatabase.accountOrderByName, {
        'A': 2,
        'B': 0,
        'C': 1,
      });
    });

    test('updateAccount keeps order and removeAccount compacts it', () async {
      final fakeDatabase = FakeLonelyDatabase();
      final model = LonelyModel(database: fakeDatabase);

      final alphaId = await model.addAccount('Alpha');
      await model.addAccount('Beta');
      await model.addAccount('Gamma');
      await model.reorderAccounts(2, 0);
      await model.updateAccount(alphaId!, 'Alpha Renamed');
      await model.removeAccount([model.accounts[2].id!]);

      expect(
        model.accounts.map((account) => account.name).toList(),
        ['Gamma', 'Alpha Renamed'],
      );
      expect(fakeDatabase.accountOrderByName, {
        'Alpha Renamed': 1,
        'Gamma': 0,
      });
    });
  });

  group('LonelyModel stock name refresh', () {
    test('refreshes only matching stock names without changing stock ids',
        () async {
      final fakeDatabase = FakeLonelyDatabase();
      final model = LonelyModel(database: fakeDatabase);

      await model.setStock(Stock(id: 0, stockId: '005930', name: '옛삼성전자'));
      await model.setStock(Stock(id: 0, stockId: 'TSLA', name: 'Tesla'));
      await model.setStock(Stock(id: 0, stockId: '000660', name: 'SK하이닉스'));

      final updatedCount = await model.refreshStockDisplayNames({
        '005930': '삼성전자',
        '000660': '에스케이하이닉스',
        '035420': 'NAVER',
      });

      expect(updatedCount, 2);
      expect(model.stocks['005930']?.stockId, '005930');
      expect(model.stocks['005930']?.name, '삼성전자');
      expect(model.stocks['TSLA']?.stockId, 'TSLA');
      expect(model.stocks['TSLA']?.name, 'Tesla');
      expect(model.stocks['000660']?.name, '에스케이하이닉스');
      expect(fakeDatabase.stockNameById, {
        '005930': '삼성전자',
        'TSLA': 'Tesla',
        '000660': '에스케이하이닉스',
      });
    });
  });
}
