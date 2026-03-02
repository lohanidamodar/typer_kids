import 'dart:math';

/// Difficulty levels shared across games, sandbox, and typing tests.
enum ContentDifficulty {
  easy('Easy', '🌱', 'Short, simple words'),
  medium('Medium', '🌿', 'Common everyday words'),
  hard('Hard', '🌳', 'Longer, trickier words');

  const ContentDifficulty(this.label, this.emoji, this.description);
  final String label;
  final String emoji;
  final String description;
}

/// Word pools for typing games, organized by difficulty.
class WordLists {
  WordLists._();

  static const List<String> easy = [
    'the', 'and', 'cat', 'dog', 'hat', 'sun', 'run', 'big', 'red',
    'hop', 'sit', 'got', 'put', 'top', 'cup', 'fun', 'map', 'net',
    'pen', 'ten', 'van', 'box', 'fox', 'yes', 'bed', 'bus', 'can',
    'eat', 'far', 'get', 'him', 'hot', 'ice', 'jet', 'kit', 'lot',
    'mix', 'new', 'old', 'pie', 'sad', 'tip', 'use', 'art', 'bat',
    'car', 'day', 'egg', 'fly', 'gum', 'hug', 'ink', 'jar', 'key',
    'lip', 'mud', 'nap', 'owl', 'pop', 'rug', 'sky', 'toy', 'vet',
    'win', 'yak', 'zip', 'arm', 'ask', 'bit', 'bow', 'cub', 'dig',
    'dry', 'elf', 'fan', 'fit', 'gem', 'hen', 'hut', 'jog', 'led',
    'log', 'mop', 'nut', 'oar', 'pad', 'pal', 'ram', 'row', 'sip',
    'sob', 'tag', 'tug', 'wig', 'yam',
  ];

  static const List<String> medium = [
    'apple', 'happy', 'smile', 'house', 'water', 'dance', 'music',
    'train', 'light', 'green', 'brown', 'cloud', 'fruit', 'plant',
    'sweet', 'brain', 'chair', 'dream', 'earth', 'flame', 'grape',
    'heart', 'juice', 'lemon', 'melon', 'night', 'ocean', 'pearl',
    'queen', 'river', 'stone', 'tiger', 'voice', 'whale', 'brave',
    'chalk', 'climb', 'giant', 'magic', 'paint', 'robot', 'space',
    'tower', 'world', 'beach', 'candy', 'fairy', 'jolly', 'lucky',
    'money', 'party', 'quick', 'sunny', 'truck', 'clock', 'cream',
    'dress', 'eagle', 'field', 'globe', 'honey', 'jelly', 'knife',
    'maple', 'olive', 'piano', 'quest', 'royal', 'sharp', 'toast',
    'unity', 'vivid', 'youth', 'bloom', 'crisp', 'drift', 'frost',
    'grasp', 'honor', 'image', 'lotus', 'north', 'orbit', 'pride',
  ];

  static const List<String> hard = [
    'amazing', 'believe', 'captain', 'dolphin', 'explore', 'freedom',
    'giraffe', 'harvest', 'imagine', 'journey', 'kitchen', 'library',
    'monster', 'natural', 'penguin', 'quality', 'rainbow', 'science',
    'teacher', 'unicorn', 'volcano', 'weather', 'excited', 'friendly',
    'tropical', 'birthday', 'champion', 'dinosaur', 'elephant', 'princess',
    'treasure', 'umbrella', 'vacation', 'alphabet', 'creative', 'carnival',
    'download', 'exercise', 'keyboard', 'mountain', 'sandwich', 'practice',
    'together', 'yourself', 'airplane', 'building', 'darkness', 'envelope',
    'favorite', 'goldfish', 'junction', 'balanced', 'complain', 'delivery',
    'engineer', 'flexible', 'grateful', 'handsome', 'interior', 'kangaroo',
    'lavender', 'michigan', 'notebook', 'offering', 'pleasant', 'realized',
    'shoulder', 'thousand', 'uncommon', 'watchful',
  ];

  static List<String> forDifficulty(ContentDifficulty d) => switch (d) {
    ContentDifficulty.easy => easy,
    ContentDifficulty.medium => medium,
    ContentDifficulty.hard => hard,
  };

  static final _random = Random();

  /// Pick a random word for the given difficulty.
  static String randomWord(ContentDifficulty d) {
    final list = forDifficulty(d);
    return list[_random.nextInt(list.length)];
  }
}
