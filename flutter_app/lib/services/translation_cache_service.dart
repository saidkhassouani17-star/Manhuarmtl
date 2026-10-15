import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class TranslationCacheService {
  static final TranslationCacheService instance = TranslationCacheService._();
  TranslationCacheService._();

  /// ضع رابط Cloudflare الناتج من Kaggle هنا من داخل واجهة التطبيق
  String kaggleServerUrl = '';
  String geminiApiKey = '';
  List<GlossaryCharacter> activeGlossary = [];

  final Map<String, TranslatedPageResult> _memoryCache = {};

  String _hashKey(String sourceId) {
    return md5.convert(utf8.encode(sourceId)).toString();
  }

  Future<File> _getCacheFile(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/madomi_real_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/$key.json');
  }

  Future<TranslatedPageResult> translatePage({
    required String cacheKeyId,
    Uint8List? imageBytes,
    String? imageUrl,
  }) async {
    final key = _hashKey(cacheKeyId);

    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!;
    }

    final cacheFile = await _getCacheFile(key);
    if (await cacheFile.exists()) {
      final raw = await cacheFile.readAsString();
      final result = TranslatedPageResult.fromJson(jsonDecode(raw));
      _memoryCache[key] = result;
      return result;
    }

    if (kaggleServerUrl.trim().isEmpty) {
      throw Exception('يرجى إدخال رابط سيرفر Kaggle في أعلى التطبيق أولاً');
    }

    final endpoint =
        '${kaggleServerUrl.trim().replaceAll(RegExp(r'/$'), '')}/translate_page';

    final payload = {
      'image_base64': imageBytes != null ? base64Encode(imageBytes) : null,
      'image_url': imageUrl,
      'glossary': activeGlossary.map((g) => g.toJson()).toList(),
      'gemini_api_key': geminiApiKey.trim(),
    };

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final bubbles = (decoded['bubbles'] as List? ?? [])
          .map((b) => TextBubble.fromJson(b))
          .toList();

      final result = TranslatedPageResult(
        cleanedImageBase64: decoded['cleaned_image_base64'],
        bubbles: bubbles,
      );

      _memoryCache[key] = result;
      await cacheFile.writeAsString(jsonEncode(result.toJson()));
      return result;
    } else {
      throw Exception('خطأ من سيرفر Kaggle: ${response.statusCode}');
    }
  }

  Future<void> clearAllCache() async {
    _memoryCache.clear();
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/madomi_real_cache');
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }
}
