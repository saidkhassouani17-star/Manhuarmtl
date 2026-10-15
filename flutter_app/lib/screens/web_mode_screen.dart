import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/translation_cache_service.dart';

class WebModeScreen extends StatefulWidget {
  const WebModeScreen({super.key});

  @override
  State<WebModeScreen> createState() => _WebModeScreenState();
}

class _WebModeScreenState extends State<WebModeScreen> {
  InAppWebViewController? _controller;
  final TextEditingController _urlController =
      TextEditingController(text: 'https://manhuaus.com');
  double _progress = 0;

  Future<void> _injectMadomiScript(InAppWebViewController controller) async {
    final jsCode = await rootBundle.loadString('assets/js/injector.js');
    await controller.evaluateJavascript(source: jsCode);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'أدخل رابط موقع المانهوا...',
                    prefixIcon: const Icon(Icons.public, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    final url = val.startsWith('http') ? val : 'https://$val';
                    _controller?.loadUrl(
                        urlRequest: URLRequest(url: WebUri(url)));
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'تفعيل زر الترجمة فوق الصور',
                icon: const Icon(Icons.bolt, color: Colors.cyanAccent),
                onPressed: () {
                  if (_controller != null) {
                    _injectMadomiScript(_controller!);
                  }
                },
              ),
            ],
          ),
        ),
        if (_progress < 1.0)
          LinearProgressIndicator(value: _progress, color: Colors.cyanAccent),
        Expanded(
          child: InAppWebView(
            initialUrlRequest:
                URLRequest(url: WebUri(_urlController.text.trim())),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
              controller.addJavaScriptHandler(
                handlerName: 'translateImage',
                callback: (args) async {
                  try {
                    final imgUrl = args.isNotEmpty ? args[0].toString() : '';
                    final res =
                        await TranslationCacheService.instance.translatePage(
                      cacheKeyId: imgUrl,
                      imageUrl: imgUrl,
                    );
                    return {
                      'status': 'success',
                      'cleanedImageBase64': res.cleanedImageBase64,
                      'bubblesCount': res.bubbles.length,
                      'bubbles': res.bubbles.map((b) => b.toJson()).toList(),
                    };
                  } catch (e) {
                    return {'status': 'error', 'message': e.toString()};
                  }
                },
              );
            },
            onLoadStop: (controller, url) async {
              if (url != null) {
                _urlController.text = url.toString();
              }
              await _injectMadomiScript(controller);
            },
            onProgressChanged: (_, progress) {
              setState(() => _progress = progress / 100);
            },
          ),
        ),
      ],
    );
  }
}
