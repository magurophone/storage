import 'dart:io';
import 'package:flutter/material.dart';
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
      debugPrint('【デバッグ】エミュレータ検出: キャッシュ使用 - $_cachedResult');
      return _cachedResult!;
    }

    // インスタンスがなければ作成
    _instance ??= EmulatorDetector._();
    
    // 検出実行
    _cachedResult = await _instance!._detectEmulator();
    debugPrint('【デバッグ】エミュレータ検出: 新規検出 - $_cachedResult');
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
        
        // エミュレータの特徴をデバッグ出力
        debugPrint('【デバッグ】デバイス情報:');
        debugPrint('  - メーカー: ${androidInfo.manufacturer}');
        debugPrint('  - モデル: ${androidInfo.model}');
        debugPrint('  - ブランド: ${androidInfo.brand}');
        debugPrint('  - 物理デバイス: ${androidInfo.isPhysicalDevice}');
        debugPrint('  - SDK: ${androidInfo.version.sdkInt}');
        
        // エミュレータの特徴をチェック
        final bool condition1 = androidInfo.isPhysicalDevice == false;
        final bool condition2 = androidInfo.model.toLowerCase().contains('sdk');
        final bool condition3 = androidInfo.model.toLowerCase().contains('emulator');
        final bool condition4 = androidInfo.model.toLowerCase().contains('google_sdk');
        final bool condition5 = androidInfo.manufacturer.toLowerCase().contains('google') && 
            androidInfo.model.toLowerCase().contains('pixel') && 
            !androidInfo.isPhysicalDevice;
        final bool condition6 = androidInfo.brand.toLowerCase().contains('android') && 
            androidInfo.manufacturer.toLowerCase().contains('google');
            
        debugPrint('【デバッグ】エミュレータ条件判定:');
        debugPrint('  - 条件1 (物理デバイスでない): $condition1');
        debugPrint('  - 条件2 (SDKを含む): $condition2');
        debugPrint('  - 条件3 (Emulatorを含む): $condition3');
        debugPrint('  - 条件4 (Google SDKを含む): $condition4');
        debugPrint('  - 条件5 (Google Pixelで物理デバイスでない): $condition5');
        debugPrint('  - 条件6 (Androidブランド + Google製造): $condition6');
        
        final bool isEmulator = condition1 || condition2 || condition3 || 
                               condition4 || condition5 || condition6;
        
        debugPrint('【デバッグ】エミュレータ検出結果: $isEmulator');
        return isEmulator;
      } 
      
      // 他のプラットフォームはエミュレータではないと判断
      debugPrint('【デバッグ】Android以外のプラットフォーム: エミュレータではないと判断');
      return false;
    } catch (e) {
      debugPrint('【デバッグ】エミュレータ検出中にエラー: $e');
      // エラーの場合はエミュレータではないと仮定
      return false;
    }
  }

  // エミュレータ用のストレージ容量調整
  // 実環境移行時にこのメソッドの中身を空にするか、
  // 単に入力値をそのまま返すように変更すれば無効化できます
  static Future<int> adjustStorageSize(int detectedSize) async {
    // デバッグ出力
    debugPrint('【デバッグ】ストレージサイズ調整: 入力サイズ = $detectedSize バイト');
    debugPrint('【デバッグ】ストレージサイズ調整: 入力サイズ = ${detectedSize / (1024 * 1024)} MB');
    
    // エミュレータでなければそのまま返す
    if (!await isEmulator()) {
      debugPrint('【デバッグ】ストレージサイズ調整: エミュレータではないため調整なし');
      return detectedSize;
    }
    
    debugPrint('【デバッグ】ストレージサイズ調整: エミュレータと判定');
    
    // ★★★ 問題解決のための修正 ★★★
    // エミュレータでストレージ容量が極端に小さい場合は調整（閾値を100MBに引き上げ）
    if (detectedSize < 100 * 1024 * 1024) { // 100MB未満（元は1MB未満）
      // 調整値も5GBに変更（実際の空き容量に近づける）
      final int adjustedSize = 5 * 1024 * 1024 * 1024; // 5GB (元は2GB)
      debugPrint('【デバッグ】エミュレータ用にストレージ容量を調整: $detectedSize バイト → $adjustedSize バイト');
      debugPrint('【デバッグ】エミュレータ用にストレージ容量を調整: ${detectedSize / (1024 * 1024)} MB → ${adjustedSize / (1024 * 1024 * 1024)} GB');
      return adjustedSize;
    }
    
    // それなりの大きさがある場合はそのまま返す
    debugPrint('【デバッグ】エミュレータでも十分な容量があるため調整なし');
    return detectedSize;
  }
}