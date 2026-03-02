import '../models/lesson.dart';

/// Expanded curriculum inspired by kid-first progressions (e.g., Jungle Junior):
/// - Lots of short lessons
/// - Repeated "finger gym", "mix", "practice", and "play" style drills
/// - Clear beginner -> intermediate -> advanced coverage
class ComprehensiveLessonCurriculum {
  ComprehensiveLessonCurriculum._();

  static final List<Lesson> allLessons = _buildLessons();

  static List<Lesson> _buildLessons() {
    final lessons = <Lesson>[];
    var order = 1;

    void addLesson({
      required String title,
      required String description,
      required LessonCategory category,
      required LessonDifficulty difficulty,
      required List<String> focusKeys,
      required List<String> exercises,
      required String emoji,
      required String funTip,
    }) {
      lessons.add(
        Lesson(
          id: 'neo-${order.toString().padLeft(3, '0')}',
          title: title,
          description: description,
          category: category,
          difficulty: difficulty,
          orderIndex: order,
          focusKeys: focusKeys,
          exercises: exercises,
          emoji: emoji,
          funTip: funTip,
        ),
      );
      order++;
    }

    final alphabet = 'abcdefghijklmnopqrstuvwxyz'.split('');

    // ------------------------------------------------------------
    // 1) Individual letter tracks: Letter -> Type + Mix
    // 26 letters * 2 = 52 lessons
    // ------------------------------------------------------------
    for (var i = 0; i < alphabet.length; i++) {
      final letter = alphabet[i];
      final upper = letter.toUpperCase();
      final category = _categoryForKey(letter);
      final learned = alphabet.sublist(0, i + 1);

      addLesson(
        title: upper,
        description: 'Find and press the $upper key.',
        category: category,
        difficulty: LessonDifficulty.beginner,
        focusKeys: [letter],
        emoji: '🔤',
        funTip: 'Use the correct finger every time for $upper.',
        exercises: _letterIntroExercises(letter),
      );

      addLesson(
        title: 'Type $upper + Mix',
        description: 'Type $upper and blend it with learned keys.',
        category: category,
        difficulty: LessonDifficulty.beginner,
        focusKeys: learned.length <= 4
            ? learned
            : learned.sublist(learned.length - 4),
        emoji: '⌨️',
        funTip: 'Mixing old and new keys helps your fingers remember faster.',
        exercises: _typeAndMixExercises(letter, learned),
      );
    }

    // ------------------------------------------------------------
    // 2) Mix-up, play, and quest groups by alphabet chunks
    // 9 groups * 3 = 27 lessons
    // ------------------------------------------------------------
    const letterGroups = <List<String>>[
      ['a', 'b', 'c'],
      ['d', 'e', 'f'],
      ['g', 'h', 'i'],
      ['j', 'k', 'l'],
      ['m', 'n', 'o'],
      ['p', 'q', 'r'],
      ['s', 't', 'u'],
      ['v', 'w', 'x'],
      ['y', 'z'],
    ];

    for (var i = 0; i < letterGroups.length; i++) {
      final group = letterGroups[i];
      final label = group.map((k) => k.toUpperCase()).join(' ');
      final category = _categoryForKeys(group);

      addLesson(
        title: '$label Mix Up!',
        description: 'Mix these letters in short bursts.',
        category: category,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: group,
        emoji: '🎯',
        funTip: 'Stay relaxed while letters switch.',
        exercises: _mixExercises(group),
      );

      addLesson(
        title: 'Play: $label',
        description: 'Fun speed round for $label.',
        category: category,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: group,
        emoji: '🎮',
        funTip: 'Accuracy first, speed second.',
        exercises: _playExercises(group),
      );

      addLesson(
        title: 'Quest: $label',
        description: 'Fun mixed mission with these keys.',
        category: category,
        difficulty: i < 5
            ? LessonDifficulty.intermediate
            : LessonDifficulty.advanced,
        focusKeys: group,
        emoji: '🕹️',
        funTip: 'Complete each mini mission with smooth rhythm.',
        exercises: _groupQuestExercises(group),
      );
    }

    // ------------------------------------------------------------
    // 3) Alphabet range practice blocks
    // 4 ranges * 5 = 20 lessons
    // ------------------------------------------------------------
    const rangeEnds = ['f', 'l', 'r', 'z'];

    for (final end in rangeEnds) {
      final endIndex = alphabet.indexOf(end) + 1;
      final range = alphabet.sublist(0, endIndex);
      final leftLabel = 'A to ${end.toUpperCase()}';
      final rightLabel = '${end.toUpperCase()} to A';

      addLesson(
        title: leftLabel,
        description: 'Forward alphabet range practice.',
        category: LessonCategory.commonWords,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: [],
        emoji: '🔡',
        funTip: 'Keep your eyes on the text, not the keys.',
        exercises: _rangeExercises(range, reverse: false),
      );

      addLesson(
        title: rightLabel,
        description: 'Backward alphabet range practice.',
        category: LessonCategory.commonWords,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: [],
        emoji: '🔠',
        funTip: 'Backward runs build strong control.',
        exercises: _rangeExercises(range, reverse: true),
      );

      addLesson(
        title: 'Practice $leftLabel',
        description: 'Mixed short runs in this range.',
        category: LessonCategory.commonWords,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: [],
        emoji: '🧩',
        funTip: 'Steady rhythm helps your hands remember.',
        exercises: _rangePracticeExercises(range),
      );

      addLesson(
        title: 'Play $leftLabel',
        description: 'Fast mini game style drills.',
        category: LessonCategory.commonWords,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: [],
        emoji: '🏁',
        funTip: 'Try to finish each line with no mistakes.',
        exercises: _rangePlayExercises(range),
      );

      addLesson(
        title: 'Practice Plus $leftLabel',
        description: 'Final checkpoint for this alphabet range.',
        category: LessonCategory.commonWords,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: [],
        emoji: '✅',
        funTip: 'Clean typing now means faster typing later.',
        exercises: _rangeCheckpointExercises(range),
      );
    }

    // ------------------------------------------------------------
    // 4) Word patterns
    // 16 lessons
    // ------------------------------------------------------------
    const patternFamilies = <String, List<String>>{
      '_ad': ['bad', 'dad', 'had', 'mad', 'sad'],
      '_at': ['cat', 'hat', 'mat', 'rat', 'sat'],
      '_ed': ['bed', 'fed', 'red', 'wed', 'sled'],
      '_et': ['jet', 'net', 'pet', 'wet', 'set'],
      '_ip': ['dip', 'hip', 'lip', 'rip', 'sip'],
      '_it': ['bit', 'fit', 'hit', 'kit', 'sit'],
      '_op': ['cop', 'hop', 'mop', 'pop', 'top'],
      '_ot': ['dot', 'got', 'hot', 'not', 'pot'],
      '_ug': ['bug', 'dug', 'hug', 'mug', 'rug'],
      '_un': ['bun', 'fun', 'run', 'sun', 'pun'],
      '_an': ['can', 'fan', 'man', 'pan', 'van'],
      '_ap': ['cap', 'gap', 'lap', 'map', 'tap'],
      '_ell': ['bell', 'fell', 'sell', 'tell', 'well'],
      '_ake': ['bake', 'cake', 'lake', 'make', 'take'],
      '_ill': ['bill', 'fill', 'hill', 'mill', 'pill'],
      '_ing': ['king', 'ring', 'sing', 'thing', 'wing'],
    };

    var patternIndex = 0;
    for (final entry in patternFamilies.entries) {
      patternIndex++;
      addLesson(
        title: 'Pattern ${entry.key}',
        description: 'Practice this word family pattern.',
        category: LessonCategory.commonWords,
        difficulty: patternIndex <= 6
            ? LessonDifficulty.beginner
            : LessonDifficulty.intermediate,
        focusKeys: [],
        emoji: '🥁',
        funTip: 'Patterns make typing feel easier and faster.',
        exercises: _patternExercises(entry.value),
      );
    }

    // ------------------------------------------------------------
    // 5) Sight words
    // 24 lessons
    // ------------------------------------------------------------
    const sightPairs = <List<String>>[
      ['a', 'are'],
      ['at', 'black'],
      ['brown', 'four'],
      ['get', 'like'],
      ['must', 'our'],
      ['out', 'ride'],
      ['saw', 'that'],
      ['there', 'was'],
      ['after', 'by'],
      ['could', 'going'],
      ['had', 'just'],
      ['know', 'put'],
      ['once', 'round'],
      ['some', 'them'],
      ['well', 'white'],
      ['who', 'yes'],
      ['come', 'from'],
      ['look', 'many'],
      ['make', 'open'],
      ['pretty', 'said'],
      ['their', 'walk'],
      ['water', 'where'],
      ['little', 'people'],
      ['sound', 'write'],
    ];

    for (final pair in sightPairs) {
      addLesson(
        title: 'Sight: ${_cap(pair[0])} - ${_cap(pair[1])}',
        description: 'High-frequency word pair practice.',
        category: LessonCategory.commonWords,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: [],
        emoji: '👀',
        funTip: 'These words appear all the time in books.',
        exercises: _sightWordExercises(pair[0], pair[1]),
      );
    }

    // ------------------------------------------------------------
    // 6) Phrases
    // 12 lessons
    // ------------------------------------------------------------
    const phraseThemes = <String>[
      'water',
      'write',
      'people',
      'more',
      'day',
      'air',
      'river',
      'sound',
      'little',
      'after',
      'animals',
      'think',
    ];

    for (final theme in phraseThemes) {
      addLesson(
        title: 'Phrase: ${_cap(theme)}',
        description: 'Short phrase typing around "$theme".',
        category: LessonCategory.commonWords,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: [],
        emoji: '📝',
        funTip: 'Short phrases build smooth sentence flow.',
        exercises: _phraseExercises(theme),
      );
    }

    // ------------------------------------------------------------
    // 7) Sentence sets
    // 12 lessons (5 sentences each)
    // ------------------------------------------------------------
    const sentenceBank = <String>[
      'the dog ran to the park.',
      'my cat likes warm milk.',
      'we read books after lunch.',
      'i can help my friend today.',
      'the sun is bright and warm.',
      'our class will plant a tree.',
      'birds sing near the window.',
      'mom and dad made soup.',
      'we play games on friday.',
      'the frog jumped in the pond.',
      'a red kite flew very high.',
      'my pencil is on the desk.',
      'we count stars at night.',
      'the rabbit hides in grass.',
      'our team won the game.',
      'i drink water after sports.',
      'the bus stops near school.',
      'a big cloud covered the sky.',
      'we draw maps in class.',
      'my shoes are under the bed.',
      'the robot can wave hello.',
      'please close the blue door.',
      'the fish swims very fast.',
      'we clap when songs begin.',
      'i packed snacks for the trip.',
      'our teacher reads a story.',
      'a fox ran past the farm.',
      'the wind moved the leaves.',
      'we clean up after art time.',
      'my brother rides his bike.',
      'the baby bird wants food.',
      'we line up by the gate.',
      'a tall tree shades the path.',
      'my friend found a shell.',
      'the rain stopped by noon.',
      'we share crayons and paper.',
      'the turtle crossed the road.',
      'i wrote my name neatly.',
      'our class sang with joy.',
      'the moon looked very bright.',
      'we built towers with blocks.',
      'dad fixed the broken toy.',
      'a bee buzzed near flowers.',
      'my lunch had rice and fruit.',
      'we watched clouds drift slowly.',
      'the puppy slept on a rug.',
      'i waved to my neighbor.',
      'our garden grew green beans.',
      'the bell rang at three.',
      'we packed bags for camp.',
      'a small boat crossed the lake.',
      'my sister made a card.',
      'we write in quiet time.',
      'the painter mixed bright colors.',
      'our team solved the puzzle.',
      'i can type with calm hands.',
      'the class cheered for all.',
      'we ended with a smile.',
      'today i practiced every key.',
      'great work, keep going.',
    ];

    for (var i = 0; i < 12; i++) {
      final start = i * 5;
      final chunk = sentenceBank.sublist(start, start + 5);
      addLesson(
        title: 'Sentence Set ${i + 1}',
        description: 'Short full sentences for fluency.',
        category: LessonCategory.sentences,
        difficulty: i < 4
            ? LessonDifficulty.intermediate
            : LessonDifficulty.advanced,
        focusKeys: [],
        emoji: '💬',
        funTip: 'Keep moving forward even after a small mistake.',
        exercises: chunk,
      );
    }

    // ------------------------------------------------------------
    // 7b) Overall mixed review lessons
    // 12 lessons
    // ------------------------------------------------------------
    const overallReviewTopics = <String>[
      'dog',
      'cat',
      'school',
      'good day',
      'people',
      'top',
      'give',
      'name',
      'mom and dad',
      'friends',
      'help',
      'line',
    ];

    for (var i = 0; i < overallReviewTopics.length; i++) {
      final topic = overallReviewTopics[i];
      addLesson(
        title: 'Review: ${_capWords(topic)}',
        description: 'Mixed review with words and short sentences.',
        category: LessonCategory.sentences,
        difficulty: i < 8
            ? LessonDifficulty.intermediate
            : LessonDifficulty.advanced,
        focusKeys: [],
        emoji: '🎉',
        funTip: 'These review sets mix old and new skills together.',
        exercises: _overallReviewExercises(topic),
      );
    }

    // ------------------------------------------------------------
    // 8) Punctuation + numbers
    // 12 lessons
    // ------------------------------------------------------------
    addLesson(
      title: 'Period',
      description: 'Practice lines that end with a period.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: ['.'],
      emoji: '🟣',
      funTip: 'Period means stop, then reset.',
      exercises: const [
        'dot. dot. dot.',
        'stop. go. stop.',
        'i can type this.',
        'we are done.',
        'good job.',
      ],
    );

    addLesson(
      title: 'Comma',
      description: 'Use commas in short lists.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [','],
      emoji: '🟠',
      funTip: 'Comma is a tiny pause in a sentence.',
      exercises: const [
        'red, blue, green,',
        'cat, dog, fish,',
        'run, jump, clap,',
        'one, two, three,',
        'eat, drink, smile,',
      ],
    );

    addLesson(
      title: 'Slash',
      description: 'Practice the slash key in pairs.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: ['/'],
      emoji: '➗',
      funTip: 'Slash is quick, then back home.',
      exercises: const [
        'up/down up/down',
        'left/right left/right',
        'in/out in/out',
        'on/off on/off',
        'yes/no yes/no',
      ],
    );

    addLesson(
      title: 'Dash and Equals',
      description: 'Top row symbol practice.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: ['-', '='],
      emoji: '➖',
      funTip: 'Right pinky leads these keys.',
      exercises: const ['1-1=0', '2-1=1', '3-1=2', '6-2=4', '9-4=5'],
    );

    addLesson(
      title: 'Numbers 1 to 5',
      description: 'Left side number row.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: ['1', '2', '3', '4', '5'],
      emoji: '1️⃣',
      funTip: 'Reach up and return to home row.',
      exercises: const [
        '1 2 3 4 5',
        '11 22 33 44 55',
        '12 23 34 45',
        '123 234 345',
        '5 4 3 2 1',
      ],
    );

    addLesson(
      title: 'Numbers 6 to 0',
      description: 'Right side number row.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: ['6', '7', '8', '9', '0'],
      emoji: '🔢',
      funTip: 'Stay relaxed while reaching.',
      exercises: const [
        '6 7 8 9 0',
        '66 77 88 99 00',
        '67 78 89 90',
        '678 789 890',
        '0 9 8 7 6',
      ],
    );

    addLesson(
      title: 'All Numbers Mix',
      description: 'Combine all digits in short bursts.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.advanced,
      focusKeys: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
      emoji: '🎲',
      funTip: 'Consistency beats rushing.',
      exercises: const [
        '123 456 789 0',
        '246 135 790',
        '987 654 321',
        '102 304 506',
        '12345 67890',
      ],
    );

    addLesson(
      title: 'Dates',
      description: 'Numbers with slash date patterns.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.advanced,
      focusKeys: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '/'],
      emoji: '📅',
      funTip: 'Keep each date clean and even.',
      exercises: const [
        '01/02 03/04',
        '05/06 07/08',
        '09/10 11/12',
        '12/25 01/01',
        '2026/03/02',
      ],
    );

    addLesson(
      title: 'Scores',
      description: 'Type score-like numeric lines.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.advanced,
      focusKeys: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', '.'],
      emoji: '🏅',
      funTip: 'Short pauses help maintain accuracy.',
      exercises: const [
        'team a 9.5',
        'team b 8.7',
        'round 1 10.0',
        'round 2 9.2',
        'final 19.2',
      ],
    );

    addLesson(
      title: 'Data Entry 1',
      description: 'Simple data style typing lines.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.advanced,
      focusKeys: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '.'],
      emoji: '📋',
      funTip: 'Keep a steady, repeatable speed.',
      exercises: const [
        'id 01, score 98.',
        'id 02, score 87.',
        'id 03, score 90.',
        'id 04, score 76.',
        'id 05, score 99.',
      ],
    );

    addLesson(
      title: 'Data Entry 2',
      description: 'More short numeric records.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.advanced,
      focusKeys: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '='],
      emoji: '📊',
      funTip: 'Aim for smooth key transitions.',
      exercises: const [
        'set-1=245',
        'set-2=389',
        'set-3=410',
        'set-4=276',
        'set-5=333',
      ],
    );

    addLesson(
      title: 'Final Challenge',
      description: 'Mixed punctuation, words, and numbers.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🏆',
      funTip: 'Finish strong with calm, accurate typing.',
      exercises: const [
        'today is 2026/03/02.',
        'we scored 9.4, then 9.8.',
        'level-4=pass.',
        'pack 2 maps, 3 pens, 1 bag.',
        'great job. keep typing.',
      ],
    );

    return lessons;
  }

  static const Set<String> _topRow = {
    'q',
    'w',
    'e',
    'r',
    't',
    'y',
    'u',
    'i',
    'o',
    'p',
  };

  static const Set<String> _homeRow = {
    'a',
    's',
    'd',
    'f',
    'g',
    'h',
    'j',
    'k',
    'l',
  };

  static const Set<String> _bottomRow = {'z', 'x', 'c', 'v', 'b', 'n', 'm'};

  static LessonCategory _categoryForKey(String key) {
    if (_topRow.contains(key)) return LessonCategory.topRow;
    if (_homeRow.contains(key)) return LessonCategory.homeRow;
    if (_bottomRow.contains(key)) return LessonCategory.bottomRow;
    return LessonCategory.commonWords;
  }

  static LessonCategory _categoryForKeys(List<String> keys) {
    var top = 0;
    var home = 0;
    var bottom = 0;

    for (final key in keys) {
      if (_topRow.contains(key)) {
        top++;
      } else if (_homeRow.contains(key)) {
        home++;
      } else if (_bottomRow.contains(key)) {
        bottom++;
      }
    }

    if (home >= top && home >= bottom) return LessonCategory.homeRow;
    if (top >= home && top >= bottom) return LessonCategory.topRow;
    if (bottom >= home && bottom >= top) return LessonCategory.bottomRow;
    return LessonCategory.commonWords;
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static String _capWords(String s) =>
      s.split(' ').map((w) => _cap(w)).join(' ');

  static List<String> _letterIntroExercises(String key) {
    return [
      '$key $key $key $key',
      '$key$key $key$key $key$key',
      '$key $key $key $key $key $key',
      '$key$key$key $key$key$key',
      '$key$key $key$key$key $key$key',
    ];
  }

  static List<String> _typeAndMixExercises(String key, List<String> learned) {
    final a = key;
    final b = learned.length > 1 ? learned[learned.length - 2] : key;
    final c = learned.length > 2 ? learned[0] : b;
    final d = learned.length > 3 ? learned[learned.length - 3] : c;

    return [
      '$a$a$a $b$b $a$a',
      '$a$b $b$a $a$b',
      '$a$c $c$a $a$c',
      '$a$d $d$a $b$a',
      '$a$b$c $c$b$a',
    ];
  }

  static List<String> _mixExercises(List<String> keys) {
    final a = keys[0];
    final b = keys.length > 1 ? keys[1] : keys[0];
    final c = keys.length > 2 ? keys[2] : b;

    return [
      '$a $b $c $a $b $c',
      '$a$b$c $c$b$a',
      '$a$a $b$b $c$c',
      '$a$b $b$c $c$a',
      '$a$b$c $a$c$b $b$a$c',
    ];
  }

  static List<String> _playExercises(List<String> keys) {
    final a = keys[0];
    final b = keys.length > 1 ? keys[1] : keys[0];
    final c = keys.length > 2 ? keys[2] : b;

    return [
      '$a$b$c $a$b$c',
      '$a$c $b$a $c$b',
      '$a$a$b $b$c$c',
      '$c$b$a $a$b$c',
      '$a$b $c$a $b$c $a$b',
    ];
  }

  static List<String> _groupQuestExercises(List<String> keys) {
    final a = keys[0];
    final b = keys.length > 1 ? keys[1] : keys[0];
    final c = keys.length > 2 ? keys[2] : b;

    return [
      '$a$b $b$c $c$a',
      '$a$a$b $b$c$c',
      '$c$b$a $a$c$b',
      '$a$b$c $b$c$a $c$a$b',
      '$a$b$c $a$b$c',
    ];
  }

  static List<String> _rangeExercises(
    List<String> range, {
    required bool reverse,
  }) {
    final keys = reverse ? range.reversed.toList() : range;
    final n = keys.length < 6 ? keys.length : 6;
    final first = keys.take(n).toList();
    final second = keys.reversed.take(n).toList().reversed.toList();

    return [
      first.join(' '),
      second.join(' '),
      '${first.join()} ${second.join()}',
      '${first.join(' ')} ${second.take(3).join(' ')}',
      '${second.join(' ')} ${first.take(3).join(' ')}',
    ];
  }

  static List<String> _rangePracticeExercises(List<String> range) {
    final n = range.length < 6 ? range.length : 6;
    final first = range.take(n).toList();
    final midStart = (range.length ~/ 2) - (n ~/ 2);
    final safeStart = midStart < 0 ? 0 : midStart;
    final middle = range.skip(safeStart).take(n).toList();
    final last = range.reversed.take(n).toList().reversed.toList();

    return [
      first.join(' '),
      middle.join(' '),
      last.join(' '),
      '${first.join()} ${middle.join()}',
      '${middle.join()} ${last.join()}',
    ];
  }

  static List<String> _rangePlayExercises(List<String> range) {
    final n = range.length < 6 ? range.length : 6;
    final a = range.take(n).toList();
    final b = range.reversed.take(n).toList();

    return [
      a.join(' '),
      b.join(' '),
      '${a.join()} ${b.join()}',
      '${a.take(3).join(' ')} ${b.take(3).join(' ')}',
      '${b.take(3).join(' ')} ${a.take(3).join(' ')}',
    ];
  }

  static List<String> _rangeCheckpointExercises(List<String> range) {
    final n = range.length < 6 ? range.length : 6;
    final left = range.take(n).toList();
    final right = range.reversed.take(n).toList();

    return [
      '${left.join(' ')} ${right.join(' ')}',
      '${left.join()} ${right.join()}',
      '${left.take(4).join(' ')} ${right.take(4).join(' ')}',
      '${right.take(4).join(' ')} ${left.take(4).join(' ')}',
      '${left.take(3).join()} ${right.take(3).join()} ${left.take(2).join()}',
    ];
  }

  static List<String> _patternExercises(List<String> words) {
    return [
      words.join(' '),
      '${words[0]} ${words[1]} ${words[0]} ${words[2]}',
      '${words[3]} ${words[4]} ${words[3]}',
      'a ${words[0]} and a ${words[1]}',
      '${words[2]} ${words[3]} ${words[4]}',
    ];
  }

  static List<String> _sightWordExercises(String a, String b) {
    return [
      '$a $b $a $b',
      '$a and $b',
      'we can $a',
      'you can $b',
      '$a $b today',
    ];
  }

  static List<String> _phraseExercises(String theme) {
    return [
      '$theme is here.',
      'we see $theme.',
      'i like $theme.',
      'more $theme today.',
      '$theme helps us.',
    ];
  }

  static List<String> _overallReviewExercises(String topic) {
    return [
      '$topic is fun.',
      'we can type $topic.',
      'i see $topic today.',
      '$topic helps me learn.',
      'great work with $topic.',
    ];
  }

  /// Get lessons by category
  static List<Lesson> byCategory(LessonCategory category) =>
      allLessons.where((l) => l.category == category).toList();

  /// Get lessons by difficulty
  static List<Lesson> byDifficulty(LessonDifficulty difficulty) =>
      allLessons.where((l) => l.difficulty == difficulty).toList();

  /// Get a lesson by its ID
  static Lesson? byId(String id) {
    try {
      return allLessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get the next lesson after the given one (across category flow)
  static Lesson? nextLesson(String currentLessonId) {
    final current = byId(currentLessonId);
    if (current == null) return null;

    // Next in same category first
    final categoryLessons = byCategory(current.category);
    final idx = categoryLessons.indexWhere((l) => l.id == currentLessonId);
    if (idx >= 0 && idx < categoryLessons.length - 1) {
      return categoryLessons[idx + 1];
    }

    // Then first lesson of next category
    final catIdx = categoryOrder.indexOf(current.category);
    if (catIdx >= 0 && catIdx < categoryOrder.length - 1) {
      final nextCatLessons = byCategory(categoryOrder[catIdx + 1]);
      if (nextCatLessons.isNotEmpty) return nextCatLessons.first;
    }

    return null;
  }

  static const List<LessonCategory> categoryOrder = [
    LessonCategory.homeRow,
    LessonCategory.topRow,
    LessonCategory.bottomRow,
    LessonCategory.commonWords,
    LessonCategory.sentences,
    LessonCategory.numbers,
  ];

  static const List<LessonDifficulty> difficultyOrder = [
    LessonDifficulty.beginner,
    LessonDifficulty.intermediate,
    LessonDifficulty.advanced,
  ];
}
