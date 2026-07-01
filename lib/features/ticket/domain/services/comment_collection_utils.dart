import '../entities/comment_entity.dart';

int compareCommentsDeterministically(CommentEntity a, CommentEntity b) {
  final createdOrder = a.createdAt.compareTo(b.createdAt);
  if (createdOrder != 0) {
    return createdOrder;
  }

  return a.id.compareTo(b.id);
}

List<CommentEntity> deduplicateAndSortComments(
  Iterable<CommentEntity> comments,
) {
  final unique = <String, CommentEntity>{};

  for (final comment in comments) {
    final previous = unique[comment.id];
    if (previous == null ||
        comment.createdAt.isAfter(previous.createdAt) ||
        comment.createdAt.isAtSameMomentAs(previous.createdAt)) {
      unique[comment.id] = comment;
    }
  }

  final sorted = unique.values.toList(growable: false);
  sorted.sort(compareCommentsDeterministically);
  return sorted;
}
