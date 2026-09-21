import 'package:flutter/material.dart';
import '../models/lesson.dart';

/// One section of the learning path: a banner plus the lessons under it,
/// in the order they unlock.
class LessonUnit {
  const LessonUnit({
    required this.section,
    required this.title,
    required this.color,
    required this.lessonIds,
  });

  /// Small label above the title, e.g. "SECTION 1, UNIT 1".
  final String section;
  final String title;
  final Color color;
  final List<String> lessonIds;
}

// Card backgrounds. Kept soft so the emoji and word stay the loudest
// thing on screen.
const _peach = Color(0xFFFFE1A8);
const _lavender = Color(0xFFE6DDF2);
const _mint = Color(0xFFD8F0CE);
const _sky = Color(0xFFD7EBF5);
const _pink = Color(0xFFF6DCE6);
const _butter = Color(0xFFFFF0BE);
const _apricot = Color(0xFFFFDBC2);
const _slate = Color(0xFFD6E4EA);
const _blush = Color(0xFFF6D3D3);
const _sage = Color(0xFFCFEBD3);

/// The catalog. Bundled for now so the app works offline.
///
/// To ship new lessons WITHOUT a new APK release, move this list to a JSON
/// manifest served from Cloudflare R2 (or Supabase) and fetch it at
/// startup — access is decided by energy + subscription, not by which
/// lessons shipped inside the app, so new ones show up for everyone
/// immediately.
class LessonCatalog {
  /// The path, top to bottom. A lesson unlocks when the one before it is
  /// finished, so order here is what gates progression.
  static const List<LessonUnit> units = [
    LessonUnit(
      section: 'SECTION 1, UNIT 1',
      title: 'First words',
      color: Color(0xFF3AA7A0),
      lessonIds: ['colours', 'numbers', 'shapes'],
    ),
    LessonUnit(
      section: 'SECTION 1, UNIT 2',
      title: 'Animal friends',
      color: Color(0xFFE08D3C),
      lessonIds: ['animals', 'farm', 'garden'],
    ),
    LessonUnit(
      section: 'SECTION 1, UNIT 3',
      title: 'Every day',
      color: Color(0xFF7C6BB5),
      lessonIds: ['food', 'body', 'clothes'],
    ),
    LessonUnit(
      section: 'SECTION 1, UNIT 4',
      title: 'My world',
      color: Color(0xFF3D8BC4),
      lessonIds: ['family', 'weather', 'vehicles'],
    ),
    LessonUnit(
      section: 'SECTION 1, UNIT 5',
      title: 'How I feel',
      color: Color(0xFFD45D79),
      lessonIds: ['feelings', 'actions'],
    ),
  ];

  static const List<Lesson> lessons = [
    // ── Unit 1 · First words ──────────────────────────────────────────
    Lesson(
      id: 'colours',
      title: 'Colours All Around',
      subtitle: 'Learn your first colours',
      coverEmoji: '🌈',
      coverColor: _lavender,
      words: [
        LessonWord(emoji: '🍎', word: 'Red', text: 'The apple is red.', color: _blush),
        LessonWord(emoji: '☀️', word: 'Yellow', text: 'The sun is yellow.', color: _butter),
        LessonWord(emoji: '🌿', word: 'Green', text: 'The leaf is green.', color: _mint),
        LessonWord(emoji: '💧', word: 'Blue', text: 'The water is blue.', color: _sky),
        LessonWord(emoji: '🍇', word: 'Purple', text: 'The grapes are purple.', color: _lavender),
      ],
    ),
    Lesson(
      id: 'numbers',
      title: 'Count to Five',
      subtitle: 'Numbers one to five',
      coverEmoji: '🔢',
      coverColor: _mint,
      words: [
        LessonWord(emoji: '🍏', word: 'One', text: 'One green apple.', color: _mint),
        LessonWord(emoji: '🐟🐟', word: 'Two', text: 'Two little fish.', color: _sky),
        LessonWord(emoji: '🎈🎈🎈', word: 'Three', text: 'Three party balloons.', color: _blush),
        LessonWord(emoji: '⭐⭐⭐⭐', word: 'Four', text: 'Four shining stars.', color: _butter),
        LessonWord(emoji: '🌸🌸🌸🌸🌸', word: 'Five', text: 'Five pretty flowers.', color: _pink),
      ],
    ),
    Lesson(
      id: 'shapes',
      title: 'Shapes Everywhere',
      subtitle: 'Circles, squares and stars',
      coverEmoji: '🔷',
      coverColor: _sky,
      words: [
        LessonWord(emoji: '⭕', word: 'Circle', text: 'A circle is round.', color: _blush),
        LessonWord(emoji: '🟦', word: 'Square', text: 'A square has four sides.', color: _sky),
        LessonWord(emoji: '🔺', word: 'Triangle', text: 'A triangle has three sides.', color: _apricot),
        LessonWord(emoji: '⭐', word: 'Star', text: 'A star shines in the sky.', color: _butter),
        LessonWord(emoji: '❤️', word: 'Heart', text: 'A heart means love.', color: _pink),
      ],
    ),

    // ── Unit 2 · Animal friends ───────────────────────────────────────
    Lesson(
      id: 'animals',
      title: 'Animal Friends',
      subtitle: 'Animals and their names',
      coverEmoji: '🦁',
      coverColor: _peach,
      words: [
        LessonWord(emoji: '🦁', word: 'Lion', text: 'The lion is the king of the animals.', color: _peach),
        LessonWord(emoji: '🐘', word: 'Elephant', text: 'The elephant is big and grey.', color: _slate),
        LessonWord(emoji: '🦒', word: 'Giraffe', text: 'The giraffe has a long neck.', color: _butter),
        LessonWord(emoji: '🐧', word: 'Penguin', text: 'The penguin cannot fly, but it can swim.', color: _sky),
        LessonWord(emoji: '🦊', word: 'Fox', text: 'The fox has a big fluffy tail.', color: _apricot),
        LessonWord(emoji: '🐸', word: 'Frog', text: 'The frog can jump very high.', color: _mint),
      ],
    ),
    Lesson(
      id: 'farm',
      title: 'On the Farm',
      subtitle: 'Meet the farm animals',
      coverEmoji: '🚜',
      coverColor: _apricot,
      words: [
        LessonWord(emoji: '🐄', word: 'Cow', text: 'The cow says moo.', color: _slate),
        LessonWord(emoji: '🐷', word: 'Pig', text: 'The pig rolls in the mud.', color: _pink),
        LessonWord(emoji: '🐑', word: 'Sheep', text: 'The sheep has soft white wool.', color: _butter),
        LessonWord(emoji: '🦆', word: 'Duck', text: 'The duck swims in the pond.', color: _sky),
        LessonWord(emoji: '🐴', word: 'Horse', text: 'The horse runs very fast.', color: _apricot),
        LessonWord(emoji: '🐔', word: 'Chicken', text: 'The chicken lays an egg.', color: _blush),
      ],
    ),
    Lesson(
      id: 'garden',
      title: 'In the Garden',
      subtitle: 'Plants and little creatures',
      coverEmoji: '🌻',
      coverColor: _sage,
      words: [
        LessonWord(emoji: '🌻', word: 'Flower', text: 'The flower is tall and yellow.', color: _butter),
        LessonWord(emoji: '🌳', word: 'Tree', text: 'The tree is big and green.', color: _sage),
        LessonWord(emoji: '🐝', word: 'Bee', text: 'The bee buzzes around the flower.', color: _peach),
        LessonWord(emoji: '🦋', word: 'Butterfly', text: 'The butterfly has pretty wings.', color: _lavender),
        LessonWord(emoji: '🍃', word: 'Leaf', text: 'The leaf falls from the tree.', color: _mint),
        LessonWord(emoji: '🐌', word: 'Snail', text: 'The snail moves very slowly.', color: _slate),
      ],
    ),

    // ── Unit 3 · Every day ────────────────────────────────────────────
    Lesson(
      id: 'food',
      title: 'Yummy Food',
      subtitle: 'Things we like to eat',
      coverEmoji: '🍎',
      coverColor: _blush,
      words: [
        LessonWord(emoji: '🍎', word: 'Apple', text: 'The apple is sweet and crunchy.', color: _blush),
        LessonWord(emoji: '🍞', word: 'Bread', text: 'We eat bread for breakfast.', color: _apricot),
        LessonWord(emoji: '🥛', word: 'Milk', text: 'Milk is white and cold.', color: _sky),
        LessonWord(emoji: '🍌', word: 'Banana', text: 'The banana is long and yellow.', color: _butter),
        LessonWord(emoji: '🧀', word: 'Cheese', text: 'The little mouse loves cheese.', color: _peach),
        LessonWord(emoji: '🥚', word: 'Egg', text: 'The egg comes from a chicken.', color: _slate),
      ],
    ),
    Lesson(
      id: 'body',
      title: 'My Body',
      subtitle: 'Point to your nose!',
      coverEmoji: '👋',
      coverColor: _pink,
      words: [
        LessonWord(emoji: '✋', word: 'Hand', text: 'I wave with my hand.', color: _apricot),
        LessonWord(emoji: '👁️', word: 'Eye', text: 'I see with my eyes.', color: _sky),
        LessonWord(emoji: '👃', word: 'Nose', text: 'I smell with my nose.', color: _pink),
        LessonWord(emoji: '👂', word: 'Ear', text: 'I hear with my ears.', color: _peach),
        LessonWord(emoji: '🦶', word: 'Foot', text: 'I walk with my feet.', color: _mint),
        LessonWord(emoji: '👄', word: 'Mouth', text: 'I eat with my mouth.', color: _blush),
      ],
    ),
    Lesson(
      id: 'clothes',
      title: 'Getting Dressed',
      subtitle: 'What we wear every day',
      coverEmoji: '🧥',
      coverColor: _slate,
      words: [
        LessonWord(emoji: '🧢', word: 'Hat', text: 'I wear a hat on my head.', color: _sky),
        LessonWord(emoji: '👟', word: 'Shoes', text: 'I put shoes on my feet.', color: _slate),
        LessonWord(emoji: '🧥', word: 'Coat', text: 'A warm coat keeps out the cold.', color: _apricot),
        LessonWord(emoji: '🧦', word: 'Socks', text: 'My socks are stripy.', color: _pink),
        LessonWord(emoji: '👕', word: 'Shirt', text: 'This shirt is my favourite.', color: _mint),
        LessonWord(emoji: '🧤', word: 'Gloves', text: 'Gloves keep my hands warm.', color: _lavender),
      ],
    ),

    // ── Unit 4 · My world ─────────────────────────────────────────────
    Lesson(
      id: 'family',
      title: 'My Family',
      subtitle: 'The people we love',
      coverEmoji: '👪',
      coverColor: _butter,
      words: [
        LessonWord(emoji: '👩', word: 'Mum', text: 'Mum gives the best hugs.', color: _pink),
        LessonWord(emoji: '👨', word: 'Dad', text: 'Dad reads me a story.', color: _sky),
        LessonWord(emoji: '👶', word: 'Baby', text: 'The baby is very small.', color: _butter),
        LessonWord(emoji: '👵', word: 'Grandma', text: 'Grandma bakes yummy cakes.', color: _lavender),
        LessonWord(emoji: '👴', word: 'Grandpa', text: 'Grandpa tells funny jokes.', color: _slate),
        LessonWord(emoji: '🧒', word: 'Me', text: 'And that one is me!', color: _mint),
      ],
    ),
    Lesson(
      id: 'weather',
      title: "What's the Weather?",
      subtitle: 'Sunny, rainy and snowy days',
      coverEmoji: '⛅',
      coverColor: _sky,
      words: [
        LessonWord(emoji: '☀️', word: 'Sun', text: 'The sun is warm and bright.', color: _butter),
        LessonWord(emoji: '🌧️', word: 'Rain', text: 'Rain falls from the clouds.', color: _sky),
        LessonWord(emoji: '❄️', word: 'Snow', text: 'Snow is cold and white.', color: _slate),
        LessonWord(emoji: '☁️', word: 'Cloud', text: 'The cloud is soft and fluffy.', color: _lavender),
        LessonWord(emoji: '🌈', word: 'Rainbow', text: 'A rainbow has many colours.', color: _pink),
        LessonWord(emoji: '🌬️', word: 'Wind', text: 'The wind blows my hat away.', color: _mint),
      ],
    ),
    Lesson(
      id: 'vehicles',
      title: 'Things That Go',
      subtitle: 'Cars, trains and planes',
      coverEmoji: '🚗',
      coverColor: _peach,
      words: [
        LessonWord(emoji: '🚗', word: 'Car', text: 'The car drives down the road.', color: _blush),
        LessonWord(emoji: '🚌', word: 'Bus', text: 'The bus takes us to school.', color: _butter),
        LessonWord(emoji: '🚂', word: 'Train', text: 'The train goes choo choo.', color: _apricot),
        LessonWord(emoji: '✈️', word: 'Plane', text: 'The plane flies in the sky.', color: _sky),
        LessonWord(emoji: '⛵', word: 'Boat', text: 'The boat floats on the water.', color: _slate),
        LessonWord(emoji: '🚲', word: 'Bike', text: 'I ride my bike very fast.', color: _mint),
      ],
    ),

    // ── Unit 5 · How I feel ───────────────────────────────────────────
    Lesson(
      id: 'feelings',
      title: 'How I Feel',
      subtitle: 'Happy, sad and sleepy',
      coverEmoji: '😀',
      coverColor: _butter,
      words: [
        LessonWord(emoji: '😀', word: 'Happy', text: 'I feel happy when I play.', color: _butter),
        LessonWord(emoji: '😢', word: 'Sad', text: 'He is sad and crying.', color: _sky),
        LessonWord(emoji: '😴', word: 'Sleepy', text: 'I am sleepy at bedtime.', color: _lavender),
        LessonWord(emoji: '😠', word: 'Angry', text: 'She looks very angry.', color: _blush),
        LessonWord(emoji: '😮', word: 'Surprised', text: 'What a big surprise!', color: _peach),
        LessonWord(emoji: '😨', word: 'Scared', text: 'The loud noise is scary.', color: _slate),
      ],
    ),
    Lesson(
      id: 'actions',
      title: 'Things I Can Do',
      subtitle: 'Jump, run and dance',
      coverEmoji: '🤸',
      coverColor: _mint,
      words: [
        LessonWord(emoji: '🤸', word: 'Jump', text: 'I can jump very high.', color: _mint),
        LessonWord(emoji: '🏃', word: 'Run', text: 'We run in the park.', color: _apricot),
        LessonWord(emoji: '💃', word: 'Dance', text: 'She dances to the music.', color: _pink),
        LessonWord(emoji: '👏', word: 'Clap', text: 'Clap your hands with me!', color: _butter),
        LessonWord(emoji: '🛌', word: 'Sleep', text: 'I sleep in my cosy bed.', color: _lavender),
        LessonWord(emoji: '🍽️', word: 'Eat', text: 'We eat dinner together.', color: _blush),
      ],
    ),
  ];

  static Lesson byId(String id) => lessons.firstWhere((l) => l.id == id);
}

/// Display-only. The real subscription price is configured in Play Console.
const String kSubscriptionPriceLabel = '€4.99 / month';
