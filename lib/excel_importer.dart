import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lonely/fetch_util.dart';
import 'package:lonely/transaction.dart';

int transactionTypeToOrderValue(String type) {
  switch (type) {
    case "매도":
      return 999;
    case "매도_NXT":
      return 999;
    case "액면병합출고":
      return 0;
    case "액면병합입고":
      return 1;
    case "감자출고":
      return 2;
    case "감자입고":
      return 3;
    default:
      return 500;
  }
}

class Importer {
  static const colDateTime = '거래일자';
  static const colTransactionType = '거래명';
  static const colCount = '거래수량';
  static const colCurrencyCode = '통화코드';
  static const colItemName = '종목명';
  static const colPrice = '거래단가';
  static const colAccum = '잔고수량/펀드평가금액';
  static const requiredColumns = [
    colDateTime,
    colTransactionType,
    colCount,
    colCurrencyCode,
    colItemName,
    colPrice,
    colAccum,
  ];

  final _colMap = <String, int>{};
  late Sheet _sheet;

  Future<void> loadSheet(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    loadExcel(excel);
  }

  void loadExcel(Excel excel) {
    final sheet = _firstSheet(excel);
    if (sheet == null) {
      throw Exception('빈 XLSX 파일입니다.');
    }
    if (!looksLikeSamsungSheet(sheet)) {
      throw Exception('Importer가 읽을 수 없는 XLSX 형식입니다.');
    }

    _sheet = sheet;
    _colMap.clear();

    final headerRow = _sheet.row(1);
    for (final colInfo
        in headerRow.where((e) => e?.value != null).map((e) => ColumnInfo(
              colIndex: e!.columnIndex,
              colName: e.value.toString(),
            ))) {
      _colMap[colInfo.colName] = colInfo.colIndex;
    }
  }

  static bool looksLikeSamsungExcel(Excel excel) {
    final sheet = _firstSheet(excel);
    return sheet != null && looksLikeSamsungSheet(sheet);
  }

  static bool looksLikeSamsungSheet(Sheet sheet) {
    if (sheet.maxRows < 2) {
      return false;
    }

    final headerValues = sheet
        .row(1)
        .where((e) => e?.value != null)
        .map((e) => e!.value.toString())
        .toSet();

    return requiredColumns.every(headerValues.contains);
  }

  static Sheet? _firstSheet(Excel excel) {
    if (excel.tables.isEmpty) {
      return null;
    }
    return excel.tables.values.first;
  }

  String? rowToDebugString(List<Data?> row) {
    var rowIndex = row[0]?.rowIndex;
    if (rowIndex != null) {
      rowIndex++; // 0-based이므로 1 증가시켜서 보여주자.
    }
    return '${rowIndex ?? '?'}행 ${getColStr(row, colDateTime)} / ${getColStr(row, colTransactionType)} / 거래수량: ${getColStr(row, colCount)} / ${getColStr(row, colItemName)}';
  }

  Future<int> execute(
    int accountId,
    StockTxtLoader stockTxtLoader, {
    required Future<void> Function(
      double progress,
      Transaction transaction,
    ) onNewTransaction,
    required Future<void> Function(
      double progress,
      DateTime dateTime,
      String stockId,
      int splitFactor,
    ) onSplitStock,
    required Future<void> Function(
      double progress,
      DateTime dateTime,
      String stockId,
      int mergeFactor,
    ) onMergeStock,
    required Future<void> Function(
      double progress,
      DateTime dateTime,
      String stockId,
      int count,
    ) onTransferStock,
  }) async {
    final missingStockIdNames = <String>{};

    final maxRows = _sheet.maxRows;

    var insertedCount = 0;

    const rowOffset = 2;

    // 처음 두 행은 거래 내역이 아니다.
    var rows = _sheet.rows.sublist(rowOffset);

    // 엑셀 파일은 과거 거래가 먼저 나올 수도, 최신 거래가 먼저 나올 수도 있다.
    // 처리를 편리하게 하기 위해 과거 거래가 먼저 나오도록 정렬한다.
    // 아울러, 일별로 '매도'항목은 항상 맨 뒤에 나오도록 한다.
    // 하루에 같은 종목을 매수, 매도 모두 한 경우 엑셀 파일에는
    // 매수, 매도 순서가 시간상 뒤바뀌어 기록되어 있는 경우도 있기 때문이다.
    // 기본 sort() 함수는 stable하지 않기 때문에 stable한 mergeSort를 쓴다.

    mergeSort(rows, compare: (a, b) {
      final dateA = getColStr(a, colDateTime)!;
      final dateB = getColStr(b, colDateTime)!;
      final dateComp = dateA.compareTo(dateB);
      if (dateComp != 0) {
        return dateComp;
      } else {
        final typeA =
            transactionTypeToOrderValue(getColStr(a, colTransactionType)!);
        final typeB =
            transactionTypeToOrderValue(getColStr(b, colTransactionType)!);
        final typeComp = typeA - typeB;
        if (typeComp != 0) {
          return typeComp;
        } else {
          final itemNameA = getColStr(a, colItemName)!;
          final itemNameB = getColStr(b, colItemName)!;
          return itemNameA.compareTo(itemNameB);
        }
      }
    });

    //final rowsIterator = firstRowDateTimeStr!.compareTo(lastRowDateTimeStr!) < 0 ? rows : rows.reversed;
    final rowsList = rows.toList();

    for (var i = 0; i < rowsList.length; i++) {
      final row = rowsList[i];

      final dateTimeStr = getColStr(row, colDateTime);

      final transactionType = getColStr(row, colTransactionType);
      final stockName = getColStr(row, colItemName);
      final price = getColStr(row, colPrice);
      final count = getColStr(row, colCount);
      final accumCount = getColStr(row, colAccum);

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

      // 현금과 관련된 것은 모두 무시한다. 거래명이 '입금'으로 끝나는 것들이다.
      final ignoredTransactionTypes = [
        '이체입금',
        '이용료입금',
        '대체입금',
        '오픈이체입금',
        '배당금입금',
        '단수주입금',
      ];
      // RP 상품 무시
      final ignoredStockNames = [
        'USD 외화수시RP',
        'USD 외화약정RP',
      ];

      final stockId = stockTxtLoader.nameToId[stockName];
      if (stockId == null) {
        missingStockIdNames.add(stockName);
      }

      // 크래프톤 특별 처리
      if (stockName == '크래프톤' && dateTimeStr.compareTo('2021-07-28') < 0) {
        continue;
      } else if (stockName == '크래프톤' && transactionType == '타사입고') {
        await onNewTransaction(
          i / maxRows,
          Transaction(
            stockId: stockId ?? stockName,
            price: 498000,
            count: int.parse(accumCount.replaceAll(',', '')),
            transactionType: TransactionType.buy,
            dateTime: dateTime,
            accountId: accountId,
          ),
        );
        insertedCount++;
        continue;
      }

      if (ignoredStockNames.contains(stockName)) {
        // 무시해도 되는 colItemName
      } else if (transactionType == '매수' ||
              transactionType == '매수_NXT' ||
              transactionType == '매도' ||
              transactionType == '매도_NXT' ||
              transactionType.endsWith('주식매수') ||
              transactionType.endsWith('주식매도') ||
              transactionType == '액면분할출고' || // 액면분할입고를 연이어 처리
              transactionType == '액면병합출고' || // 액면병합입고를 연이어 처리
              transactionType == '타사출고' ||
              transactionType == '타사입고' ||
              transactionType == '무상입고' ||
              transactionType == '신주인수권입고' ||
              transactionType == '신주인수권출고' ||
              transactionType == '감자출고' // 감자입고를 연이어 처리
          ) {
        final currencyCode = getColStr(row, colCurrencyCode);

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
          if (stockName != getColStr(nextRow, colItemName) ||
              '액면분할입고' != getColStr(nextRow, colTransactionType)) {
            throw Exception('inconsistent data 1a: ${rowToDebugString(row)}');
          }

          final nextCount = getColStr(nextRow, colCount);
          final nextCountInt =
              int.tryParse(nextCount.toString().replaceAll(',', '')) ?? 0;

          await onSplitStock(i / maxRows, dateTime, stockId ?? stockName,
              (nextCountInt / countInt).round());

          i++; // 다음 행 건너뛰기

          insertedCount++;
          insertedCount++;
        } else if (transactionType == '액면병합출고') {
          // 출고 후 입고를 전량 매도 후 전량 매수로 처리한다. (이익 0)
          final nextRow = rowsList[i + 1];
          if (stockName != getColStr(nextRow, colItemName) ||
              '액면병합입고' != getColStr(nextRow, colTransactionType)) {
            throw Exception('inconsistent data 1b: ${rowToDebugString(row)}');
          }

          final nextCount = getColStr(nextRow, colCount);
          final nextCountInt =
              int.tryParse(nextCount.toString().replaceAll(',', '')) ?? 0;

          await onMergeStock(i / maxRows, dateTime, stockId ?? stockName,
              (countInt / nextCountInt).floor());

          i++; // 다음 행 건너뛰기

          insertedCount++;
          insertedCount++;
        } else if (transactionType == '감자출고') {
          // 출고 후 입고를 전량 매도 후 전량 매수로 처리한다. (이익 0)
          final nextRow = rowsList[i + 1];
          if (stockName != getColStr(nextRow, colItemName) ||
              '감자입고' != getColStr(nextRow, colTransactionType)) {
            throw Exception('inconsistent data 1c: ${rowToDebugString(row)}');
          }

          final nextCount = getColStr(nextRow, colCount);
          final nextCountInt =
              int.tryParse(nextCount.toString().replaceAll(',', '')) ?? 0;

          // 감자도 병합으로 친다.
          await onMergeStock(i / maxRows, dateTime, stockId ?? stockName,
              (countInt / nextCountInt).floor());

          i++; // 다음 행 건너뛰기

          insertedCount++;
          insertedCount++;
        } else if (transactionType == '매수' ||
            transactionType == '매수_NXT' ||
            transactionType.endsWith('주식매수') ||
            transactionType == '매도' ||
            transactionType == '매도_NXT' ||
            transactionType.endsWith('주식매도')) {
          await onNewTransaction(
            i / maxRows,
            Transaction(
              stockId: stockId ?? stockName,
              price: priceInt,
              count: countInt,
              transactionType: (transactionType == '매수' ||
                      transactionType == '매수_NXT' ||
                      transactionType.endsWith('주식매수'))
                  ? TransactionType.buy
                  : TransactionType.sell,
              dateTime: dateTime,
              accountId: accountId,
            ),
          );
          insertedCount++;
        } else if (transactionType == '타사입고' ||
            transactionType == '무상입고' ||
            transactionType == '신주인수권입고') {
          await onTransferStock(
              i / maxRows, dateTime, stockId ?? stockName, countInt);
          insertedCount++;
        } else if (transactionType == '타사출고' || transactionType == '신주인수권출고') {
          await onTransferStock(
              i / maxRows, dateTime, stockId ?? stockName, -countInt);
          insertedCount++;
        } else {
          if (kDebugMode) {
            print('Unhandled type of transaction a: ${rowToDebugString(row)}');
          }
        }
      } else if (transactionType == '액면분할입고') {
        // 액면분할입고는 반드시 액면분할출고가 처리될 때 같이 처리되었어야 했다...
        // 여기에 왔다면 엑셀 파일 이상한 것이다.
        throw Exception('inconsistent data 2a: ${rowToDebugString(row)}');
      } else if (transactionType == '액면병합입고') {
        // 액면병합입고는 반드시 액면병합출고가 처리될 때 같이 처리되었어야 했다...
        // 여기에 왔다면 엑셀 파일 이상한 것이다.
        throw Exception('inconsistent data 2b: ${rowToDebugString(row)}');
      } else if (ignoredTransactionTypes.contains(transactionType)) {
        // 무시해도 되는 '거래명'
      } else {
        if (kDebugMode) {
          print('Unhandled type of transaction b: ${rowToDebugString(row)}');
        }
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
