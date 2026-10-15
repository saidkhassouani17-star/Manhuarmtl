import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/translation_cache_service.dart';

class TranslatedMangaPage extends StatefulWidget {
  final String pageId;
  final Uint8List? memoryImageBytes;
  final String? networkImageUrl;
  final bool autoTranslate;

  const TranslatedMangaPage({
    super.key,
    required this.pageId,
    this.memoryImageBytes,
    this.networkImageUrl,
    this.autoTranslate = false,
  });

  @override
  State<TranslatedMangaPage> createState() => _TranslatedMangaPageState();
}

class _TranslatedMangaPageState extends State<TranslatedMangaPage> {
  TranslatedPageResult? _result;
  Uint8List? _cleanedBytes;
  bool _isTranslating = false;
  bool _showOriginal = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.autoTranslate) {
      _runTranslation();
    }
  }

  Future<void> _runTranslation() async {
    setState(() {
      _isTranslating = true;
      _errorMsg = null;
    });
    try {
      final res = await TranslationCacheService.instance.translatePage(
        cacheKeyId: widget.pageId,
        imageBytes: widget.memoryImageBytes,
        imageUrl: widget.networkImageUrl,
      );
      Uint8List? decodedClean;
      if (res.cleanedImageBase64 != null &&
          res.cleanedImageBase64!.isNotEmpty) {
        decodedClean = base64Decode(res.cleanedImageBase64!);
      }
      if (mounted) {
        setState(() {
          _result = res;
          _cleanedBytes = decodedClean;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll('Exception: ', '');
          _isTranslating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * 1.42;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: _buildDisplayedImage()),
              if (_result != null && !_showOriginal)
                ..._result!.bubbles.map((b) => Positioned(
                      left: b.x * width,
                      top: b.y * height,
                      width: b.w * width,
                      height: b.h * height,
                      child: _buildTypesetText(b.translatedText),
                    )),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    if (_result != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FloatingActionButton.small(
                          heroTag: '${widget.pageId}_eye',
                          backgroundColor: Colors.black87,
                          onPressed: () =>
                              setState(() => _showOriginal = !_showOriginal),
                          child: Icon(
                            _showOriginal
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: _result != null
                            ? Colors.greenAccent
                            : Colors.cyanAccent,
                      ),
                      onPressed: _isTranslating ? null : _runTranslation,
                      icon: _isTranslating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.amberAccent,
                              ),
                            )
                          : Icon(_result != null
                              ? Icons.check_circle
                              : Icons.translate),
                      label: Text(
                        _isTranslating
                            ? 'جاري المسح (Kaggle GPU)...'
                            : (_result != null
                                ? 'مترجم (${_result!.bubbles.length})'
                                : 'ترجم الصفحة'),
                      ),
                    ),
                  ],
                ),
              ),
              if (_errorMsg != null)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisplayedImage() {
    if (!_showOriginal && _cleanedBytes != null) {
      return Image.memory(_cleanedBytes!, fit: BoxFit.fill);
    }
    if (widget.memoryImageBytes != null) {
      return Image.memory(widget.memoryImageBytes!, fit: BoxFit.fill);
    }
    if (widget.networkImageUrl != null) {
      return Image.network(widget.networkImageUrl!, fit: BoxFit.fill);
    }
    return const SizedBox();
  }

  /// يكتب النص العربي فوق الصورة الممسوحة (Cleaned Inpainted Image) مع Stroke واضح
  Widget _buildTypesetText(String arabicText) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Stack(
            children: [
              Text(
                arabicText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3.5
                    ..color = Colors.white,
                ),
              ),
              Text(
                arabicText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
