/// Domain model representing a verified 60-90s micro-reel for the Explore Feed.
class WorkoutMicroReel {
  final String id;
  final String tenantId;
  final String userId;
  final String? memberName;
  final String videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String? routineTitle;
  final int streakDaysAtRecord;
  final bool isPublicExplore;
  final bool isFlagged;
  final int likesCount;
  final DateTime? createdAt;

  const WorkoutMicroReel({
    required this.id,
    required this.tenantId,
    required this.userId,
    this.memberName,
    required this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds = 60,
    this.routineTitle,
    this.streakDaysAtRecord = 0,
    this.isPublicExplore = true,
    this.isFlagged = false,
    this.likesCount = 0,
    this.createdAt,
  });

  factory WorkoutMicroReel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return WorkoutMicroReel(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      memberName: profile?['full_name'] as String? ?? json['member_name'] as String?,
      videoUrl: json['video_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 60,
      routineTitle: json['routine_title'] as String?,
      streakDaysAtRecord: (json['streak_days_at_record'] as num?)?.toInt() ?? 0,
      isPublicExplore: json['is_public_explore'] as bool? ?? true,
      isFlagged: json['is_flagged'] as bool? ?? false,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'user_id': userId,
    'video_url': videoUrl,
    'thumbnail_url': thumbnailUrl,
    'duration_seconds': durationSeconds,
    'routine_title': routineTitle,
    'streak_days_at_record': streakDaysAtRecord,
    'is_public_explore': isPublicExplore,
    'is_flagged': isFlagged,
    'likes_count': likesCount,
  };
}
