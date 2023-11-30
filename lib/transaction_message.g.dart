// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionMessage _$TransactionMessageFromJson(Map<String, dynamic> json) =>
    TransactionMessage(
      json['senderId'] as String,
      $enumDecode(_$TransactionMessageTypeEnumMap, json['messageType']),
      json['payload'],
    );

Map<String, dynamic> _$TransactionMessageToJson(TransactionMessage instance) =>
    <String, dynamic>{
      'senderId': instance.senderId,
      'messageType': _$TransactionMessageTypeEnumMap[instance.messageType]!,
      'payload': instance.payload,
    };

const _$TransactionMessageTypeEnumMap = {
  TransactionMessageType.addTransaction: 0,
  TransactionMessageType.removeTransaction: 1,
  TransactionMessageType.updateTransaction: 2,
  TransactionMessageType.requestSync: 3,
  TransactionMessageType.sync: 4,
};
