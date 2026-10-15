import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/anilist_glossary_service.dart';
import '../services/translation_cache_service.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final AniListGlossaryService _aniList = AniListGlossaryService();
  final TextEditingController _searchController =
      TextEditingController(text: 'Magic Emperor');
  List<GlossaryCharacter> _characters = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchGlossary();
  }

  Future<void> _fetchGlossary() async {
    setState(() => _loading = true);
    final chars = await _aniList
        .fetchCharactersByMangaTitle(_searchController.text.trim());
    TranslationCacheService.instance.activeGlossary = chars;
    if (mounted) {
      setState(() {
        _characters = chars;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'ابحث عن المانهوا في AniList لبناء القاموس',
                    prefixIcon: const Icon(Icons.auto_stories),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onSubmitted: (_) => _fetchGlossary(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _fetchGlossary,
                icon: const Icon(Icons.cloud_download),
                label: const Text('سحب الأسماء'),
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(color: Colors.cyanAccent),
        Expanded(
          child: ListView.builder(
            itemCount: _characters.length,
            itemBuilder: (context, index) {
              final char = _characters[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                color: Colors.grey.shade900,
                child: ListTile(
                  title: Text(char.originalName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Gender: ${char.gender}'),
                  trailing: SizedBox(
                    width: 155,
                    child: TextFormField(
                      initialValue: char.translatedName,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        labelText: 'الترجمة العربية',
                        isDense: true,
                      ),
                      onChanged: (val) => char.translatedName = val,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
