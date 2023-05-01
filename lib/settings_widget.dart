import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database.dart';
import 'excel_importer.dart';
import 'inventory_widget.dart';
import 'item_widget.dart';
import 'new_transaction_widget.dart';
import 'lonely_model.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Consumer<LonelyModel>(
        builder: (context, model, child) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    OutlinedButton(
                      onPressed: () async => await onExportDatabase(),
                      child: const Text('매매 기록 내보내기'),
                    ),
                    OutlinedButton(
                      onPressed: () async => await onImportDatabase(model),
                      child: const Text('매매 기록 불러오기'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            const indicatorColor = Colors.white;
                            return Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: const [
                                    CircularProgressIndicator(
                                      color: indicatorColor,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        '삼성증권 XLSX 불러오는 중...',
                                        style: TextStyle(color: indicatorColor),
                                      ),
                                    ),
                                  ]),
                            );
                          },
                        );
                        onImportSsXlsx(model)
                            .then((value) => Navigator.pop(context));
                      },
                      child: const Text('삼성증권 XLSX 불러오기'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => onClearAllData(context, model),
                child: const Text(
                  '매매 기록 모두 삭제',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              const Spacer(),
              const Text(
                'v0.1.0',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void onClearAllData(BuildContext context, LonelyModel model) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('경고'),
              content: const Text('모든 매매 기록이 삭제되고, 초기 상태로 돌아갑니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context, 'OK');
                    await model.closeAndReplaceDatabase(null);
                    model.setEditingTransaction(null);
                  },
                  child: const Text('모두 삭제'),
                ),
              ],
            ),
        barrierDismissible: true);
  }

  Future<void> onImportSsXlsx(LonelyModel model) async {
    final result = await FilePicker.platform
        .pickFiles(allowedExtensions: ['xlsx'], type: FileType.custom);

    if (result != null) {
      final file = File(result.files.single.path!);
      if (kDebugMode) {
        print(file.path);
      }

      // XLSX 파일 하나 당 하나의 계좌인 것으로 가정
      const accountId = 1;

      final importer = Importer();

      await importer.loadSheet(file);

      await importer.execute(
        accountId,
        model.stockTxtLoader,
        (progress, transaction) async {
          await registerNewTransaction(transaction, model, (_) {}, true);
        },
        (progress, stockId, splitFactor) async {
          // 매 호출 시마다 model.transactions 바뀌기 때문에,
          // 더 넓은 범위에서 한번만 계산해선 안된다.
          final itemMapOnAccount = createItemMap(
              model.transactions.where((e) => e.accountId == accountId),
              model.stocks);

          final item = itemMapOnAccount[stockId];
          if (item == null) {
            //throw Exception('cannot split with null item');
            return;
          }

          final itemOnAccount = ItemOnAccount(item, accountId);

          await splitStock(itemOnAccount, model, splitFactor, true);
        },
        (progress, stockId, count) async {
          // 매 호출 시마다 model.transactions 바뀌기 때문에,
          // 더 넓은 범위에서 한번만 계산해선 안된다.

          final itemMapOnAccount = createItemMap(
              model.transactions.where((e) => e.accountId == accountId),
              model.stocks);

          final item = itemMapOnAccount[stockId];
          if (item == null) {
            //throw Exception('cannot transfer with null item');
            return;
          }

          final itemOnAccount = ItemOnAccount(item, accountId);

          await transferStock(itemOnAccount, count, model, true);
        },
      );
    } else {
      // User canceled the picker
    }
  }

  Future<void> onImportDatabase(LonelyModel model) async {
    final result = await FilePicker.platform
        .pickFiles(allowedExtensions: ['db'], type: FileType.custom);

    if (result != null) {
      final file = File(result.files.single.path!);
      if (kDebugMode) {
        print(file.path);
      }
      await model.closeAndReplaceDatabase(file);
    } else {
      // User canceled the picker
    }
  }

  Future<void> onExportDatabase() async {
    Share.shareXFiles([XFile(await getDbPath())]);
  }
}
