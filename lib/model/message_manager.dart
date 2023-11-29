import 'dart:io';

import 'package:dart_amqp/dart_amqp.dart';
import 'package:flutter/foundation.dart';

class MessageManager {
  final Client _client = Client(
    settings: ConnectionSettings(
      host: Platform.isAndroid ? '10.0.2.2' : 'localhost',
      virtualHost: '/',
    ),
  );
  late final Channel _channel;
  late final Exchange _actionExchange;

  bool _init = false;

  Future<void> init() async {
    if (_init) {
      return;
    }

    _init = true;

    _channel = await _client.channel();

    _actionExchange = await _channel.exchange('action', ExchangeType.FANOUT);
    final actionConsumer = await _actionExchange.bindPrivateQueueConsumer(null);
    actionConsumer.listen((message) {
      if (kDebugMode) {
        print(
            " [x] Received string from action exchange: ${message.payloadAsString}");
      }
    });
  }

  void publish(String message) {
    _actionExchange.publish(message, null);
  }
}
