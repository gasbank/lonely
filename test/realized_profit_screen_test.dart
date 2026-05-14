import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:lonely/database.dart';
import 'package:lonely/model/lonely_model.dart';
import 'package:lonely/realized_profit_screen.dart';
import 'package:provider/provider.dart';
import 'package:lonely/realized_profit_screen.dart';
import 'package:lonely/transaction.dart';

class _FakeLonelyDatabase extends LonelyDatabase {
  int _nextAccountId = 1;
  int _nextStockId = 1;
  int _nextTransactionId = 1;

  @override
  Future<int> insertAccount(Map<String, Object?> values) async {
    return _nextAccountId++;
  }

  @override
  Future<int> insertStock(Map<String, Object?> values) async {
    return _nextStockId++;
  }

  @override
  Future<int> insertTransaction(Map<String, Object?> values) async {
    return _nextTransactionId++;
  }
}

void main() {
  test('buildRealizedProfitItems aggregates earn per stock and keeps zero rows',
      () {
    final transactions = [
      Transaction(
        stockId: '005930',
        price: 70000,
        count: 1,
        transactionType: TransactionType.buy,
        dateTime: DateTime.parse('2025-01-01T00:00:00.000'),
        accountId: 1,
      ),
      Transaction(
        stockId: '005930',
        price: 72000,
        count: 1,
        transactionType: TransactionType.sell,
        dateTime: DateTime.parse('2025-01-02T00:00:00.000'),
        accountId: 1,
      )..earn = 2000,
      Transaction(
        stockId: 'TSLA',
        price: 2500000,
        count: 1,
        transactionType: TransactionType.sell,
        dateTime: DateTime.parse('2025-01-03T00:00:00.000'),
        accountId: 1,
      )..earn = -500000,
      Transaction(
        stockId: 'AAPL',
        price: 1800000,
        count: 1,
        transactionType: TransactionType.buy,
        dateTime: DateTime.parse('2025-01-04T00:00:00.000'),
        accountId: 1,
      ),
    ];

    final stocks = {
      '005930': Stock(id: 1, stockId: '005930', name: '삼성전자'),
      'TSLA': Stock(id: 2, stockId: 'TSLA', name: 'Tesla'),
      'AAPL': Stock(id: 3, stockId: 'AAPL', name: 'Apple'),
    };

    final items = buildRealizedProfitItems(transactions, stocks);

    expect(items.map((item) => item.stockId).toList(), [
      '005930',
      'AAPL',
      'TSLA',
    ]);
    expect(items.map((item) => item.accumEarn).toList(), [
      2000,
      0,
      -500000,
    ]);
    expect(items.map((item) => item.stockName).toList(), [
      '삼성전자',
      'Apple',
      'Tesla',
    ]);
  });

  test('buildRealizedProfitItems filters domestic and foreign markets', () {
    final transactions = [
      Transaction(
        stockId: '005930',
        price: 70000,
        count: 1,
        transactionType: TransactionType.sell,
        dateTime: DateTime.parse('2025-01-02T00:00:00.000'),
        accountId: 1,
      )..earn = 2000,
      Transaction(
        stockId: 'TSLA',
        price: 2500000,
        count: 1,
        transactionType: TransactionType.sell,
        dateTime: DateTime.parse('2025-01-03T00:00:00.000'),
        accountId: 1,
      )..earn = -500000,
    ];

    final stocks = {
      '005930': Stock(id: 1, stockId: '005930', name: '삼성전자'),
      'TSLA': Stock(id: 2, stockId: 'TSLA', name: 'Tesla'),
    };

    expect(
      buildRealizedProfitItems(
        transactions,
        stocks,
        marketFilter: RealizedProfitMarketFilter.domestic,
      ).map((item) => item.stockId).toList(),
      ['005930'],
    );
    expect(
      buildRealizedProfitItems(
        transactions,
        stocks,
        marketFilter: RealizedProfitMarketFilter.foreign,
      ).map((item) => item.stockId).toList(),
      ['TSLA'],
    );
  });

  testWidgets('shows total earn only when domestic or foreign filter is selected',
      (tester) async {
    final model = LonelyModel(database: _FakeLonelyDatabase());
    final accountId = await model.addAccount('Alpha');
    await model.setStock(Stock(id: 0, stockId: '005930', name: '삼성전자'));
    await model.setStock(Stock(id: 0, stockId: 'TSLA', name: 'Tesla'));
    await model.addTransaction(Transaction(
      stockId: '005930',
      price: 70000,
      count: 1,
      transactionType: TransactionType.sell,
      dateTime: DateTime.parse('2025-01-02T00:00:00.000'),
      accountId: accountId,
    )..earn = 2000);
    await model.addTransaction(Transaction(
      stockId: 'TSLA',
      price: 2500000,
      count: 1,
      transactionType: TransactionType.sell,
      dateTime: DateTime.parse('2025-01-03T00:00:00.000'),
      accountId: accountId,
    )..earn = -500000);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: model,
        child: const MaterialApp(
          home: Scaffold(
            body: RealizedProfitScreen(),
          ),
        ),
      ),
    );

    expect(find.text('총 수익'), findsNothing);

    await tester.tap(find.text('국내'));
    await tester.pumpAndSettle();

    expect(find.text('총 수익'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('realized-profit-total-earn')))
          .data,
      '2,000',
    );

    await tester.tap(find.text('해외'));
    await tester.pumpAndSettle();

    expect(find.text('총 수익'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('realized-profit-total-earn')))
          .data,
      '-\$50.0',
    );

    await tester.tap(find.text('해외'));
    await tester.pumpAndSettle();

    expect(find.text('총 수익'), findsNothing);
  });
}
