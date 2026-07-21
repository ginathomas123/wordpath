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

  Future<void> _like(String postId) async {
    await CircleStore.toggleReaction(_studyId, postId, 'like');
    setState(() {
      if (_reactions[postId] == 'like') {
        _reactions.remove(postId);
      } else {
        _reactions[postId] = 'like';
      }
    });
  }

  bool _liked(String postId) => _reactions[postId] == 'like';

  int _likeCount(CirclePost post) => post.likes + (_liked(post.id) ? 1 : 0);

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

  Future<void> _shareThought() async {
    final text = await _compose(
      title: 'Share your thoughts',
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
            const SizedBox(height: 24),
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
                            liked: _liked,
                            likeCount: _likeCount,
                            onLike: _like,
                            onReply: () => _answerQuestion(i),
                          ),
                          const SizedBox(height: 16),
                        ],
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
                                avatar: kYouAvatar,
                              ),
                              palette: palette,
                              liked: false,
                              likeCount: 0,
                              onLike: null,
                            ),
                          ),
                        const SizedBox(height: 4),
                        _AddButton(
                          label: 'Share your thoughts',
                          accent: widget.book.color,
                          palette: palette,
                          onTap: _shareThought,
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
                _Avatar(
                  size: 42,
                  avatar: member.avatar,
                  fallbackText: member.initials,
                  color: member.color,
                  fontSize: 15,
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

/// A circular avatar: shows a face photo when [avatar] is set, otherwise a
/// tinted circle with the member's initials.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.size,
    required this.avatar,
    required this.fallbackText,
    required this.color,
    required this.fontSize,
  });

  final double size;
  final String? avatar;
  final String fallbackText;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (avatar != null) {
      return ClipOval(
        child: Image.asset(
          avatar!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialsCircle(),
        ),
      );
    }
    return _initialsCircle();
  }

  Widget _initialsCircle() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackText,
        style: AppFonts.sans(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
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
    required this.liked,
    required this.likeCount,
    required this.onLike,
    required this.onReply,
  });

  final int index;
  final String question;
  final List<CirclePost> answers;
  final String? yourAnswer;
  final Color accent;
  final AppPalette palette;
  final bool Function(String) liked;
  final int Function(CirclePost) likeCount;
  final void Function(String postId) onLike;
  final VoidCallback onReply;

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
              liked: liked(a.id),
              likeCount: likeCount(a),
              onLike: () => onLike(a.id),
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
                avatar: kYouAvatar,
              ),
              palette: palette,
              liked: false,
              likeCount: 0,
              onLike: null,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onReply,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                foregroundColor: accent,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(LucideIcons.reply, size: 15),
              label: Text(
                yourAnswer == null ? 'Reply' : 'Edit reply',
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

/// A standalone card (used for the thoughts you share).
class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.palette,
    required this.liked,
    required this.likeCount,
    required this.onLike,
  });

  final CirclePost post;
  final AppPalette palette;
  final bool liked;
  final int likeCount;
  final VoidCallback? onLike;

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
        liked: liked,
        likeCount: likeCount,
        onLike: onLike,
      ),
    );
  }
}

/// The avatar + name + text + like layout shared by answers and thoughts.
class _PostBody extends StatelessWidget {
  const _PostBody({
    required this.post,
    required this.palette,
    required this.liked,
    required this.likeCount,
    required this.onLike,
  });

  final CirclePost post;
  final AppPalette palette;
  final bool liked;
  final int likeCount;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(
          size: 32,
          avatar: post.avatar,
          fallbackText: initialsFor(post.author),
          color: post.color,
          fontSize: 12,
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
              // Own posts (no onLike) don't show a like control.
              if (onLike != null) ...[
                const SizedBox(height: 8),
                _LikeButton(
                  liked: liked,
                  count: likeCount,
                  palette: palette,
                  onTap: onLike!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A single heart "like" control with a count.
class _LikeButton extends StatelessWidget {
  const _LikeButton({
    required this.liked,
    required this.count,
    required this.palette,
    required this.onTap,
  });

  final bool liked;
  final int count;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const likeColor = Color(0xFFE0245E);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: liked ? likeColor : palette.inkFaint,
          ),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Text(
              '$count',
              style: AppFonts.sans(
                color: liked ? likeColor : palette.inkSoft,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
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
