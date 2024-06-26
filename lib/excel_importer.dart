import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lonely/account_list_widget.dart';
import 'package:lonely/fetch_util.dart';
import 'package:lonely/transaction.dart';

class Importer {
  final _colMap = <String, int>{};
  late final Sheet _sheet;

  Future<void> loadSheet(File file) async {
    var bytes = await file.readAsBytes();
    var excel = Excel.decodeBytes(bytes);

    for (var sheetName in excel.tables.keys) {
      //print(sheetName);
      _sheet = excel.tables[sheetName]!;

      //print(_sheet.maxCols);
      //print(_sheet.maxRows);

      final headerRow = _sheet.rows[1];
      for (final colInfo in headerRow.where((e) => e != null).map((e) =>
          ColumnInfo(colIndex: e!.columnIndex, colName: e.value.toString()))) {
        _colMap[colInfo.colName] = colInfo.colIndex;
      }
      break;
    }
  }

  Future<int> execute(
    int accountId,
    StockTxtLoader stockTxtLoader,
    Future<void> Function(
      double progress,
      Transaction transaction,
    ) onNewTransaction,
    Future<void> Function(
      double progress,
      DateTime dateTime,
      String stockId,
      int splitFactor,
    ) onSplitStock,
    Future<void> Function(
      double progress,
      DateTime dateTime,
      String stockId,
      int count,
    ) onTransferStock,
  ) async {
    final missingStockIdNames = <String>{};

    final maxRows = _sheet.maxRows;

    var insertedCount = 0;

    // 과거 내역이 먼저 나올 수도 있고, (A)
    // 최근 내역이 먼저 나올 수도 있다. (B)
    // 거래 내역을 일괄 등록하는 방식이므로, (A) 방식이 더 자연스럽다.
    // 처음과 마지막 거래 내역 날짜를 보고 순서 뒤집어야 할지 말지 판단하자.

    final firstRowDateTimeStr = getColStr(_sheet.rows[2], '거래일자');
    final lastRowDateTimeStr = getColStr(_sheet.rows[maxRows - 1], '거래일자');

    final rows = _sheet.rows.sublist(2).sortedBy((e) => getColStr(e, '거래일자')!).stableSortedBy((e) {
      final transactionType = getColStr(e, '거래명')!;
      switch (transactionType) {
        case '매수': return 0;
        case '무상입고': return 1;
        case '매도': return 2;
        default: return 3;
      }
    });

    //final rowsIterator = firstRowDateTimeStr!.compareTo(lastRowDateTimeStr!) < 0 ? rows : rows.reversed;
    final rowsList = rows.toList();

    for (var i = 0; i < rowsList.length; i++) {
      final row = rowsList[i];

      final dateTimeStr = getColStr(row, '거래일자');

      final transactionType = getColStr(row, '거래명');
      final stockName = getColStr(row, '종목명');
      final price = getColStr(row, '거래단가');
      final count = getColStr(row, '거래수량');
      final accumCount = getColStr(row, '잔고수량/펀드평가금액');

      if (dateTimeStr == null ||
          transactionType == null ||
          stockName == null ||
          price == null ||
          count == null ||
          accumCount == null) {
        continue;
      }

      // TODO 디버그용
      // if (stockName.toString() != '펄어비스') {
      //   continue;
      // }

      final dateTime = DateTime.tryParse(dateTimeStr)!;

      if (transactionType == '매수' ||
          transactionType == '매도' ||
          transactionType.endsWith('주식매수') ||
          transactionType.endsWith('주식매도') ||
          transactionType == '액면분할출고' ||
          transactionType == '타사출고' ||
          transactionType == '타사입고') {
        final stockId = stockTxtLoader.nameToId[stockName];
        if (stockId == null) {
          missingStockIdNames.add(stockName);
        }

        final currencyCode = getColStr(row, '통화코드');

        final priceTxt = price.toString().replaceAll(',', '');

        final priceInt = ((double.tryParse(priceTxt) ?? 0) *
                (currencyCode.toString() == 'USD' ? fracMultiplier : 1))
            .round();

        final countInt =
            int.tryParse(count.toString().replaceAll(',', '')) ?? 0;

        if (kDebugMode) {
          // print(
          //     '${dateTime.toString().substring(0, 10)},${transactionType.substring(transactionType.length - 2)},$stockId,$stockName,${price.toString().replaceAll(',', '')},${count.toString().replaceAll(',', '')},${accumCount.toString().replaceAll(',', '')}');
        }

        if (transactionType == '액면분할출고') {
          // 출고 후 입고를 전량 매도 후 전량 매수로 처리한다. (이익 0)
          final nextRow = rowsList[i + 1];
          if (stockName != getColStr(nextRow, '종목명') ||
              '액면분할입고' != getColStr(nextRow, '거래명')) {
            throw Exception('inconsistent data 1');
          }

          final nextCount = getColStr(nextRow, '거래수량');
          final nextCountInt =
              int.tryParse(nextCount.toString().replaceAll(',', '')) ?? 0;

          await onSplitStock(i / maxRows, dateTime, stockId ?? stockName,
              (nextCountInt / countInt).round());

          i++; // 다음 행 건너뛰기

          insertedCount++;
          insertedCount++;
        } else if (transactionType == '매수' ||
            transactionType.endsWith('주식매수') ||
            transactionType == '매도' ||
            transactionType.endsWith('주식매도')) {
          await onNewTransaction(
            i / maxRows,
            Transaction(
              stockId: stockId ?? stockName,
              price: priceInt,
              count: countInt,
              transactionType:
                  (transactionType == '매수' || transactionType.endsWith('주식매수'))
                      ? TransactionType.buy
                      : TransactionType.sell,
              dateTime: dateTime,
              accountId: accountId,
            ),
          );
          insertedCount++;
        } else if (transactionType == '타사입고') {
          await onTransferStock(
              i / maxRows, dateTime, stockId ?? stockName, countInt);
          insertedCount++;
        } else if (transactionType == '타사출고') {
          await onTransferStock(
              i / maxRows, dateTime, stockId ?? stockName, -countInt);
          insertedCount++;
        }
      } else if (transactionType == '액면분할입고') {
        // 액면분할입고는 반드시 액면분할출고가 처리될 때 같이 처리되었어야 했다...
        // 여기에 왔다면 엑셀 파일 이상한 것이다.
        throw Exception('inconsistent data 2');
      }
    }

    if (missingStockIdNames.isNotEmpty) {
      if (kDebugMode) {
        print('=== Stock ID 조회 불가 종목명 (시작) ===');
      }
      for (final missingStockIdName in missingStockIdNames) {
        if (kDebugMode) {
          print(missingStockIdName);
        }
      }
      if (kDebugMode) {
        print('=== Stock ID 조회 불가 종목명 (끝) ===');
      }
    }

    return insertedCount;
  }

  String? getColStr(List<Data?> row, String colName) {
    final colIndex = _colMap[colName];
    if (colIndex == null) return null;

    return row[colIndex]?.value.toString();
  }
}

class ColumnInfo {
  final int colIndex;
  final String colName;

  ColumnInfo({required this.colIndex, required this.colName});
}

class StockImporter {
  final _colMap = <String, int>{};
  final _idToNameMap = <String, String>{};
  final _nameToIdMap = <String, String>{};
  late final Sheet _sheet;

  UnmodifiableMapView<String, String> get idToName =>
      UnmodifiableMapView(_idToNameMap);

  UnmodifiableMapView<String, String> get nameToId =>
      UnmodifiableMapView(_nameToIdMap);

  StockImporter(String file) {
    var bytes = File(file).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    for (var sheetName in excel.tables.keys) {
      //print(sheetName);
      _sheet = excel.tables[sheetName]!;

      //print(_sheet.maxCols);
      //print(_sheet.maxRows);

      final headerRow = _sheet.rows[0];
      for (final colInfo in headerRow.where((e) => e != null).map((e) =>
          ColumnInfo(colIndex: e!.columnIndex, colName: e.value.toString()))) {
        _colMap[colInfo.colName] = colInfo.colIndex;
      }
      break;
    }
  }

  void execute() {
    for (var row in _sheet.rows) {
      final stockName = getColStr(row, '회사명');
      final stockId = getColStr(row, '종목코드');
      if (stockName != null && stockId != null) {
        //print('$stockName,$stockId');
        _idToNameMap[stockId] = stockName;
        _nameToIdMap[stockName] = stockId;
      }
    }
  }

  String? getColStr(List<Data?> row, String colName) {
    final colIndex = _colMap[colName];
    if (colIndex == null) return null;

    return row[colIndex]?.value.toString();
  }
}

class StockTxtLoader {
  final _idToNameMap = <String, String>{};
  final _nameToIdMap = <String, String>{};

  UnmodifiableMapView<String, String> get idToName =>
      UnmodifiableMapView(_idToNameMap);

  UnmodifiableMapView<String, String> get nameToId =>
      UnmodifiableMapView(_nameToIdMap);

  Future<void> load() async {
    final stockTxtStr = await rootBundle.loadString('assets/Stock.txt');
    const lineSplitter = LineSplitter();
    final lines = lineSplitter.convert(stockTxtStr);

    for (final l in lines) {
      final stockId = l.substring(0, 6);
      final stockName = l.substring(7);
      _idToNameMap[stockId] = stockName;
      _nameToIdMap[stockName] = stockId;
    }
    if (kDebugMode) {
      print('${_idToNameMap.length} stock(s) loaded from Stock.txt.');
    }
  }
}
