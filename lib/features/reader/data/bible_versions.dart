import 'package:shared_preferences/shared_preferences.dart';

/// A selectable English Bible translation. [id] is the wldeh/bible-api edition
/// slug used to build chapter URLs; [abbrev] is the short label shown in the
/// reader pill; [name] is the full title shown in the picker.
class BibleVersion {
  const BibleVersion({
    required this.id,
    required this.abbrev,
    required this.name,
    required this.blurb,
  });

  final String id;
  final String abbrev;
  final String name;

  /// A one-line character note shown in the picker.
  final String blurb;
}

/// The default translation the reader opens with.
const String kDefaultVersionId = 'en-kjv';

/// Ten freely-usable / public-domain English translations, all verified to
/// resolve for both Old and New Testament in the upstream dataset.
const List<BibleVersion> kBibleVersions = [
  BibleVersion(
    id: 'en-kjv',
    abbrev: 'KJV',
    name: 'King James Version',
    blurb: 'The classic 1769 Authorized text.',
  ),
  BibleVersion(
    id: 'en-web',
    abbrev: 'WEB',
    name: 'World English Bible',
    blurb: 'Modern, readable public-domain update of the ASV.',
  ),
  BibleVersion(
    id: 'en-bsb',
    abbrev: 'BSB',
    name: 'Berean Study Bible',
    blurb: 'Contemporary and accurate, freely licensed.',
  ),
  BibleVersion(
    id: 'en-asv',
    abbrev: 'ASV',
    name: 'American Standard Version',
    blurb: 'Precise, formal 1901 translation.',
  ),
  BibleVersion(
    id: 'en-fbv',
    abbrev: 'FBV',
    name: 'Free Bible Version',
    blurb: 'Clear modern English from the original languages.',
  ),
  BibleVersion(
    id: 'en-lsv',
    abbrev: 'LSV',
    name: 'Literal Standard Version',
    blurb: 'A very literal, word-for-word rendering.',
  ),
  BibleVersion(
    id: 'en-webbe',
    abbrev: 'WEBBE',
    name: 'World English Bible (British)',
    blurb: 'The WEB with British spelling and phrasing.',
  ),
  BibleVersion(
    id: 'en-gnv',
    abbrev: 'GNV',
    name: 'Geneva Bible (1599)',
    blurb: 'The Bible of the Reformation and the Pilgrims.',
  ),
  BibleVersion(
    id: 'en-dra',
    abbrev: 'DRA',
    name: 'Douay-Rheims (1899)',
    blurb: 'Traditional Catholic translation.',
  ),
  BibleVersion(
    id: 'en-rv',
    abbrev: 'RV',
    name: 'Revised Version (1885)',
    blurb: 'The first major revision of the KJV.',
  ),
];

/// Resolves an edition slug to its [BibleVersion], falling back to KJV.
BibleVersion versionById(String? id) {
  for (final v in kBibleVersions) {
    if (v.id == id) return v;
  }
  return kBibleVersions.first;
}

/// Persists the reader's chosen translation across sessions.
class VersionStore {
  VersionStore._();

  static const _prefsKey = 'readerVersionId';

  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? kDefaultVersionId;
  }

  static Future<void> save(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
  }
}
