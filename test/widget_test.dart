import 'package:flutter_test/flutter_test.dart';
import 'package:lonely/database.dart';
import 'package:lonely/model/lonely_model.dart';

class FakeLonelyDatabase extends LonelyDatabase {
  final _accounts = <Map<String, dynamic>>[];
  int _nextAccountId = 1;

  Map<String, int?> get accountOrderByName {
    return {
      for (final account in _accounts)
        account['name'] as String: account['accountOrder'] as int?,
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
}
