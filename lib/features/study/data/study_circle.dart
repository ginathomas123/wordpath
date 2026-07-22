import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prototype "Study with friends" data.
///
/// This is a local, seeded model so the group experience looks and feels real
/// on one device for demos. Your own answers / ideas / reactions persist via
/// [SharedPreferences]; friends' contributions are seeded. Swap [CircleStore]
/// for a real backend (e.g. Firestore) later without touching the UI.

/// Your own avatar, reused for the thoughts you post.
const String kYouAvatar = 'assets/people/avatar_you.jpg';

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
  final String? avatar; // asset path to a face photo
  const CircleMember({
    required this.name,
    required this.color,
    required this.progress,
    this.isYou = false,
    this.avatar,
  });

  String get initials => initialsFor(name);
}

class CirclePost {
  final String id;
  final String author;
  final Color color;
  final String text;
  final bool byYou;
  final String? avatar; // asset path to author's face photo
  final int likes; // seeded base like count

  const CirclePost({
    required this.id,
    required this.author,
    required this.color,
    required this.text,
    this.byYou = false,
    this.avatar,
    this.likes = 0,
  });
}

/// The curated + seeded contents of a circle for a given study.
class StudyCircle {
  final List<CircleMember> members;
  final List<String> questions;
  final List<List<CirclePost>> seededAnswers; // parallel to [questions]

  const StudyCircle({
    required this.members,
    required this.questions,
    required this.seededAnswers,
  });

  /// Seeds a believable circle. [accent] tints "You" so it matches the study.
  factory StudyCircle.seed(Color accent) {
    const sarah = Color(0xFF3E7CB1);
    const marcus = Color(0xFF9B5DE5);
    const grace = Color(0xFFE07A5F);
    const david = Color(0xFF4C9A6A);

    return StudyCircle(
      members: [
        CircleMember(
            name: 'You', color: accent, progress: 0.6, isYou: true, avatar: kYouAvatar),
        const CircleMember(
            name: 'Sarah K.',
            color: sarah,
            progress: 0.85,
            avatar: 'assets/people/avatar_sarah.jpg'),
        const CircleMember(
            name: 'Marcus T.',
            color: marcus,
            progress: 0.4,
            avatar: 'assets/people/avatar_marcus.jpg'),
        const CircleMember(
            name: 'Grace L.',
            color: grace,
            progress: 1.0,
            avatar: 'assets/people/avatar_grace.jpg'),
        const CircleMember(
            name: 'David R.',
            color: david,
            progress: 0.55,
            avatar: 'assets/people/avatar_david.jpg'),
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
            avatar: 'assets/people/avatar_grace.jpg',
            text:
                'How patient God is — the same promise repeated even when the people keep forgetting. It made me exhale.',
            likes: 3,
          ),
          CirclePost(
            id: 'q0a1',
            author: 'Marcus T.',
            color: marcus,
            avatar: 'assets/people/avatar_marcus.jpg',
            text: 'The detail that deliverance came before the law, not after. Grace first.',
            likes: 2,
          ),
        ],
        [
          CirclePost(
            id: 'q1a0',
            author: 'Sarah K.',
            color: sarah,
            avatar: 'assets/people/avatar_sarah.jpg',
            text:
                'Honestly in my job stress. Reading this reminded me He goes ahead of me into the hard rooms.',
            likes: 4,
          ),
        ],
        [
          CirclePost(
            id: 'q2a0',
            author: 'David R.',
            color: david,
            avatar: 'assets/people/avatar_david.jpg',
            text: 'Going to actually pause and pray before reacting this week. One breath first.',
            likes: 1,
          ),
        ],
      ],
    );
  }

  /// Deterministically seeds a few friends' comments for a per-task discussion
  /// thread (keyed by [threadId]) so each passage feels lived-in without a
  /// backend. Returns 0–2 posts; the same thread always yields the same seed.
  List<CirclePost> seedThreadPosts(String threadId) {
    var h = 0;
    for (final c in threadId.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    final friends = members.where((m) => !m.isYou).toList();
    if (friends.isEmpty) return const [];
    // ~20% of threads stay empty, ~40% get one comment, ~40% get two.
    final roll = h % 5;
    final count = roll == 0 ? 0 : (roll <= 2 ? 1 : 2);
    final posts = <CirclePost>[];
    for (var i = 0; i < count; i++) {
      final hh = (h + i * 97) & 0x7fffffff;
      final m = friends[(hh + i) % friends.length];
      final msg = _threadSeedPool[(hh ~/ 7) % _threadSeedPool.length];
      posts.add(CirclePost(
        id: '$threadId#s$i',
        author: m.name,
        color: m.color,
        avatar: m.avatar,
        text: msg,
        likes: (hh ~/ 13) % 4,
      ));
    }
    return posts;
  }
}

/// A small pool of contextual, passage-agnostic comments used to seed the
/// per-task discussion threads.
const List<String> _threadSeedPool = [
  'This is the part I keep coming back to.',
  'Reading it slowly completely changed how I heard it.',
  'Anyone else wrestle with this one? It sat heavy with me.',
  'The wording here is so tender — I had to pause.',
  'Needed this exact reminder this week.',
  'I never noticed this detail until now.',
  'Sitting with this one a little longer today.',
  'This gave me so much hope honestly.',
];

/// Persists the current user's contributions per study.
class CircleStore {
  CircleStore._();

  static String _answersKey(String s) => 'circle_answers_$s';
  static String _ideasKey(String s) => 'circle_ideas_$s';
  static String _reactionsKey(String s) => 'circle_reactions_$s';
  static String _threadsKey(String s) => 'circle_threads_$s';

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

  /// Your replies on each per-task thread, keyed by threadId.
  static Future<Map<String, List<String>>> loadThreads(String studyId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_threadsKey(studyId));
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as List).cast<String>()));
  }

  static Future<void> addThreadReply(
      String studyId, String threadId, String text) async {
    if (text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await loadThreads(studyId);
    final list = current[threadId] ?? <String>[];
    list.add(text.trim());
    current[threadId] = list;
    await prefs.setString(_threadsKey(studyId), jsonEncode(current));
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
