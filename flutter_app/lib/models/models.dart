class GlossaryCharacter {
  final String originalName;
  String translatedName;
  final String gender;

  GlossaryCharacter({
    required this.originalName,
    required this.translatedName,
    required this.gender,
  });

  Map<String, dynamic> toJson() => {
        'originalName': originalName,
        'translatedName': translatedName,
        'gender': gender,
      };

  factory GlossaryCharacter.fromJson(Map<String, dynamic> json) =>
      GlossaryCharacter(
        originalName: json['originalName'] ?? '',
        translatedName: json['translatedName'] ?? '',
        gender: json['gender'] ?? 'Unknown',
      );
}

class TextBubble {
  final double x;
  final double y;
  final double w;
  final double h;
  final String originalText;
  final String translatedText;

  TextBubble({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.originalText,
    required this.translatedText,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'originalText': originalText,
        'translatedText': translatedText,
      };

  factory TextBubble.fromJson(Map<String, dynamic> json) => TextBubble(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        w: (json['w'] as num).toDouble(),
        h: (json['h'] as num).toDouble(),
        originalText: json['originalText'] ?? '',
        translatedText: json['translatedText'] ?? '',
      );
}

class TranslatedPageResult {
  final String? cleanedImageBase64;
  final List<TextBubble> bubbles;

  TranslatedPageResult({
    this.cleanedImageBase64,
    required this.bubbles,
  });

  Map<String, dynamic> toJson() => {
        'cleanedImageBase64': cleanedImageBase64,
        'bubbles': bubbles.map((e) => e.toJson()).toList(),
      };

  factory TranslatedPageResult.fromJson(Map<String, dynamic> json) =>
      TranslatedPageResult(
        cleanedImageBase64: json['cleanedImageBase64'],
        bubbles: (json['bubbles'] as List? ?? [])
            .map((e) => TextBubble.fromJson(e))
            .toList(),
      );
}
