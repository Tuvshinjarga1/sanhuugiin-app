import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  // Жинхэнэ апп хөгжүүлэлтэд API түлхүүрийг environment variables эсвэл secure storage-д хадгална
  static const String apiKey = 'api_key_here';

  Future<String> getFinancialAdvice(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Чи миний санхүүгийн зөвлөгч AI туслах болж ажиллана. '
                      'Би санхүүгийн асуултуудад хариулт авахыг хүсэж байна. '
                      'Хэрэв миний асуулт санхүүтэй холбоогүй бол санхүүгийн чиглэлийн асуулт асуухыг сануулаарай. '
                      'Монгол хэл дээр хариултыг өгнө үү.\n\n'
                      'Миний асуулт: $query'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print('API алдаа: ${response.statusCode}');
        print('Хариу: ${response.body}');
        return 'Уучлаарай, хариулт авахад алдаа гарлаа. Алдааны код: ${response.statusCode}';
      }
    } catch (e) {
      print('Алдаа: $e');
      return 'Уучлаарай, хариулт авахад техникийн алдаа гарлаа.';
    }
  }
}
