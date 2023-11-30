import 'package:json_annotation/json_annotation.dart';

part 'transaction_message.g.dart';

enum TransactionMessageType {
  @JsonValue(0) addTransaction,
  @JsonValue(1) removeTransaction,
  @JsonValue(2) updateTransaction,
  @JsonValue(3) requestSync,
  @JsonValue(4) sync,
}

@JsonSerializable(explicitToJson: true)
class TransactionMessage {
  final String senderId;
  final TransactionMessageType messageType;
  final dynamic payload;

  TransactionMessage(this.senderId, this.messageType, this.payload);

  factory TransactionMessage.fromJson(Map<String, dynamic> json) => _$TransactionMessageFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionMessageToJson(this);
}