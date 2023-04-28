import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lonely_flutter/number_format_util.dart';
import 'item_widget.dart';

final krExp = RegExp(r'^[0-9]{6}$');

const fracMultiplier = 10000;

// 사용자가 입력한 값을 저장 상태로 변환
// KR: "12345" -> 12345
// EN: "12345" -> 123450000
int priceInputToData(String stockId, String priceStr) {
  return (krExp.hasMatch(stockId)
          ? int.tryParse(priceStr)
          : ((double.tryParse(priceStr) ?? 0) * fracMultiplier).round()) ??
      0;
}

// 앞에 $ 기호를 붙인다.
// 음수 부호하고 같이 있으면 음수 부호가 우선한다.
// "1,000" -> "$1,000"
// "-1" -> "-$1"
String prependCurrencySymbol(String symbol, String priceStr) {
  if (symbol.isEmpty) {
    return priceStr;
  }

  if (priceStr.isEmpty) {
    return priceStr;
  }

  if (priceStr[0] == '-') {
    return '-$symbol${priceStr.substring(1)}';
  } else {
    return '$symbol$priceStr';
  }
}

// 저장 상태의 값을 보기 예쁜 문자열로 변환
// KR: 123456789 -> "123,456,789"
// EN: 123456789 -> "$12,345.6789"
String priceDataToDisplay(String stockId, int price) {
  final isKr = krExp.hasMatch(stockId);
  return prependCurrencySymbol(isKr == false ? '\$' : '',
      formatThousandsStr(priceDataToInput(stockId, price)));
}

// 저장 상태의 값을 입력(편집)하기 편한 문자열로 변환
// KR: 123456789 -> "123456789"
// EN: 123456789 -> "12345.6789"
String priceDataToInput(String stockId, int price) {
  final isKr = krExp.hasMatch(stockId);
  return isKr ? price.toString() : (price / fracMultiplier).toString();
}

// 저장 상태의 값을 보기 예쁜 문자열로 변환하되, 달러면 소수점 둘째자리까지
// (보유하고 있는 평가금액 나타낼 때 씀)
// KR: 12345.6789 -> "12,346"
// EN: 12345.6789 -> "$1.23"
String priceDataToDisplayTruncated(String stockId, double price) {
  final isKr = krExp.hasMatch(stockId);
  final priceRealScale = priceDataToRealScale(stockId, price);
  return prependCurrencySymbol(isKr == false ? '\$' : '',
      formatThousandsStr(priceRealScale.toStringAsFixed(isKr ? 0 : 2)));
}

// 저장 상태의 가격 값을 실제 가격으로 변환
// KR: 12345.6789 -> 12345.6789
// EN: 12345.6789 -> 1.23456789
double priceDataToRealScale(String stockId, double price) {
  return krExp.hasMatch(stockId) ? price : (price / fracMultiplier);
}

Future<KrStock?> fetchStockInfo(String stockId) async {
  if (krExp.hasMatch(stockId)) {
    return Random().nextInt(2) == 0
        ? _fetchKrStockD(stockId)
        : _fetchKrStockN(stockId);
  } else {
    return _fetchKrStockY(stockId);
  }
}

Future<KrStock?> _fetchKrStockN(String stockId) async {
  if (stockId.length != 6) {
    return null;
  }

  try {
    final response = await http
        .get(Uri.parse('https://m.stock.naver.com/api/stock/$stockId/basic'));
    if (response.statusCode == 200) {
      return KrStock.fromJsonN(jsonDecode(response.body));
    } else if ((response.statusCode == 409)) {
      return null;
    } else {
      throw Exception('failed to http get');
    }
  } on SocketException catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  } on http.ClientException catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  }
}

Future<KrStock?> _fetchKrStockY(String stockId) async {
  if (stockId.isEmpty) {
    return null;
  }

  try {
    final response = await http.get(
      Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$stockId?interval=3mo'),
    );
    if (response.statusCode == 200) {
      return KrStock.fromJsonY(jsonDecode(response.body));
    } else if ((response.statusCode == 409)) {
      // Conflict
      return null;
    } else if ((response.statusCode == 502)) {
      // Bad Gateway
      return null;
    } else {
      throw Exception('failed to http get');
    }
  } on SocketException catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  } on http.ClientException catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  } on Exception catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  }
}

Future<KrStock?> _fetchKrStockD(String stockId) async {
  // "000000" ~ "999999"
  if (stockId.length != 6) {
    return null;
  }

  try {
    final response = await http.get(
        Uri.parse(
            'https://finance.daum.net/api/quotes/A$stockId?changeStatistics=true&chartSlideImage=true&isMobile=true'),
        headers: {
          'referer': 'https://m.finance.daum.net/',
        });
    if (response.statusCode == 200) {
      return KrStock.fromJsonD(jsonDecode(response.body));
    } else if ((response.statusCode == 409)) {
      // Conflict
      return null;
    } else if ((response.statusCode == 502)) {
      // Bad Gateway
      return null;
    } else {
      throw Exception('failed to http get');
    }
  } on SocketException catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  } on http.ClientException catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  }
}
