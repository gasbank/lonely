import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PackageModel extends ChangeNotifier {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  PackageModel() {
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
    notifyListeners();
  }

  PackageInfo get info => _packageInfo;
}