import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../utils/preferences.dart';
import '../services/foreground_task_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int? selectedDeviceNumber;
  bool isSaving = false;

  // デバイス番号のリスト（1～34）
  final List<int> deviceNumbers = List.generate(34, (index) => index + 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('初期設定'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'デバイス番号の設定',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'このデバイスに割り当てる番号を選択してください。この番号は空き容量管理システムで使用されます。',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<int>(
                        hint: const Text('デバイス番号を選択'),
                        items: deviceNumbers
                            .map((item) => DropdownMenuItem<int>(
                                  value: item,
                                  child: Text(
                                    '【$item】',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ))
                            .toList(),
                        value: selectedDeviceNumber,
                        onChanged: (value) {
                          setState(() {
                            selectedDeviceNumber = value;
                          });
                        },
                        // 新しいAPI仕様に合わせたスタイル設定
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 300,
                          width: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // 新しいボタンスタイル
                        buttonStyleData: const ButtonStyleData(
                          height: 50,
                          width: double.infinity,
                        ),
                        // 新しいメニューアイテムスタイル
                        menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: selectedDeviceNumber == null || isSaving
                  ? null
                  : () => _saveSettings(),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '設定を保存',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '設定が完了すると、アプリはバックグラウンドでデバイスの空き容量を監視します。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '通知をスワイプしてサービスを停止しないようにしてください。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 設定を保存する処理
  Future<void> _saveSettings() async {
    if (selectedDeviceNumber == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      // デバイス番号を保存
      await PreferencesUtil.saveDeviceNumber(selectedDeviceNumber!);
      
      // セットアップ完了フラグを設定
      await PreferencesUtil.setSetupCompleted(true);
      
      // フォアグラウンドサービスを開始
      await initForegroundTask();

      // メイン画面に遷移
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定の保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }
}