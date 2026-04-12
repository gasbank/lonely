import 'package:excel/excel.dart';

import 'excel_importer.dart';

// 메리츠증권의 2행 거래 내역 XLSX를 Importer가 읽는 포맷으로 변환한다.
class ConverterMeritz {
  static const _upperDate = '거래일자';
  static const _upperTransactionType = '거래적요';
  static const _upperCount = '수량';
  static const _upperCurrencyCode = '통화구분';

  static const _lowerItemName = '종목명';
  static const _lowerPrice = '단가';
  static const _lowerAccum = '유가증권잔고';

  static bool looksLikeMeritzExcel(Excel excel) {
    final sheet = _firstSheet(excel);
    if (sheet == null) {
      return false;
    }
    return _findHeader(sheet) != null;
  }

  static Excel convert(Excel excel) {
    final sheet = _firstSheet(excel);
    if (sheet == null) {
      throw Exception('빈 XLSX 파일입니다.');
    }

    final convertedExcel = Excel.createExcel();
    final defaultSheetName = convertedExcel.getDefaultSheet();
    if (defaultSheetName == null) {
      throw Exception('기본 시트를 만들 수 없습니다.');
    }
    final convertedSheet = convertedExcel[defaultSheetName];

    // Importer는 앞의 2행을 건너뛴다.
    convertedSheet.appendRow([const TextCellValue('')]);
    convertedSheet.appendRow(Importer.requiredColumns
        .map((e) => TextCellValue(e))
        .toList(growable: false));

    _MeritzHeader? currentHeader;

    for (var rowIndex = 0; rowIndex < sheet.maxRows - 1; rowIndex++) {
      final upperRow = sheet.row(rowIndex);
      final lowerRow = sheet.row(rowIndex + 1);

      final detectedHeader = _MeritzHeader.tryParse(upperRow, lowerRow);
      if (detectedHeader != null) {
        currentHeader = detectedHeader;
        rowIndex++;
        continue;
      }

      if (currentHeader == null ||
          !_isTransactionPair(upperRow, lowerRow, currentHeader)) {
        continue;
      }

      convertedSheet
          .appendRow(_buildImporterRow(upperRow, lowerRow, currentHeader));
      rowIndex++;
    }

    return convertedExcel;
  }

  static Sheet? _firstSheet(Excel excel) {
    if (excel.tables.isEmpty) {
      return null;
    }
    return excel.tables.values.first;
  }

  static _MeritzHeader? _findHeader(Sheet sheet) {
    for (var rowIndex = 0; rowIndex < sheet.maxRows - 1; rowIndex++) {
      final header =
          _MeritzHeader.tryParse(sheet.row(rowIndex), sheet.row(rowIndex + 1));
      if (header != null) {
        return header;
      }
    }
    return null;
  }

  static bool _isTransactionPair(
    List<Data?> upperRow,
    List<Data?> lowerRow,
    _MeritzHeader header,
  ) {
    final dateTime = _normalizeDateTime(_cellValue(upperRow, header.dateTime));
    final transactionType = _cellText(upperRow, header.transactionType);
    final itemName = _cellText(lowerRow, header.itemName);
    final accum = _cellText(lowerRow, header.accum);

    return dateTime != null &&
        transactionType != null &&
        itemName != null &&
        accum != null;
  }

  static List<CellValue?> _buildImporterRow(
    List<Data?> upperRow,
    List<Data?> lowerRow,
    _MeritzHeader header,
  ) {
    final dateTime =
        _normalizeDateTime(_cellValue(upperRow, header.dateTime)) ?? '';
    final transactionType = _cellText(upperRow, header.transactionType) ?? '';
    final count = _cellNumberText(upperRow, header.count) ?? '0';
    final currencyCode = _cellText(upperRow, header.currencyCode) ?? '';
    final itemName = _cellText(lowerRow, header.itemName) ?? '';
    final price = _cellNumberText(lowerRow, header.price) ?? '0';
    final accum = _cellNumberText(lowerRow, header.accum) ?? '0';

    return [
      TextCellValue(dateTime),
      TextCellValue(transactionType),
      TextCellValue(count),
      TextCellValue(currencyCode),
      TextCellValue(itemName),
      TextCellValue(price),
      TextCellValue(accum),
    ];
  }

  static String? _normalizeDateTime(CellValue? value) {
    if (value == null) {
      return null;
    }

    if (value is DateCellValue) {
      return value.asDateTimeUtc().toIso8601String();
    }
    if (value is DateTimeCellValue) {
      return value.asDateTimeUtc().toIso8601String();
    }

    final text = _normalizeCellText(value.toString());
    if (text == null) {
      return null;
    }

    final replaced = text.replaceAll('.', '-');
    if (DateTime.tryParse(replaced) != null) {
      return replaced;
    }

    return null;
  }

  static String? _normalizeNumberText(String? text) {
    final normalized = _normalizeCellText(text);
    if (normalized == null) {
      return null;
    }

    if (normalized.endsWith('.0')) {
      return normalized.substring(0, normalized.length - 2);
    }

    return normalized;
  }

  static String? _normalizeCellText(String? text) {
    if (text == null) {
      return null;
    }

    final normalized = text
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized.isEmpty ? null : normalized;
  }

  static CellValue? _cellValue(List<Data?> row, int columnIndex) {
    if (columnIndex >= row.length) {
      return null;
    }
    return row[columnIndex]?.value;
  }

  static String? _cellText(List<Data?> row, int columnIndex) {
    return _normalizeCellText(_cellValue(row, columnIndex)?.toString());
  }

  static String? _cellNumberText(List<Data?> row, int columnIndex) {
    return _normalizeNumberText(_cellValue(row, columnIndex)?.toString());
  }
}

class _MeritzHeader {
  final int dateTime;
  final int transactionType;
  final int count;
  final int currencyCode;
  final int itemName;
  final int price;
  final int accum;

  const _MeritzHeader({
    required this.dateTime,
    required this.transactionType,
    required this.count,
    required this.currencyCode,
    required this.itemName,
    required this.price,
    required this.accum,
  });

  static _MeritzHeader? tryParse(List<Data?> upperRow, List<Data?> lowerRow) {
    final upperHeaderMap = _toHeaderIndexMap(upperRow);
    final lowerHeaderMap = _toHeaderIndexMap(lowerRow);

    final dateTime = upperHeaderMap[ConverterMeritz._upperDate];
    final transactionType =
        upperHeaderMap[ConverterMeritz._upperTransactionType];
    final count = upperHeaderMap[ConverterMeritz._upperCount];
    final currencyCode = upperHeaderMap[ConverterMeritz._upperCurrencyCode];

    final itemName = lowerHeaderMap[ConverterMeritz._lowerItemName];
    final price = lowerHeaderMap[ConverterMeritz._lowerPrice];
    final accum = lowerHeaderMap[ConverterMeritz._lowerAccum];

    if (dateTime == null ||
        transactionType == null ||
        count == null ||
        currencyCode == null ||
        itemName == null ||
        price == null ||
        accum == null) {
      return null;
    }

    return _MeritzHeader(
      dateTime: dateTime,
      transactionType: transactionType,
      count: count,
      currencyCode: currencyCode,
      itemName: itemName,
      price: price,
      accum: accum,
    );
  }

  static Map<String, int> _toHeaderIndexMap(List<Data?> row) {
    final headerMap = <String, int>{};

    for (final cell in row.where((e) => e?.value != null)) {
      final normalized =
          ConverterMeritz._normalizeCellText(cell!.value.toString());
      if (normalized == null) {
        continue;
      }
      headerMap[normalized] = cell.columnIndex;
    }

    return headerMap;
  }
}
