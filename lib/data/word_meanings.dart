import 'dart:math';

import 'word_lists.dart';

/// A word paired with its kid-friendly meaning for the Word Builder game.
class WordMeaning {
  final String word;
  final String meaning;

  const WordMeaning(this.word, this.meaning);
}

/// Word meanings organized by difficulty for the Word Builder game.
class WordMeanings {
  WordMeanings._();

  static const List<WordMeaning> easy = [
    // Animals
    WordMeaning('cat', 'A small furry pet that purrs'),
    WordMeaning('dog', 'A friendly pet that barks'),
    WordMeaning('bat', 'A flying animal that comes out at night'),
    WordMeaning('hen', 'A female chicken'),
    WordMeaning('fox', 'A clever orange animal with a bushy tail'),
    WordMeaning('pig', 'A pink farm animal that says oink'),
    WordMeaning('cow', 'A farm animal that gives us milk'),
    WordMeaning('ant', 'A tiny insect that lives in a colony'),
    WordMeaning('bee', 'A buzzing insect that makes honey'),
    WordMeaning('owl', 'A bird that hoots at night'),
    WordMeaning('yak', 'A big hairy animal from the mountains'),
    WordMeaning('eel', 'A long slippery fish'),
    WordMeaning('ram', 'A male sheep with big horns'),
    WordMeaning('cub', 'A baby bear or lion'),
    WordMeaning('pup', 'A baby dog'),

    // Things
    WordMeaning('hat', 'You wear it on your head'),
    WordMeaning('cup', 'You drink water from it'),
    WordMeaning('bed', 'You sleep on it at night'),
    WordMeaning('bus', 'A big vehicle that carries many people'),
    WordMeaning('map', 'A picture that shows where places are'),
    WordMeaning('net', 'Used to catch fish or butterflies'),
    WordMeaning('pen', 'You write with it using ink'),
    WordMeaning('box', 'You put things inside it'),
    WordMeaning('jar', 'A glass container with a lid'),
    WordMeaning('key', 'Used to open a lock'),
    WordMeaning('rug', 'A soft cover for the floor'),
    WordMeaning('toy', 'Something fun to play with'),
    WordMeaning('bag', 'You carry things in it'),
    WordMeaning('mop', 'Used to clean the floor'),
    WordMeaning('pot', 'Used to cook food in'),

    // Nature
    WordMeaning('sun', 'The bright star in our sky'),
    WordMeaning('sky', 'The blue space above us'),
    WordMeaning('ice', 'Frozen water'),
    WordMeaning('mud', 'Wet dirt'),
    WordMeaning('fog', 'A thick cloud near the ground'),
    WordMeaning('sea', 'A big body of salty water'),
    WordMeaning('dew', 'Tiny water drops on grass in the morning'),
    WordMeaning('oak', 'A big strong tree'),
    WordMeaning('ivy', 'A green plant that climbs walls'),
    WordMeaning('elm', 'A tall shade tree'),

    // Actions
    WordMeaning('run', 'To move your legs very fast'),
    WordMeaning('hop', 'To jump on one foot'),
    WordMeaning('sit', 'To rest on a chair'),
    WordMeaning('fly', 'To move through the air'),
    WordMeaning('dig', 'To make a hole in the ground'),
    WordMeaning('hug', 'To wrap your arms around someone'),
    WordMeaning('nap', 'A short sleep during the day'),
    WordMeaning('eat', 'To put food in your mouth'),
    WordMeaning('mix', 'To stir things together'),
    WordMeaning('win', 'To come first in a game'),

    // Describing words
    WordMeaning('big', 'The opposite of small'),
    WordMeaning('red', 'The color of a fire truck'),
    WordMeaning('hot', 'The opposite of cold'),
    WordMeaning('new', 'Not old, just made'),
    WordMeaning('old', 'Has been around for a long time'),
    WordMeaning('sad', 'When you feel unhappy'),
    WordMeaning('wet', 'Covered in water'),
    WordMeaning('dry', 'Not wet at all'),
    WordMeaning('fun', 'Something that makes you happy'),
    WordMeaning('shy', 'Feeling nervous around others'),

    // Food
    WordMeaning('pie', 'A baked food with a crust'),
    WordMeaning('jam', 'Sweet fruit spread for bread'),
    WordMeaning('egg', 'It comes from a chicken'),
    WordMeaning('pea', 'A small round green vegetable'),
    WordMeaning('ham', 'Meat from a pig'),
    WordMeaning('fig', 'A soft sweet fruit'),
    WordMeaning('gum', 'You chew it but do not swallow'),
    WordMeaning('oat', 'A grain used to make porridge'),
    WordMeaning('yam', 'A sweet root vegetable'),
    WordMeaning('tea', 'A warm drink made from leaves'),

    // Other
    WordMeaning('art', 'Drawing and painting'),
    WordMeaning('ink', 'The liquid inside a pen'),
    WordMeaning('day', 'When the sun is out'),
    WordMeaning('job', 'Work that you do'),
    WordMeaning('car', 'A vehicle with four wheels'),
    WordMeaning('jet', 'A very fast airplane'),
    WordMeaning('gem', 'A beautiful shiny stone'),
    WordMeaning('web', 'A spider makes this'),
    WordMeaning('van', 'A big car for carrying things'),
    WordMeaning('zoo', 'A place to see wild animals'),
  ];

  static const List<WordMeaning> medium = [
    // Animals
    WordMeaning('tiger', 'A big striped wild cat'),
    WordMeaning('whale', 'The biggest animal in the ocean'),
    WordMeaning('eagle', 'A large bird with sharp eyes'),
    WordMeaning('horse', 'A big animal you can ride'),
    WordMeaning('moose', 'A large deer with flat antlers'),
    WordMeaning('otter', 'A playful water animal'),
    WordMeaning('panda', 'A black and white bear from China'),
    WordMeaning('snail', 'A slow animal with a shell on its back'),
    WordMeaning('robin', 'A small bird with a red chest'),
    WordMeaning('camel', 'An animal with humps on its back'),

    // Things
    WordMeaning('chair', 'You sit on it at a table'),
    WordMeaning('clock', 'It tells you what time it is'),
    WordMeaning('dress', 'A piece of clothing girls often wear'),
    WordMeaning('piano', 'A big musical instrument with keys'),
    WordMeaning('tower', 'A tall narrow building'),
    WordMeaning('shelf', 'A flat board where you put books'),
    WordMeaning('scarf', 'You wrap it around your neck when cold'),
    WordMeaning('torch', 'A light you hold in your hand'),
    WordMeaning('crown', 'A king or queen wears it on their head'),
    WordMeaning('wagon', 'A small cart you pull with a handle'),

    // Nature
    WordMeaning('ocean', 'A very large body of salt water'),
    WordMeaning('cloud', 'White fluffy shapes in the sky'),
    WordMeaning('river', 'Water that flows across the land'),
    WordMeaning('stone', 'A small hard piece of rock'),
    WordMeaning('flame', 'The bright part of a fire'),
    WordMeaning('frost', 'Thin ice that forms on cold mornings'),
    WordMeaning('beach', 'Sandy land next to the ocean'),
    WordMeaning('storm', 'Bad weather with wind and rain'),
    WordMeaning('grove', 'A small group of trees'),
    WordMeaning('creek', 'A small stream of water'),

    // Actions
    WordMeaning('climb', 'To go up using hands and feet'),
    WordMeaning('dance', 'To move your body to music'),
    WordMeaning('paint', 'To make a picture with colors'),
    WordMeaning('dream', 'Pictures you see when you sleep'),
    WordMeaning('smile', 'A happy look on your face'),
    WordMeaning('skate', 'To glide on ice or wheels'),
    WordMeaning('float', 'To stay on top of water'),
    WordMeaning('chase', 'To run after someone'),
    WordMeaning('greet', 'To say hello to someone'),
    WordMeaning('shout', 'To call out in a loud voice'),

    // Describing words
    WordMeaning('brave', 'Not afraid of scary things'),
    WordMeaning('happy', 'Feeling glad and joyful'),
    WordMeaning('sweet', 'Tasting like sugar'),
    WordMeaning('sunny', 'When the sun is shining bright'),
    WordMeaning('quick', 'Very fast'),
    WordMeaning('sharp', 'Has a thin edge that can cut'),
    WordMeaning('grand', 'Very big and impressive'),
    WordMeaning('crisp', 'Fresh and crunchy'),
    WordMeaning('vivid', 'Very bright and colorful'),
    WordMeaning('noble', 'Good, honest, and brave'),

    // Food
    WordMeaning('apple', 'A round red or green fruit'),
    WordMeaning('grape', 'A small round fruit that grows in bunches'),
    WordMeaning('lemon', 'A sour yellow fruit'),
    WordMeaning('melon', 'A big round juicy fruit'),
    WordMeaning('olive', 'A small green or black fruit used on pizza'),
    WordMeaning('peach', 'A soft fuzzy orange fruit'),
    WordMeaning('toast', 'Bread that has been browned by heat'),
    WordMeaning('cream', 'The thick white part of milk'),
    WordMeaning('honey', 'Sweet golden liquid made by bees'),
    WordMeaning('candy', 'A sweet treat made from sugar'),

    // Places / Other
    WordMeaning('house', 'A building where people live'),
    WordMeaning('space', 'The area beyond Earth where stars are'),
    WordMeaning('world', 'The planet we live on'),
    WordMeaning('music', 'Sounds that make a melody'),
    WordMeaning('magic', 'Tricks that seem impossible'),
    WordMeaning('party', 'A fun gathering to celebrate'),
    WordMeaning('heart', 'The organ that pumps blood in your body'),
    WordMeaning('brain', 'The part of you that thinks'),
    WordMeaning('light', 'What lets you see in the dark'),
    WordMeaning('night', 'When the sky is dark and stars come out'),
  ];

  static const List<WordMeaning> hard = [
    // Animals
    WordMeaning('dolphin', 'A smart ocean animal that jumps and clicks'),
    WordMeaning('giraffe', 'The tallest animal with a very long neck'),
    WordMeaning('penguin', 'A bird that swims but cannot fly'),
    WordMeaning('elephant', 'The biggest land animal with a long trunk'),
    WordMeaning('dinosaur', 'A giant reptile that lived long ago'),
    WordMeaning('kangaroo', 'An animal from Australia that hops and has a pouch'),
    WordMeaning('goldfish', 'A small orange pet fish'),
    WordMeaning('squirrel', 'A small animal that collects nuts'),
    WordMeaning('tortoise', 'A slow reptile with a hard shell'),
    WordMeaning('mushroom', 'A small plant that grows in damp places'),

    // Things
    WordMeaning('keyboard', 'The part of a computer you type on'),
    WordMeaning('notebook', 'A book with blank pages for writing'),
    WordMeaning('airplane', 'A flying machine with wings'),
    WordMeaning('umbrella', 'Keeps you dry when it rains'),
    WordMeaning('sandwich', 'Food between two slices of bread'),
    WordMeaning('backpack', 'A bag you carry on your back'),
    WordMeaning('necklace', 'Jewelry you wear around your neck'),
    WordMeaning('bracelet', 'Jewelry you wear on your wrist'),
    WordMeaning('envelope', 'A paper cover for a letter'),
    WordMeaning('windmill', 'A machine with spinning blades that uses wind'),

    // Nature
    WordMeaning('rainbow', 'Colorful arc in the sky after rain'),
    WordMeaning('volcano', 'A mountain that can shoot out lava'),
    WordMeaning('mountain', 'A very tall piece of land'),
    WordMeaning('sunlight', 'The bright light from the sun'),
    WordMeaning('seashell', 'A hard cover left by ocean creatures'),
    WordMeaning('starfish', 'A star shaped animal in the ocean'),
    WordMeaning('snowfall', 'When snow comes down from the sky'),
    WordMeaning('woodland', 'An area covered with many trees'),
    WordMeaning('midnight', 'The middle of the night, twelve o clock'),
    WordMeaning('wildfire', 'A large fire that spreads through nature'),

    // Actions / Concepts
    WordMeaning('imagine', 'To make pictures in your mind'),
    WordMeaning('explore', 'To travel and discover new things'),
    WordMeaning('believe', 'To think something is true'),
    WordMeaning('journey', 'A long trip from one place to another'),
    WordMeaning('practice', 'To do something again to get better'),
    WordMeaning('exercise', 'Moving your body to stay healthy'),
    WordMeaning('treasure', 'Something very valuable and special'),
    WordMeaning('discover', 'To find something for the first time'),
    WordMeaning('remember', 'To keep something in your mind'),
    WordMeaning('surprise', 'Something you did not expect'),

    // Describing words
    WordMeaning('amazing', 'So great it makes you say wow'),
    WordMeaning('creative', 'Good at thinking of new ideas'),
    WordMeaning('friendly', 'Kind and nice to other people'),
    WordMeaning('grateful', 'Feeling thankful for something'),
    WordMeaning('peaceful', 'Calm and quiet, without trouble'),
    WordMeaning('cheerful', 'Happy and full of good feelings'),
    WordMeaning('splendid', 'Very impressive and wonderful'),
    WordMeaning('graceful', 'Moving in a smooth and pretty way'),
    WordMeaning('enormous', 'Really, really big'),
    WordMeaning('precious', 'Very special and worth a lot'),

    // Food
    WordMeaning('birthday', 'The day you were born, celebrated each year'),
    WordMeaning('lollipop', 'A hard candy on a stick'),
    WordMeaning('broccoli', 'A green vegetable that looks like tiny trees'),
    WordMeaning('cinnamon', 'A brown spice that smells warm and sweet'),
    WordMeaning('zucchini', 'A long green vegetable'),
    WordMeaning('macaroni', 'Small curved pasta tubes'),
    WordMeaning('tomatoes', 'Round red fruits used in sauces'),
    WordMeaning('cucumber', 'A long cool green vegetable'),
    WordMeaning('sandwich', 'Food between two slices of bread'),
    WordMeaning('barbecue', 'Cooking food over a fire outside'),

    // Places / Other
    WordMeaning('library', 'A place full of books to read and borrow'),
    WordMeaning('hospital', 'A building where doctors help sick people'),
    WordMeaning('vacation', 'Time off from school or work to have fun'),
    WordMeaning('alphabet', 'All the letters from A to Z'),
    WordMeaning('carnival', 'A fun fair with rides and games'),
    WordMeaning('champion', 'The winner of a contest'),
    WordMeaning('princess', 'The daughter of a king and queen'),
    WordMeaning('building', 'A structure with walls and a roof'),
    WordMeaning('treasure', 'Something very valuable like gold or jewels'),
    WordMeaning('together', 'When people are with each other'),
  ];

  static List<WordMeaning> forDifficulty(ContentDifficulty d) => switch (d) {
    ContentDifficulty.easy => easy,
    ContentDifficulty.medium => medium,
    ContentDifficulty.hard => hard,
  };

  static final _random = Random();

  /// Pick a random word-meaning pair, optionally excluding recent words.
  static WordMeaning randomWord(
    ContentDifficulty d, {
    Set<String>? exclude,
  }) {
    final list = forDifficulty(d);
    if (exclude == null || exclude.isEmpty) {
      return list[_random.nextInt(list.length)];
    }
    final filtered = list.where((wm) => !exclude.contains(wm.word)).toList();
    if (filtered.isEmpty) return list[_random.nextInt(list.length)];
    return filtered[_random.nextInt(filtered.length)];
  }
}
