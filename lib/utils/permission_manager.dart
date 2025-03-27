import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  // 必要な権限をリクエスト
  static Future<bool> requestStoragePermissions(BuildContext context) async {
    // Android 6.0以上の場合のみ権限リクエストが必要
    if (Platform.isAndroid) {
      // ストレージ権限の状態を確認
      PermissionStatus status = await Permission.storage.status;
      
      if (status.isDenied) {
        // 権限リクエスト
        status = await Permission.storage.request();
        
        // 権限が拒否された場合、ユーザーに説明
        if (status.isDenied && context.mounted) {
          _showPermissionDialog(context);
          return false;
        }
      }
      
      // 永久に拒否された場合は設定画面に誘導
      if (status.isPermanentlyDenied && context.mounted) {
        _showSettingsDialog(context);
        return false;
      }
      
      return status.isGranted;
    }
    
    // Androidでない場合は常にtrue
    return true;
  }
  
  // 権限説明ダイアログ
  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('ストレージアクセス権限が必要です'),
        content: const Text('空き容量を監視するために外部ストレージへのアクセス権限が必要です。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // 設定画面誘導ダイアログ
  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('権限設定'),
        content: const Text('アプリの設定画面からストレージのアクセス権限を有効にしてください。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }
}