import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'item_widget.dart';

final krExp = RegExp(r'^[0-9]{6}$');

// $1.2345 <-> 12345
const fracMultiplier = 10000;

int priceInputToData(String stockId, String priceStr) {
  return (krExp.hasMatch(stockId)
          ? int.tryParse(priceStr)
          : ((double.tryParse(priceStr) ?? 0) * fracMultiplier).round()) ??
      0;
}

String priceDataToDisplay(String stockId, int price) {
  return krExp.hasMatch(stockId)
      ? price.toString()
      : (price / fracMultiplier).toString();
}

String priceDataToDisplayTruncated(String stockId, double price) {
  final isKr = krExp.hasMatch(stockId);
  final priceRealScale = krExp.hasMatch(stockId) ? price : (price / fracMultiplier);
  return priceRealScale.toStringAsFixed(isKr ? 0 : 2);
}

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
