import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PreferencesUtil {
  static const String DEVICE_NUMBER_KEY = 'device_number';
  static const String SETUP_COMPLETED_KEY = 'setup_completed';
  static const String FIRST_RUN_KEY = 'first_run';
  static const String LAST_SYNC_KEY = 'last_sync';
  static const String LAST_FREE_SPACE_KEY = 'last_free_space';

  // デバイス番号を保存
  static Future<bool> saveDeviceNumber(int deviceNumber) async {
    try {
      debugPrint('デバイス番号保存開始: $deviceNumber');
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setInt(DEVICE_NUMBER_KEY, deviceNumber);
      debugPrint('デバイス番号保存結果: $result ($deviceNumber)');
      
      // 即時読み込みテスト
      final savedValue = prefs.getInt(DEVICE_NUMBER_KEY);
      debugPrint('保存後読み込み確認: $savedValue');
      
      // ファイルバックアップ
      await _saveToFile(DEVICE_NUMBER_KEY, deviceNumber);
      
      return result;
    } catch (e) {
      debugPrint('デバイス番号保存エラー: $e');
      // ファイルバックアップ
      await _saveToFile(DEVICE_NUMBER_KEY, deviceNumber);
      return false;
    }
  }

  // デバイス番号を取得
  static Future<int?> getDeviceNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(DEVICE_NUMBER_KEY);
      debugPrint('デバイス番号取得: $value');
      
      // SharedPreferencesから取得できなければファイルから取得
      if (value == null) {
        return await _getFromFile(DEVICE_NUMBER_KEY) as int?;
      }
      
      return value;
    } catch (e) {
      debugPrint('デバイス番号取得エラー: $e');
      // ファイルから取得
      return await _getFromFile(DEVICE_NUMBER_KEY) as int?;
    }
  }


  // セットアップ完了フラグを保存
  static Future<bool> setSetupCompleted(bool completed) async {
    try {
      debugPrint('セットアップ完了フラグ保存開始: $completed');
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setBool(SETUP_COMPLETED_KEY, completed);
      debugPrint('セットアップ完了フラグ保存結果: $result ($completed)');
      
      // 即時読み込みテスト
      final savedValue = prefs.getBool(SETUP_COMPLETED_KEY);
      debugPrint('保存後読み込み確認: $savedValue');
      
      // ファイルバックアップ
      await _saveToFile(SETUP_COMPLETED_KEY, completed);
      
      return result;
    } catch (e) {
      debugPrint('セットアップ完了フラグ保存エラー: $e');
      // ファイルバックアップ
      await _saveToFile(SETUP_COMPLETED_KEY, completed);
      return false;
    }
  }

  // セットアップ完了フラグを取得
  static Future<bool> isSetupCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(SETUP_COMPLETED_KEY);
      debugPrint('セットアップ完了フラグ取得: $value');
      
      // SharedPreferencesから取得できなければファイルから取得
      if (value == null) {
        return await _getFromFile(SETUP_COMPLETED_KEY) as bool? ?? false;
      }
      
      return value;
    } catch (e) {
      debugPrint('セットアップ完了フラグ取得エラー: $e');
      // ファイルから取得
      return await _getFromFile(SETUP_COMPLETED_KEY) as bool? ?? false;
    }
  }
  
  // 初回実行フラグを取得
  static Future<bool> isFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(FIRST_RUN_KEY);
      debugPrint('初回実行フラグ取得: $value');
      
      // 値が存在しない場合はtrueを返す (= 初回実行とみなす)
      if (value == null) {
        // ファイルから取得
        return await _getFromFile(FIRST_RUN_KEY) as bool? ?? true;
      }
      
      return value;
    } catch (e) {
      debugPrint('初回実行フラグ取得エラー: $e');
      // ファイルから取得
      return await _getFromFile(FIRST_RUN_KEY) as bool? ?? true;
    }
  }
  
  // 初回実行フラグを設定
  static Future<bool> setFirstRun(bool isFirstRun) async {
    try {
      debugPrint('初回実行フラグ保存開始: $isFirstRun');
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setBool(FIRST_RUN_KEY, isFirstRun);
      debugPrint('初回実行フラグ保存結果: $result ($isFirstRun)');
      
      // ファイルバックアップ
      await _saveToFile(FIRST_RUN_KEY, isFirstRun);
      
      return result;
    } catch (e) {
      debugPrint('初回実行フラグ保存エラー: $e');
      // ファイルバックアップ
      await _saveToFile(FIRST_RUN_KEY, isFirstRun);
      return false;
    }
  }
  
  // 最終同期日時を取得
  static Future<String?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(LAST_SYNC_KEY);
      debugPrint('最終同期日時取得: $value');
      
      // SharedPreferencesから取得できなければファイルから取得
      if (value == null) {
        return await _getFromFile(LAST_SYNC_KEY) as String?;
      }
      
      return value;
    } catch (e) {
      debugPrint('最終同期日時取得エラー: $e');
      // ファイルから取得
      return await _getFromFile(LAST_SYNC_KEY) as String?;
    }
  }
  
  // 最終同期日時を保存
  static Future<bool> setLastSync(String datetime) async {
    try {
      debugPrint('最終同期日時保存開始: $datetime');
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(LAST_SYNC_KEY, datetime);
      debugPrint('最終同期日時保存結果: $result ($datetime)');
      
      // ファイルバックアップ
      await _saveToFile(LAST_SYNC_KEY, datetime);
      
      return result;
    } catch (e) {
      debugPrint('最終同期日時保存エラー: $e');
      // ファイルバックアップ
      await _saveToFile(LAST_SYNC_KEY, datetime);
      return false;
    }
  }
  
  // 最終空き容量を取得
  static Future<int?> getLastFreeSpace() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(LAST_FREE_SPACE_KEY);
      debugPrint('最終空き容量取得: $value');
      
      // SharedPreferencesから取得できなければファイルから取得
      if (value == null) {
        return await _getFromFile(LAST_FREE_SPACE_KEY) as int?;
      }
      
      return value;
    } catch (e) {
      debugPrint('最終空き容量取得エラー: $e');
      // ファイルから取得
      return await _getFromFile(LAST_FREE_SPACE_KEY) as int?;
    }
  }
  
  // 最終空き容量を保存
  static Future<bool> setLastFreeSpace(int freeSpace) async {
    try {
      debugPrint('最終空き容量保存開始: $freeSpace');
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setInt(LAST_FREE_SPACE_KEY, freeSpace);
      debugPrint('最終空き容量保存結果: $result ($freeSpace)');
      
      // ファイルバックアップ
      await _saveToFile(LAST_FREE_SPACE_KEY, freeSpace);
      
      return result;
    } catch (e) {
      debugPrint('最終空き容量保存エラー: $e');
      // ファイルバックアップ
      await _saveToFile(LAST_FREE_SPACE_KEY, freeSpace);
      return false;
    }
  }
  
  // ファイルに設定を保存するバックアップ機能
  static Future<bool> _saveToFile(String key, dynamic value) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_settings.json');
      
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          data = json.decode(contents) as Map<String, dynamic>;
        }
      }
      
      data[key] = value;
      await file.writeAsString(json.encode(data));
      debugPrint('ファイルに設定を保存しました: $key=$value');
      return true;
    } catch (e) {
      debugPrint('ファイル保存エラー: $e');
      return false;
    }
  }
  
  // ファイルから設定を読み込むバックアップ機能
  static Future<dynamic> _getFromFile(String key) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_settings.json');
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          final data = json.decode(contents) as Map<String, dynamic>;
          final value = data[key];
          debugPrint('ファイルから設定を読み込みました: $key=$value');
          return value;
        }
      }
      
      debugPrint('ファイルに設定が存在しません: $key');
      return null;
    } catch (e) {
      debugPrint('ファイル読み込みエラー: $e');
      return null;
    }
  }
  
  // 設定の保存状態を診断
  static Future<String> diagnose() async {
    final buffer = StringBuffer();
    try {
      buffer.writeln('===== 設定診断開始 =====');
      
      // プラットフォーム情報
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        buffer.writeln('Platform: Android ${androidInfo.version.release} (${androidInfo.model})');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        buffer.writeln('Platform: iOS ${iosInfo.systemVersion} (${iosInfo.model})');
      } else {
        buffer.writeln('Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      }
      
      // ストレージパス
      final appDir = await getApplicationDocumentsDirectory();
      buffer.writeln('App directory: ${appDir.path}');
      
      // SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        buffer.writeln('SharedPreferences available: Yes');
        buffer.writeln('Keys: ${prefs.getKeys().join(', ')}');
        
        // 各設定値
        buffer.writeln('device_number: ${prefs.getInt(DEVICE_NUMBER_KEY)}');
        buffer.writeln('setup_completed: ${prefs.getBool(SETUP_COMPLETED_KEY)}');
        buffer.writeln('first_run: ${prefs.getBool(FIRST_RUN_KEY)}');
        buffer.writeln('last_sync: ${prefs.getString(LAST_SYNC_KEY)}');
        buffer.writeln('last_free_space: ${prefs.getInt(LAST_FREE_SPACE_KEY)}');
      } catch (e) {
        buffer.writeln('SharedPreferences error: $e');
      }
      
      // ファイルバックアップ
      try {
        final file = File('${appDir.path}/app_settings.json');
        if (await file.exists()) {
          final contents = await file.readAsString();
          buffer.writeln('Backup file exists: Yes');
          buffer.writeln('Backup contents: $contents');
        } else {
          buffer.writeln('Backup file exists: No');
        }
      } catch (e) {
        buffer.writeln('Backup file error: $e');
      }
      
      buffer.writeln('===== 設定診断終了 =====');
      return buffer.toString();
    } catch (e) {
      buffer.writeln('Diagnostic error: $e');
      return buffer.toString();
    }
  }
  
  // すべての設定をクリア（トラブルシューティング用）
  static Future<bool> clearAll() async {
    try {
      // SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // バックアップファイル
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_settings.json');
      if (await file.exists()) {
        await file.delete();
      }
      
      debugPrint('すべての設定をクリアしました');
      return true;
    } catch (e) {
      debugPrint('設定クリアエラー: $e');
      return false;
    }
  }
}