import 'dart:convert';

/// A user profile for tracking individual progress
class Profile {
  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  String encode() => jsonEncode(toJson());

  factory Profile.decode(String source) =>
      Profile.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Available avatar emojis kids can choose from
  static const List<String> avatarOptions = [
    '🐵',
    '🐶',
    '🐱',
    '🐰',
    '🦊',
    '🐻',
    '🐼',
    '🐨',
    '🦁',
    '🐯',
    '🐸',
    '🐧',
    '🦄',
    '🐲',
    '🦋',
    '🐬',
  ];
}
