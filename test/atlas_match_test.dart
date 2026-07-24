import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/reader/maps/bible_map_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('atlas loads and matches place words (KJV spellings too)', () async {
    final d = await BibleGeo.ensureLoaded();
    expect(d.places, isNotEmpty);
    expect(d.land, isNotEmpty);

    expect(BibleGeo.match(['Nineveh']), isNotNull);
    expect(BibleGeo.match(['Jerusalem']), isNotNull);
    expect(BibleGeo.match(['Capernaum']), isNotNull);
    // KJV alias for Pergamum.
    expect(BibleGeo.match(['Pergamos']), isNotNull);
    // Punctuation should be stripped.
    expect(BibleGeo.match(['Bethlehem,']), isNotNull);
    // A helper word should not match.
    expect(BibleGeo.match(['the']), isNull);
  });
}
