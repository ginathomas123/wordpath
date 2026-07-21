import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prototype "Study with friends" data.
///
/// This is a local, seeded model so the group experience looks and feels real
/// on one device for demos. Your own answers / ideas / reactions persist via
/// [SharedPreferences]; friends' contributions are seeded. Swap [CircleStore]
/// for a real backend (e.g. Firestore) later without touching the UI.

const List<String> kReactions = ['🙏', '❤️', '💡'];

/// Two-letter initials from a display name ("Sarah K." → "SK").
String initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

class CircleMember {
  final String name;
  final Color color;
  final double progress; // 0..1 mastery
  final bool isYou;
  const CircleMember({
    required this.name,
    required this.color,
    required this.progress,
    this.isYou = false,
  });

  String get initials => initialsFor(name);
}

class CirclePost {
  final String id;
  final String author;
  final Color color;
  final String text;
  final bool byYou;
  final Map<String, int> reactions; // seeded base counts

  const CirclePost({
    required this.id,
    required this.author,
    required this.color,
    required this.text,
    this.byYou = false,
    this.reactions = const {},
  });
}

/// The curated + seeded contents of a circle for a given study.
class StudyCircle {
  final List<CircleMember> members;
  final List<String> questions;
  final List<List<CirclePost>> seededAnswers; // parallel to [questions]
  final List<CirclePost> seededIdeas;

  const StudyCircle({
    required this.members,
    required this.questions,
    required this.seededAnswers,
    required this.seededIdeas,
  });

  /// Seeds a believable circle. [accent] tints "You" so it matches the study.
  factory StudyCircle.seed(Color accent) {
    const sarah = Color(0xFF3E7CB1);
    const marcus = Color(0xFF9B5DE5);
    const grace = Color(0xFFE07A5F);
    const david = Color(0xFF4C9A6A);

    return StudyCircle(
      members: [
        CircleMember(name: 'You', color: accent, progress: 0.6, isYou: true),
        const CircleMember(name: 'Sarah K.', color: sarah, progress: 0.85),
        const CircleMember(name: 'Marcus T.', color: marcus, progress: 0.4),
        const CircleMember(name: 'Grace L.', color: grace, progress: 1.0),
        const CircleMember(name: 'David R.', color: david, progress: 0.55),
      ],
      questions: const [
        'What stood out to you most in this study?',
        'Where is God meeting you in this right now?',
        "What's one thing you'll carry into this week?",
      ],
      seededAnswers: const [
        [
          CirclePost(
            id: 'q0a0',
            author: 'Grace L.',
            color: grace,
            text:
                'How patient God is — the same promise repeated even when the people keep forgetting. It made me exhale.',
            reactions: {'🙏': 3, '❤️': 2},
          ),
          CirclePost(
            id: 'q0a1',
            author: 'Marcus T.',
            color: marcus,
            text: 'The detail that deliverance came before the law, not after. Grace first.',
            reactions: {'💡': 4},
          ),
        ],
        [
          CirclePost(
            id: 'q1a0',
            author: 'Sarah K.',
            color: sarah,
            text:
                'Honestly in my job stress. Reading this reminded me He goes ahead of me into the hard rooms.',
            reactions: {'🙏': 2, '❤️': 3},
          ),
        ],
        [
          CirclePost(
            id: 'q2a0',
            author: 'David R.',
            color: david,
            text: 'Going to actually pause and pray before reacting this week. One breath first.',
            reactions: {'🙏': 1},
          ),
        ],
      ],
      seededIdeas: const [
        CirclePost(
          id: 'idea0',
          author: 'Sarah K.',
          color: sarah,
          text:
              'Idea: what if we each pick one verse from this study to memorize and check in on Friday?',
          reactions: {'💡': 3, '❤️': 1},
        ),
        CirclePost(
          id: 'idea1',
          author: 'Grace L.',
          color: grace,
          text: 'This pairs so well with Psalm 77 if anyone wants to go deeper on remembering God\u2019s works.',
          reactions: {'❤️': 2},
        ),
      ],
    );
  }
}

/// Persists the current user's contributions per study.
class CircleStore {
  CircleStore._();

  static String _answersKey(String s) => 'circle_answers_$s';
  static String _ideasKey(String s) => 'circle_ideas_$s';
  static String _reactionsKey(String s) => 'circle_reactions_$s';

  static Future<Map<int, String>> loadAnswers(String studyId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_answersKey(studyId));
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as String));
  }

  static Future<void> saveAnswer(String studyId, int qIndex, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadAnswers(studyId);
    if (text.trim().isEmpty) {
      current.remove(qIndex);
    } else {
      current[qIndex] = text.trim();
    }
    await prefs.setString(
      _answersKey(studyId),
      jsonEncode(current.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  static Future<List<String>> loadIdeas(String studyId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ideasKey(studyId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  static Future<void> addIdea(String studyId, String text) async {
    if (text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await loadIdeas(studyId);
    current.add(text.trim());
    await prefs.setString(_ideasKey(studyId), jsonEncode(current));
  }

  static Future<Map<String, String>> loadReactions(String studyId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reactionsKey(studyId));
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).cast<String, String>();
  }

  /// Sets (or clears, if same) the user's single reaction on a post.
  static Future<void> toggleReaction(String studyId, String postId, String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadReactions(studyId);
    if (current[postId] == emoji) {
      current.remove(postId);
    } else {
      current[postId] = emoji;
    }
    await prefs.setString(_reactionsKey(studyId), jsonEncode(current));
  }
}
