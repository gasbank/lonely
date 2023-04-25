enum TransactionType {
  buy,
  sell,
}

class Transaction {
  Transaction(
      {required this.stockId,
        required this.price,
        required this.count,
        required this.transactionType,
        required this.dateTime,
        required this.accountId});

  Transaction.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    stockId = map['stockId'];
    price = map['price'];
    count = map['count'];
    transactionType = map['transactionType'] == 0
        ? TransactionType.buy
        : TransactionType.sell;
    dateTime = DateTime.parse(map['dateTime']);
    earn = map['earn'];
    accountId = map['accountId'];
  }

  int? id;
  late final String stockId;
  late final int price;
  late final int count;
  late final TransactionType transactionType;
  late final DateTime dateTime;
  int? earn;
  int? accountId;

  Map<String, dynamic> toMap() {
    return {
      'stockId': stockId,
      'price': price,
      'count': count,
      'transactionType': transactionType == TransactionType.buy
          ? 0
          : transactionType == TransactionType.sell
          ? 1
          : -1,
      'dateTime': dateTime.toIso8601String(),
      'earn': earn,
      'accountId': accountId,
    };
  }
}
