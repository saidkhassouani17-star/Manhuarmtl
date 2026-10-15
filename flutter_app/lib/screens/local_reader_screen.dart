import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/local_cbz_service.dart';
import '../widgets/translated_manga_page.dart';

class LocalReaderScreen extends StatefulWidget {
  const LocalReaderScreen({super.key});

  @override
  State<LocalReaderScreen> createState() => _LocalReaderScreenState();
}

class _LocalReaderScreenState extends State<LocalReaderScreen> {
  final LocalCbzService _service = LocalCbzService();
  List<Uint8List> _cbzPages = [];
  bool _bulkAutoTranslate = false;
  bool _loading = false;

  Future<void> _pickImagesOrCbz() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['cbz', 'zip', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _loading = true);
      final firstPath = result.files.first.path!;
      if (firstPath.toLowerCase().endsWith('.cbz') ||
          firstPath.toLowerCase().endsWith('.zip')) {
        final pages = await _service.extractImagesFromCbz(File(firstPath));
        setState(() {
          _cbzPages = pages;
          _loading = false;
        });
      } else {
        final List<Uint8List> imgs = [];
        for (final f in result.files) {
          if (f.path != null) {
            imgs.add(await File(f.path!).readAsBytes());
          }
        }
        setState(() {
          _cbzPages = imgs;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade900,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickImagesOrCbz,
                  icon: const Icon(Icons.folder_open),
                  label: const Text(
                      'اختر ملف فصل (CBZ / ZIP) أو صور مانهوا من جهازك'),
                ),
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'ترجمة جميع صفحات الفصل تلقائياً عبر Kaggle GPU',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                value: _bulkAutoTranslate,
                activeColor: Colors.cyanAccent,
                onChanged: (val) => setState(() => _bulkAutoTranslate = val),
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(color: Colors.cyanAccent),
        Expanded(
          child: _cbzPages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'قم باختيار ملف CBZ/ZIP أو صور مانهوا من هاتفك لتجربة مسح النص (Inpainting) والترجمة الحقيقية عبر سيرفر Kaggle!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _cbzPages.length,
                  itemBuilder: (context, index) {
                    return TranslatedMangaPage(
                      pageId:
                          'real_local_page_${index}_${_cbzPages[index].length}',
                      memoryImageBytes: _cbzPages[index],
                      autoTranslate: _bulkAutoTranslate,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
