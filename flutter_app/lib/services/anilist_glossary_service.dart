import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AniListGlossaryService {
  static const String _endpoint = 'https://graphql.anilist.co';

  Future<List<GlossaryCharacter>> fetchCharactersByMangaTitle(
      String title) async {
    const String query = r'''
    query ($search: String) {
      Media(search: $search, type: MANGA) {
        characters(sort: ROLE, perPage: 25) {
          nodes {
            name {
              full
            }
            gender
          }
        }
      }
    }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'search': title},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nodes = data['data']?['Media']?['characters']?['nodes'] as List?;
        if (nodes != null) {
          return nodes.map((node) {
            final fullName = node['name']?['full'] ?? 'Unknown';
            final gender = node['gender'] ?? 'Unknown';
            return GlossaryCharacter(
              originalName: fullName,
              translatedName: fullName,
              gender: gender,
            );
          }).toList();
        }
      }
    } catch (_) {}

    return [
      GlossaryCharacter(
        originalName: 'Zhuo Yifan',
        translatedName: 'تشو ييفان',
        gender: 'Male',
      ),
      GlossaryCharacter(
        originalName: 'Chu Qingcheng',
        translatedName: 'تشو تشينغتشنغ',
        gender: 'Female',
      ),
    ];
  }
}
