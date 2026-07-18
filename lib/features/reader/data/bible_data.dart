class BibleBook {
  final String name;
  final String abbrev;
  final String apiName;
  final bool isOT;
  final int chapterCount;

  const BibleBook({
    required this.name,
    required this.abbrev,
    required this.apiName,
    required this.isOT,
    required this.chapterCount,
  });

  String chapterUrl(int chapter) {
    final bookPath = apiName.replaceAll(' ', '');
    return 'https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/en-kjv/books/$bookPath/chapters/$chapter.json';
  }
}

const List<BibleBook> bibleBooks = [
  // Old Testament
  BibleBook(name: 'Genesis',        abbrev: 'Gen', apiName: 'genesis',          isOT: true,  chapterCount: 50),
  BibleBook(name: 'Exodus',         abbrev: 'Exo', apiName: 'exodus',           isOT: true,  chapterCount: 40),
  BibleBook(name: 'Leviticus',      abbrev: 'Lev', apiName: 'leviticus',        isOT: true,  chapterCount: 27),
  BibleBook(name: 'Numbers',        abbrev: 'Num', apiName: 'numbers',          isOT: true,  chapterCount: 36),
  BibleBook(name: 'Deuteronomy',    abbrev: 'Deu', apiName: 'deuteronomy',      isOT: true,  chapterCount: 34),
  BibleBook(name: 'Joshua',         abbrev: 'Jos', apiName: 'joshua',           isOT: true,  chapterCount: 24),
  BibleBook(name: 'Judges',         abbrev: 'Jdg', apiName: 'judges',           isOT: true,  chapterCount: 21),
  BibleBook(name: 'Ruth',           abbrev: 'Rut', apiName: 'ruth',             isOT: true,  chapterCount: 4),
  BibleBook(name: '1 Samuel',       abbrev: '1Sa', apiName: '1 samuel',         isOT: true,  chapterCount: 31),
  BibleBook(name: '2 Samuel',       abbrev: '2Sa', apiName: '2 samuel',         isOT: true,  chapterCount: 24),
  BibleBook(name: '1 Kings',        abbrev: '1Ki', apiName: '1 kings',          isOT: true,  chapterCount: 22),
  BibleBook(name: '2 Kings',        abbrev: '2Ki', apiName: '2 kings',          isOT: true,  chapterCount: 25),
  BibleBook(name: '1 Chronicles',   abbrev: '1Ch', apiName: '1 chronicles',     isOT: true,  chapterCount: 29),
  BibleBook(name: '2 Chronicles',   abbrev: '2Ch', apiName: '2 chronicles',     isOT: true,  chapterCount: 36),
  BibleBook(name: 'Ezra',           abbrev: 'Ezr', apiName: 'ezra',             isOT: true,  chapterCount: 10),
  BibleBook(name: 'Nehemiah',       abbrev: 'Neh', apiName: 'nehemiah',         isOT: true,  chapterCount: 13),
  BibleBook(name: 'Esther',         abbrev: 'Est', apiName: 'esther',           isOT: true,  chapterCount: 10),
  BibleBook(name: 'Job',            abbrev: 'Job', apiName: 'job',              isOT: true,  chapterCount: 42),
  BibleBook(name: 'Psalms',         abbrev: 'Psa', apiName: 'psalms',           isOT: true,  chapterCount: 150),
  BibleBook(name: 'Proverbs',       abbrev: 'Pro', apiName: 'proverbs',         isOT: true,  chapterCount: 31),
  BibleBook(name: 'Ecclesiastes',   abbrev: 'Ecc', apiName: 'ecclesiastes',     isOT: true,  chapterCount: 12),
  BibleBook(name: 'Song of Solomon',abbrev: 'Sng', apiName: 'song of solomon',  isOT: true,  chapterCount: 8),
  BibleBook(name: 'Isaiah',         abbrev: 'Isa', apiName: 'isaiah',           isOT: true,  chapterCount: 66),
  BibleBook(name: 'Jeremiah',       abbrev: 'Jer', apiName: 'jeremiah',         isOT: true,  chapterCount: 52),
  BibleBook(name: 'Lamentations',   abbrev: 'Lam', apiName: 'lamentations',     isOT: true,  chapterCount: 5),
  BibleBook(name: 'Ezekiel',        abbrev: 'Ezk', apiName: 'ezekiel',          isOT: true,  chapterCount: 48),
  BibleBook(name: 'Daniel',         abbrev: 'Dan', apiName: 'daniel',           isOT: true,  chapterCount: 12),
  BibleBook(name: 'Hosea',          abbrev: 'Hos', apiName: 'hosea',            isOT: true,  chapterCount: 14),
  BibleBook(name: 'Joel',           abbrev: 'Joe', apiName: 'joel',             isOT: true,  chapterCount: 3),
  BibleBook(name: 'Amos',           abbrev: 'Amo', apiName: 'amos',             isOT: true,  chapterCount: 9),
  BibleBook(name: 'Obadiah',        abbrev: 'Oba', apiName: 'obadiah',          isOT: true,  chapterCount: 1),
  BibleBook(name: 'Jonah',          abbrev: 'Jon', apiName: 'jonah',            isOT: true,  chapterCount: 4),
  BibleBook(name: 'Micah',          abbrev: 'Mic', apiName: 'micah',            isOT: true,  chapterCount: 7),
  BibleBook(name: 'Nahum',          abbrev: 'Nah', apiName: 'nahum',            isOT: true,  chapterCount: 3),
  BibleBook(name: 'Habakkuk',       abbrev: 'Hab', apiName: 'habakkuk',         isOT: true,  chapterCount: 3),
  BibleBook(name: 'Zephaniah',      abbrev: 'Zep', apiName: 'zephaniah',        isOT: true,  chapterCount: 3),
  BibleBook(name: 'Haggai',         abbrev: 'Hag', apiName: 'haggai',           isOT: true,  chapterCount: 2),
  BibleBook(name: 'Zechariah',      abbrev: 'Zec', apiName: 'zechariah',        isOT: true,  chapterCount: 14),
  BibleBook(name: 'Malachi',        abbrev: 'Mal', apiName: 'malachi',          isOT: true,  chapterCount: 4),
  // New Testament
  BibleBook(name: 'Matthew',        abbrev: 'Mat', apiName: 'matthew',          isOT: false, chapterCount: 28),
  BibleBook(name: 'Mark',           abbrev: 'Mar', apiName: 'mark',             isOT: false, chapterCount: 16),
  BibleBook(name: 'Luke',           abbrev: 'Luk', apiName: 'luke',             isOT: false, chapterCount: 24),
  BibleBook(name: 'John',           abbrev: 'Joh', apiName: 'john',             isOT: false, chapterCount: 21),
  BibleBook(name: 'Acts',           abbrev: 'Act', apiName: 'acts',             isOT: false, chapterCount: 28),
  BibleBook(name: 'Romans',         abbrev: 'Rom', apiName: 'romans',           isOT: false, chapterCount: 16),
  BibleBook(name: '1 Corinthians',  abbrev: '1Co', apiName: '1 corinthians',    isOT: false, chapterCount: 16),
  BibleBook(name: '2 Corinthians',  abbrev: '2Co', apiName: '2 corinthians',    isOT: false, chapterCount: 13),
  BibleBook(name: 'Galatians',      abbrev: 'Gal', apiName: 'galatians',        isOT: false, chapterCount: 6),
  BibleBook(name: 'Ephesians',      abbrev: 'Eph', apiName: 'ephesians',        isOT: false, chapterCount: 6),
  BibleBook(name: 'Philippians',    abbrev: 'Php', apiName: 'philippians',      isOT: false, chapterCount: 4),
  BibleBook(name: 'Colossians',     abbrev: 'Col', apiName: 'colossians',       isOT: false, chapterCount: 4),
  BibleBook(name: '1 Thessalonians',abbrev: '1Th', apiName: '1 thessalonians',  isOT: false, chapterCount: 5),
  BibleBook(name: '2 Thessalonians',abbrev: '2Th', apiName: '2 thessalonians',  isOT: false, chapterCount: 3),
  BibleBook(name: '1 Timothy',      abbrev: '1Ti', apiName: '1 timothy',        isOT: false, chapterCount: 6),
  BibleBook(name: '2 Timothy',      abbrev: '2Ti', apiName: '2 timothy',        isOT: false, chapterCount: 4),
  BibleBook(name: 'Titus',          abbrev: 'Tit', apiName: 'titus',            isOT: false, chapterCount: 3),
  BibleBook(name: 'Philemon',       abbrev: 'Phm', apiName: 'philemon',         isOT: false, chapterCount: 1),
  BibleBook(name: 'Hebrews',        abbrev: 'Heb', apiName: 'hebrews',          isOT: false, chapterCount: 13),
  BibleBook(name: 'James',          abbrev: 'Jam', apiName: 'james',            isOT: false, chapterCount: 5),
  BibleBook(name: '1 Peter',        abbrev: '1Pe', apiName: '1 peter',          isOT: false, chapterCount: 5),
  BibleBook(name: '2 Peter',        abbrev: '2Pe', apiName: '2 peter',          isOT: false, chapterCount: 3),
  BibleBook(name: '1 John',         abbrev: '1Jo', apiName: '1 john',           isOT: false, chapterCount: 5),
  BibleBook(name: '2 John',         abbrev: '2Jo', apiName: '2 john',           isOT: false, chapterCount: 1),
  BibleBook(name: '3 John',         abbrev: '3Jo', apiName: '3 john',           isOT: false, chapterCount: 1),
  BibleBook(name: 'Jude',           abbrev: 'Jud', apiName: 'jude',             isOT: false, chapterCount: 1),
  BibleBook(name: 'Revelation',     abbrev: 'Rev', apiName: 'revelation',       isOT: false, chapterCount: 22),
];
