import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely/transaction_message.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database.dart';
import 'excel_importer.dart';
import 'inventory_widget.dart';
import 'item_widget.dart';
import 'model/package_model.dart';
import 'new_transaction_widget.dart';
import 'model/lonely_model.dart';

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
                    TextButton(
                      onPressed: () async => await onExportDatabase(),
                      child: const Text('매매 기록 내보내기'),
                    ),
                    TextButton(
                      onPressed: () async => await onImportDatabase(model),
                      child: const Text('매매 기록 불러오기'),
                    ),
                    TextButton(
                      onPressed: () => onImportSs(context, model),
                      child: const Text('삼성증권 XLSX 불러오기'),
                    ),
                    TextButton(
                      onPressed: () => onImportFromOtherDevice(context, model),
                      child: const Text('매매 기록 불러오기 (다른 기기에서)'),
                    ),
                    TextButton(
                      onPressed: () async =>
                          await onRemoveTransactionWhereNullAccountId(
                              context, model),
                      child: const Text(
                        '삭제된 계좌와 관련된 매매 기록 모두 삭제',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => onClearAllData(context, model),
                child: const Text(
                  '매매 기록 모두 삭제',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              const Spacer(),
              Consumer<PackageModel>(builder: (_, packageModel, __) {
                return Text(
                  '${packageModel.info.version} (${packageModel.info.buildNumber})',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void onImportSs(BuildContext context, LonelyModel model) {
    Function(String)? onSetState;
    const importAccountName = '삼성증권 XLSX';
    onImportSsXlsx(model, importAccountName, (progress) {
      if (onSetState != null) {
        onSetState!(
            '$importAccountName 불러오는 중... ${(100 * progress).toStringAsFixed(1)}%');
      }
    }).then((importedCount) {
      Navigator.pop(context);
      if (importedCount != null) {
        _showSimpleText('$importedCount개 매매 내역이 추가됐습니다.');
      }
    }, onError: (err) {
      if (onSetState != null) {
        if (err != null) {
          onSetState!(err.toString());
        } else {
          onSetState!('Unknown error A occurred.');
        }
      }
    }).catchError((err) {
      if (onSetState != null) {
        if (err != null) {
          onSetState!(err.toString());
        } else {
          onSetState!('Unknown error B occurred.');
        }
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String progressText = '삼성증권 XLSX 불러오는 중...';

        return StatefulBuilder(
          builder: (context, setState) {
            const indicatorColor = Colors.white;
            onSetState = (progress) {
              setState(() {
                progressText = progress;
              });
            };
            return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: indicatorColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        progressText,
                        style: const TextStyle(color: indicatorColor),
                      ),
                    ),
                  ]),
            );
          },
        );
      },
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

  void _showSimpleText(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  Future<int?> onImportSsXlsx(
    LonelyModel model,
    String importAccountName,
    Function(double progress) onProgress,
  ) async {
    // XLSX 파일 하나 당 하나의 계좌인 것으로 가정
    final accountId = await model.addAccount(importAccountName);
    if (accountId == null) {
      _showSimpleText('먼저 \'$importAccountName\' 계좌명을 변경하세요.');
      return null;
    }

    final result = await FilePicker.platform
        .pickFiles(allowedExtensions: ['xlsx'], type: FileType.custom);

    if (result != null) {
      final file = File(result.files.single.path!);
      if (kDebugMode) {
        print(file.path);
      }

      final importer = Importer();

      await importer.loadSheet(file);

      final insertedCount = await importer.execute(
        accountId,
        model.stockTxtLoader,
        (progress, transaction) async {
          await registerNewTransaction(transaction, model, (_) {}, true);
          onProgress(progress);
        },
        (progress, dateTime, stockId, splitFactor) async {
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

          await splitStock(dateTime, itemOnAccount, model, splitFactor, true);

          onProgress(progress);
        },
        (progress, dateTime, stockId, count) async {
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

          await transferStock(dateTime, itemOnAccount, count, model, true);

          onProgress(progress);
        },
      );

      return insertedCount;
    } else {
      // User canceled the picker
      return 0;
    }
  }

  Future<void> onImportDatabase(LonelyModel model) async {
    final result = await FilePicker.platform.pickFiles();

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
    if (Platform.isWindows) {
      final outPath = await FilePicker.platform.saveFile(
        dialogTitle: '내보낼 데이터 위치 지정',
        fileName: 'lonely.db',
      );
      if (outPath != null) {
        if (kDebugMode) {
          print(outPath);
        }

        await File(await getDbPath()).copy(outPath);
      }
    } else {
      Share.shareXFiles([XFile(await getDbPath())]);
    }
  }

  Future<void> onRemoveTransactionWhereNullAccountId(
    BuildContext context,
    LonelyModel model,
  ) async {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('경고'),
              content: const Text('삭제된 계좌와 관련된 매매 기록이 모두 삭제됩니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context, 'OK');
                    final count =
                        await model.removeTransactionWhereNullAccountId();
                    _showSimpleText('매매 기록 $count개 삭제되었습니다.');
                  },
                  child: const Text('모두 삭제'),
                ),
              ],
            ),
        barrierDismissible: true);
  }

  void onImportFromOtherDevice(BuildContext context, LonelyModel model) {
    model.publish(TransactionMessageType.requestSync, null);

    const outlinedButtonRadius = 8.0;
    final cancelButton = Expanded(
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: OutlinedButton.styleFrom(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(outlinedButtonRadius),
                  bottomRight: Radius.circular(outlinedButtonRadius),
                ))),
        child: const Text('취소'),
      ),
    );

    AlertDialog alert = AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(outlinedButtonRadius))),
        contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        //backgroundColor: Colors.white,
        elevation: 0,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 8),
              child: Text('불러오기',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(fontWeight: FontWeight.bold)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: Text('다른 기기의 응답 기다리는 중'),
            ),
            Row(
              children: [
                cancelButton,
              ],
            )
          ],
        ));

    showDialog(context: context, builder: (_) => alert);
  }
}
