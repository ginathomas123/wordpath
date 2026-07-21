import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/fonts.dart';
import '../../app/theme.dart';
import '../../app/widgets/app_icon_button.dart';
import '../../data/bible_data.dart';
import 'data/study_circle.dart';

/// "Study with friends" — an async study circle for a single [book].
///
/// Prototype: friends' content is seeded; your answers, ideas and reactions
/// persist locally via [CircleStore].
class StudyCircleScreen extends StatefulWidget {
  const StudyCircleScreen({super.key, required this.book});

  final BibleBook book;

  @override
  State<StudyCircleScreen> createState() => _StudyCircleScreenState();
}

class _StudyCircleScreenState extends State<StudyCircleScreen> {
  late final StudyCircle _circle = StudyCircle.seed(widget.book.color);
  String get _studyId => widget.book.title;

  Map<int, String> _answers = {};
  List<String> _ideas = [];
  Map<String, String> _reactions = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final answers = await CircleStore.loadAnswers(_studyId);
    final ideas = await CircleStore.loadIdeas(_studyId);
    final reactions = await CircleStore.loadReactions(_studyId);
    if (!mounted) return;
    setState(() {
      _answers = answers;
      _ideas = ideas;
      _reactions = reactions;
      _loaded = true;
    });
  }

  Future<void> _react(String postId, String emoji) async {
    await CircleStore.toggleReaction(_studyId, postId, emoji);
    setState(() {
      if (_reactions[postId] == emoji) {
        _reactions.remove(postId);
      } else {
        _reactions[postId] = emoji;
      }
    });
  }

  Future<void> _answerQuestion(int index) async {
    final text = await _compose(
      title: _circle.questions[index],
      hint: 'Share your thoughts…',
      initial: _answers[index],
    );
    if (text == null) return;
    await CircleStore.saveAnswer(_studyId, index, text);
    setState(() {
      if (text.trim().isEmpty) {
        _answers.remove(index);
      } else {
        _answers[index] = text.trim();
      }
    });
  }

  Future<void> _shareIdea() async {
    final text = await _compose(
      title: 'Share an idea',
      hint: 'A verse, a connection, a question for the group…',
    );
    if (text == null || text.trim().isEmpty) return;
    await CircleStore.addIdea(_studyId, text);
    setState(() => _ideas.add(text.trim()));
  }

  Future<String?> _compose({
    required String title,
    required String hint,
    String? initial,
  }) {
    final controller = TextEditingController(text: initial);
    final palette = context.palette;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: palette.inkFaint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                title,
                style: AppFonts.serif(
                  color: palette.ink,
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: AppFonts.serif(color: palette.ink, fontSize: 16, height: 1.4),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppFonts.serif(color: palette.inkFaint, fontSize: 16),
                  filled: true,
                  fillColor: palette.paperDim,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: widget.book.color,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.of(ctx).pop(controller.text),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                      child: Text(
                        'Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _count(CirclePost post, String emoji) {
    final base = post.reactions[emoji] ?? 0;
    return base + (_reactions[post.id] == emoji ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(palette),
            _membersStrip(palette),
            const SizedBox(height: 6),
            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _sectionLabel('Discussion', palette),
                        const SizedBox(height: 14),
                        for (int i = 0; i < _circle.questions.length; i++) ...[
                          _QuestionCard(
                            index: i,
                            question: _circle.questions[i],
                            answers: _circle.seededAnswers[i],
                            yourAnswer: _answers[i],
                            accent: widget.book.color,
                            palette: palette,
                            count: _count,
                            userReaction: (id) => _reactions[id],
                            onReact: _react,
                            onAnswer: () => _answerQuestion(i),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 8),
                        _sectionLabel('Ideas & reflections', palette),
                        const SizedBox(height: 14),
                        for (final idea in _circle.seededIdeas)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PostCard(
                              post: idea,
                              palette: palette,
                              count: _count,
                              userReaction: _reactions[idea.id],
                              onReact: (e) => _react(idea.id, e),
                            ),
                          ),
                        for (final idea in _ideas)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PostCard(
                              post: CirclePost(
                                id: 'you_idea',
                                author: 'You',
                                color: widget.book.color,
                                text: idea,
                                byYou: true,
                              ),
                              palette: palette,
                              count: _count,
                              userReaction: null,
                              onReact: null,
                            ),
                          ),
                        const SizedBox(height: 4),
                        _AddButton(
                          label: 'Share an idea',
                          accent: widget.book.color,
                          palette: palette,
                          onTap: _shareIdea,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          AppIconButton(
            icon: LucideIcons.chevronLeft,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.book.title,
                  style: AppFonts.serif(
                    color: palette.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Study circle · ${_circle.members.length} members',
                  style: AppFonts.sans(
                    color: palette.inkSoft,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _membersStrip(AppPalette palette) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _circle.members.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == _circle.members.length) {
            return _InviteChip(accent: widget.book.color, palette: palette);
          }
          return _MemberAvatar(member: _circle.members[index], palette: palette);
        },
      ),
    );
  }

  Widget _sectionLabel(String text, AppPalette palette) {
    return Text(
      text.toUpperCase(),
      style: AppFonts.sans(
        color: palette.inkSoft,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.palette});
  final CircleMember member;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: member.progress,
                    strokeWidth: 3,
                    backgroundColor: palette.inkFaint.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation(member.color),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: member.color.withValues(alpha: 0.16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    member.initials,
                    style: AppFonts.sans(
                      color: member.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            member.isYou ? 'You' : member.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.sans(
              color: palette.inkSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteChip extends StatelessWidget {
  const _InviteChip({required this.accent, required this.palette});
  final Color accent;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite link copied (prototype)')),
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.inkFaint.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(LucideIcons.plus, color: palette.inkSoft, size: 22),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Invite',
            style: AppFonts.sans(
              color: palette.inkSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.answers,
    required this.yourAnswer,
    required this.accent,
    required this.palette,
    required this.count,
    required this.userReaction,
    required this.onReact,
    required this.onAnswer,
  });

  final int index;
  final String question;
  final List<CirclePost> answers;
  final String? yourAnswer;
  final Color accent;
  final AppPalette palette;
  final int Function(CirclePost, String) count;
  final String? Function(String) userReaction;
  final void Function(String postId, String emoji) onReact;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.paperDim : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 10),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: AppFonts.sans(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  question,
                  style: AppFonts.serif(
                    color: palette.ink,
                    fontSize: 17,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final a in answers) ...[
            _PostBody(
              post: a,
              palette: palette,
              count: count,
              userReaction: userReaction(a.id),
              onReact: (e) => onReact(a.id, e),
            ),
            const SizedBox(height: 12),
          ],
          if (yourAnswer != null)
            _PostBody(
              post: CirclePost(
                id: 'you_q$index',
                author: 'You',
                color: accent,
                text: yourAnswer!,
                byYou: true,
              ),
              palette: palette,
              count: count,
              userReaction: null,
              onReact: null,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAnswer,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                foregroundColor: accent,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                yourAnswer == null ? LucideIcons.pencil : LucideIcons.pencilLine,
                size: 15,
              ),
              label: Text(
                yourAnswer == null ? 'Share your answer' : 'Edit your answer',
                style: AppFonts.sans(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A standalone card (used for the ideas wall).
class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.palette,
    required this.count,
    required this.userReaction,
    required this.onReact,
  });

  final CirclePost post;
  final AppPalette palette;
  final int Function(CirclePost, String) count;
  final String? userReaction;
  final void Function(String emoji)? onReact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.paperDim : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: _PostBody(
        post: post,
        palette: palette,
        count: count,
        userReaction: userReaction,
        onReact: onReact,
      ),
    );
  }
}

/// The avatar + name + text + reactions layout shared by answers and ideas.
class _PostBody extends StatelessWidget {
  const _PostBody({
    required this.post,
    required this.palette,
    required this.count,
    required this.userReaction,
    required this.onReact,
  });

  final CirclePost post;
  final AppPalette palette;
  final int Function(CirclePost, String) count;
  final String? userReaction;
  final void Function(String emoji)? onReact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: post.color.withValues(alpha: 0.16),
          ),
          alignment: Alignment.center,
          child: Text(
            initialsFor(post.author),
            style: AppFonts.sans(
              color: post.color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author,
                style: AppFonts.sans(
                  color: palette.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                post.text,
                style: AppFonts.serif(
                  color: palette.inkSoft,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              _ReactionsRow(
                post: post,
                palette: palette,
                count: count,
                userReaction: userReaction,
                onReact: onReact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReactionsRow extends StatelessWidget {
  const _ReactionsRow({
    required this.post,
    required this.palette,
    required this.count,
    required this.userReaction,
    required this.onReact,
  });

  final CirclePost post;
  final AppPalette palette;
  final int Function(CirclePost, String) count;
  final String? userReaction;
  final void Function(String emoji)? onReact;

  @override
  Widget build(BuildContext context) {
    // Own posts (no onReact) render nothing.
    if (onReact == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      children: [
        for (final emoji in kReactions)
          _ReactionPill(
            emoji: emoji,
            count: count(post, emoji),
            selected: userReaction == emoji,
            accent: post.color,
            palette: palette,
            onTap: () => onReact!(emoji),
          ),
      ],
    );
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.accent,
    required this.palette,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool selected;
  final Color accent;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : palette.inkFaint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: accent.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppFonts.sans(
                  color: selected ? accent : palette.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.label,
    required this.accent,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.5),
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppFonts.sans(
                  color: accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
