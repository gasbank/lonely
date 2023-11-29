// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      stockId: json['stockId'] as String,
      price: json['price'] as int,
      count: json['count'] as int,
      transactionType:
          $enumDecode(_$TransactionTypeEnumMap, json['transactionType']),
      dateTime: DateTime.parse(json['dateTime'] as String),
      accountId: json['accountId'] as int?,
    )
      ..id = json['id'] as int?
      ..earn = json['earn'] as int?;

Map<String, dynamic> _$TransactionToJson(Transaction instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['stockId'] = instance.stockId;
  val['price'] = instance.price;
  val['count'] = instance.count;
  val['transactionType'] = _$TransactionTypeEnumMap[instance.transactionType]!;
  val['dateTime'] = instance.dateTime.toIso8601String();
  writeNotNull('earn', instance.earn);
  writeNotNull('accountId', instance.accountId);
  return val;
}

const _$TransactionTypeEnumMap = {
  TransactionType.buy: 0,
  TransactionType.sell: 1,
  TransactionType.splitIn: 2,
  TransactionType.splitOut: 3,
  TransactionType.transferIn: 4,
  TransactionType.transferOut: 5,
};
