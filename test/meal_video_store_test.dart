import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/meal_video_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'meal_edit_pending_path';

void main() {
  late Directory root;
  late Directory outside;
  late SharedPreferences prefs;
  late MealVideoStore store;

  File touch(String path) {
    final f = File(path);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync('x');
    return f;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    root = Directory.systemTemp.createTempSync('mvs_root_');
    outside = Directory.systemTemp.createTempSync('mvs_out_');
    store = MealVideoStore(prefs: prefs, roots: () async => [root.path]);
  });

  tearDown(() {
    for (final d in [root, outside]) {
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
  });

  test('kök dışındaki dosya asla silinmez', () async {
    final f = touch('${outside.path}/user.mp4');
    expect(await store.isOwned(f.path), isFalse);
    await store.discard(f.path);
    expect(f.existsSync(), isTrue);
  });

  test("'..' ile kökten çıkan yol sahipli sayılmaz ve silinmez", () async {
    final f = touch('${outside.path}/user.mp4');
    final sneaky =
        '${root.path}/../${outside.uri.pathSegments.where((s) => s.isNotEmpty).last}/user.mp4';
    expect(await store.isOwned(sneaky), isFalse);
    await store.discard(sneaky);
    expect(f.existsSync(), isTrue);
  });

  test('sahipli dosya küçük resmiyle silinir ve boş üst klasör kalkar',
      () async {
    final f = touch('${root.path}/uuid/clip.mp4');
    final thumb = touch('${root.path}/uuid/clip.mp4.png');
    expect(await store.isOwned(f.path), isTrue);
    await store.discard(f.path);
    expect(f.existsSync(), isFalse);
    expect(thumb.existsSync(), isFalse);
    expect(Directory('${root.path}/uuid').existsSync(), isFalse);
  });

  test('üst klasör kökün kendisiyse klasör silinmez', () async {
    final f = touch('${root.path}/clip.mp4');
    await store.discard(f.path);
    expect(f.existsSync(), isFalse);
    expect(root.existsSync(), isTrue);
  });

  test('sweepOrphan bekleyen dosyayı siler ve anahtarı kaldırır', () async {
    final f = touch('${root.path}/old.mp4');
    await store.markPending(f.path);
    expect(prefs.getString(_key), f.path);
    await store.sweepOrphan();
    expect(f.existsSync(), isFalse);
    expect(prefs.containsKey(_key), isFalse);
  });

  test('sweepOrphan except ile eşleşen dosyaya dokunmaz', () async {
    final f = touch('${root.path}/cur.mp4');
    await store.markPending(f.path);
    await store.sweepOrphan(except: '${root.path}/./cur.mp4');
    expect(f.existsSync(), isTrue);
    expect(prefs.getString(_key), f.path);
    await store.clearPending();
    expect(prefs.containsKey(_key), isFalse);
  });

  test('var olmayan yol için discard fırlatmaz', () async {
    await store.discard('${root.path}/yok.mp4');
    await store.discard('');
  });
}
