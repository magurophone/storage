import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../utils/preferences.dart';
import '../utils/optimization_helper.dart';
import '../services/foreground_task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int? deviceNumber;
  String? lastSync;
  int? lastFreeSpace;
  bool isLoading = true;
  bool isServiceRunning = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _checkServiceStatus();

    // 定期的に画面を更新（30秒ごと）
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
        _checkServiceStatus();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
      _checkServiceStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  // サービスの状態を確認
  Future<void> _checkServiceStatus() async {
    final running = await FlutterForegroundTask.isRunningService;
    if (mounted) {
      setState(() {
        isServiceRunning = running;
      });
    }
  }

  // データを読み込む
  Future<void> _loadData() async {
    final number = await PreferencesUtil.getDeviceNumber();
    final sync = await PreferencesUtil.getLastSync();
    final space = await PreferencesUtil.getLastFreeSpace();

    if (mounted) {
      setState(() {
        deviceNumber = number;
        lastSync = sync;
        lastFreeSpace = space;
        isLoading = false;
      });
    }
  }

  // GB単位に変換
  String _formatSize(int? bytes) {
    if (bytes == null) return '不明';
    final gb = bytes / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(2)} GB';
  }

  // 日時をフォーマット
  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '同期情報なし';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}秒前';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分前';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}時間前';
      } else {
        return '${difference.inDays}日前';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }

  // サービスを開始/停止
  Future<void> _toggleService() async {
    if (isServiceRunning) {
      await stopForegroundTask();
    } else {
      await initForegroundTask();
    }

    // サービスの状態を取得して更新
    await _checkServiceStatus();
  }

  // 手動更新リクエスト
  Future<void> _requestRefresh() async {
    // サービスが実行中なら手動でデータ送信リクエスト
    if (isServiceRunning) {
      try {
        // 代わりに単にサービスを再起動してデータ更新を促す
        await stopForegroundTask();
        await Future.delayed(const Duration(milliseconds: 500));
        bool success = await initForegroundTask();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success
              ? 'サービスを再起動して更新しました'
              : 'サービスの再起動に問題が発生しました')),
        );

        // 少し待ってからデータを再読み込み
        await Future.delayed(const Duration(seconds: 2));
        await _loadData();
      } catch (e) {
        debugPrint('更新リクエスト中にエラー: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新リクエストエラー: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('サービスが実行されていません。開始してください。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('空き容量モニター'),
        actions: [
          IconButton(
            icon: const Icon(Icons.battery_alert),
            onPressed: () => OptimizationHelper.showOptimizationDialog(context),
            tooltip: 'バッテリー設定',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
            tooltip: '設定',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'デバイス情報',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('デバイス番号: 【$deviceNumber】'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('ステータス: '),
                          Icon(
                            isServiceRunning
                                ? Icons.circle
                                : Icons.error_outline,
                            color: isServiceRunning
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          Text(
                              isServiceRunning
                                  ? ' モニタリング中'
                                  : ' 停止中'
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('最終同期: ${_formatDateTime(lastSync)}'),
                      const SizedBox(height: 4),
                      Text('空き容量: ${_formatSize(lastFreeSpace)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '動作ステータス',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.access_time, color: Colors.blue),
                        title: const Text('送信頻度'),
                        subtitle: const Text('15分ごと'),
                        dense: true,
                      ),
                      ListTile(
                        leading: Icon(
                            lastSync != null
                                ? Icons.check_circle
                                : Icons.error,
                            color: lastSync != null
                                ? Colors.green
                                : Colors.red
                        ),
                        title: const Text('同期状態'),
                        subtitle: Text(
                            lastSync != null
                                ? '正常に動作しています'
                                : '同期記録がありません'
                        ),
                        dense: true,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('監視サービス'),
                        subtitle: Text(
                            isServiceRunning
                                ? '実行中 - 通知から確認できます'
                                : '停止中 - タップして開始'
                        ),
                        value: isServiceRunning,
                        onChanged: (value) async {
                          await _toggleService();
                        },
                        secondary: Icon(
                          isServiceRunning
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: isServiceRunning
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ヘルプ',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.battery_alert, color: Colors.orange),
                        title: const Text('バッテリー最適化設定'),
                        subtitle: const Text('端末のバッテリー設定を変更して、バックグラウンド動作を最適化します'),
                        onTap: () => OptimizationHelper.showOptimizationDialog(context),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'このアプリはバックグラウンドで動作しています。',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'デバイスの空き容量情報を15分ごとに送信しています。',
                style: TextStyle(fontSize: 14),
              ),
              if (isServiceRunning)
                const Text(
                  '※通知を消すと監視サービスが停止する場合があります。',
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _loadData();
          await _checkServiceStatus();
          if (isServiceRunning) {
            await _requestRefresh();
          }
        },
        tooltip: '手動更新',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // 設定ダイアログを表示
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('現在のデバイス番号: 【$deviceNumber】'),
            const SizedBox(height: 16),
            const Text('デバイス番号を変更するには、アプリを再インストールしてください。'),
            const SizedBox(height: 16),
            Text('最終同期: ${_formatDateTime(lastSync)}'),
            const SizedBox(height: 4),
            Text('空き容量: ${_formatSize(lastFreeSpace)}'),
            const SizedBox(height: 16),
            Text('サービス状態: ${isServiceRunning ? "実行中" : "停止中"}'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _toggleService,
              icon: Icon(isServiceRunning ? Icons.stop : Icons.play_arrow),
              label: Text(isServiceRunning ? 'サービスを停止する' : 'サービスを開始する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isServiceRunning ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}