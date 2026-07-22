import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/fonts.dart';
import '../../../app/theme.dart';
import '../data/study_circle.dart';

// ─── Shared primitives ───────────────────────────────────────────────────────

/// A circular avatar: a face photo when [avatar] is set, else a tinted circle
/// with the author's initials.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
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
          errorBuilder: (_, _, _) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() {
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

/// A single heart "like" control with a count.
class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
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

/// avatar + name + text (+ optional like) layout shared by all posts.
class PostBody extends StatelessWidget {
  const PostBody({
    super.key,
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
        Avatar(
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
              if (onLike != null) ...[
                const SizedBox(height: 8),
                LikeButton(
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

// ─── Per-task discussion thread ──────────────────────────────────────────────

/// A lightweight, inline-expandable discussion attached to a single study task
/// (a chapter, a key verse, the reflection). Collapsed it's a quiet "Discuss"
/// row with participant avatars; expanded it reveals the thread in place.
class DiscussionThread extends StatefulWidget {
  const DiscussionThread({
    super.key,
    required this.seededPosts,
    required this.yourReplies,
    required this.accent,
    required this.liked,
    required this.likeCount,
    required this.onLike,
    required this.onAddReply,
  });

  final List<CirclePost> seededPosts;
  final List<String> yourReplies;
  final Color accent;
  final bool Function(String postId) liked;
  final int Function(CirclePost post) likeCount;
  final void Function(String postId) onLike;
  final VoidCallback onAddReply;

  @override
  State<DiscussionThread> createState() => _DiscussionThreadState();
}

class _DiscussionThreadState extends State<DiscussionThread> {
  bool _expanded = false;

  int get _count => widget.seededPosts.length + widget.yourReplies.length;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = widget.accent;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: accent.withValues(alpha: 0.35), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(LucideIcons.messageCircle, size: 15, color: accent),
                const SizedBox(width: 7),
                Text(
                  _count == 0 ? 'Discuss' : 'Discussion · $_count',
                  style: AppFonts.sans(
                    color: accent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (widget.seededPosts.isNotEmpty && !_expanded)
                  _AvatarStack(posts: widget.seededPosts),
                const SizedBox(width: 6),
                Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                  color: palette.inkFaint,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            for (final p in widget.seededPosts) ...[
              PostBody(
                post: p,
                palette: palette,
                liked: widget.liked(p.id),
                likeCount: widget.likeCount(p),
                onLike: () => widget.onLike(p.id),
              ),
              const SizedBox(height: 12),
            ],
            for (var i = 0; i < widget.yourReplies.length; i++) ...[
              PostBody(
                post: CirclePost(
                  id: 'you_reply_$i',
                  author: 'You',
                  color: accent,
                  text: widget.yourReplies[i],
                  byYou: true,
                  avatar: kYouAvatar,
                ),
                palette: palette,
                liked: false,
                likeCount: 0,
                onLike: null,
              ),
              const SizedBox(height: 12),
            ],
            if (_count == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Be the first to share a thought on this.',
                  style: AppFonts.sans(
                    color: palette.inkFaint,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onAddReply,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  foregroundColor: accent,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(LucideIcons.reply, size: 15),
                label: Text(
                  'Add a comment',
                  style: AppFonts.sans(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Up to three overlapping avatars used as a "who's talking" affordance.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.posts});
  final List<CirclePost> posts;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shown = posts.take(3).toList();
    const d = 20.0;
    const step = 13.0;
    return SizedBox(
      width: d + (shown.length - 1) * step,
      height: d,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.paper, width: 1.5),
                ),
                child: Avatar(
                  size: d - 3,
                  avatar: shown[i].avatar,
                  fallbackText: initialsFor(shown[i].author),
                  color: shown[i].color,
                  fontSize: 9,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Group discussion forum (bottom of the study) ────────────────────────────

/// The whole-study conversation: curated prompts everyone answers, plus an
/// open "thoughts" wall. Lives at the bottom of a "study with friends" page.
class GroupForum extends StatelessWidget {
  const GroupForum({
    super.key,
    required this.circle,
    required this.answers,
    required this.ideas,
    required this.accent,
    required this.liked,
    required this.likeCount,
    required this.onLike,
    required this.onReply,
    required this.onShareThought,
  });

  final StudyCircle circle;
  final Map<int, String> answers;
  final List<String> ideas;
  final Color accent;
  final bool Function(String postId) liked;
  final int Function(CirclePost post) likeCount;
  final void Function(String postId) onLike;
  final void Function(int index) onReply;
  final VoidCallback onShareThought;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GROUP DISCUSSION',
          style: AppFonts.sans(
            color: palette.inkSoft,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < circle.questions.length; i++) ...[
          _QuestionCard(
            index: i,
            question: circle.questions[i],
            answers: circle.seededAnswers[i],
            yourAnswer: answers[i],
            accent: accent,
            palette: palette,
            liked: liked,
            likeCount: likeCount,
            onLike: onLike,
            onReply: () => onReply(i),
          ),
          const SizedBox(height: 16),
        ],
        for (final idea in ideas)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PostCard(
              post: CirclePost(
                id: 'you_idea',
                author: 'You',
                color: accent,
                text: idea,
                byYou: true,
                avatar: kYouAvatar,
              ),
              palette: palette,
            ),
          ),
        const SizedBox(height: 4),
        _AddButton(
          label: 'Share your thoughts',
          accent: accent,
          palette: palette,
          onTap: onShareThought,
        ),
      ],
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
            PostBody(
              post: a,
              palette: palette,
              liked: liked(a.id),
              likeCount: likeCount(a),
              onLike: () => onLike(a.id),
            ),
            const SizedBox(height: 12),
          ],
          if (yourAnswer != null)
            PostBody(
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

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.palette});
  final CirclePost post;
  final AppPalette palette;

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
      child: PostBody(
        post: post,
        palette: palette,
        liked: false,
        likeCount: 0,
        onLike: null,
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
            border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.4),
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

// ─── Participants "more" menu ────────────────────────────────────────────────

/// Shows the circle's participants and their progress in a bottom sheet.
Future<void> showCircleMembers(BuildContext context, StudyCircle circle) {
  final palette = context.palette;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: palette.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.inkFaint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Study circle',
                style: AppFonts.serif(
                    color: palette.ink, fontSize: 22, fontWeight: FontWeight.w600),
              ),
              Text(
                '${circle.members.length} members',
                style: AppFonts.sans(color: palette.inkSoft, fontSize: 13),
              ),
              const SizedBox(height: 16),
              for (final m in circle.members) ...[
                _MemberRow(member: m, palette: palette),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 2),
              _AddButton(
                label: 'Invite a friend',
                accent: circle.members.first.color,
                palette: palette,
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite link copied (prototype)')),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.palette});
  final CircleMember member;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final pct = (member.progress * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  value: member.progress,
                  strokeWidth: 3,
                  backgroundColor: palette.inkFaint.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation(member.color),
                ),
              ),
              Avatar(
                size: 36,
                avatar: member.avatar,
                fallbackText: member.initials,
                color: member.color,
                fontSize: 13,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.isYou ? 'You' : member.name,
                style: AppFonts.sans(
                  color: palette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pct >= 100 ? 'Completed the study' : '$pct% through',
                style: AppFonts.sans(color: palette.inkSoft, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Compose sheet ───────────────────────────────────────────────────────────

/// A bottom-sheet composer used for replies and shared thoughts. Returns the
/// entered text, or null if dismissed.
Future<String?> composeCircleText(
  BuildContext context, {
  required String title,
  required String hint,
  required Color accent,
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
                color: accent,
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
