import 'dart:math';

import 'word_lists.dart';

/// A single passage of text for sandbox / typing test modes.
class StoryPassage {
  final String title;
  final String source;
  final String text;

  const StoryPassage({
    required this.title,
    required this.source,
    required this.text,
  });
}

/// Story content organized by difficulty for sandbox and typing-test modes.
///
/// Easy: short sentences, common words, simple punctuation.
/// Medium: longer sentences, wider vocabulary, mixed punctuation.
/// Hard: complex sentences, advanced vocabulary, full punctuation.
class StoryContent {
  StoryContent._();

  // ── Easy passages ───────────────────────────────────────────────────────

  static const List<StoryPassage> easy = [
    StoryPassage(
      title: 'The Little Red Hen',
      source: 'Classic Folk Tale',
      text:
          'Once there was a little red hen. She lived on a farm. '
          'She found some seeds on the ground. '
          'She asked her friends to help her plant the seeds. '
          'The cat said no. The dog said no. The duck said no. '
          'So the little red hen did it all by herself.',
    ),
    StoryPassage(
      title: 'The Three Bears',
      source: 'Classic Folk Tale',
      text:
          'Once upon a time there were three bears. '
          'There was a big papa bear, a mama bear, and a tiny baby bear. '
          'They lived in a little house in the woods. '
          'One day they made some soup for lunch. '
          'It was too hot to eat so they went for a walk.',
    ),
    StoryPassage(
      title: 'The Ugly Duckling',
      source: 'Hans Christian Andersen',
      text:
          'A mother duck sat on her eggs. One by one they began to crack. '
          'Out came little yellow ducklings. But the last egg was big. '
          'When it cracked, out came a gray bird. '
          'He did not look like the others. They called him ugly. '
          'But he did not give up hope.',
    ),
    StoryPassage(
      title: 'The Tortoise and the Hare',
      source: 'Aesop\'s Fables',
      text:
          'A hare made fun of a slow tortoise. '
          'The tortoise said he could win a race. '
          'The hare laughed but said yes. '
          'The race began. The hare ran fast then took a nap. '
          'The tortoise kept going slow and steady. '
          'He won the race while the hare slept.',
    ),
    StoryPassage(
      title: 'Jack and the Beanstalk',
      source: 'English Fairy Tale',
      text:
          'Jack lived with his mother. They were very poor. '
          'One day Jack sold their cow for magic beans. '
          'His mother was upset and threw the beans out the window. '
          'The next day a huge beanstalk grew up to the sky. '
          'Jack climbed up to see what was at the top.',
    ),
    StoryPassage(
      title: 'The Gingerbread Man',
      source: 'Classic Folk Tale',
      text:
          'An old woman made a gingerbread man. '
          'When she opened the oven, he jumped out and ran. '
          'Run, run, as fast as you can. '
          'You cannot catch me, I am the gingerbread man. '
          'He ran past the cow and the horse.',
    ),
    StoryPassage(
      title: 'The Boy Who Cried Wolf',
      source: 'Aesop\'s Fables',
      text:
          'A boy watched over the sheep on a hill. '
          'He was bored so he cried out that a wolf was coming. '
          'The people in the town ran to help but there was no wolf. '
          'He did it again the next day. '
          'When a real wolf came, no one came to help him.',
    ),
    StoryPassage(
      title: 'The Ant and the Dove',
      source: 'Aesop\'s Fables',
      text:
          'An ant fell into a stream. A dove saw the ant. '
          'The dove dropped a leaf into the water. '
          'The ant climbed on the leaf and was safe. '
          'Later a man tried to catch the dove. '
          'The ant bit the man on the foot. The dove flew away.',
    ),
  ];

  // ── Medium passages ─────────────────────────────────────────────────────

  static const List<StoryPassage> medium = [
    StoryPassage(
      title: 'Alice in Wonderland',
      source: 'Lewis Carroll',
      text:
          'Alice was beginning to get very tired of sitting by her sister '
          'on the bank, and of having nothing to do. She peeped into the '
          'book her sister was reading, but it had no pictures or '
          'conversations in it. "What is the use of a book," thought Alice, '
          '"without pictures or conversations?"',
    ),
    StoryPassage(
      title: 'The Wonderful Wizard of Oz',
      source: 'L. Frank Baum',
      text:
          'Dorothy lived in the middle of the great Kansas prairies, with '
          'Uncle Henry, who was a farmer, and Aunt Em, who was the farmer\'s '
          'wife. Their house was small, for the lumber to build it had to '
          'be carried by wagon many miles. There were four walls, a floor, '
          'and a roof, which made one room.',
    ),
    StoryPassage(
      title: 'Peter Pan',
      source: 'J. M. Barrie',
      text:
          'All children grow up, except one. They soon know that they will '
          'grow up, and the way Wendy knew was this. One day when she was '
          'two years old she was playing in a garden, and she picked a '
          'flower and ran with it to her mother. She must have looked '
          'rather delightful, for her mother put her hand to her heart.',
    ),
    StoryPassage(
      title: 'Pinocchio',
      source: 'Carlo Collodi',
      text:
          'There was once upon a time a piece of wood. It was not an '
          'expensive piece of wood. Far from it. It was just a common '
          'block of firewood, one of those thick, solid logs that are '
          'put on the fire in winter to make cold rooms warm and cozy. '
          'But something wonderful happened to this piece of wood.',
    ),
    StoryPassage(
      title: 'The Secret Garden',
      source: 'Frances Hodgson Burnett',
      text:
          'When Mary Lennox was sent to live at her uncle\'s great house '
          'on the edge of the moor, everybody said she was the most '
          'disagreeable looking child ever seen. It was true, too. She had '
          'a thin little face and a thin little body, thin light hair, and '
          'a sour expression.',
    ),
    StoryPassage(
      title: 'Treasure Island',
      source: 'Robert Louis Stevenson',
      text:
          'I remember him as if it were yesterday, as he came plodding '
          'to the inn door, his sea chest following behind him. He was a '
          'tall, strong, heavy, nut-brown man, his tarry pigtail falling '
          'over the shoulder of his soiled blue coat. His hands were '
          'rough and scarred, with black, broken nails.',
    ),
    StoryPassage(
      title: 'The Wind in the Willows',
      source: 'Kenneth Grahame',
      text:
          'The Mole had been working very hard all the morning, '
          'spring-cleaning his little home. First with brooms, then with '
          'dusters, then on ladders and steps and chairs, with a brush '
          'and a pail of whitewash. Spring was moving in the air above '
          'and in the earth below and around him.',
    ),
    StoryPassage(
      title: 'The Jungle Book',
      source: 'Rudyard Kipling',
      text:
          'It was seven o\'clock of a very warm evening in the hills when '
          'Father Wolf woke up from his day\'s rest. He scratched himself, '
          'yawned, and spread out his paws one after the other to get rid '
          'of the sleepy feeling in their tips. Mother Wolf lay with her '
          'big gray nose dropped across her four tumbling cubs.',
    ),
  ];

  // ── Hard passages ───────────────────────────────────────────────────────

  static const List<StoryPassage> hard = [
    StoryPassage(
      title: 'A Christmas Carol',
      source: 'Charles Dickens',
      text:
          'Marley was dead, to begin with. There is no doubt whatever '
          'about that. The register of his burial was signed by the '
          'clergyman, the clerk, the undertaker, and the chief mourner. '
          'Scrooge signed it. And Scrooge\'s name was good upon the '
          'Exchange for anything he chose to put his hand to.',
    ),
    StoryPassage(
      title: 'The Call of the Wild',
      source: 'Jack London',
      text:
          'Buck did not read the newspapers, or he would have known that '
          'trouble was brewing, not alone for himself, but for every '
          'tidewater dog, strong of muscle and with warm, long hair, from '
          'the Sound to San Diego. Because men, groping in the Arctic '
          'darkness, had found a yellow metal worthy of discovery.',
    ),
    StoryPassage(
      title: 'Twenty Thousand Leagues',
      source: 'Jules Verne',
      text:
          'The year 1866 was marked by a remarkable incident, a mysterious '
          'and inexplicable phenomenon, which doubtless no one has yet '
          'forgotten. Without mentioning rumors which agitated the maritime '
          'population and excited the public mind, even in the interior '
          'of continents, seafaring men were particularly disturbed.',
    ),
    StoryPassage(
      title: 'Robin Hood',
      source: 'Howard Pyle',
      text:
          'In merry England, in the time of old, when good King Henry the '
          'Second ruled the land, there lived within the green glades of '
          'Sherwood Forest, near Nottingham town, a famous outlaw whose '
          'name was Robin Hood. No archer ever lived that could speed a '
          'gray goose shaft with such skill and cunning as his.',
    ),
    StoryPassage(
      title: 'Around the World',
      source: 'Jules Verne',
      text:
          'In the year 1872, the house at No. 7, Saville Row, Burlington '
          'Gardens, was inhabited by Phileas Fogg, Esquire, one of the '
          'most noticeable members of the Reform Club, though he seemed '
          'always to avoid attracting attention. He was an enigmatical '
          'personage, about whom little was known.',
    ),
    StoryPassage(
      title: 'The Time Machine',
      source: 'H. G. Wells',
      text:
          'The Time Traveller was expounding a recondite matter to us. '
          'His grey eyes shone and twinkled, and his usually pale face was '
          'flushed and animated. The fire burned brightly, and the soft '
          'radiance of the incandescent lights in the lilies of silver '
          'caught the bubbles that flashed and passed in our glasses.',
    ),
    StoryPassage(
      title: 'The Hobbit',
      source: 'J. R. R. Tolkien',
      text:
          'In a hole in the ground there lived a hobbit. Not a nasty, '
          'dirty, wet hole, filled with the ends of worms and an oozy '
          'smell, nor yet a dry, bare, sandy hole with nothing in it to '
          'sit down on or to eat; it was a hobbit-hole, and that means '
          'comfort. The door was perfectly round, like a porthole.',
    ),
    StoryPassage(
      title: 'Little Women',
      source: 'Louisa May Alcott',
      text:
          '"Christmas won\'t be Christmas without any presents," grumbled '
          'Jo, lying on the rug. "It\'s so dreadful to be poor!" sighed '
          'Meg, looking down at her old dress. "I don\'t think it\'s fair '
          'for some girls to have plenty of pretty things, and other girls '
          'nothing at all," added little Amy, with an injured sniff.',
    ),
  ];

  static List<StoryPassage> forDifficulty(ContentDifficulty d) => switch (d) {
    ContentDifficulty.easy => easy,
    ContentDifficulty.medium => medium,
    ContentDifficulty.hard => hard,
  };

  static final _random = Random();

  /// Pick a random passage for the given difficulty.
  static StoryPassage randomPassage(ContentDifficulty d) {
    final list = forDifficulty(d);
    return list[_random.nextInt(list.length)];
  }
}
