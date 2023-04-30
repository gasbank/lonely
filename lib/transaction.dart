// DB에 기록되는 값이라 순서 바뀌어서는 안된다.
enum TransactionType {
  buy, // 매수
  sell, // 매도
  splitIn, // 액면분할입고 (출고와 쌍 이루어야 한다.)
  splitOut, // 액면분할출고 (입고와 쌍 이루어야 한다.)
  transferIn, // 타사출고
  transferOut, // 타사출고
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

class Transaction {
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
