import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'services/foreground_task_service.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'utils/optimization_helper.dart';
import 'utils/preferences.dart';  // 使用するので残します

void main() async {
  // Flutter初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();
  
  // 設定の問題の診断
  await _diagnosePreferences();
  
  // フォアグラウンドタスクの初期設定
  await _initForegroundTask();
  
  runApp(const MyApp());
}

// 設定の問題を診断する
Future<void> _diagnosePreferences() async {
  try {
    print('===== 設定診断開始 =====');
    
    // ストレージへのアクセス確認
    final appDir = await getApplicationDocumentsDirectory();
    print('アプリストレージパス: ${appDir.path}');
    
    // ファイル書き込みテスト
    try {
      final testFile = File('${appDir.path}/test_write.txt');
      await testFile.writeAsString('Test write at: ${DateTime.now()}');
      print('ファイル書き込みテスト: 成功');
      await testFile.delete();
    } catch (e) {
      print('ファイル書き込みテスト: 失敗 - $e');
    }
    
    // SharedPreferences初期化確認
    try {
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences初期化: 成功');
      print('保存されているキー: ${prefs.getKeys().join(', ')}');
      
      // テスト値の保存と読み込み
      await prefs.setString('diagnostic_test', 'test_value_${DateTime.now().millisecondsSinceEpoch}');
      final testValue = prefs.getString('diagnostic_test');
      print('SharedPreferences書き込み・読み込みテスト: ${testValue != null ? "成功" : "失敗"}');
      
      // 既存の設定値の確認
      print('device_number: ${prefs.getInt('device_number')}');
      print('setup_completed: ${prefs.getBool('setup_completed')}');
    } catch (e) {
      print('SharedPreferencesテスト: 失敗 - $e');
      
      // 代替策: ファイルベースの設定を確認
      await _checkBackupSettingsFile();
    }
    
    print('===== 設定診断終了 =====');
  } catch (e) {
    print('設定診断中にエラー: $e');
  }
}

// バックアップ設定ファイルの確認
Future<void> _checkBackupSettingsFile() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/app_settings.json');
    
    if (await file.exists()) {
      final contents = await file.readAsString();
      print('バックアップ設定ファイル: 存在する');
      if (contents.isNotEmpty) {
        final data = json.decode(contents) as Map<String, dynamic>;
        print('バックアップ設定内容: $data');
      } else {
        print('バックアップ設定ファイル: 空');
      }
    } else {
      print('バックアップ設定ファイル: 存在しない');
      
      // 初期バックアップファイルの作成
      await file.writeAsString('{}');
      print('初期バックアップファイルを作成しました');
    }
  } catch (e) {
    print('バックアップ設定ファイル確認エラー: $e');
  }
}

// フォアグラウンドタスクの初期設定
Future<void> _initForegroundTask() async {
  try {
    // パッケージの新しいAPIに合わせた初期化
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
        eventAction: ForegroundTaskEventAction.repeat(15 * 60 * 1000), // 15分間隔
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    print('フォアグラウンドタスク初期設定成功');
  } catch (e) {
    print('フォアグラウンドタスク初期設定エラー: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '空き容量モニター',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: WithForegroundTask(
        child: FutureBuilder<bool>(
          future: _isSetupCompleted(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            
            final setupCompleted = snapshot.data ?? false;
            print('セットアップ完了状態: $setupCompleted');
            return setupCompleted 
                ? const BatteryOptimizationWrapper(child: HomeScreen())
                : const SetupScreen();
          },
        ),
      ),
    );
  }
  
  // セットアップが完了しているかどうかを確認（PreferencesUtilを使用）
  Future<bool> _isSetupCompleted() async {
    try {
      // 改善されたPreferencesUtilクラスを使用
      final completed = await PreferencesUtil.isSetupCompleted();
      print('セットアップ完了状態: $completed');
      return completed;
    } catch (e) {
      print('セットアップ確認エラー: $e');
      
      // 直接SharedPreferencesを試してみる（フォールバック）
      try {
        final prefs = await SharedPreferences.getInstance();
        final value = prefs.getBool('setup_completed') ?? false;
        print('直接確認したセットアップ状態: $value');
        return value;
      } catch (e2) {
        print('直接確認でもエラー: $e2');
        
        // 最後の手段：ファイルから直接読み込む
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/app_settings.json');
          if (await file.exists()) {
            final contents = await file.readAsString();
            if (contents.isNotEmpty) {
              final data = json.decode(contents) as Map<String, dynamic>;
              final value = data['setup_completed'] == true;
              print('ファイルから読み込んだセットアップ状態: $value');
              return value;
            }
          }
        } catch (e3) {
          print('ファイル読み込みでもエラー: $e3');
        }
        
        return false;
      }
    }
  }
}

// バッテリー最適化設定を案内するラッパーウィジェット
class BatteryOptimizationWrapper extends StatefulWidget {
  final Widget child;
  
  const BatteryOptimizationWrapper({super.key, required this.child});
  
  @override
  _BatteryOptimizationWrapperState createState() => _BatteryOptimizationWrapperState();
}

class _BatteryOptimizationWrapperState extends State<BatteryOptimizationWrapper> {
  bool _checkingOptimization = true;
  
  @override
  void initState() {
    super.initState();
    _checkOptimizationSettings();
  }
  
  Future<void> _checkOptimizationSettings() async {
    try {
      // 初回実行フラグを確認（PreferencesUtilを使用）
      final isFirstRun = await PreferencesUtil.isFirstRun();
      print('初回実行確認: $isFirstRun');
      
      // 最適化設定のダイアログを表示するかどうか
      if (isFirstRun) {
        // 1秒待機して、UIが完全に描画された後にダイアログを表示
        if (mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              OptimizationHelper.showOptimizationDialog(context).then((_) async {
                // 初回実行フラグをオフに
                await PreferencesUtil.setFirstRun(false);
                
                // セットアップ済みの場合はサービスを開始
                if (await PreferencesUtil.isSetupCompleted()) {
                  print('サービス開始');
                  await initForegroundTask();
                }
                
                if (mounted) {
                  setState(() {
                    _checkingOptimization = false;
                  });
                }
              });
            }
          });
        }
      } else {
        // セットアップ済みの場合はサービスを開始
        if (await PreferencesUtil.isSetupCompleted()) {
          print('サービス開始');
          await initForegroundTask();
        }
        
        setState(() {
          _checkingOptimization = false;
        });
      }
    } catch (e) {
      print('最適化設定チェック中にエラー: $e');
      setState(() {
        _checkingOptimization = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_checkingOptimization) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return widget.child;
  }
}