import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_config.dart';

/// Outcome of a realistic hair-generation request.
enum HairAiStatus { notConfigured, success, failed, timeout }

class HairAiResult {
  const HairAiResult(this.status, {this.image, this.message});
  final HairAiStatus status;
  final Uint8List? image; // the edited photo, when status == success
  final String? message;

  bool get ok => status == HairAiStatus.success && image != null;
}

/// Calls a cloud AI to re-render the hair in a real photo.
///
/// Request  (POST [AiConfig.endpoint], JSON):
///   { "image": "<base64 jpeg/png>", "hairstyle": "Pompadour",
///     "color": "Brown", "prompt": "<readable instruction>" }
/// Response (JSON), any one of:
///   { "image":     "<base64 of the edited photo>" }
///   { "image_url": "https://…/result.png" }
///
/// This shape is deliberately simple so it maps onto a tiny proxy in front of
/// Replicate / Stability / an AI-hairstyle API. No key shipped → returns
/// [HairAiStatus.notConfigured] and the UI shows the connect-AI state.
class HairAiService {
  HairAiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<HairAiResult> generate({
    required Uint8List photo,
    required String hairstyle,
    required String color,
    required String prompt,
    String? endpoint,
    String? apiKey,
    Uint8List? mask,
  }) async {
    // Runtime endpoint (e.g. a pasted Cloudflare worker URL) overrides the
    // compile-time one. Auth header is sent only when a key is present —
    // a personal worker can be keyless.
    final ep = (endpoint ?? AiConfig.endpoint).trim();
    if (ep.isEmpty) {
      return const HairAiResult(HairAiStatus.notConfigured);
    }
    final key = (apiKey ?? AiConfig.apiKey).trim();

    try {
      final res = await _client
          .post(
            Uri.parse(ep),
            headers: {
              'Content-Type': 'application/json',
              if (key.isNotEmpty) 'Authorization': 'Bearer $key',
            },
            body: jsonEncode({
              'image': base64Encode(photo),
              if (mask != null) 'mask': base64Encode(mask),
              'hairstyle': hairstyle,
              'color': color,
              'prompt': prompt,
            }),
          )
          .timeout(const Duration(seconds: AiConfig.timeoutSeconds));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return HairAiResult(HairAiStatus.failed,
            message: 'Service returned ${res.statusCode}');
      }

      final body = jsonDecode(res.body);
      if (body is! Map) {
        return const HairAiResult(HairAiStatus.failed,
            message: 'Unexpected response');
      }

      // Inline base64 image.
      final inline = body['image'];
      if (inline is String && inline.isNotEmpty) {
        return HairAiResult(HairAiStatus.success,
            image: base64Decode(_stripDataUri(inline)));
      }

      // Or a URL to fetch.
      final url = body['image_url'];
      if (url is String && url.isNotEmpty) {
        final img = await _client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: AiConfig.timeoutSeconds));
        if (img.statusCode == 200) {
          return HairAiResult(HairAiStatus.success, image: img.bodyBytes);
        }
      }

      return const HairAiResult(HairAiStatus.failed,
          message: 'No image in response');
    } on TimeoutException {
      return const HairAiResult(HairAiStatus.timeout,
          message: 'The AI took too long. Try again.');
    } catch (e) {
      return HairAiResult(HairAiStatus.failed, message: 'Could not reach the AI.');
    }
  }

  /// Strip a `data:image/...;base64,` prefix if the API returns one.
  String _stripDataUri(String s) {
    final i = s.indexOf('base64,');
    return i >= 0 ? s.substring(i + 7) : s;
  }

  /// Build a natural-language instruction for the model.
  static String prompt(String hairstyle, String color) =>
      'Replace only the hair with a realistic $color $hairstyle. '
      'Keep the same face, skin, lighting and background. Photorealistic.';

  void dispose() => _client.close();
}
