import 'package:flutter/material.dart';
import 'screens/glossary_screen.dart';
import 'screens/local_reader_screen.dart';
import 'screens/web_mode_screen.dart';
import 'services/translation_cache_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MadomiCloneApp());
}

class MadomiCloneApp extends StatelessWidget {
  const MadomiCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Madomi AI Reader (Kaggle Edition)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.cyanAccent.shade400,
          secondary: Colors.amberAccent,
        ),
      ),
      home: const MainHomeShell(),
    );
  }
}

class MainHomeShell extends StatefulWidget {
  const MainHomeShell({super.key});

  @override
  State<MainHomeShell> createState() => _MainHomeShellState();
}

class _MainHomeShellState extends State<MainHomeShell> {
  int _selectedIndex = 1;

  void _openKaggleSettingsDialog() {
    final urlCtrl = TextEditingController(
        text: TranslationCacheService.instance.kaggleServerUrl);
    final keyCtrl = TextEditingController(
        text: TranslationCacheService.instance.geminiApiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعدادات سيرفر Kaggle GPU'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'رابط Cloudflare Tunnel من Kaggle',
                hintText: 'https://xxxx.trycloudflare.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key (اختياري للترجمة السياقية)',
                hintText: 'اتركه فارغاً لاستخدام المترجم المجاني المدمج',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                TranslationCacheService.instance.kaggleServerUrl =
                    urlCtrl.text.trim();
                TranslationCacheService.instance.geminiApiKey =
                    keyCtrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('حفظ الاتصال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected =
        TranslationCacheService.instance.kaggleServerUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Madomi AI + Kaggle'),
        actions: [
          TextButton.icon(
            onPressed: _openKaggleSettingsDialog,
            icon: Icon(
              Icons.cloud_done,
              color: connected ? Colors.greenAccent : Colors.orangeAccent,
            ),
            label: Text(
              connected ? 'Kaggle متصل' : 'ربط Kaggle URL',
              style: TextStyle(
                color: connected ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          WebModeScreen(),
          LocalReaderScreen(),
          GlossaryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.public), label: 'Web Mode'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_rounded), label: 'Local Reader'),
          NavigationDestination(
              icon: Icon(Icons.people_alt_rounded), label: 'Glossary'),
        ],
      ),
    );
  }
}
