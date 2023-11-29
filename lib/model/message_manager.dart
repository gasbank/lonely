import 'dart:convert';
import 'dart:io';

import 'package:dart_amqp/dart_amqp.dart';
import 'package:flutter/foundation.dart';
import 'package:lonely/model/lonely_model.dart';

import '../transaction.dart';
import '../transaction_message.dart';

class MessageManager {
  final Client _client = Client(
    settings: ConnectionSettings(
      host: Platform.isAndroid ? '10.0.2.2' : 'localhost',
      virtualHost: '/',
    ),
  );
  late final Channel _channel;
  late final Exchange _actionExchange;
  late final Consumer _actionConsumer;

  bool _init = false;

  String get actionConsumerQueueName => _actionConsumer.queue.name;

  Future<void> init(LonelyModel lonelyModel) async {
    if (_init) {
      return;
    }

    _init = true;

    _channel = await _client.channel();

    _actionExchange = await _channel.exchange('action', ExchangeType.FANOUT);
    _actionConsumer = await _actionExchange.bindPrivateQueueConsumer(null);
    _actionConsumer.listen((message) {
      final msg =
          TransactionMessage.fromJson(jsonDecode(message.payloadAsString));
      if (kDebugMode) {
        print("Received from action exchange: ${message.payloadAsString}");
        //print(msg);
      }

      // 내가 일으킨 메시지에 대해서는 내가 처리할 필요가 없다.
      if (msg.senderId == actionConsumerQueueName) {
        return;
      }

      switch (msg.messageType) {
        case TransactionMessageType.addTransaction:
          lonelyModel.addTransaction(
              Transaction.fromJson(msg.payload as Map<String, dynamic>));
          break;
        case TransactionMessageType.removeTransaction:
          lonelyModel
              .removeTransaction(List<int>.from(msg.payload as List<dynamic>));
          break;
        case TransactionMessageType.updateTransaction:
          final payloadMap = msg.payload as Map<String, dynamic>;
          lonelyModel.updateTransaction(
            payloadMap['id'],
            Transaction.fromJson(
                payloadMap['transaction'] as Map<String, dynamic>),
          );
      }
    });
  }

  void publish(String message) {
    _actionExchange.publish(message, null);
  }
}
