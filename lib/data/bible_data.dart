import 'package:flutter/material.dart';

/// Bundled leather / textured cover photos, all sourced from Unsplash. A single
/// grained photo can be recolored via [BibleBook.tint] so each book reads as a
/// visibly distinct hide while keeping genuine photographic grain.
class LeatherTexture {
  const LeatherTexture._();

  // Original Unsplash textures.
  static const darkPebble = 'assets/covers/grain.jpg';
  static const indigo = 'assets/covers/leather_blue.jpg';
  static const sage = 'assets/covers/leather_green.jpg';

  // Additional Unsplash textures.
  static const brown = 'assets/covers/uns_brown1.jpg';
  static const brownGrain = 'assets/covers/uns_brown2.jpg';
  static const brownPlain = 'assets/covers/uns_brown_plain.jpg';
  static const redBook = 'assets/covers/uns_red_book.jpg';
  static const redTextile = 'assets/covers/uns_red_textile.jpg';
  static const concrete = 'assets/covers/uns_concrete.jpg';
  static const plaster = 'assets/covers/uns_plaster.jpg';
  static const slate = 'assets/covers/uns_blackboard.jpg';
  static const plaid = 'assets/covers/uns_plaid.jpg';
}

/// A single book of the Bible as shown on the shelf.
class BibleBook {
  const BibleBook({
    required this.title,
    required this.attribution,
    required this.texture,
    required this.color,
    this.tint,
    this.about,
  });

  /// Display title on the spine, e.g. "Genesis".
  final String title;

  /// Small label above the title, e.g. the traditional author "Moses".
  final String attribution;

  /// Asset path of the real leather texture used for the cover.
  final String texture;

  /// Representative accent color for the book (used for shelf tinting/UI).
  final Color color;

  /// Optional hue applied over the leather (via a color blend) so a single
  /// pebbled texture can read as different colored leather. Null keeps the
  /// photo's natural color.
  final Color? tint;

  /// Short summary shown on the inside page when the book opens.
  final String? about;
}

/// A titled shelf section containing a horizontal row of books.
class BibleSection {
  const BibleSection({
    required this.title,
    required this.books,
    this.itemNoun = 'books',
  });

  final String title;
  final List<BibleBook> books;

  /// Plural noun used in the section's count label (e.g. "books", "topics").
  final String itemNoun;
}

/// Sample library data matching the concept mockup. This is a curated subset,
/// not the full 66-book canon, so we can iterate on the design quickly. Each
/// section uses a unique base texture per book so no two adjacent covers repeat.
const List<BibleSection> kBibleSections = [
  BibleSection(
    title: 'Old Testament',
    books: [
      BibleBook(
        title: 'Genesis',
        attribution: 'Moses',
        texture: LeatherTexture.brown,
        color: Color(0xFF6B4226),
        about:
            'The book of beginnings: creation, the fall, the flood, and God\'s '
            'covenant with Abraham. It traces the promise through the patriarchs '
            'down to Joseph in Egypt.',
      ),
      BibleBook(
        title: 'Exodus',
        attribution: 'Moses',
        texture: LeatherTexture.brownGrain,
        color: Color(0xFFB2603A),
        tint: Color(0xFFB2603A),
        about:
            'Israel\'s deliverance from slavery in Egypt through Moses, the '
            'parting of the Red Sea, and the giving of the Law at Mount Sinai.',
      ),
      BibleBook(
        title: 'Leviticus',
        attribution: 'Moses',
        texture: LeatherTexture.indigo,
        color: Color(0xFF6E8CA0),
        about:
            'A handbook of worship and holiness. Its laws for sacrifice, '
            'priesthood, and clean living taught Israel how to draw near to a '
            'holy God.',
      ),
      BibleBook(
        title: 'Numbers',
        attribution: 'Moses',
        texture: LeatherTexture.darkPebble,
        color: Color(0xFF8A7A4E),
        tint: Color(0xFF8F7F52),
        about:
            'Israel\'s forty years in the wilderness, marked by census, '
            'rebellion, and God\'s faithfulness on the long road to the Promised '
            'Land.',
      ),
      BibleBook(
        title: 'Deuteronomy',
        attribution: 'Moses',
        texture: LeatherTexture.sage,
        color: Color(0xFF5E7355),
        about:
            'Moses\' farewell sermons, restating the Law for a new generation '
            'and calling them to love and obey God as they enter Canaan.',
      ),
    ],
  ),
  BibleSection(
    title: 'New Testament',
    books: [
      BibleBook(
        title: 'Matthew',
        attribution: 'Matthew',
        texture: LeatherTexture.redBook,
        color: Color(0xFF7A2E2E),
        about:
            'Presents Jesus as the promised Messiah and King, weaving Old '
            'Testament prophecy through his birth, teaching, death, and '
            'resurrection.',
      ),
      BibleBook(
        title: 'Mark',
        attribution: 'John Mark',
        texture: LeatherTexture.darkPebble,
        color: Color(0xFF5C4433),
        tint: Color(0xFF5C4433),
        about:
            'A fast-paced account of Jesus the servant, full of action and '
            'miracles, driving urgently toward the cross and the empty tomb.',
      ),
      BibleBook(
        title: 'Luke',
        attribution: 'Luke',
        texture: LeatherTexture.concrete,
        color: Color(0xFFB98A56),
        tint: Color(0xFFB98A56),
        about:
            'A careful, orderly account that highlights Jesus\' compassion for '
            'the poor, the outsider, and the lost.',
      ),
      BibleBook(
        title: 'John',
        attribution: 'John',
        texture: LeatherTexture.plaster,
        color: Color(0xFF2E4A5C),
        tint: Color(0xFF2E4A5C),
        about:
            'A theological portrait of Jesus as the eternal Son of God, built '
            'around seven signs and the "I am" sayings that invite belief.',
      ),
      BibleBook(
        title: 'Acts',
        attribution: 'Luke',
        texture: LeatherTexture.brownPlain,
        color: Color(0xFF3B5641),
        tint: Color(0xFF3B5641),
        about:
            'The birth and rapid growth of the early church, from Pentecost to '
            'Paul, as the Spirit carries the gospel to the ends of the earth.',
      ),
      BibleBook(
        title: 'Romans',
        attribution: 'Paul',
        texture: LeatherTexture.redTextile,
        color: Color(0xFF6E2A28),
        tint: Color(0xFF7A2E2C),
        about:
            'Paul\'s fullest explanation of the gospel: sin, grace, faith, and '
            'new life, showing how God makes people right with himself.',
      ),
    ],
  ),
  BibleSection(
    title: 'Study by Topic',
    itemNoun: 'topics',
    books: [
      BibleBook(
        title: 'Marriage',
        attribution: 'Ephesians 5',
        texture: _imgMarriage,
        color: _topicMarriage,
        about:
            'What Scripture teaches about covenant love, sacrifice, and building '
            'a marriage that reflects Christ and the church.',
      ),
      BibleBook(
        title: 'Anxiety',
        attribution: 'Philippians 4',
        texture: _imgAnxiety,
        color: _topicAnxiety,
        about:
            'Bringing worry to God in prayer and receiving the peace that guards '
            'the heart and mind in Christ Jesus.',
      ),
      BibleBook(
        title: 'Anger',
        attribution: 'James 1',
        texture: _imgAnger,
        color: _topicAnger,
        about:
            'Being slow to anger and quick to listen, and facing conflict with '
            'patience, wisdom, and self-control.',
      ),
      BibleBook(
        title: 'Fear',
        attribution: 'Psalm 23',
        texture: _imgFear,
        color: _topicFear,
        about:
            'Finding courage and peace in God\'s presence when life feels '
            'uncertain, and trusting Him with what we cannot control.',
      ),
      BibleBook(
        title: 'Hope',
        attribution: 'Romans 15',
        texture: _imgHope,
        color: _topicHope,
        about:
            'Anchoring the heart in God\'s promises and the sure, living hope we '
            'have through the resurrection.',
      ),
      BibleBook(
        title: 'Gratitude',
        attribution: 'Psalm 100',
        texture: _imgGratitude,
        color: _topicGratitude,
        about:
            'Cultivating a thankful heart in every season and giving thanks to '
            'God in all circumstances.',
      ),
    ],
  ),
];

/// Each topical study wears its own mood photo (soft-focus, atmospheric) chosen
/// to match the feeling of the topic, so the row reads as an emotional,
/// personality-rich set that is visually distinct from the leather-bound books.
/// These are shown untinted so the photo's real colors carry the mood.
const String _imgMarriage = 'assets/covers/topic_marriage.jpg'; // warm bokeh
const String _imgAnxiety = 'assets/covers/topic_anxiety.jpg'; // storm clouds
const String _imgAnger = 'assets/covers/topic_anger.jpg'; // fire sparks
const String _imgFear = 'assets/covers/topic_fear.jpg'; // foggy forest
const String _imgHope = 'assets/covers/topic_hope.jpg'; // sun rays
const String _imgGratitude = 'assets/covers/topic_gratitude.jpg'; // golden grass

// Representative accent colors (used for the small foil label on each cover).
const Color _topicMarriage = Color(0xFF9A7B57); // warm gold
const Color _topicAnxiety = Color(0xFF3E5566); // storm blue
const Color _topicAnger = Color(0xFF8A3B1E); // ember orange
const Color _topicFear = Color(0xFF4B5259); // misty slate
const Color _topicHope = Color(0xFFB0763A); // sunrise amber
const Color _topicGratitude = Color(0xFF9A6E2E); // golden field

/// Canonical section titles, shared between [kBibleSections] and the add
/// catalog so an added item lands in the right shelf.
class SectionTitles {
  const SectionTitles._();

  static const oldTestament = 'Old Testament';
  static const newTestament = 'New Testament';
  static const topics = 'Study by Topic';
}

/// An item the user can add to their library from the + menu. [section] must
/// match a [BibleSection.title] so the book lands on the correct shelf.
class AddableItem {
  const AddableItem({required this.book, required this.section});

  final BibleBook book;
  final String section;
}

/// The catalog offered in the floating "+" menu: extra books and topics not on
/// the shelves by default. Books reuse the leather textures; topics wear the
/// same dreamy soft-focus photos as the study path for a cohesive mood.
const List<AddableItem> kAddableItems = [
  // --- Books ---
  AddableItem(
    section: SectionTitles.oldTestament,
    book: BibleBook(
      title: 'Psalms',
      attribution: 'David',
      texture: LeatherTexture.brownGrain,
      color: Color(0xFF7A5A2E),
      tint: Color(0xFF6E5A34),
      about:
          'The songbook of Scripture — prayers of lament, thanksgiving, and '
          'praise that give words to every season of the heart.',
    ),
  ),
  AddableItem(
    section: SectionTitles.oldTestament,
    book: BibleBook(
      title: 'Proverbs',
      attribution: 'Solomon',
      texture: LeatherTexture.concrete,
      color: Color(0xFF8A6B3A),
      tint: Color(0xFF8A6B3A),
      about:
          'Practical wisdom for daily life: sayings on speech, work, money, and '
          'the fear of the Lord as the beginning of knowledge.',
    ),
  ),
  AddableItem(
    section: SectionTitles.newTestament,
    book: BibleBook(
      title: 'Philippians',
      attribution: 'Paul',
      texture: LeatherTexture.redTextile,
      color: Color(0xFF7A2E2C),
      tint: Color(0xFF7A2E2C),
      about:
          'A letter of joy written from prison, urging believers to rejoice '
          'always and to press on toward the goal in Christ.',
    ),
  ),
  AddableItem(
    section: SectionTitles.newTestament,
    book: BibleBook(
      title: 'Revelation',
      attribution: 'John',
      texture: LeatherTexture.slate,
      color: Color(0xFF3B2E4A),
      tint: Color(0xFF3B2E4A),
      about:
          'A vision of the risen Christ and the end of the story — judgment, '
          'hope, and the promise of a new heaven and new earth.',
    ),
  ),
  // --- Topics ---
  AddableItem(
    section: SectionTitles.topics,
    book: BibleBook(
      title: 'Faith',
      attribution: 'Hebrews 11',
      texture: 'assets/covers/blur_sun.jpg',
      color: Color(0xFFB0763A),
      about:
          'Trusting God for what we cannot yet see, and stepping forward on the '
          'strength of his promises.',
    ),
  ),
  AddableItem(
    section: SectionTitles.topics,
    book: BibleBook(
      title: 'Forgiveness',
      attribution: 'Colossians 3',
      texture: 'assets/covers/blur_dune.jpg',
      color: Color(0xFF8C7A5A),
      about:
          'Releasing debts as we have been forgiven, and letting grace heal what '
          'bitterness would keep bound.',
    ),
  ),
  AddableItem(
    section: SectionTitles.topics,
    book: BibleBook(
      title: 'Joy',
      attribution: 'Psalm 16',
      texture: 'assets/covers/blur_clouds.jpg',
      color: Color(0xFF8A6E8C),
      about:
          'The deep gladness of life with God, a joy that runs beneath every '
          'circumstance and cannot be taken away.',
    ),
  ),
  AddableItem(
    section: SectionTitles.topics,
    book: BibleBook(
      title: 'Patience',
      attribution: 'Romans 12',
      texture: 'assets/covers/blur_forest.jpg',
      color: Color(0xFF4F6470),
      about:
          'Waiting well — steady endurance and gentleness with others as God '
          'works out his purposes in his time.',
    ),
  ),
];
