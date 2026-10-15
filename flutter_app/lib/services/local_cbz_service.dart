import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';

class LocalCbzService {
  Future<List<Uint8List>> extractImagesFromCbz(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final imageEntries = archive.files.where((f) {
      if (!f.isFile) return false;
      final lower = f.name.toLowerCase();
      return lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp');
    }).toList();

    imageEntries.sort((a, b) => a.name.compareTo(b.name));

    return imageEntries
        .map((entry) => Uint8List.fromList(entry.content as List<int>))
        .toList();
  }
}
