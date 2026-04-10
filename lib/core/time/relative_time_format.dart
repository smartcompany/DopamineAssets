import 'package:intl/intl.dart';

/// [localeTag] 예: `ko`, `ko-KR`, `en`, `en-US`
String formatRelativeCommentTime(DateTime createdAt, String localeTag) {
  final local = createdAt.toLocal();
  final now = DateTime.now();
  var diff = now.difference(local);
  if (diff.isNegative) {
    diff = Duration.zero;
  }
  final parts = localeTag.trim().split(RegExp(r'[-_]'));
  final primary = parts.isEmpty ? '' : parts.first.toLowerCase();
  final isKo = primary == 'ko';

  if (diff.inSeconds < 60) {
    return isKo ? '방금' : 'just now';
  }
  final mins = diff.inMinutes;
  if (mins < 60) {
    return isKo ? '$mins분 전' : '${mins}m ago';
  }
  final hours = diff.inHours;
  if (hours < 24) {
    return isKo ? '$hours시간 전' : '${hours}h ago';
  }
  return DateFormat.yMMMd(localeTag).add_jm().format(local);
}

/// 게시글·피드 카드 등 본문 작성 시각 표시용 ([formatRelativeCommentTime] 와 동일 규칙).
String formatRelativePostTime(DateTime createdAt, String localeTag) {
  return formatRelativeCommentTime(createdAt, localeTag);
}
