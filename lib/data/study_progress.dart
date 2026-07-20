import 'package:shared_preferences/shared_preferences.dart';

/// Persisted progress for the study "mastery" tracks, layered on top of
/// [ReadProgress] (which owns the Read track). A study is identified by its
/// title (e.g. "Anxiety", "Genesis").
///
/// Three tracks live here:
///  * Understand — the reader/study opened Matthew Henry commentary for a passage.
///  * Memorize   — a key verse was locked in.
///  * Apply      — a reflection was written for the study.
///
/// The Read track is derived from [ReadProgress] at the call site and combined
/// into the overall mastery percentage by the study screen.
class StudyProgressData {
  const StudyProgressData({
    required this.understood,
    required this.memorized,
    required this.reflected,
  });

  /// "studyId|book|chapter" for each passage whose commentary has been read.
  final Set<String> understood;

  /// "studyId|verseRef" for each key verse the user has locked in.
  final Set<String> memorized;

  /// studyIds whose reflection/application step is complete.
  final Set<String> reflected;

  bool isUnderstood(String studyId, String book, int chapter) =>
      understood.contains(StudyProgress.passageKey(studyId, book, chapter));

  bool isMemorized(String studyId, String verseRef) =>
      memorized.contains(StudyProgress.verseKey(studyId, verseRef));

  bool isReflected(String studyId) => reflected.contains(studyId.trim().toLowerCase());
}

class StudyProgress {
  StudyProgress._();

  static const _understoodKey = 'studyUnderstood';
  static const _memorizedKey = 'studyMemorized';
  static const _reflectedKey = 'studyReflected';
  static const _reflectionTextPrefix = 'studyReflectionText:';

  static String _norm(String s) => s.trim().toLowerCase();

  static String passageKey(String studyId, String book, int chapter) =>
      '${_norm(studyId)}|${_norm(book)}|$chapter';

  static String verseKey(String studyId, String verseRef) =>
      '${_norm(studyId)}|${_norm(verseRef)}';

  static Future<StudyProgressData> load() async {
    final prefs = await SharedPreferences.getInstance();
    return StudyProgressData(
      understood: (prefs.getStringList(_understoodKey) ?? const []).toSet(),
      memorized: (prefs.getStringList(_memorizedKey) ?? const []).toSet(),
      reflected: (prefs.getStringList(_reflectedKey) ?? const []).toSet(),
    );
  }

  static Future<void> _add(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(key) ?? const <String>[]).toSet();
    if (set.add(value)) await prefs.setStringList(key, set.toList());
  }

  static Future<void> _remove(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(key) ?? const <String>[]).toSet();
    if (set.remove(value)) await prefs.setStringList(key, set.toList());
  }

  static Future<void> markUnderstood(String studyId, String book, int chapter) =>
      _add(_understoodKey, passageKey(studyId, book, chapter));

  static Future<void> setMemorized(String studyId, String verseRef, bool value) =>
      value
          ? _add(_memorizedKey, verseKey(studyId, verseRef))
          : _remove(_memorizedKey, verseKey(studyId, verseRef));

  static Future<void> setReflected(String studyId, bool value) =>
      value ? _add(_reflectedKey, _norm(studyId)) : _remove(_reflectedKey, _norm(studyId));

  static Future<String> reflectionText(String studyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_reflectionTextPrefix${_norm(studyId)}') ?? '';
  }

  static Future<void> saveReflectionText(String studyId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_reflectionTextPrefix${_norm(studyId)}', text);
  }
}
