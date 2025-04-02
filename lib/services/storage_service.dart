import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/emulator_detector.dart';

class StorageInfo {
  final int totalSpace;
  final int freeSpace;
  final int usedSpace;

  StorageInfo({
    required this.totalSpace,
    required this.freeSpace,
    required this.usedSpace,
  });
}

class StorageService {
  // ストレージ情報を取得（path_providerを使用）
// ストレージ情報を取得（path_providerを使用）
  static Future<StorageInfo> getStorageInfo() async {
    try {
      print('ストレージ情報の取得を開始...');
      // 外部ストレージディレクトリの取得を試みる
      Directory? directory;

      try {
        directory = await getExternalStorageDirectory();
        print('外部ストレージへのアクセス: ${directory?.path}');
      } catch (e) {
        print('外部ストレージへのアクセスエラー: $e');
      }

      // 外部ストレージが取得できない場合はアプリケーションディレクトリを使用
      directory ??= await getApplicationDocumentsDirectory();

      // ファイルシステムの統計情報を取得
      final statFs = directory.statSync();

      // 利用可能なサイズを取得
      int freeBytes = statFs.size;
      print('取得した空き容量: $freeBytes バイト');
      
      // ★★★ エミュレータ対応（実環境移行時に除外可能） ★★★
      freeBytes = await EmulatorDetector.adjustStorageSize(freeBytes);
      // ★★★ エミュレータ対応ここまで ★★★

      // 注：正確な合計容量は取得が難しいため、推定値を使用
      // 多くのデバイスでは、内部ストレージの合計サイズは数十GBなので、妥当な推定値を設定
      final totalBytes = 64 * 1024 * 1024 * 1024; // 仮の値: 64GB
      final usedBytes = totalBytes - freeBytes;

      return StorageInfo(
        totalSpace: totalBytes,
        freeSpace: freeBytes,
        usedSpace: usedBytes,
      );
    } catch (e) {
      print('ストレージ情報の取得に失敗: $e');

      // エラー発生時のフォールバック
      try {
        // 代替手段: アプリケーションディレクトリの取得を試みる
        final directory = await getApplicationDocumentsDirectory();

        // 仮の値を使用
        final totalSpace = 64 * 1024 * 1024 * 1024; // 仮の値: 64GB
        final freeSpace = 32 * 1024 * 1024 * 1024;  // 仮の値: 32GB
        final usedSpace = totalSpace - freeSpace;

        return StorageInfo(
          totalSpace: totalSpace,
          freeSpace: freeSpace,
          usedSpace: usedSpace,
        );
      } catch (fallbackError) {
        print('フォールバック実装でも失敗: $fallbackError');
      }

      // エラー時はデフォルト値を返す
      return StorageInfo(
        totalSpace: 0,
        freeSpace: 0,
        usedSpace: 0,
      );
    }
  }
}