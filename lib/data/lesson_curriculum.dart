import '../models/lesson.dart';

/// All lessons in the Typer Kids curriculum
/// Structured progressively from home row basics to full sentences
class LessonCurriculum {
  LessonCurriculum._();

  static const List<Lesson> allLessons = [
    // ============================================================
    // HOME ROW - Beginner
    // ============================================================
    Lesson(
      id: 'hr-01',
      title: 'Meet F and J',
      description: 'Learn where your index fingers rest. Feel the bumps!',
      category: LessonCategory.homeRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 1,
      focusKeys: ['f', 'j'],
      emoji: '👆',
      funTip:
          'Put your pointer fingers on F and J. Can you feel the little bumps? Those help you find the right spot!',
      exercises: [
        'fff jjj fff jjj',
        'fj fj fj fj fj fj',
        'fjf fjf jfj jfj',
        'ff jj ff jj ff jj',
        'fjfj jfjf fjfj jfjf',
      ],
    ),
    Lesson(
      id: 'hr-02',
      title: 'D and K Join In',
      description: 'Your middle fingers get to play!',
      category: LessonCategory.homeRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 2,
      focusKeys: ['d', 'k'],
      emoji: '✌️',
      funTip:
          'Your middle fingers sit right next to your pointer fingers on D and K.',
      exercises: [
        'ddd kkk ddd kkk',
        'dk dk dk dk dk dk',
        'dkd dkd kdk kdk',
        'fd jk fd jk fd jk',
        'fdk jkf dkf jfd',
      ],
    ),
    Lesson(
      id: 'hr-03',
      title: 'S and L Say Hello',
      description: 'Ring fingers join the typing party!',
      category: LessonCategory.homeRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 3,
      focusKeys: ['s', 'l'],
      emoji: '💍',
      funTip:
          'Your ring fingers rest on S and L. They might feel a bit shy at first!',
      exercises: [
        'sss lll sss lll',
        'sl sl sl sl sl sl',
        'sls sls lsl lsl',
        'fds jkl fds jkl',
        'sdl lkj fds jkl',
      ],
    ),
    Lesson(
      id: 'hr-04',
      title: 'A and ; Complete the Row',
      description: 'Your pinkies get their turn!',
      category: LessonCategory.homeRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 4,
      focusKeys: ['a', ';'],
      emoji: '🤙',
      funTip:
          'Pinkies are small but mighty! They type A and the semicolon key.',
      exercises: [
        'aaa ;;; aaa ;;;',
        'a; a; a; a; a;',
        'asdf jkl; asdf jkl;',
        'aa ;; ss ll dd kk ff jj',
        'as;l dk fj as;l dkfj',
      ],
    ),
    Lesson(
      id: 'hr-05',
      title: 'Home Row Party!',
      description: 'Mix all home row keys together!',
      category: LessonCategory.homeRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 5,
      focusKeys: ['a', 's', 'd', 'f', 'j', 'k', 'l', ';'],
      emoji: '🎉',
      funTip: 'You know all the home row keys now! Let\'s practice them all!',
      exercises: [
        'asdf jkl; asdf jkl;',
        'fdsa ;lkj fdsa ;lkj',
        'asd fds jkl lkj',
        'alsk djfj dksl afj;',
        'all sad lad fall',
      ],
    ),
    Lesson(
      id: 'hr-06',
      title: 'Home Row Words',
      description: 'Type real words using home row keys!',
      category: LessonCategory.homeRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 6,
      focusKeys: ['a', 's', 'd', 'f', 'j', 'k', 'l'],
      emoji: '📝',
      funTip: 'Did you know you can make real words with just the home row?',
      exercises: [
        'dad sad lad ask',
        'all fall flask',
        'salad flask add',
        'ask dad all sad',
        'a lad asks dad',
      ],
    ),

    // ============================================================
    // HOME ROW + G and H
    // ============================================================
    Lesson(
      id: 'hr-07',
      title: 'G and H - Reach!',
      description: 'Index fingers stretch to the middle.',
      category: LessonCategory.homeRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 7,
      focusKeys: ['g', 'h'],
      emoji: '🤲',
      funTip:
          'G and H are in the middle. Your pointer fingers reach inward to type them!',
      exercises: [
        'ggg hhh ggg hhh',
        'gh gh gh gh gh gh',
        'fg hj fg hj fg hj',
        'gash hash glad half',
        'hag gag had gal',
      ],
    ),
    Lesson(
      id: 'hr-08',
      title: 'Home Row Master!',
      description: 'Use all home row keys including G and H!',
      category: LessonCategory.homeRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 8,
      focusKeys: ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      emoji: '👑',
      funTip: 'You\'re becoming a home row master! Keep those fingers dancing!',
      exercises: [
        'flash gash hall shall',
        'glad half dash lash',
        'a flash shall dash',
        'had half a salad',
        'a glad lad shall ask dad',
      ],
    ),

    // ============================================================
    // TOP ROW
    // ============================================================
    Lesson(
      id: 'tr-01',
      title: 'E and I - Reach Up!',
      description: 'Middle fingers reach up to the top row.',
      category: LessonCategory.topRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 9,
      focusKeys: ['e', 'i'],
      emoji: '⬆️',
      funTip:
          'E and I are right above D and K. Lift your middle fingers up, then bring them back home!',
      exercises: [
        'eee iii eee iii',
        'ded kik ded kik',
        'die did hid hide',
        'like life size file',
        'he fed his fish',
      ],
    ),
    Lesson(
      id: 'tr-02',
      title: 'R and U Too!',
      description: 'Index fingers reach up for R and U.',
      category: LessonCategory.topRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 10,
      focusKeys: ['r', 'u'],
      emoji: '🦊',
      funTip: 'R and U are above F and J. Quick reach up and back down!',
      exercises: [
        'rrr uuu rrr uuu',
        'frf juj frf juj',
        'fur rule drum dull',
        'ride rude sure duke',
        'a rug is sure red',
      ],
    ),
    Lesson(
      id: 'tr-03',
      title: 'T and Y in the Middle',
      description: 'Index fingers stretch up and inward!',
      category: LessonCategory.topRow,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 11,
      focusKeys: ['t', 'y'],
      emoji: '🎯',
      funTip:
          'T is above G and Y is above H. A little stretch for your pointers!',
      exercises: [
        'ttt yyy ttt yyy',
        'ftf jyj ftf jyj',
        'yet yell they try',
        'the this that these',
        'try the kite first',
      ],
    ),
    Lesson(
      id: 'tr-04',
      title: 'W and O Join',
      description: 'Ring fingers reach up to W and O.',
      category: LessonCategory.topRow,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 12,
      focusKeys: ['w', 'o'],
      emoji: '🦉',
      funTip:
          'W is above S, and O is above L. Your ring fingers take a little trip!',
      exercises: [
        'www ooo www ooo',
        'sws lol sws lol',
        'low wow work word',
        'owl wolf world follow',
        'two owls work slowly',
      ],
    ),
    Lesson(
      id: 'tr-05',
      title: 'Q and P Finish the Top',
      description: 'Pinkies reach up for the corners!',
      category: LessonCategory.topRow,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 13,
      focusKeys: ['q', 'p'],
      emoji: '🐧',
      funTip: 'Q is above A, P is above the semicolon. Pinky power!',
      exercises: [
        'qqq ppp qqq ppp',
        'aqa ;p; aqa ;p;',
        'quip quote pique',
        'quiet purple quest',
        'a quiet puppy sleeps',
      ],
    ),
    Lesson(
      id: 'tr-06',
      title: 'Top Row Review',
      description: 'Practice all top row keys together!',
      category: LessonCategory.topRow,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 14,
      focusKeys: ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      emoji: '🌟',
      funTip: 'You\'ve learned the whole top row! Time to mix it all up!',
      exercises: [
        'the quick red fox',
        'your pretty white house',
        'quiet people type well',
        'we are quite proud today',
        'put your paws up top',
      ],
    ),

    // ============================================================
    // BOTTOM ROW
    // ============================================================
    Lesson(
      id: 'br-01',
      title: 'C and M - Reach Down!',
      description: 'Middle and index fingers dip down.',
      category: LessonCategory.bottomRow,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 15,
      focusKeys: ['c', 'm'],
      emoji: '⬇️',
      funTip: 'C is below D, M is below J. A quick dip down and back home!',
      exercises: [
        'ccc mmm ccc mmm',
        'dcd jmj dcd jmj',
        'come much cream clam',
        'mice crime match mock',
        'milk comes from cows',
      ],
    ),
    Lesson(
      id: 'br-02',
      title: 'V and N Next',
      description: 'Index fingers dip down and inward.',
      category: LessonCategory.bottomRow,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 16,
      focusKeys: ['v', 'n'],
      emoji: '🎵',
      funTip: 'V is below F, N is below J. Your index fingers are busy bees!',
      exercises: [
        'vvv nnn vvv nnn',
        'fvf jnj fvf jnj',
        'vine van nice never',
        'even seven given river',
        'seven vines never vine',
      ],
    ),
    Lesson(
      id: 'br-03',
      title: 'X and . (Period)',
      description: 'Ring fingers go down for X and period.',
      category: LessonCategory.bottomRow,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 17,
      focusKeys: ['x', '.'],
      emoji: '📌',
      funTip: 'X is below S, period is below L. Every sentence needs a period!',
      exercises: [
        'xxx ... xxx ...',
        'sxs l.l sxs l.l',
        'fox. mix. fix. six.',
        'next. text. exit.',
        'the fox is next.',
      ],
    ),
    Lesson(
      id: 'br-04',
      title: 'Z and / (Slash)',
      description: 'Pinkies dip down for the corners.',
      category: LessonCategory.bottomRow,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 18,
      focusKeys: ['z', '/'],
      emoji: '⚡',
      funTip:
          'Z is below A, slash is below the semicolon. Pinkies are stretchy!',
      exercises: [
        'zzz /// zzz ///',
        'aza ;/; aza ;/;',
        'zoo zero zone zig/zag',
        'fizz buzz jazz quiz',
        'the zoo has a quiz.',
      ],
    ),
    Lesson(
      id: 'br-05',
      title: 'B and , (Comma)',
      description: 'Almost done! B and comma join the family.',
      category: LessonCategory.bottomRow,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 19,
      focusKeys: ['b', ','],
      emoji: '🐝',
      funTip:
          'B is typed with your left index finger, comma with your right middle finger.',
      exercises: [
        'bbb ,,, bbb ,,,',
        'fbf k,k fbf k,k',
        'big, bad, bold, brave',
        'bob, ben, and bill',
        'bees buzz, birds sing.',
      ],
    ),
    Lesson(
      id: 'br-06',
      title: 'Bottom Row Review',
      description: 'Mix all the bottom row keys together!',
      category: LessonCategory.bottomRow,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 20,
      focusKeys: ['z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'],
      emoji: '🏆',
      funTip: 'You know all the bottom row keys! That\'s incredible!',
      exercises: [
        'vim, can, man, van.',
        'zap, box, mix, zen.',
        'big, brown, crafty fox.',
        'monkeys climb, bees buzz.',
        'a brave fox can zig/zag.',
      ],
    ),

    // ============================================================
    // COMMON WORDS
    // ============================================================
    Lesson(
      id: 'cw-01',
      title: 'Easy Peasy Words',
      description: 'Type the most common short words!',
      category: LessonCategory.commonWords,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 21,
      focusKeys: [],
      emoji: '🧩',
      funTip: 'These are the words you see most often in books!',
      exercises: [
        'the and for are but',
        'not you all can had',
        'her was one our out',
        'has his how its may',
        'who did get has him',
      ],
    ),
    Lesson(
      id: 'cw-02',
      title: 'Animal Words',
      description: 'Type fun animal names!',
      category: LessonCategory.commonWords,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 22,
      focusKeys: [],
      emoji: '🦁',
      funTip:
          'Can you type all these animal names? Which one is your favorite?',
      exercises: [
        'cat dog bird fish frog',
        'lion tiger bear wolf fox',
        'duck goat sheep pig cow',
        'snake lizard turtle crab',
        'monkey parrot eagle owl bat',
      ],
    ),
    Lesson(
      id: 'cw-03',
      title: 'Color Words',
      description: 'Type all the rainbow colors!',
      category: LessonCategory.commonWords,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 23,
      focusKeys: [],
      emoji: '🌈',
      funTip: 'Red, orange, yellow, green, blue, indigo, violet - a rainbow!',
      exercises: [
        'red blue green yellow',
        'pink orange purple white',
        'black brown gray silver',
        'gold teal violet indigo',
        'a red and blue rainbow',
      ],
    ),
    Lesson(
      id: 'cw-04',
      title: 'Food Words',
      description: 'Yummy words to type!',
      category: LessonCategory.commonWords,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 24,
      focusKeys: [],
      emoji: '🍕',
      funTip: 'Don\'t get too hungry while typing these!',
      exercises: [
        'cake pie bread rice',
        'apple grape mango pear',
        'pizza pasta salad soup',
        'milk juice water honey',
        'a slice of warm pizza',
      ],
    ),
    Lesson(
      id: 'cw-05',
      title: 'Action Words',
      description: 'Type words that show action!',
      category: LessonCategory.commonWords,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 25,
      focusKeys: [],
      emoji: '🏃',
      funTip: 'Verbs are words that describe what you do!',
      exercises: [
        'run jump walk skip hop',
        'sing dance play read write',
        'eat drink cook bake make',
        'swim fly climb swing slide',
        'kick throw catch push pull',
      ],
    ),

    // ============================================================
    // SENTENCES
    // ============================================================
    Lesson(
      id: 'sn-01',
      title: 'Short Sentences',
      description: 'Type your first full sentences!',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 26,
      focusKeys: [],
      emoji: '💬',
      funTip: 'Sentences start with a capital letter and end with a period!',
      exercises: [
        'the cat sat on the mat.',
        'a big red dog ran fast.',
        'she has a pet fish.',
        'we like to play games.',
        'the sun is very bright.',
      ],
    ),
    Lesson(
      id: 'sn-02',
      title: 'Fun Sentences',
      description: 'Type silly and fun sentences!',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 27,
      focusKeys: [],
      emoji: '😄',
      funTip: 'Typing is more fun with silly sentences!',
      exercises: [
        'a frog jumped over the log.',
        'the purple cow ate pizza.',
        'monkeys love to eat bananas.',
        'fish can swim very fast.',
        'birds sing songs in the trees.',
      ],
    ),
    Lesson(
      id: 'sn-03',
      title: 'Story Time',
      description: 'Type parts of a little story!',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      orderIndex: 28,
      focusKeys: [],
      emoji: '📖',
      funTip: 'Every great author started by learning to type!',
      exercises: [
        'once upon a time there was a brave little fox.',
        'the fox lived in a big green forest.',
        'every day the fox liked to explore.',
        'one day the fox found a hidden cave.',
        'inside the cave was a treasure of gold coins.',
      ],
    ),
    Lesson(
      id: 'sn-04',
      title: 'Tongue Twisters',
      description: 'Can you type these tricky sentences?',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      orderIndex: 29,
      focusKeys: [],
      emoji: '🤪',
      funTip: 'Tongue twisters are hard to say AND type!',
      exercises: [
        'she sells sea shells by the sea shore.',
        'peter piper picked a peck of pickled peppers.',
        'how much wood would a woodchuck chuck.',
        'red lorry yellow lorry red lorry.',
        'a big black bug bit a big black dog.',
      ],
    ),
    Lesson(
      id: 'sn-05',
      title: 'The Quick Brown Fox',
      description: 'The classic sentence that uses every letter!',
      category: LessonCategory.sentences,
      difficulty: LessonDifficulty.advanced,
      orderIndex: 30,
      focusKeys: [],
      emoji: '🦊',
      funTip: 'This famous sentence contains every letter of the alphabet!',
      exercises: [
        'the quick brown fox jumps over the lazy dog.',
        'pack my box with five dozen liquor jugs.',
        'how vexingly quick daft zebras jump.',
        'the five boxing wizards jump quickly.',
        'a quick brown fox jumps over the lazy dog.',
      ],
    ),

    // ============================================================
    // NUMBERS
    // ============================================================
    Lesson(
      id: 'nm-01',
      title: 'Numbers 1-5',
      description: 'Left hand reaches up for numbers!',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 31,
      focusKeys: ['1', '2', '3', '4', '5'],
      emoji: '1️⃣',
      funTip: 'Numbers are on the very top row. Take it slow!',
      exercises: [
        '111 222 333 444 555',
        '12 23 34 45 51 13 24',
        '123 234 345 451 512',
        '11 22 33 44 55 12 34',
        '1 and 2 and 3 and 4 and 5',
      ],
    ),
    Lesson(
      id: 'nm-02',
      title: 'Numbers 6-0',
      description: 'Right hand reaches up for more numbers!',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.intermediate,
      orderIndex: 32,
      focusKeys: ['6', '7', '8', '9', '0'],
      emoji: '🔢',
      funTip: 'Almost there! The right hand types 6, 7, 8, 9, and 0.',
      exercises: [
        '666 777 888 999 000',
        '67 78 89 90 06 68 79',
        '678 789 890 906 067',
        '66 77 88 99 00 67 89',
        '6 and 7 and 8 and 9 and 0',
      ],
    ),
    Lesson(
      id: 'nm-03',
      title: 'All Numbers Mix',
      description: 'Mix all the numbers together!',
      category: LessonCategory.numbers,
      difficulty: LessonDifficulty.advanced,
      orderIndex: 33,
      focusKeys: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
      emoji: '🎰',
      funTip: 'You can type all ten digits! A real pro!',
      exercises: [
        '10 20 30 40 50 60 70 80 90',
        '123 456 789 012 345 678',
        '1234567890 0987654321',
        '42 is the answer to everything.',
        'there are 365 days in a year.',
      ],
    ),
  ];

  /// Get lessons by category
  static List<Lesson> byCategory(LessonCategory category) =>
      allLessons.where((l) => l.category == category).toList();

  /// Get a lesson by its ID
  static Lesson? byId(String id) {
    try {
      return allLessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get the next lesson after the given one (across all lessons by orderIndex)
  static Lesson? nextLesson(String currentLessonId) {
    final current = byId(currentLessonId);
    if (current == null) return null;

    // Find next lesson in the same category first
    final categoryLessons = byCategory(current.category);
    final idx = categoryLessons.indexWhere((l) => l.id == currentLessonId);
    if (idx >= 0 && idx < categoryLessons.length - 1) {
      return categoryLessons[idx + 1];
    }

    // If last in category, find first lesson of next category
    final catIdx = categoryOrder.indexOf(current.category);
    if (catIdx >= 0 && catIdx < categoryOrder.length - 1) {
      final nextCatLessons = byCategory(categoryOrder[catIdx + 1]);
      if (nextCatLessons.isNotEmpty) return nextCatLessons.first;
    }

    return null;
  }

  /// All categories in display order
  static const List<LessonCategory> categoryOrder = [
    LessonCategory.homeRow,
    LessonCategory.topRow,
    LessonCategory.bottomRow,
    LessonCategory.commonWords,
    LessonCategory.sentences,
    LessonCategory.numbers,
  ];
}
