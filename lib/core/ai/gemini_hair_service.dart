import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'hair_ai_service.dart' show HairAiResult, HairAiStatus;

/// Real hair re-rendering via Google Gemini's image models (a.k.a. "nano
/// banana"). Sends the user's photo + an instruction to change ONLY the hair,
/// and returns the edited photo.
///
/// The key is supplied at runtime (pasted in-app) and sent as the `?key=`
/// query param — Google's Generative Language API allows browser (CORS) calls,
/// so no proxy is needed for a personal build. Use a restricted key, since a
/// web build's key is visible to users.
class GeminiHairService {
  GeminiHairService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 60);

  /// Image-capable models to try, in order. `modalities` is sent as
  /// `responseModalities` (empty = omit — the 2.5 image models output an image
  /// by default; the 2.0 preview model requires TEXT+IMAGE).
  static const List<Map<String, Object>> _models = [
    {'model': 'gemini-2.5-flash-image', 'modalities': <String>[]},
    {'model': 'gemini-2.5-flash-image-preview', 'modalities': <String>[]},
    {
      'model': 'gemini-2.0-flash-preview-image-generation',
      'modalities': ['TEXT', 'IMAGE'],
    },
  ];

  /// Instruction for the model — hair only, identity preserved, photoreal.
  static String prompt(String hairstyle, String color) =>
      'Edit this photo of a person: change ONLY the hair to a realistic '
      '$color $hairstyle haircut. Keep the exact same face, identity, skin '
      'tone, facial features, expression, body, lighting and background. '
      'Do not change anything except the hair. Return a photorealistic '
      'photograph, not an illustration or cartoon.';

  Future<HairAiResult> generate({
    required Uint8List photo,
    required String apiKey,
    required String prompt,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) return const HairAiResult(HairAiStatus.notConfigured);

    var lastError = 'The AI didn\'t return an image.';
    for (final m in _models) {
      HairAiResult res;
      try {
        res = await _tryModel(
          m['model'] as String,
          m['modalities'] as List,
          photo,
          key,
          prompt,
        );
      } on TimeoutException {
        return const HairAiResult(HairAiStatus.timeout,
            message: 'The AI took too long. Try again.');
      } catch (_) {
        return const HairAiResult(HairAiStatus.failed,
            message: 'Could not reach the AI. Check your key and connection.');
      }
      if (res.ok) return res;
      if (res.message != null) lastError = res.message!;
      // A bad key / billing / quota problem won't be fixed by another model.
      if (_isFatal(lastError)) break;
    }
    return HairAiResult(HairAiStatus.failed, message: lastError);
  }

  Future<HairAiResult> _tryModel(
    String model,
    List modalities,
    Uint8List photo,
    String key,
    String prompt,
  ) async {
    // Key goes in the x-goog-api-key HEADER, never the URL query string —
    // query strings get logged by proxies/crash-reporters far more than headers.
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent',
    );
    final body = <String, dynamic>{
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': _mimeOf(photo),
                'data': base64Encode(photo),
              },
            },
          ],
        },
      ],
    };
    if (modalities.isNotEmpty) {
      body['generationConfig'] = {'responseModalities': modalities};
    }

    final res = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': key,
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      return HairAiResult(HairAiStatus.failed, message: _errorOf(res));
    }

    final decoded = jsonDecode(res.body);
    final block = decoded['promptFeedback']?['blockReason'];
    if (block is String) {
      return HairAiResult(HairAiStatus.failed,
          message: 'Blocked ($block) — try a clearer, front-facing selfie.');
    }
    final image = _extractImage(decoded);
    if (image != null) return HairAiResult(HairAiStatus.success, image: image);
    return const HairAiResult(HairAiStatus.failed,
        message: 'The model returned text only — no image.');
  }

  /// Pull the first inline image out of a Gemini generateContent response.
  Uint8List? _extractImage(dynamic body) {
    try {
      final candidates = body['candidates'];
      if (candidates is List) {
        for (final c in candidates) {
          final parts = c['content']?['parts'];
          if (parts is List) {
            for (final part in parts) {
              final inline = part['inlineData'] ?? part['inline_data'];
              if (inline is Map) {
                final data = inline['data'];
                if (data is String && data.isNotEmpty) {
                  return base64Decode(data);
                }
              }
            }
          }
        }
      }
    } catch (_) {
      // fall through
    }
    return null;
  }

  String _errorOf(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      final msg = body['error']?['message'];
      if (msg is String && msg.isNotEmpty) {
        // Trim very long API messages to something readable.
        return msg.length > 140 ? '${msg.substring(0, 140)}…' : msg;
      }
    } catch (_) {}
    return 'Service returned ${res.statusCode}.';
  }

  bool _isFatal(String message) {
    final m = message.toLowerCase();
    return m.contains('api key') ||
        m.contains('api_key') ||
        m.contains('permission') ||
        m.contains('denied') ||
        m.contains('billing') ||
        m.contains('quota') ||
        m.contains('exceeded') ||
        m.contains('invalid') ||
        m.contains('not enabled') ||
        m.contains('blocked');
  }

  /// Sniff the image format so the request's mime type is correct.
  String _mimeOf(Uint8List b) {
    if (b.length >= 4 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
    if (b.length >= 12 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  void dispose() => _client.close();
}
