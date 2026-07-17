import 'package:flutter/material.dart';

/// Bundled Unsplash leather textures used as book covers. All are genuine
/// pebbled/grained leather (no smooth "satin" hides).
class LeatherTexture {
  const LeatherTexture._();

  static const darkPebble = 'assets/covers/grain.jpg';
  static const indigo = 'assets/covers/leather_blue.jpg';
  static const sage = 'assets/covers/leather_green.jpg';
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

  /// Short description shown on the book detail screen (built later).
  final String? about;
}

/// A titled shelf section containing a horizontal row of books.
class BibleSection {
  const BibleSection({required this.title, required this.books});

  final String title;
  final List<BibleBook> books;
}

/// Sample library data matching the concept mockup. This is a curated subset,
/// not the full 66-book canon, so we can iterate on the design quickly.
const List<BibleSection> kBibleSections = [
  BibleSection(
    title: 'Old Testament',
    books: [
      BibleBook(
        title: 'Genesis',
        attribution: 'Moses',
        texture: LeatherTexture.darkPebble,
        color: Color(0xFF6B4226),
        tint: Color(0xFF7A4A28),
      ),
      BibleBook(
        title: 'Exodus',
        attribution: 'Moses',
        texture: LeatherTexture.sage,
        color: Color(0xFFB2603A),
        tint: Color(0xFFB2603A),
      ),
      BibleBook(
        title: 'Leviticus',
        attribution: 'Moses',
        texture: LeatherTexture.indigo,
        color: Color(0xFF6E8CA0),
      ),
      BibleBook(
        title: 'Numbers',
        attribution: 'Moses',
        texture: LeatherTexture.sage,
        color: Color(0xFF8A7A4E),
        tint: Color(0xFF8F7F52),
      ),
      BibleBook(
        title: 'Deuteronomy',
        attribution: 'Moses',
        texture: LeatherTexture.sage,
        color: Color(0xFF5E7355),
      ),
    ],
  ),
  BibleSection(
    title: 'New Testament',
    books: [
      BibleBook(
        title: 'Matthew',
        attribution: 'Matthew',
        texture: LeatherTexture.sage,
        color: Color(0xFF7A2E2E),
        tint: Color(0xFF8C3230),
      ),
      BibleBook(
        title: 'Mark',
        attribution: 'John Mark',
        texture: LeatherTexture.darkPebble,
        color: Color(0xFF5C4433),
        tint: Color(0xFF5C4433),
      ),
      BibleBook(
        title: 'Luke',
        attribution: 'Luke',
        texture: LeatherTexture.sage,
        color: Color(0xFFB98A56),
        tint: Color(0xFFB98A56),
      ),
      BibleBook(
        title: 'John',
        attribution: 'John',
        texture: LeatherTexture.indigo,
        color: Color(0xFF2E4A5C),
      ),
      BibleBook(
        title: 'Acts',
        attribution: 'Luke',
        texture: LeatherTexture.sage,
        color: Color(0xFF3B5641),
      ),
      BibleBook(
        title: 'Romans',
        attribution: 'Paul',
        texture: LeatherTexture.sage,
        color: Color(0xFF6E2A28),
        tint: Color(0xFF7A2E2C),
      ),
    ],
  ),
  BibleSection(
    title: 'Wisdom',
    books: [
      BibleBook(
        title: 'Job',
        attribution: 'Unknown',
        texture: LeatherTexture.darkPebble,
        color: Color(0xFF2B2B2E),
      ),
      BibleBook(
        title: 'Psalms',
        attribution: 'David',
        texture: LeatherTexture.indigo,
        color: Color(0xFF31506E),
      ),
      BibleBook(
        title: 'Proverbs',
        attribution: 'Solomon',
        texture: LeatherTexture.sage,
        color: Color(0xFFB07C3A),
        tint: Color(0xFFB07C3A),
      ),
      BibleBook(
        title: 'Ecclesiastes',
        attribution: 'Solomon',
        texture: LeatherTexture.sage,
        color: Color(0xFF9C4A2E),
        tint: Color(0xFFA85232),
      ),
      BibleBook(
        title: 'Song of Songs',
        attribution: 'Solomon',
        texture: LeatherTexture.sage,
        color: Color(0xFF3B5B4A),
      ),
    ],
  ),
];
