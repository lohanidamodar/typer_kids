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
      description: 'Numbers in date style patterns.',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.advanced,
      focusKeys: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
      emoji: '📅',
      funTip: 'Keep each date clean and even.',
      exercises: const [
        '01 02 03 04',
        '05 06 07 08',
        '09 10 11 12',
        '12 25 01 01',
        '2026 03 02',
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
      focusKeys: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
      emoji: '📊',
      funTip: 'Aim for smooth key transitions.',
      exercises: const [
        'set 1, 245.',
        'set 2, 389.',
        'set 3, 410.',
        'set 4, 276.',
        'set 5, 333.',
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
        'today is march 2, 2026.',
        'we scored 9.4, then 9.8.',
        'level 4 is a pass.',
        'pack 2 maps, 3 pens, 1 bag.',
        'great job. keep typing.',
      ],
    );

    // ------------------------------------------------------------
    // 9) Digraphs – common two-letter combos
    // 10 lessons
    // ------------------------------------------------------------
    const digraphs = <String, List<String>>{
      'sh': ['she', 'ship', 'shop', 'shed', 'fish', 'wish', 'rush', 'bash'],
      'ch': ['chin', 'chop', 'much', 'such', 'chat', 'chip', 'rich', 'each'],
      'th': ['the', 'this', 'that', 'them', 'then', 'with', 'bath', 'math'],
      'wh': ['what', 'when', 'where', 'why', 'which', 'while', 'white', 'wheel'],
      'ph': ['phone', 'photo', 'graph', 'phase', 'phew', 'phrase'],
      'ck': ['back', 'kick', 'duck', 'rock', 'lock', 'pack', 'neck', 'pick'],
      'ng': ['ring', 'song', 'long', 'sing', 'king', 'bang', 'hung', 'wing'],
      'qu': ['quit', 'quiz', 'queen', 'quick', 'quiet', 'quest', 'quote', 'quilt'],
      'wr': ['wrap', 'wren', 'write', 'wrong', 'wrist', 'wrote'],
      'kn': ['knit', 'know', 'knob', 'knee', 'kneel', 'knack', 'knife', 'knock'],
    };

    for (final entry in digraphs.entries) {
      final dg = entry.key;
      final words = entry.value;
      addLesson(
        title: 'Digraph: ${dg.toUpperCase()}',
        description: 'Practice words with the "$dg" sound.',
        category: LessonCategory.commonWords,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: dg.split(''),
        emoji: '🔗',
        funTip: 'These two letters always work as a team.',
        exercises: [
          '$dg $dg $dg $dg $dg',
          words.take(4).join(' '),
          words.skip(4).take(4).join(' '),
          '${words[0]} and ${words[1]}',
          words.join(' '),
        ],
      );
    }

    // ------------------------------------------------------------
    // 10) Consonant blends
    // 12 lessons
    // ------------------------------------------------------------
    const blends = <String, List<String>>{
      'bl': ['blue', 'black', 'blend', 'block', 'blank', 'bloom'],
      'br': ['brown', 'brave', 'bring', 'bread', 'brain', 'brush'],
      'cl': ['clap', 'climb', 'class', 'clean', 'close', 'cloud'],
      'cr': ['crab', 'crisp', 'cross', 'crown', 'crash', 'creek'],
      'dr': ['draw', 'drink', 'dream', 'dress', 'drive', 'drift'],
      'fl': ['flag', 'flame', 'float', 'floor', 'flash', 'flock'],
      'fr': ['frog', 'fresh', 'fruit', 'front', 'frame', 'frost'],
      'gr': ['gray', 'green', 'grape', 'grass', 'grand', 'grain'],
      'pl': ['play', 'plant', 'plane', 'place', 'pluck', 'plumb'],
      'sl': ['sled', 'slice', 'sleep', 'slide', 'slope', 'slime'],
      'sp': ['spot', 'space', 'spark', 'speak', 'speed', 'spice'],
      'st': ['star', 'stone', 'stand', 'steam', 'stick', 'storm'],
    };

    for (final entry in blends.entries) {
      final bl = entry.key;
      final words = entry.value;
      addLesson(
        title: 'Blend: ${bl.toUpperCase()}',
        description: 'Practice words starting with "$bl".',
        category: LessonCategory.commonWords,
        difficulty: LessonDifficulty.intermediate,
        focusKeys: bl.split(''),
        emoji: '🌀',
        funTip: 'Say the blend out loud as you type it.',
        exercises: [
          '$bl $bl $bl $bl $bl $bl',
          words.take(3).join(' '),
          words.skip(3).take(3).join(' '),
          '${words[0]} ${words[2]} ${words[4]}',
          words.join(' '),
        ],
      );
    }

    // ------------------------------------------------------------
    // 11) Compound words
    // 8 lessons
    // ------------------------------------------------------------
    const compoundGroups = <String, List<String>>{
      'Sun & Moon': ['sunshine', 'sunburn', 'sunset', 'moonlight', 'moonbeam'],
      'Home': ['homework', 'homemade', 'homeland', 'hometown', 'homeroom'],
      'Rain & Snow': ['rainbow', 'raindrop', 'rainfall', 'snowfall', 'snowman'],
      'Play & Fun': ['playground', 'playmate', 'playtime', 'funfair', 'campfire'],
      'Sea & Water': ['seashell', 'seaweed', 'seafood', 'waterfall', 'watermelon'],
      'Book & School': ['bookshelf', 'bookmark', 'notebook', 'backpack', 'classroom'],
      'Day & Night': ['daytime', 'daylight', 'birthday', 'nightfall', 'midnight'],
      'Air & Sky': ['airplane', 'airport', 'airmail', 'skyline', 'skyscraper'],
    };

    for (final entry in compoundGroups.entries) {
      final theme = entry.key;
      final words = entry.value;
      addLesson(
        title: 'Compound: $theme',
        description: 'Type compound words about $theme.',
        category: LessonCategory.commonWords,
        difficulty: LessonDifficulty.advanced,
        focusKeys: [],
        emoji: '🧱',
        funTip: 'Compound words are two words stuck together.',
        exercises: [
          words.take(3).join(' '),
          words.skip(3).join(' '),
          '${words[0]} and ${words[1]}',
          '${words[2]} ${words[3]} ${words[4]}',
          words.join(' '),
        ],
      );
    }

    // ------------------------------------------------------------
    // 12) Themed fun sentences – Space
    // 5 lessons
    // ------------------------------------------------------------
    addLesson(
      title: 'Space: Planets',
      description: 'Type sentences about planets.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '🪐',
      funTip: 'Explore the solar system one word at a time.',
      exercises: const [
        'mars is the red planet.',
        'jupiter is the biggest planet.',
        'saturn has beautiful rings.',
        'earth is where we live.',
        'neptune is cold and blue.',
      ],
    );

    addLesson(
      title: 'Space: Stars',
      description: 'Type sentences about stars.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '⭐',
      funTip: 'Stars are like tiny suns far, far away.',
      exercises: const [
        'the sun is a star.',
        'stars twinkle in the night sky.',
        'some stars are very old.',
        'a group of stars is called a constellation.',
        'the north star helps people find their way.',
      ],
    );

    addLesson(
      title: 'Space: Rockets',
      description: 'Type sentences about space travel.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🚀',
      funTip: 'Blast off with every sentence.',
      exercises: const [
        'astronauts fly rockets to space.',
        'a space suit keeps you safe.',
        'the rocket blasted off with a roar.',
        'we dream of visiting the moon.',
        'robots explore mars for us.',
      ],
    );

    // ------------------------------------------------------------
    // 13) Themed fun sentences – Ocean
    // 5 lessons
    // ------------------------------------------------------------
    addLesson(
      title: 'Ocean: Sea Life',
      description: 'Type sentences about sea creatures.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '🐠',
      funTip: 'Dive deep into typing practice.',
      exercises: const [
        'fish swim in the ocean.',
        'a dolphin jumps over waves.',
        'the octopus has eight arms.',
        'sea turtles live a long time.',
        'whales are the biggest animals.',
      ],
    );

    addLesson(
      title: 'Ocean: Coral Reef',
      description: 'Type sentences about coral reefs.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '🪸',
      funTip: 'Coral reefs are like underwater cities.',
      exercises: const [
        'coral reefs are full of color.',
        'tiny fish hide in the coral.',
        'starfish sit on the sea floor.',
        'crabs walk sideways on the sand.',
        'jellyfish float gently in the water.',
      ],
    );

    addLesson(
      title: 'Ocean: Deep Sea',
      description: 'Type sentences about the deep ocean.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🌊',
      funTip: 'The deep sea is full of mystery.',
      exercises: const [
        'the deep ocean is very dark and cold.',
        'some fish glow in the deep sea.',
        'giant squid live far below the waves.',
        'submarines explore the ocean floor.',
        'scientists discover new species every year.',
      ],
    );

    // ------------------------------------------------------------
    // 14) Themed fun sentences – Animals
    // 5 lessons
    // ------------------------------------------------------------
    addLesson(
      title: 'Animals: Farm',
      description: 'Type sentences about farm animals.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.beginner,
      focusKeys: [],
      emoji: '🐄',
      funTip: 'Farms are fun and full of animals.',
      exercises: const [
        'the cow eats green grass.',
        'the chicken lays an egg.',
        'pigs roll in the mud.',
        'the horse runs in the field.',
        'a sheep has soft wool.',
      ],
    );

    addLesson(
      title: 'Animals: Safari',
      description: 'Type sentences about wild animals.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '🦁',
      funTip: 'Wild animals are amazing to learn about.',
      exercises: const [
        'the lion is called the king of beasts.',
        'elephants have long trunks and big ears.',
        'a giraffe has a very long neck.',
        'zebras have black and white stripes.',
        'hippos spend most of the day in water.',
      ],
    );

    addLesson(
      title: 'Animals: Pets',
      description: 'Type sentences about pet animals.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.beginner,
      focusKeys: [],
      emoji: '🐶',
      funTip: 'Pets are our best friends.',
      exercises: const [
        'my dog likes to fetch the ball.',
        'the cat sleeps on a soft pillow.',
        'a goldfish swims in a bowl.',
        'the hamster runs on a wheel.',
        'a parrot can learn to talk.',
      ],
    );

    addLesson(
      title: 'Animals: Bugs',
      description: 'Type sentences about insects.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '🐛',
      funTip: 'Bugs may be small but they are mighty.',
      exercises: const [
        'ants carry food back to their nest.',
        'a ladybug has tiny spots.',
        'bees make honey from flowers.',
        'butterflies have colorful wings.',
        'a caterpillar turns into a butterfly.',
      ],
    );

    addLesson(
      title: 'Animals: Arctic',
      description: 'Type sentences about arctic animals.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🐧',
      funTip: 'Arctic animals are built for the cold.',
      exercises: const [
        'penguins waddle on the ice.',
        'polar bears have thick white fur.',
        'arctic foxes change color with the seasons.',
        'walruses have long tusks made of ivory.',
        'snowy owls hunt in the frozen tundra.',
      ],
    );

    // ------------------------------------------------------------
    // 15) Themed fun sentences – Food & Cooking
    // 4 lessons
    // ------------------------------------------------------------
    addLesson(
      title: 'Food: Fruits',
      description: 'Type sentences about fruits.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.beginner,
      focusKeys: [],
      emoji: '🍎',
      funTip: 'Fruits are yummy and good for you.',
      exercises: const [
        'an apple a day keeps you healthy.',
        'bananas are yellow and sweet.',
        'grapes grow on a vine.',
        'oranges are full of juice.',
        'strawberries are red and small.',
      ],
    );

    addLesson(
      title: 'Food: Kitchen',
      description: 'Type sentences about cooking.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '🍳',
      funTip: 'Cooking is like a fun experiment.',
      exercises: const [
        'we mix flour, eggs, and milk.',
        'the oven bakes bread and cakes.',
        'dad flips pancakes on the pan.',
        'mom chops vegetables for the soup.',
        'the kitchen smells wonderful today.',
      ],
    );

    addLesson(
      title: 'Food: Around the World',
      description: 'Type sentences about food from different places.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🍕',
      funTip: 'Every country has delicious food.',
      exercises: const [
        'pizza comes from italy.',
        'sushi is a popular dish in japan.',
        'tacos are loved in mexico.',
        'croissants are buttery french pastries.',
        'noodles are eaten all across asia.',
      ],
    );

    addLesson(
      title: 'Food: Snack Time',
      description: 'Type sentences about snacks.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.beginner,
      focusKeys: [],
      emoji: '🍿',
      funTip: 'Snack breaks make everything better.',
      exercises: const [
        'i like crackers and cheese.',
        'popcorn is great for movie night.',
        'trail mix has nuts and raisins.',
        'yogurt with fruit is a nice treat.',
        'we share cookies after school.',
      ],
    );

    // ------------------------------------------------------------
    // 16) Themed fun sentences – Weather & Seasons
    // 4 lessons
    // ------------------------------------------------------------
    addLesson(
      title: 'Weather: Sunny Days',
      description: 'Type sentences about sunny weather.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.beginner,
      focusKeys: [],
      emoji: '☀️',
      funTip: 'Sunny days make everyone smile.',
      exercises: const [
        'the sun is shining bright today.',
        'we play outside when it is warm.',
        'sunflowers turn to face the sun.',
        'put on sunscreen before you go out.',
        'the sky is clear and blue.',
      ],
    );

    addLesson(
      title: 'Weather: Rainy Days',
      description: 'Type sentences about rain.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '🌧️',
      funTip: 'Rain helps flowers and trees grow.',
      exercises: const [
        'rain drops fall from gray clouds.',
        'we jump in puddles with our boots.',
        'the sound of rain is relaxing.',
        'a rainbow appears after the rain.',
        'plants drink water from the soil.',
      ],
    );

    addLesson(
      title: 'Seasons: Spring and Summer',
      description: 'Type sentences about spring and summer.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '🌸',
      funTip: 'Warm seasons bring new adventures.',
      exercises: const [
        'flowers bloom in the spring.',
        'birds build nests in the trees.',
        'we swim in the pool all summer.',
        'ice cream melts fast in the heat.',
        'fireflies glow on summer nights.',
      ],
    );

    addLesson(
      title: 'Seasons: Fall and Winter',
      description: 'Type sentences about fall and winter.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '🍂',
      funTip: 'Every season has something special.',
      exercises: const [
        'leaves turn red, orange, and gold.',
        'we rake leaves into a big pile.',
        'snow covers the ground in winter.',
        'we build a snowman in the yard.',
        'hot cocoa warms us on cold days.',
      ],
    );

    // ------------------------------------------------------------
    // 17) Capital letters practice
    // 4 lessons
    // ------------------------------------------------------------
    addLesson(
      title: 'Capitals: Names',
      description: 'Practice typing names with capital letters.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '🅰️',
      funTip: 'Names always start with a capital letter.',
      exercises: const [
        'Anna Ben Carl Dana Eve',
        'Fred Gina Hugo Iris Jake',
        'Kate Leo Mia Noah Olivia',
        'Paul Quinn Rose Sam Tara',
        'Uma Vince Wendy Xena Yuri Zoe',
      ],
    );

    addLesson(
      title: 'Capitals: Places',
      description: 'Practice typing place names.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🗺️',
      funTip: 'Cities and countries start with capitals.',
      exercises: const [
        'London Paris Tokyo Delhi Rome',
        'New York Los Angeles Chicago',
        'India China Brazil Egypt Japan',
        'Africa Europe Asia Australia',
        'Amazon River Rocky Mountains Pacific Ocean',
      ],
    );

    addLesson(
      title: 'Capitals: Days and Months',
      description: 'Type days of the week and months.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '📆',
      funTip: 'Days and months always get capitals.',
      exercises: const [
        'Monday Tuesday Wednesday Thursday',
        'Friday Saturday Sunday',
        'January February March April',
        'May June July August',
        'September October November December',
      ],
    );

    addLesson(
      title: 'Capitals: Start of Sentences',
      description: 'Practice starting sentences with capitals.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '📐',
      funTip: 'Every sentence starts with a capital letter.',
      exercises: const [
        'The dog ran home. He was happy.',
        'We had lunch. It was very good.',
        'She found a book. It had pictures.',
        'They played a game. It was fun.',
        'He drew a map. We followed it.',
      ],
    );

    // ------------------------------------------------------------
    // 19) Long word challenge
    // 4 lessons
    // ------------------------------------------------------------
    addLesson(
      title: 'Long Words: Nature',
      description: 'Type long nature words.',
      category: LessonCategory.commonWords,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🌲',
      funTip: 'Break big words into small pieces in your mind.',
      exercises: const [
        'butterfly sunflower waterfall',
        'grasshopper caterpillar dragonfly',
        'thunderstorm earthquake avalanche',
        'wilderness adventure ecosystem',
        'environment temperature atmosphere',
      ],
    );

    addLesson(
      title: 'Long Words: Science',
      description: 'Type long science words.',
      category: LessonCategory.commonWords,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🔬',
      funTip: 'Scientists type carefully and so should you.',
      exercises: const [
        'microscope telescope experiment',
        'electricity magnetism laboratory',
        'thermometer barometer discovery',
        'photosynthesis evaporation condensation',
        'acceleration measurement observation',
      ],
    );

    addLesson(
      title: 'Long Words: Technology',
      description: 'Type long technology words.',
      category: LessonCategory.commonWords,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '💻',
      funTip: 'Tech words may be long but you can handle them.',
      exercises: const [
        'computer keyboard monitor',
        'programming application developer',
        'technology information communication',
        'engineering mathematics automation',
        'smartphone bluetooth controller',
      ],
    );

    addLesson(
      title: 'Long Words: Challenge',
      description: 'The ultimate long word challenge.',
      category: LessonCategory.commonWords,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🏅',
      funTip: 'You have come so far. Keep going.',
      exercises: const [
        'extraordinary unbelievable magnificent',
        'constellation encyclopedia encyclopedia',
        'archaeological communication professional',
        'environmental international determination',
        'congratulations understanding accomplished',
      ],
    );

    // ------------------------------------------------------------
    // 20) Typing speed builders – common phrases
    // 6 lessons
    // ------------------------------------------------------------
    addLesson(
      title: 'Speed: Common Phrases 1',
      description: 'Build speed with everyday phrases.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '⚡',
      funTip: 'Repeat these phrases to build muscle memory.',
      exercises: const [
        'thank you very much',
        'how are you doing',
        'have a great day',
        'see you later',
        'nice to meet you',
      ],
    );

    addLesson(
      title: 'Speed: Common Phrases 2',
      description: 'More everyday phrases for speed.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '⚡',
      funTip: 'Smooth, even strokes beat hammering fast.',
      exercises: const [
        'good morning everyone',
        'what do you think',
        'i would like to go',
        'let me know if you need help',
        'that sounds like a good idea',
      ],
    );

    addLesson(
      title: 'Speed: Short Sentences',
      description: 'Quick fire short sentences.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      focusKeys: [],
      emoji: '💨',
      funTip: 'Short and fast builds your rhythm.',
      exercises: const [
        'the quick brown fox jumps.',
        'she sells sea shells.',
        'i can do this well.',
        'keep calm and type on.',
        'practice makes perfect.',
      ],
    );

    addLesson(
      title: 'Speed: Pangrams',
      description: 'Type sentences that use every letter.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🔤',
      funTip: 'Pangrams use every letter of the alphabet.',
      exercises: const [
        'the quick brown fox jumps over the lazy dog.',
        'pack my box with five dozen liquor jugs.',
        'how vexingly quick daft zebras jump.',
        'the five boxing wizards jump quickly.',
        'bright vixens jump, dozy fowl quack.',
      ],
    );

    addLesson(
      title: 'Speed: Tongue Twisters',
      description: 'Fun tongue twisters to type fast.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '👅',
      funTip: 'Tongue twisters are tricky but fun to type.',
      exercises: const [
        'peter piper picked a peck of peppers.',
        'she sells sea shells by the sea shore.',
        'red lorry, yellow lorry, red lorry.',
        'how much wood would a woodchuck chuck.',
        'fuzzy wuzzy was a bear.',
      ],
    );

    addLesson(
      title: 'Speed: Mixed Challenge',
      description: 'A final speed building challenge.',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      focusKeys: [],
      emoji: '🏁',
      funTip: 'You are now a typing champion.',
      exercises: const [
        'the sun sets behind the tall mountains.',
        'a gentle breeze carried leaves across the yard.',
        'children laughed as they chased butterflies.',
        'the old lighthouse stood guard over the shore.',
        'every day brings a new chance to learn and grow.',
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
