// Guards the one class of breakage that only a RELEASE build reveals.
//
// Two files sharing a resource name inside a single res/ folder — say
// ic_stat_fade.png next to ic_stat_fade.xml in drawable/ — fail Android's
// `mergeReleaseResources` task with "Duplicate resources". Neither
// `flutter analyze` nor a debug run notices, so the first symptom is a failed
// upload build on launch day. That is exactly what happened here: an asset
// generator in the test suite kept re-emitting a PNG that a vector drawable had
// replaced, so every `flutter test` run quietly re-broke `flutter build
// appbundle`.
//
// This test costs milliseconds and closes that hole permanently.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no duplicate resource names within an Android res/ folder', () {
    final res = Directory('android/app/src/main/res');
    expect(res.existsSync(), isTrue, reason: 'android res/ folder is missing');

    final clashes = <String>[];

    for (final folder in res.listSync().whereType<Directory>()) {
      // Android identifies a resource by folder + filename WITHOUT extension,
      // so ic_stat_fade.png and ic_stat_fade.xml are one name declared twice.
      final byName = <String, List<String>>{};
      for (final f in folder.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        final stem = name.contains('.') ? name.split('.').first : name;
        byName.putIfAbsent(stem, () => []).add(name);
      }
      byName.forEach((stem, files) {
        if (files.length > 1) {
          files.sort();
          clashes.add('${folder.uri.pathSegments.reversed.elementAt(1)}/'
              '$stem -> ${files.join(' + ')}');
        }
      });
    }

    expect(
      clashes,
      isEmpty,
      reason: 'Duplicate Android resources will fail mergeReleaseResources '
          'and block the release build:\n  ${clashes.join('\n  ')}',
    );
  });
}
