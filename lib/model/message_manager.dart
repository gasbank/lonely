import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_amqp/dart_amqp.dart';
import 'package:flutter/foundation.dart';
import 'package:lonely/database.dart';
import 'package:lonely/model/lonely_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ulid/ulid.dart';

import '../transaction.dart';
import '../transaction_message.dart';

class MessageManager {
  late final Client _client;
  late final Channel _channel;
  late final Exchange _singleExchange;
  Exchange? _actionExchange;
  late final Consumer _singleConsumer;
  late final Consumer _actionConsumer;

  bool _init = false;
  Completer<bool>? _syncDbCompleter;

  String get privateQueueName => instanceId;

  late final String instanceId;

  Future<void> init(LonelyModel model) async {
    if (_init) {
      return;
    }

    _init = true;

    instanceId = Ulid().toCanonical();

    // String.fromEnvironment 호출은 반드시 const가 붙어야만 제대로 작동한다. (ㄷㄷ)
    const mqHost = String.fromEnvironment('MQ_HOST');
    final mqPort = int.parse(
        const String.fromEnvironment('MQ_PORT', defaultValue: '5672'));

    final settings = ConnectionSettings(
      host: mqHost.isNotEmpty
          ? mqHost
          : Platform.isAndroid
              ? '10.0.2.2'
              : 'localhost',
      port: mqPort,
      authProvider: const PlainAuthenticator(
        String.fromEnvironment('MQ_USERNAME', defaultValue: 'guest'),
        String.fromEnvironment('MQ_PASSWORD', defaultValue: 'guest'),
      ),
      tlsContext: mqPort == 5671 ? SecurityContext.defaultContext : null,
      virtualHost:
          const String.fromEnvironment('MQ_VIRTUAL_HOST', defaultValue: '/'),
      onBadCertificate: (cert) {
        if (kDebugMode) {
          print(cert);
        }
        return false;
      },
    );

    _client = Client(settings: settings)
      ..errorListener((error) {
        if (kDebugMode) {
          print(error);
        }
      });

    await _client.connect();

    _channel = await _client.channel();

    _singleExchange = await _channel.exchange('single', ExchangeType.DIRECT);
    _singleConsumer =
        await _singleExchange.bindPrivateQueueConsumer([instanceId]);
    _singleConsumer.listen((message) {
      if (message.properties?.contentType == 'db') {
        importFromPayload(model, message.payload!);
        return;
      }
    });

    _actionExchange = await _channel.exchange('action', ExchangeType.FANOUT);
    _actionConsumer = await _actionExchange!.bindPrivateQueueConsumer(null);
    _actionConsumer.listen((message) {
      final msg =
          TransactionMessage.fromJson(jsonDecode(message.payloadAsString));
      if (kDebugMode) {
        print("Received from action exchange: ${message.payloadAsString}");
        //print(msg);
      }

      // 내가 일으킨 메시지에 대해서는 내가 처리할 필요가 없다.
      if (msg.senderId == privateQueueName) {
        return;
      }

      switch (msg.messageType) {
        case TransactionMessageType.addTransaction:
          model.addTransaction(Transaction.fromJson(msg.payload));
          break;
        case TransactionMessageType.removeTransaction:
          model.removeTransaction(List<int>.from(msg.payload));
          break;
        case TransactionMessageType.updateTransaction:
          final payloadMap = msg.payload as Map<String, dynamic>;
          model.updateTransaction(
            payloadMap['id'],
            Transaction.fromJson(payloadMap['transaction']),
          );
        case TransactionMessageType.requestSync:
          model.queueShowRequestSyncPopup(msg.senderId);
          break;
        case TransactionMessageType.sync:
          throw Exception('unexpected message type');
      }
    });
  }

  void publish(String message) {
    _actionExchange?.publish(message, null);
  }

  void sendDatabaseTo(String requesterId) async {
    final bytes = await File(await getDbPath()).readAsBytes();
    _singleExchange.publish(bytes, requesterId,
        properties: MessageProperties()..contentType = 'db');
  }

  void importFromPayload(LonelyModel model, Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();

    final tempPath = p.join(tempDir.path, 'lonely.db');

    final newDb = await File(tempPath).create();
    await newDb.writeAsBytes(bytes);

    await model.closeAndReplaceDatabase(newDb);

    _syncDbCompleter?.complete(true);
  }

  Future<bool> waitForDbSync() async {
    _syncDbCompleter = Completer();

    return _syncDbCompleter!.future;
  }

  void cancelWaitForDbSync() {
    _syncDbCompleter?.complete(false);
  }
}
