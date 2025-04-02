import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/emulator_detector.dart';
import '../utils/preferences.dart';
import '../services/api_service.dart';

// トップレベル関数としてコールバックを定義
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(StorageMonitorTaskHandler());
}

// フォアグラウンドサービス用のタスクハンドラ
class StorageMonitorTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 開始時に一度実行
    await _checkAndSendStorageInfo();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // 定期的にこのメソッドが呼び出される
    await _checkAndSendStorageInfo();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('フォアグラウンドサービスが停止しました');
  }

  // ストレージ情報のチェックとサーバーへの送信
  Future<void> _checkAndSendStorageInfo() async {
    try {
      print('ストレージ情報のチェックを開始...');

      // デバイス番号を取得 - PreferencesUtilを使用
      final deviceNumber = await PreferencesUtil.getDeviceNumber();
      if (deviceNumber == null) {
        print('デバイス番号が設定されていません');
        return;
      }
      print('デバイス番号取得: $deviceNumber');

      // 空き容量を取得
      final freeSpace = await _getFreeSpace();
      print('空き容量を取得: $freeSpace バイト');

      // サーバーにデータを送信
      final success = await _sendStorageData(
        deviceNumber: deviceNumber,
        freeSpace: freeSpace,
      );

      if (success) {
        // 成功した場合、最終更新情報を保存
        final now = DateTime.now().toIso8601String();

        // PreferencesUtilを使用して保存
        final syncResult = await PreferencesUtil.setLastSync(now);
        print('同期日時保存結果: $syncResult ($now)');

        final spaceResult = await PreferencesUtil.setLastFreeSpace(freeSpace);
        print('空き容量保存結果: $spaceResult ($freeSpace)');

        // 保存確認のデバッグ
        final savedSync = await PreferencesUtil.getLastSync();
        final savedFreeSpace = await PreferencesUtil.getLastFreeSpace();
        print('保存確認 - 同期日時: $savedSync, 空き容量: $savedFreeSpace');

        // 通知を更新
        final freeSpaceGB = (freeSpace / (1024 * 1024 * 1024)).toStringAsFixed(2);
        await FlutterForegroundTask.updateService(
          notificationTitle: 'ストレージモニター実行中',
          notificationText: 'デバイス #$deviceNumber: $freeSpaceGB GB空き',
        );

        print('データ送信完了: $freeSpaceGB GB空き容量');
      } else {
        print('データ送信に失敗しました');
      }
    } catch (e) {
      print('ストレージ監視でエラー: $e');
    }
  }

  // 空き容量の取得
  Future<int> _getFreeSpace() async {
    try {
      Directory? directory;

      try {
        // アプリのドキュメントディレクトリを使用（権限問題が少ない）
        directory = await getApplicationDocumentsDirectory();
        print('ディレクトリパス: ${directory.path}');
      } catch (e) {
        print('ディレクトリアクセスエラー: $e');
        throw e;
      }

      // ファイルシステムの統計情報を取得
      final statFs = directory.statSync();
      print('ディレクトリ統計: ${statFs.toString()}');

      // 利用可能なサイズを取得
      int freeSpace = statFs.size;

      // エミュレータ対応
      freeSpace = await EmulatorDetector.adjustStorageSize(freeSpace);

      return freeSpace;
    } catch (e) {
      print('ストレージ情報の取得に失敗: $e');

      // エラー時はフォールバック値を返す
      return 32 * 1024 * 1024;  // 32MBのフォールバック
    }
  }

  // ストレージデータをサーバーに送信
  Future<bool> _sendStorageData({
    required int deviceNumber,
    required int freeSpace,
  }) async {
    try {
      // デバイス情報を取得
      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = "不明";

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.model ?? "iOS Device";
      }

      // JSONデータの作成
      final data = {
        'device_number': deviceNumber,
        'free_space': freeSpace,
        'device_model': deviceModel,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('送信データ準備: $data');

      // 実際のAPI呼び出し - ApiServiceを使用
      try {
        // API呼び出し（実際のHTTPリクエスト）
        final apiUrl = 'http://10.0.2.2/storage_monitor/public/receive_data.php';

        print('APIリクエスト送信: $apiUrl');

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'device_number': deviceNumber,
            'free_space': freeSpace,
          }),
        );

        print('APIレスポンス: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          try {
            final responseData = jsonDecode(response.body);
            final success = responseData['status'] == 'success';
            print('API呼び出し成功: $success');
            return success;
          } catch (e) {
            print('レスポンス解析エラー: $e');
            return false;
          }
        } else {
          print('APIエラー: ${response.statusCode}');
          return false;
        }
      } catch (e) {
        print('API呼び出しエラー: $e');
        return false;
      }
    } catch (e) {
      print('データ送信処理でエラー: $e');
      return false;
    }
  }
}

// フォアグラウンドタスクの初期化
Future<bool> initForegroundTask() async {
  print('フォアグラウンドタスク初期化開始...');

  // 通知テキスト用にデバイス番号を取得
  final deviceNumber = await PreferencesUtil.getDeviceNumber() ?? 0;

  // フォアグラウンドタスク設定の初期化
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'storage_monitor_channel',
      channelName: 'ストレージモニターサービス',
      channelDescription: 'デバイスストレージを監視しています',
      channelImportance: NotificationChannelImportance.DEFAULT,
      priority: NotificationPriority.DEFAULT,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      // 開発中はより短い間隔でテスト
      eventAction: ForegroundTaskEventAction.repeat(60 * 1000), // 1分間隔（テスト用）
      // eventAction: ForegroundTaskEventAction.repeat(15 * 60 * 1000), // 15分間隔（本番用）
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  // タスク開始
  try {
    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'ストレージモニター実行中',
      notificationText: 'デバイス #$deviceNumber を監視中',
      callback: startCallback,
    );

    print('フォアグラウンドタスク初期化結果: $result');
    return true; // 常に成功とみなす
  } catch (e) {
    print('フォアグラウンドタスク初期化エラー: $e');
    return false;
  }
}

// サービスを停止
Future<bool> stopForegroundTask() async {
  print('フォアグラウンドタスク停止開始...');
  try {
    final result = await FlutterForegroundTask.stopService();
    print('フォアグラウンドタスク停止結果: $result');
    return true; // 常に成功とみなす
  } catch (e) {
    print('フォアグラウンドタスク停止エラー: $e');
    return false;
  }
}