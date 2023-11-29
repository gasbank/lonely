// 이 파일 내용이 바뀌면 아래 명령어 실행해서 자동 생성하는 코드도 갱신시켜야 한다.
// dart run build_runner build --delete-conflicting-outputs
import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

// DB에 기록되는 값이라 순서 바뀌어서는 안된다.
enum TransactionType {
  @JsonValue(0) buy, // 매수
  @JsonValue(1) sell, // 매도
  @JsonValue(2) splitIn, // 액면분할입고 (출고와 쌍 이루어야 한다.)
  @JsonValue(3) splitOut, // 액면분할출고 (입고와 쌍 이루어야 한다.)
  @JsonValue(4) transferIn, // 타사출고
  @JsonValue(5) transferOut, // 타사출고
}

const transactionTypeIn = <TransactionType>{
  TransactionType.buy,
  TransactionType.splitIn,
  TransactionType.transferIn,
};

const transactionTypeOut = <TransactionType>{
  TransactionType.sell,
  TransactionType.splitOut,
  TransactionType.transferOut,
};

@JsonSerializable(includeIfNull: false)
class Transaction {
  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  int? id;
  late final String stockId;
  late final int price;
  late final int count;
  late final TransactionType transactionType;
  late final DateTime dateTime;
  int? earn;
  int? accountId;

  Transaction({
    required this.stockId,
    required this.price,
    required this.count,
    required this.transactionType,
    required this.dateTime,
    required this.accountId,
  });

  Transaction.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    stockId = map['stockId'];
    price = map['price'];
    count = map['count'];
    transactionType = TransactionType.values[map['transactionType']];
    dateTime = DateTime.parse(map['dateTime']);
    earn = map['earn'];
    accountId = map['accountId'];
  }

  Map<String, dynamic> toMap() {
    return {
      'stockId': stockId,
      'price': price,
      'count': count,
      'transactionType': transactionType.index,
      'dateTime': dateTime.toIso8601String(),
      'earn': earn,
      'accountId': accountId,
    };
  }
}
