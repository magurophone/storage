import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

// エミュレータ検出クラス
// 実環境移行時にこのファイルを削除するか、isEmulatorメソッドの戻り値をfalseに固定すれば無効化できます
class EmulatorDetector {
  // エミュレータかどうかを検出（シングルトンパターン）
  static EmulatorDetector? _instance;
  static bool? _cachedResult;

  // キャッシュしたエミュレータ判定結果を取得
  static Future<bool> isEmulator() async {
    // キャッシュがあればそれを返す
    if (_cachedResult != null) {
      return _cachedResult!;
    }

    // インスタンスがなければ作成
    _instance ??= EmulatorDetector._();
    
    // 検出実行
    _cachedResult = await _instance!._detectEmulator();
    return _cachedResult!;
  }
  
  // プライベートコンストラクタ
  EmulatorDetector._();
  
  // エミュレータ検出の実装
  Future<bool> _detectEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      // Androidの場合
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        
        // エミュレータの特徴をチェック
        final bool isEmulator = 
            // 物理デバイスフラグがfalse
            androidInfo.isPhysicalDevice == false ||
            // モデル名に「sdk」「emulator」「google_sdk」などが含まれる
            androidInfo.model.toLowerCase().contains('sdk') ||
            androidInfo.model.toLowerCase().contains('emulator') ||
            androidInfo.model.toLowerCase().contains('google_sdk') ||
            // 製造元がGoogle
            androidInfo.manufacturer.toLowerCase().contains('google') && 
                androidInfo.model.toLowerCase().contains('pixel') && 
                !androidInfo.isPhysicalDevice ||
            // エミュレータに特有のビルド特性
            androidInfo.brand.toLowerCase().contains('android') && 
                androidInfo.manufacturer.toLowerCase().contains('google');
        
        print('エミュレータ検出結果: $isEmulator (${androidInfo.model})');
        return isEmulator;
      } 
      
      // 他のプラットフォームはエミュレータではないと判断
      return false;
    } catch (e) {
      print('エミュレータ検出中にエラー: $e');
      // エラーの場合はエミュレータではないと仮定
      return false;
    }
  }

  // エミュレータ用のストレージ容量調整
  // 実環境移行時にこのメソッドの中身を空にするか、
  // 単に入力値をそのまま返すように変更すれば無効化できます
  static Future<int> adjustStorageSize(int detectedSize) async {
    // エミュレータでなければそのまま返す
    if (!await isEmulator()) {
      return detectedSize;
    }
    
    // エミュレータでストレージ容量が極端に小さい場合は調整
    if (detectedSize < 1024 * 1024) { // 1MB未満
      print('エミュレータ用にストレージ容量を調整: $detectedSize バイト → 2GB');
      return 2 * 1024 * 1024 * 1024; // 2GB
    }
    
    // それなりの大きさがある場合はそのまま返す
    return detectedSize;
  }
}