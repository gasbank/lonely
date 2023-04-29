import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely/excel_importer.dart';
import 'package:lonely/inventory_widget.dart';
import 'package:lonely/new_transaction_widget.dart';
import 'database.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'lonely_model.dart';

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Consumer<LonelyModel>(
        builder: (context, model, child) {
          return ListView(children: [
            OutlinedButton(
              onPressed: () async {
                Share.shareXFiles([XFile(await getDbPath())]);
              },
              child: const Text('매매 기록 내보내기'),
            ),
            OutlinedButton(
              onPressed: () async {
                final result = await FilePicker.platform
                    .pickFiles(allowedExtensions: ['db']);

                if (result != null) {
                  final file = File(result.files.single.path!);
                  if (kDebugMode) {
                    print(file.path);
                  }
                  await model.closeAndReplaceDatabase(file);
                } else {
                  // User canceled the picker
                }
              },
              child: const Text('매매 기록 불러오기'),
            ),
            OutlinedButton(
              onPressed: () async {
                final result = await FilePicker.platform
                    .pickFiles(allowedExtensions: ['xlsx']);

                if (result != null) {
                  final file = File(result.files.single.path!);
                  if (kDebugMode) {
                    print(file.path);
                  }

                  const accountId = 1;
                  final importer = Importer();
                  await importer.loadSheet(file);
                  await importer.execute(
                    accountId,
                    model.stockTxtLoader,
                    (transaction) async {
                      await registerNewTransaction(
                          transaction, model, (_) {}, true);
                    },
                    (stockId, accountId, splitFactor) async {
                      final itemMap =
                          createItemMap(model.transactions, model.stocks);
                      final item = itemMap[stockId];
                      if (item == null) return;

                      await splitStock(
                          item, accountId, model, splitFactor, true);
                    },
                  );
                } else {
                  // User canceled the picker
                }
              },
              child: const Text('삼성증권 XLSX 불러오기'),
            ),
            OutlinedButton(
              onPressed: () async {
                await model.closeAndReplaceDatabase(null);
              },
              child: const Text('DB 초기화'),
            ),
          ]);
        },
      ),
    );
  }
}
