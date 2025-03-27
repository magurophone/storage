import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // サーバーのURL（実際の環境に合わせて変更）
  static const String apiUrl = 'https://example.com/api/receive_data.php';
  
  // リトライ回数
  static const int maxRetry = 2;
  
  // リトライ間隔（ミリ秒）
  static const int retryInterval = 5000;
  
  // ストレージデータを送信（シンプル化）
  static Future<bool> sendStorageData({
    required int deviceNumber,
    required int freeSpace,
  }) async {
    // JSONデータの作成（デバイス番号と空き容量のみ）
    final data = {
      'device_number': deviceNumber,
      'free_space': freeSpace,
    };
    
    // リトライロジック
    for (int i = 0; i <= maxRetry; i++) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          return responseData['status'] == 'success';
        }
      } catch (e) {
        print('API呼び出しエラー (試行 ${i+1}/${maxRetry+1}): $e');
        
        // 最後の試行でなければ待機して再試行
        if (i < maxRetry) {
          await Future.delayed(Duration(milliseconds: retryInterval));
        }
      }
    }
    
    return false;
  }
}