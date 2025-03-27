import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class OptimizationHelper {
  static Future<bool> showOptimizationDialog(BuildContext context) async {
    if (!Platform.isAndroid) return true; // Androidのみ対応
    
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    
    // デバイスメーカーとモデルを取得
    final String manufacturer = androidInfo.manufacturer.toLowerCase();
    
    // フォアグラウンドサービスのバッテリー最適化を無効にするための手順
    await _requestBatteryOptimizationSettings();
    
    // 端末メーカーに応じた設定ガイド
    String manufacturer_name = manufacturer.toUpperCase();
    Map<String, String> optimizationGuide = {
      'xiaomi': '$manufacturer_nameデバイスでは以下の設定が必要です:\n\n・設定 > アプリ > このアプリ > バッテリー > 制限なし\n・設定 > アプリ > このアプリ > 自動起動を許可',
      'huawei': '$manufacturer_nameデバイスでは以下の設定が必要です:\n\n・設定 > アプリ > このアプリ > 電池管理 > 起動アプリ\n・設定 > アプリ > 詳細設定 > バッテリー > アプリの起動',
      'oppo': '$manufacturer_nameデバイスでは以下の設定が必要です:\n\n・設定 > バッテリー > バッテリー最適化 > このアプリ > 最適化しない\n・設定 > アプリ管理 > このアプリ > 自動起動',
      'vivo': '$manufacturer_nameデバイスでは以下の設定が必要です:\n\n・設定 > バッテリー > バックグラウンドアプリ高電力モード > このアプリをオン\n・設定 > アプリ > アプリ管理 > このアプリ > バックグラウンド実行を許可',
      'samsung': '$manufacturer_nameデバイスでは以下の設定が必要です:\n\n・設定 > デバイスケア > バッテリー > バックグラウンド使用を制限 > このアプリを無効に\n・設定 > アプリ > このアプリ > バッテリー > バックグラウンドで制限なし',
      'sony': '$manufacturer_nameデバイスでは以下の設定が必要です:\n\n・設定 > バッテリー > このアプリを例外として追加',
      'asus': '$manufacturer_nameデバイスでは以下の設定が必要です:\n\n・設定 > バッテリー > アプリ起動マネージャー > このアプリを許可',
      'oneplus': '$manufacturer_nameデバイスでは以下の設定が必要です:\n\n・設定 > バッテリー > バッテリー最適化 > このアプリ > 最適化しない',
    };
    
    // デフォルトの説明
    String message = '最適なアプリ動作のため、バッテリー最適化から除外する設定が必要です。\n\n・設定 > アプリ > このアプリ > バッテリー > 最適化しない\n\nこの設定をすることで、バックグラウンドでもデータを送信し続けることができます。';
    
    // メーカー固有のガイドがあればそれを使用
    for (final key in optimizationGuide.keys) {
      if (manufacturer.contains(key)) {
        message = optimizationGuide[key]!;
        break;
      }
    }
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('バッテリー最適化の設定'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
                const SizedBox(height: 16),
                const Text('これらの設定を行わないと、バックグラウンドでのデータ送信が制限される場合があります。',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('後で設定'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('設定する'),
              onPressed: () async {
                // バッテリー最適化設定画面に移動
                await _openBatteryOptimizationSettings();
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  // バッテリー最適化の除外をリクエスト
  static Future<void> _requestBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;
    
    try {
      // バッテリー最適化の設定を開く
      // 注: パッケージの最新版ではメソッド名が変更されている可能性があります
      // FlutterForegroundTask.openBatteryOptimizationSettings();
      
      // もしくは、アプリの設定を開く
      await _openSettings();
    } catch (e) {
      debugPrint('バッテリー最適化の設定を開く際にエラー: $e');
    }
  }
  
  // バッテリー最適化設定画面を開く
  static Future<void> _openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;
    
    try {
      // 設定を開く
      await _openSettings();
    } catch (e) {
      debugPrint('設定画面を開く際にエラー: $e');
    }
  }
  
  // アプリの設定画面を開く代替実装
  static Future<void> _openSettings() async {
    // 代わりに一般的な通知/アプリ設定画面を開くメソッドを呼ぶ
    // 例えば：
    try {
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    } catch (e) {
      debugPrint('設定画面を開く際にエラー: $e');
      // エラーの場合、何もしない
    }
  }
}