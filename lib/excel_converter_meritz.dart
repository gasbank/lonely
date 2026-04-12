import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

import 'excel_importer.dart';

// 메리츠증권의 '거래내역' 엑셀 파일을 삼성증권 거래내역 엑셀 파일 포맷으로 바꿔서
// 삼성증권과 동일한 코드로 불러와지도록 한다.
class ConverterMeritz {
  Future<void> loadSheet(File file) async {
    var bytes = await file.readAsBytes();
    var excel = Excel.decodeBytes(bytes);

    var dateRegExp = RegExp(r'\d{4}.\d{2}.\d{2}');

    for (var sheetName in excel.tables.keys) {
      //print(sheetName);
      final sheet = excel.tables[sheetName]!;

      final colConvertMap = <String, String>{
        '거래일자': Importer.colDateTime,
        '거래적요': Importer.colTransactionType,
        '수량': Importer.colCount,
        '통화구분': Importer.colCurrencyCode,
        '종목명': Importer.colItemName,
        '단가': Importer.colPrice,
        '유가증권잔고': Importer.colAccum,
      };

      final convertedExcel = Excel.createExcel();
      final convertedSheet = convertedExcel.sheets[convertedExcel.getDefaultSheet()];

      for (final row in sheet.rows) {
        final dateTime = row[1]?.value.toString() ?? "";
        if (dateRegExp.hasMatch(dateTime)) {
            if (kDebugMode) {
              print(dateTime);
            }
          }
      }

      break;
    }
  }
}