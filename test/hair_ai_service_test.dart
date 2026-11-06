import 'dart:convert';
import 'dart:typed_data';

import 'package:barber_app/core/ai/hair_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// The free model sometimes answers HTTP 200 with a solid black ~1 KB PNG.
// The app used to show that black picture as the result; it now retries.
void main() {
  final blank = Uint8List(842); // the size of a real black frame we got back
  final real = Uint8List(340000); // a real edit is hundreds of KB

  http.Response reply(Uint8List img) =>
      http.Response(jsonEncode({'image': base64Encode(img)}), 200);

  test('a blank frame is retried and the real one is shown', () async {
    var n = 0;
    final svc = HairAiService(
      client: MockClient((_) async => reply(n++ == 0 ? blank : real)),
    );
    final res = await svc.generate(
      photo: Uint8List(10),
      mask: Uint8List(10),
      hairstyle: 'Crop',
      color: 'Brown',
      prompt: 'p',
      endpoint: 'https://example.test',
    );
    expect(res.ok, isTrue);
    expect(res.image!.length, real.length);
    expect(n, 2);
  });

  test('only blank frames: a failure, never a black picture', () async {
    var n = 0;
    final svc = HairAiService(
      client: MockClient((_) async {
        n++;
        return reply(blank);
      }),
    );
    final res = await svc.generate(
      photo: Uint8List(10),
      mask: Uint8List(10),
      hairstyle: 'Crop',
      color: 'Brown',
      prompt: 'p',
      endpoint: 'https://example.test',
    );
    expect(res.ok, isFalse);
    expect(n, HairAiService.blankRetries + 1);
  });

  test('a real server error is not retried', () async {
    var n = 0;
    final svc = HairAiService(
      client: MockClient((_) async {
        n++;
        return http.Response('{"error":"x"}', 502);
      }),
    );
    final res = await svc.generate(
      photo: Uint8List(10),
      mask: Uint8List(10),
      hairstyle: 'Crop',
      color: 'Brown',
      prompt: 'p',
      endpoint: 'https://example.test',
    );
    expect(res.status, HairAiStatus.failed);
    expect(n, 1);
  });
}
