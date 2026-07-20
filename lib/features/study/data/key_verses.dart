/// A genuine, public-domain Charles Spurgeon excerpt with its source, shown as
/// the devotional "depth" on a key-verse card. We only include excerpts we can
/// attribute accurately — never invented text. Where no verified Spurgeon
/// excerpt exists yet, the key-verse card falls back to Matthew Henry's note on
/// that verse (fetched live), so attribution always stays honest.
class SpurgeonExcerpt {
  const SpurgeonExcerpt({required this.text, required this.source});
  final String text;
  final String source;
}

/// A memorization target for a study — the verse the user works to internalize.
class KeyVerse {
  const KeyVerse({
    required this.ref,
    required this.book,
    required this.chapter,
    required this.verses,
    this.spurgeon,
  });

  /// Human display reference, e.g. "Philippians 4:6-7".
  final String ref;

  /// Reader book name + chapter this verse lives in, for fetching real text.
  final String book;
  final int chapter;

  /// Verse numbers that make up the key verse (contiguous).
  final List<int> verses;

  /// Optional verified Spurgeon reflection tied to this verse.
  final SpurgeonExcerpt? spurgeon;
}

/// Curated key verses per study, keyed by study title (lower-cased). Refs are
/// drawn from each study's anchor passage.
const Map<String, List<KeyVerse>> _kStudyKeyVerses = {
  // ── Topical studies ──
  'marriage': [
    KeyVerse(ref: 'Ephesians 5:25', book: 'Ephesians', chapter: 5, verses: [25]),
    KeyVerse(ref: 'Ephesians 5:33', book: 'Ephesians', chapter: 5, verses: [33]),
  ],
  'anxiety': [
    KeyVerse(ref: 'Philippians 4:6-7', book: 'Philippians', chapter: 4, verses: [6, 7]),
  ],
  'anger': [
    KeyVerse(ref: 'James 1:19-20', book: 'James', chapter: 1, verses: [19, 20]),
  ],
  'fear': [
    KeyVerse(
      ref: 'Psalm 23:4',
      book: 'Psalms',
      chapter: 23,
      verses: [4],
      spurgeon: SpurgeonExcerpt(
        text:
            'This is the pearl of Psalms, whose soft and pure radiance delights '
            'every eye. The position of this Psalm is worthy of notice. It '
            'follows the twenty-second, which is peculiarly the Psalm of the '
            'Cross. There are no green pastures, no still waters on the other '
            'side of the twenty-second Psalm. It is only after we have read, '
            '"My God, my God, why hast thou forsaken me?" that we come to "The '
            'Lord is my shepherd."',
        source: 'C. H. Spurgeon, The Treasury of David — Psalm 23',
      ),
    ),
  ],
  'hope': [
    KeyVerse(ref: 'Romans 15:13', book: 'Romans', chapter: 15, verses: [13]),
  ],
  'gratitude': [
    KeyVerse(ref: 'Psalm 100:4-5', book: 'Psalms', chapter: 100, verses: [4, 5]),
  ],
  'faith': [
    KeyVerse(ref: 'Hebrews 11:1', book: 'Hebrews', chapter: 11, verses: [1]),
  ],
  'forgiveness': [
    KeyVerse(ref: 'Colossians 3:13', book: 'Colossians', chapter: 3, verses: [13]),
  ],
  'joy': [
    KeyVerse(ref: 'Psalm 16:11', book: 'Psalms', chapter: 16, verses: [11]),
  ],
  'patience': [
    KeyVerse(ref: 'Romans 12:12', book: 'Romans', chapter: 12, verses: [12]),
  ],

  // ── Canonical books ──
  'genesis': [
    KeyVerse(ref: 'Genesis 1:1', book: 'Genesis', chapter: 1, verses: [1]),
  ],
  'exodus': [
    KeyVerse(ref: 'Exodus 14:14', book: 'Exodus', chapter: 14, verses: [14]),
  ],
  'psalms': [
    KeyVerse(
      ref: 'Psalm 23:1',
      book: 'Psalms',
      chapter: 23,
      verses: [1],
      spurgeon: SpurgeonExcerpt(
        text:
            '"The Lord is my shepherd." What condescension is this, that the '
            'infinite Lord assumes towards his people the office and character of '
            'a Shepherd! It should be the subject of grateful admiration that '
            'the great God allows himself to be compared to anything which will '
            'set forth his great love and care for his own people.',
        source: 'C. H. Spurgeon, The Treasury of David — Psalm 23',
      ),
    ),
  ],
  'proverbs': [
    KeyVerse(ref: 'Proverbs 3:5-6', book: 'Proverbs', chapter: 3, verses: [5, 6]),
  ],
  'matthew': [
    KeyVerse(ref: 'Matthew 6:33', book: 'Matthew', chapter: 6, verses: [33]),
  ],
  'john': [
    KeyVerse(ref: 'John 3:16', book: 'John', chapter: 3, verses: [16]),
  ],
  'romans': [
    KeyVerse(ref: 'Romans 8:28', book: 'Romans', chapter: 8, verses: [28]),
  ],
  'philippians': [
    KeyVerse(ref: 'Philippians 4:6-7', book: 'Philippians', chapter: 4, verses: [6, 7]),
  ],
};

List<KeyVerse> keyVersesFor(String studyTitle) =>
    _kStudyKeyVerses[studyTitle.trim().toLowerCase()] ?? const [];
