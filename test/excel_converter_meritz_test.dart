import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonely/excel_converter_meritz.dart';
import 'package:lonely/excel_importer.dart';

void main() {
  group('Importer format detection', () {
    test('detects Samsung workbook', () {
      final excel = _createSamsungWorkbook();

      expect(Importer.looksLikeSamsungExcel(excel), isTrue);
      expect(ConverterMeritz.looksLikeMeritzExcel(excel), isFalse);
    });
  });

  group('Meritz converter', () {
    test('detects Meritz workbook and converts stock rows only', () {
      final excel = _createMeritzWorkbook();

      expect(ConverterMeritz.looksLikeMeritzExcel(excel), isTrue);
      expect(Importer.looksLikeSamsungExcel(excel), isFalse);

      final converted = ConverterMeritz.convert(excel);
      final sheet = converted.tables.values.first;

      expect(Importer.looksLikeSamsungExcel(converted), isTrue);
      expect(sheet.row(0)[0]?.value.toString(), '');
      expect(
        _rowValues(sheet.row(1)),
        Importer.requiredColumns,
      );
      expect(
        _rowValues(sheet.row(2)),
        [
          '2025-03-10T00:00:00.000Z',
          '매수',
          '3',
          'KRW',
          '삼성전자',
          '70000',
          '3',
        ],
      );
      expect(
        _rowValues(sheet.row(3)),
        [
          '2025-03-11',
          '매도',
          '1',
          'USD',
          'Tesla',
          '250.5',
          '2',
        ],
      );
      expect(sheet.maxRows, 4);
    });
  });
}

Excel _createSamsungWorkbook() {
  final excel = Excel.createExcel();
  final sheet = excel[excel.getDefaultSheet()!];

  sheet.appendRow([const TextCellValue('')]);
  sheet.appendRow(
    Importer.requiredColumns.map((e) => TextCellValue(e)).toList(),
  );
  sheet.appendRow([
    const TextCellValue('2025-03-10'),
    const TextCellValue('매수'),
    const TextCellValue('3'),
    const TextCellValue('KRW'),
    const TextCellValue('삼성전자'),
    const TextCellValue('70000'),
    const TextCellValue('3'),
  ]);

  return excel;
}

Excel _createMeritzWorkbook() {
  final excel = Excel.createExcel();
  final sheet = excel[excel.getDefaultSheet()!];

  sheet.appendRow(_sparseRow({
    1: const TextCellValue('조회부서 :'),
    22: const TextCellValue('디지털센터'),
  }));
  sheet.appendRow(_sparseRow({
    7: const TextCellValue('Super365 거래내역'),
  }));
  sheet.appendRow(_sparseRow({
    1: const TextCellValue('계좌번호 :'),
    3: const TextCellValue('111'),
  }));
  sheet.appendRow(_sparseRow({
    1: const TextCellValue('거래일자 :'),
    3: const TextCellValue('2024.04.12 ~ 2026.04.12'),
  }));
  sheet.appendRow(_meritzUpperHeaderRow());
  sheet.appendRow(_meritzLowerHeaderRow());

  // 환전 행은 유가증권잔고가 없어서 건너뛴다.
  sheet.appendRow(_sparseRow({
    1: const DateCellValue(year: 2025, month: 3, day: 9),
    4: const TextCellValue('환전외화매수(자체)'),
    25: const TextCellValue('USD'),
  }));
  sheet.appendRow(_sparseRow({
    4: const TextCellValue('USD'),
    5: const TextCellValue('미국 달러'),
    11: const TextCellValue('145725'),
  }));

  sheet.appendRow(_sparseRow({
    1: const DateCellValue(year: 2025, month: 3, day: 10),
    4: const TextCellValue('매수'),
    8: const IntCellValue(3),
    25: const TextCellValue('KRW'),
  }));
  sheet.appendRow(_sparseRow({
    4: const TextCellValue('005930'),
    5: const TextCellValue('삼성전자'),
    8: const IntCellValue(70000),
    17: const IntCellValue(3),
  }));

  sheet.appendRow(_sparseRow({
    0: const TextCellValue('조회정보 :'),
    2: const TextCellValue('15:41:19(219022)'),
  }));
  sheet.appendRow(_sparseRow({
    13: const TextCellValue('1 / 2'),
  }));

  sheet.appendRow(_meritzUpperHeaderRow());
  sheet.appendRow(_meritzLowerHeaderRow());
  sheet.appendRow(_sparseRow({
    1: const TextCellValue('2025.03.11'),
    4: const TextCellValue('매도'),
    8: const IntCellValue(1),
    25: const TextCellValue('USD'),
  }));
  sheet.appendRow(_sparseRow({
    4: const TextCellValue('TSLA'),
    5: const TextCellValue('Tesla'),
    8: const DoubleCellValue(250.5),
    17: const IntCellValue(2),
  }));

  return excel;
}

List<CellValue?> _meritzUpperHeaderRow() {
  return _sparseRow({
    1: const TextCellValue('거래일자'),
    4: const TextCellValue('거래적요'),
    8: const TextCellValue('수량'),
    25: const TextCellValue('통화구분'),
  });
}

List<CellValue?> _meritzLowerHeaderRow() {
  return _sparseRow({
    5: const TextCellValue('종목명'),
    8: const TextCellValue('단가'),
    17: const TextCellValue('유가증권잔고'),
  });
}

List<CellValue?> _sparseRow(Map<int, CellValue> cells) {
  const rowLength = 26;
  final row = List<CellValue?>.filled(rowLength, null, growable: false);
  for (final entry in cells.entries) {
    row[entry.key] = entry.value;
  }
  return row;
}

List<String?> _rowValues(List<Data?> row) {
  return row.map((cell) => cell?.value.toString()).toList();
}
