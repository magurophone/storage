import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // サーバーのURL - ローカルで実行している場合はエミュレータからホストマシンへの特殊なIPを使用
  static const String apiUrl = 'http://10.0.2.2/storage_monitor/public/receive_data.php';

  // リトライ回数
  static const int maxRetry = 2;

  // リトライ間隔（ミリ秒）
  static const int retryInterval = 5000;

  // ストレージデータを送信
  static Future<bool> sendStorageData({
    required int deviceNumber,
    required int freeSpace,
  }) async {
    // JSONデータの作成（デバイス番号と空き容量のみ）
    final data = {
      'device_number': deviceNumber,
      'free_space': freeSpace,
    };

    print('APIサービス: 送信開始 - $data');

    // リトライロジック
    for (int i = 0; i <= maxRetry; i++) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );

        print('APIサービス: ステータスコード - ${response.statusCode}');
        print('APIサービス: レスポンスボディ - ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          return responseData['status'] == 'success';
        }
      } catch (e) {
        print('APIサービス: 呼び出しエラー (試行 ${i+1}/${maxRetry+1}): $e');

        // 最後の試行でなければ待機して再試行
        if (i < maxRetry) {
          await Future.delayed(Duration(milliseconds: retryInterval));
        }
      }
    }

    return false;
  }
}