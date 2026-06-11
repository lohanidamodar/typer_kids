import 'dart:math';

import 'word_lists.dart';

/// Sentence pools for the Story Sprint game, organized by difficulty.
///
/// Easy sentences are short and lowercase; medium adds capitals and commas;
/// hard adds questions, exclamations, and apostrophes — matching the skills
/// taught in the capitals and punctuation lessons.
class SentenceLists {
  SentenceLists._();

  static const List<String> easy = [
    'the cat naps on the mat.',
    'a red bus rolls by.',
    'we run to the park.',
    'the sun is up now.',
    'my dog digs a hole.',
    'a frog hops on a log.',
    'we eat rice and beans.',
    'the kite flies high.',
    'a fish swims fast.',
    'the bell rings twice.',
    'we hop and skip home.',
    'a bug sits on a leaf.',
    'the moon glows at night.',
    'we read a fun book.',
    'a bird sings a song.',
    'the milk is very cold.',
    'we draw with crayons.',
    'a crab walks sideways.',
    'the train goes fast.',
    'we clap for the team.',
  ];

  static const List<String> medium = [
    'The puppy chased its tail in circles.',
    'We packed apples, bread, and juice.',
    'My sister found a shiny blue shell.',
    'The robot beeped twice and rolled away.',
    'Dad made pancakes for breakfast today.',
    'A rainbow appeared after the storm.',
    'The library opens at nine in the morning.',
    'We planted seeds, watered them, and waited.',
    'The squirrel hid acorns under the tree.',
    'Grandma tells the best bedtime stories.',
    'Our team scored in the final minute.',
    'The baker sells muffins, rolls, and pies.',
    'A gentle breeze moved the tall grass.',
    'We built a fort out of old boxes.',
    'The astronaut waved from the rocket.',
    'My favorite color is bright green.',
    'The turtle won the race in the end.',
    'We saw ducks, geese, and one swan.',
    'The magician pulled a rabbit from his hat.',
    'Everyone cheered when the lights came on.',
  ];

  static const List<String> hard = [
    "Where did the little fox hide? It's behind the log!",
    "Don't forget your umbrella; it might rain today.",
    'Who left the gate open? The goats are loose!',
    "It's almost time for the show, so find your seats.",
    'Can you believe we won? What an amazing game!',
    "The dragon's cave was dark, deep, and very quiet.",
    "Let's pack the tent, the map, and the flashlight.",
    "What's the fastest animal? It's the peregrine falcon!",
    "We couldn't stop laughing at the clown's tiny car.",
    'Did you hear that sound? Maybe it was an owl.',
    "The chef shouted, and the kitchen burst into action!",
    "It isn't easy to juggle, but practice helps a lot.",
    'How many stars can you count? More than a hundred!',
    "The captain's parrot squawked, then flew to the mast.",
    "Wasn't that roller coaster fast? Let's ride it again!",
    'Why do leaves change color? Ask your science teacher.',
    "The detective checked the clues; something didn't fit.",
    "You're almost at the finish line, so don't give up!",
    'Whose footprints are these? They lead to the garden.',
    "That's the biggest pumpkin I've ever seen!",
  ];

  static List<String> forDifficulty(ContentDifficulty d) => switch (d) {
    ContentDifficulty.easy => easy,
    ContentDifficulty.medium => medium,
    ContentDifficulty.hard => hard,
  };

  static final _random = Random();

  /// A shuffled copy of the pool for one game round.
  static List<String> shuffledFor(ContentDifficulty d) {
    final list = List<String>.from(forDifficulty(d));
    list.shuffle(_random);
    return list;
  }
}
