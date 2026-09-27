import 'package:flutter/material.dart';
import '../models/lesson.dart';

/// One section of the learning path: a banner plus the lessons under it,
/// in the order they unlock.
class LessonUnit {
  const LessonUnit({
    required this.id,
    required this.section,
    required this.title,
    required this.color,
    required this.lessonIds,
  });

  /// Stable id, and the stem of [reviewId].
  final String id;

  /// Small label above the title, e.g. "SECTION 1, UNIT 1".
  final String section;
  final String title;
  final Color color;
  final List<String> lessonIds;

  /// How the unit's review is tracked in ProgressService. The review is
  /// built at runtime rather than sitting in the catalog, so its id has
  /// to come from somewhere both the path and the profile can reach.
  String get reviewId => 'review_$id';

  /// Lessons plus the review — the unit's real length, which is what
  /// both the path banner and the profile count against.
  int get stepCount => lessonIds.length + 1;
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
      id: 'first_words',
      section: 'SECTION 1, UNIT 1',
      title: 'First words',
      color: Color(0xFF3AA7A0),
      lessonIds: ['colours', 'numbers', 'shapes'],
    ),
    LessonUnit(
      id: 'animal_friends',
      section: 'SECTION 1, UNIT 2',
      title: 'Animal friends',
      color: Color(0xFFE08D3C),
      lessonIds: ['animals', 'farm', 'garden'],
    ),
    LessonUnit(
      id: 'every_day',
      section: 'SECTION 1, UNIT 3',
      title: 'Every day',
      color: Color(0xFF7C6BB5),
      lessonIds: ['food', 'body', 'clothes'],
    ),
    LessonUnit(
      id: 'my_world',
      section: 'SECTION 1, UNIT 4',
      title: 'My world',
      color: Color(0xFF3D8BC4),
      lessonIds: ['family', 'weather', 'vehicles'],
    ),
    LessonUnit(
      id: 'how_i_feel',
      section: 'SECTION 1, UNIT 5',
      title: 'How I feel',
      color: Color(0xFFD45D79),
      lessonIds: ['feelings', 'actions'],
    ),

    // ── Section 2 ─────────────────────────────────────────────────────
    LessonUnit(
      id: 'in_the_kitchen',
      section: 'SECTION 2, UNIT 1',
      title: 'In the kitchen',
      color: Color(0xFFE2703A),
      lessonIds: ['fruit', 'vegetables', 'treats'],
    ),
    LessonUnit(
      id: 'play_time',
      section: 'SECTION 2, UNIT 2',
      title: 'Play time',
      color: Color(0xFFC4557E),
      lessonIds: ['toys', 'music', 'playground'],
    ),
    LessonUnit(
      id: 'out_and_about',
      section: 'SECTION 2, UNIT 3',
      title: 'Out and about',
      color: Color(0xFF3D8BC4),
      lessonIds: ['places', 'helpers', 'shopping'],
    ),
    LessonUnit(
      id: 'big_and_small',
      section: 'SECTION 2, UNIT 4',
      title: 'Big and small',
      color: Color(0xFF6B8E3D),
      lessonIds: ['opposites', 'sizes', 'positions'],
    ),
    LessonUnit(
      id: 'getting_ready',
      section: 'SECTION 2, UNIT 5',
      title: 'Getting ready',
      color: Color(0xFFB8802E),
      lessonIds: ['morning', 'bath_time', 'bed_time'],
    ),

    // ── Section 3 ─────────────────────────────────────────────────────
    LessonUnit(
      id: 'out_in_nature',
      section: 'SECTION 3, UNIT 1',
      title: 'Out in nature',
      color: Color(0xFF2F8F5B),
      lessonIds: ['plants', 'space', 'beach'],
    ),
    LessonUnit(
      id: 'wild_animals',
      section: 'SECTION 3, UNIT 2',
      title: 'Wild animals',
      color: Color(0xFFA35A2A),
      lessonIds: ['jungle', 'ocean', 'bugs_and_birds'],
    ),
    LessonUnit(
      id: 'seasons_and_days',
      section: 'SECTION 3, UNIT 3',
      title: 'Seasons and days',
      color: Color(0xFF8A6DBF),
      lessonIds: ['seasons', 'day_and_night', 'party'],
    ),
    LessonUnit(
      id: 'my_house',
      section: 'SECTION 3, UNIT 4',
      title: 'My house',
      color: Color(0xFF4D7EA8),
      lessonIds: ['rooms', 'furniture', 'helping_at_home'],
    ),
    LessonUnit(
      id: 'lets_go',
      section: 'SECTION 3, UNIT 5',
      title: "Let's go!",
      color: Color(0xFFD4562F),
      lessonIds: ['sports', 'moving', 'on_the_road'],
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

    // ── SECTION 2, UNIT 1 · In the kitchen ───────────────────────────────
    Lesson(
      id: 'fruit',
      title: 'Fruit Basket',
      subtitle: 'Sweet things that grow',
      coverEmoji: '🍓',
      coverColor: _blush,
      words: [
        LessonWord(emoji: '🍊', word: 'Orange', text: 'The orange is round and juicy.', color: _apricot),
        LessonWord(emoji: '🍓', word: 'Strawberry', text: 'The strawberry is small and red.', color: _blush),
        LessonWord(emoji: '🍐', word: 'Pear', text: 'The pear is green and sweet.', color: _mint),
        LessonWord(emoji: '🍉', word: 'Watermelon', text: 'The watermelon is big and pink inside.', color: _pink),
        LessonWord(emoji: '🍑', word: 'Peach', text: 'The peach has soft fuzzy skin.', color: _peach),
        LessonWord(emoji: '🍒', word: 'Cherry', text: 'Two cherries hang together.', color: _blush),
      ],
    ),
    Lesson(
      id: 'vegetables',
      title: 'Vegetable Patch',
      subtitle: 'Good things from the ground',
      coverEmoji: '🥕',
      coverColor: _sage,
      words: [
        LessonWord(emoji: '🥕', word: 'Carrot', text: 'The carrot is orange and crunchy.', color: _apricot),
        LessonWord(emoji: '🥔', word: 'Potato', text: 'The potato grows under the ground.', color: _slate),
        LessonWord(emoji: '🍅', word: 'Tomato', text: 'The tomato is red and round.', color: _blush),
        LessonWord(emoji: '🌽', word: 'Corn', text: 'The corn is yellow on a cob.', color: _butter),
        LessonWord(emoji: '🥦', word: 'Broccoli', text: 'The broccoli looks like a little tree.', color: _sage),
        LessonWord(emoji: '🥒', word: 'Cucumber', text: 'The cucumber is long and green.', color: _mint),
      ],
    ),
    Lesson(
      id: 'treats',
      title: 'Sweet Treats',
      subtitle: 'Yummy things for special days',
      coverEmoji: '🍰',
      coverColor: _pink,
      words: [
        LessonWord(emoji: '🧃', word: 'Juice', text: 'The juice box is cold and sweet.', color: _apricot),
        LessonWord(emoji: '🍦', word: 'Ice cream', text: 'The ice cream melts in the sun.', color: _sky),
        LessonWord(emoji: '🍰', word: 'Cake', text: 'We share the cake with everyone.', color: _pink),
        LessonWord(emoji: '🍪', word: 'Cookie', text: 'The cookie is round and crunchy.', color: _peach),
        LessonWord(emoji: '🍯', word: 'Honey', text: 'The honey is sticky and golden.', color: _butter),
        LessonWord(emoji: '🍫', word: 'Chocolate', text: 'The chocolate is brown and sweet.', color: _apricot),
      ],
    ),

    // ── SECTION 2, UNIT 2 · Play time ────────────────────────────────────
    Lesson(
      id: 'toys',
      title: 'My Toy Box',
      subtitle: 'Things we play with',
      coverEmoji: '🧸',
      coverColor: _peach,
      words: [
        LessonWord(emoji: '🧸', word: 'Teddy', text: 'The teddy is soft and cuddly.', color: _apricot),
        LessonWord(emoji: '🧱', word: 'Blocks', text: 'We build a tower with blocks.', color: _blush),
        LessonWord(emoji: '🪁', word: 'Kite', text: 'The kite flies high in the wind.', color: _sky),
        LessonWord(emoji: '🧩', word: 'Puzzle', text: 'The puzzle piece fits right here.', color: _lavender),
        LessonWord(emoji: '🤖', word: 'Robot', text: 'The robot walks and beeps.', color: _slate),
        LessonWord(emoji: '🎈', word: 'Balloon', text: 'The balloon floats up and up.', color: _pink),
      ],
    ),
    Lesson(
      id: 'music',
      title: 'Make Some Music',
      subtitle: 'Instruments and sounds',
      coverEmoji: '🥁',
      coverColor: _lavender,
      words: [
        LessonWord(emoji: '🥁', word: 'Drum', text: 'The drum goes boom boom boom.', color: _apricot),
        LessonWord(emoji: '🎸', word: 'Guitar', text: 'The guitar has six strings.', color: _peach),
        LessonWord(emoji: '🎹', word: 'Piano', text: 'The piano has black and white keys.', color: _slate),
        LessonWord(emoji: '🎺', word: 'Trumpet', text: 'The trumpet is loud and shiny.', color: _butter),
        LessonWord(emoji: '🔔', word: 'Bell', text: 'The bell goes ding ding.', color: _butter),
        LessonWord(emoji: '🎵', word: 'Song', text: 'We sing a happy song.', color: _lavender),
      ],
    ),
    Lesson(
      id: 'playground',
      title: 'At the Playground',
      subtitle: 'Outside with friends',
      coverEmoji: '🎠',
      coverColor: _mint,
      words: [
        LessonWord(emoji: '🏐', word: 'Ball', text: 'We throw the ball to each other.', color: _butter),
        LessonWord(emoji: '🛴', word: 'Scooter', text: 'The scooter goes fast down the path.', color: _sky),
        LessonWord(emoji: '🎠', word: 'Carousel', text: 'The carousel goes round and round.', color: _pink),
        LessonWord(emoji: '🏖️', word: 'Sandpit', text: 'We dig a hole in the sandpit.', color: _butter),
        LessonWord(emoji: '🎡', word: 'Big wheel', text: 'The big wheel turns very slowly.', color: _lavender),
        LessonWord(emoji: '🧒', word: 'Friend', text: 'We play with a friend.', color: _mint),
      ],
    ),

    // ── SECTION 2, UNIT 3 · Out and about ────────────────────────────────
    Lesson(
      id: 'places',
      title: 'Places We Go',
      subtitle: 'Around the town',
      coverEmoji: '🏫',
      coverColor: _sky,
      words: [
        LessonWord(emoji: '🏫', word: 'School', text: 'We learn new things at school.', color: _apricot),
        LessonWord(emoji: '🏬', word: 'Shop', text: 'We buy our food at the shop.', color: _sky),
        LessonWord(emoji: '🏞️', word: 'Park', text: 'We run and play in the park.', color: _sage),
        LessonWord(emoji: '🏥', word: 'Hospital', text: 'The doctor works at the hospital.', color: _blush),
        LessonWord(emoji: '🏠', word: 'House', text: 'We live in a warm house.', color: _peach),
        LessonWord(emoji: '📚', word: 'Library', text: 'The library is full of books.', color: _lavender),
      ],
    ),
    Lesson(
      id: 'helpers',
      title: 'People Who Help',
      subtitle: 'Helpers in our town',
      coverEmoji: '🚒',
      coverColor: _blush,
      words: [
        LessonWord(emoji: '🩺', word: 'Doctor', text: 'The doctor helps us feel better.', color: _sky),
        LessonWord(emoji: '🔨', word: 'Builder', text: 'The builder fixes and builds things.', color: _butter),
        LessonWord(emoji: '👮', word: 'Police', text: 'The police keep everyone safe.', color: _slate),
        LessonWord(emoji: '🚒', word: 'Firefighter', text: 'The firefighter drives the red engine.', color: _blush),
        LessonWord(emoji: '📮', word: 'Postman', text: 'The postman brings us letters.', color: _butter),
        LessonWord(emoji: '🌾', word: 'Farmer', text: 'The farmer grows our food.', color: _sage),
      ],
    ),
    Lesson(
      id: 'shopping',
      title: 'Going Shopping',
      subtitle: 'At the shop',
      coverEmoji: '🛒',
      coverColor: _butter,
      words: [
        LessonWord(emoji: '💰', word: 'Money', text: 'We pay with money.', color: _butter),
        LessonWord(emoji: '🧺', word: 'Basket', text: 'The basket is full of fruit.', color: _apricot),
        LessonWord(emoji: '🛍️', word: 'Bag', text: 'We carry the bag home.', color: _pink),
        LessonWord(emoji: '🛒', word: 'Trolley', text: 'The trolley has four wheels.', color: _slate),
        LessonWord(emoji: '🎫', word: 'Ticket', text: 'We need a ticket to go in.', color: _lavender),
        LessonWord(emoji: '📝', word: 'List', text: 'The list says what we need.', color: _sky),
      ],
    ),

    // ── SECTION 2, UNIT 4 · Big and small ────────────────────────────────
    Lesson(
      id: 'opposites',
      title: 'Opposites',
      subtitle: 'Words that are the other way',
      coverEmoji: '🔥',
      coverColor: _apricot,
      words: [
        LessonWord(emoji: '🐘', word: 'Big', text: 'The elephant is very big.', color: _slate),
        LessonWord(emoji: '🐜', word: 'Small', text: 'The ant is very small.', color: _apricot),
        LessonWord(emoji: '🔥', word: 'Hot', text: 'The fire is hot. Do not touch!', color: _blush),
        LessonWord(emoji: '🧊', word: 'Cold', text: 'The ice is cold in my hand.', color: _sky),
        LessonWord(emoji: '🐆', word: 'Fast', text: 'The cheetah runs very fast.', color: _butter),
        LessonWord(emoji: '🐢', word: 'Slow', text: 'The turtle walks very slow.', color: _sage),
      ],
    ),
    Lesson(
      id: 'sizes',
      title: 'How Big Is It?',
      subtitle: 'Tall, long and tiny',
      coverEmoji: '🦒',
      coverColor: _mint,
      words: [
        LessonWord(emoji: '🌲', word: 'Tall', text: 'The tree is tall and straight.', color: _sage),
        LessonWord(emoji: '🍄', word: 'Short', text: 'The mushroom is short and round.', color: _blush),
        LessonWord(emoji: '🐍', word: 'Long', text: 'The snake is very long.', color: _mint),
        LessonWord(emoji: '⚪', word: 'Round', text: 'The ball is round like a circle.', color: _slate),
        LessonWord(emoji: '🐞', word: 'Tiny', text: 'The ladybird is tiny.', color: _blush),
        LessonWord(emoji: '🏔️', word: 'Huge', text: 'The mountain is huge.', color: _sky),
      ],
    ),
    Lesson(
      id: 'positions',
      title: 'Where Is It?',
      subtitle: 'Up, down, in and out',
      coverEmoji: '⬆️',
      coverColor: _sky,
      words: [
        LessonWord(emoji: '⬆️', word: 'Up', text: 'The balloon goes up.', color: _sky),
        LessonWord(emoji: '⬇️', word: 'Down', text: 'The ball rolls down.', color: _apricot),
        LessonWord(emoji: '📥', word: 'In', text: 'Put the toy in the box.', color: _mint),
        LessonWord(emoji: '📤', word: 'Out', text: 'Take the toy out again.', color: _butter),
        LessonWord(emoji: '⬅️', word: 'Left', text: 'The arrow points to the left.', color: _lavender),
        LessonWord(emoji: '➡️', word: 'Right', text: 'The arrow points to the right.', color: _pink),
      ],
    ),

    // ── SECTION 2, UNIT 5 · Getting ready ────────────────────────────────
    Lesson(
      id: 'morning',
      title: 'Good Morning',
      subtitle: 'How the day starts',
      coverEmoji: '⏰',
      coverColor: _butter,
      words: [
        LessonWord(emoji: '⏰', word: 'Alarm', text: 'The alarm wakes us up.', color: _blush),
        LessonWord(emoji: '🪥', word: 'Toothbrush', text: 'We brush our teeth every morning.', color: _sky),
        LessonWord(emoji: '🥣', word: 'Breakfast', text: 'Breakfast is the first meal.', color: _butter),
        LessonWord(emoji: '🎒', word: 'Backpack', text: 'The backpack holds all my things.', color: _apricot),
        LessonWord(emoji: '🌅', word: 'Sunrise', text: 'The sunrise is orange and pink.', color: _peach),
      ],
    ),
    Lesson(
      id: 'bath_time',
      title: 'Bath Time',
      subtitle: 'Splash and get clean',
      coverEmoji: '🛁',
      coverColor: _sky,
      words: [
        LessonWord(emoji: '🛁', word: 'Bath', text: 'The bath is warm and bubbly.', color: _sky),
        LessonWord(emoji: '🚿', word: 'Shower', text: 'The shower sprays warm water.', color: _slate),
        LessonWord(emoji: '🧼', word: 'Soap', text: 'The soap makes lots of bubbles.', color: _pink),
        LessonWord(emoji: '🧽', word: 'Sponge', text: 'The sponge is soft and squishy.', color: _butter),
        LessonWord(emoji: '🦷', word: 'Tooth', text: 'We keep every tooth clean.', color: _blush),
        LessonWord(emoji: '💦', word: 'Splash', text: 'We splash the water everywhere.', color: _mint),
      ],
    ),
    Lesson(
      id: 'bed_time',
      title: 'Time for Bed',
      subtitle: 'Goodnight, sleep tight',
      coverEmoji: '🌙',
      coverColor: _lavender,
      words: [
        LessonWord(emoji: '🛏️', word: 'Bed', text: 'The bed is soft and warm.', color: _lavender),
        LessonWord(emoji: '🌙', word: 'Moon', text: 'The moon shines at night.', color: _slate),
        LessonWord(emoji: '📖', word: 'Story', text: 'We read a story before bed.', color: _apricot),
        LessonWord(emoji: '🕯️', word: 'Candle', text: 'The candle makes a little light.', color: _butter),
        LessonWord(emoji: '💭', word: 'Dream', text: 'We dream when we are asleep.', color: _sky),
        LessonWord(emoji: '🥱', word: 'Yawn', text: 'A big yawn means we are tired.', color: _peach),
      ],
    ),

    // ── SECTION 3, UNIT 1 · Out in nature ────────────────────────────────
    Lesson(
      id: 'plants',
      title: 'Growing Things',
      subtitle: 'Plants big and small',
      coverEmoji: '🌵',
      coverColor: _sage,
      words: [
        LessonWord(emoji: '🌱', word: 'Seedling', text: 'The seedling is just starting to grow.', color: _mint),
        LessonWord(emoji: '🍄', word: 'Mushroom', text: 'The mushroom grows after the rain.', color: _blush),
        LessonWord(emoji: '🌵', word: 'Cactus', text: 'The cactus is prickly. Be careful!', color: _sage),
        LessonWord(emoji: '🌹', word: 'Rose', text: 'The rose smells lovely.', color: _blush),
        LessonWord(emoji: '🌷', word: 'Tulip', text: 'The tulip opens in the spring.', color: _pink),
        LessonWord(emoji: '🌴', word: 'Palm', text: 'The palm tree grows where it is hot.', color: _butter),
      ],
    ),
    Lesson(
      id: 'space',
      title: 'Up in Space',
      subtitle: 'Above the clouds',
      coverEmoji: '🚀',
      coverColor: _slate,
      words: [
        LessonWord(emoji: '🚀', word: 'Rocket', text: 'The rocket flies up to space.', color: _blush),
        LessonWord(emoji: '🪐', word: 'Planet', text: 'The planet has a ring around it.', color: _butter),
        LessonWord(emoji: '☄️', word: 'Comet', text: 'The comet has a long bright tail.', color: _slate),
        LessonWord(emoji: '🌌', word: 'Galaxy', text: 'The galaxy is full of stars.', color: _lavender),
        LessonWord(emoji: '🛰️', word: 'Satellite', text: 'The satellite goes around the Earth.', color: _sky),
        LessonWord(emoji: '🔭', word: 'Telescope', text: 'We look at the stars through a telescope.', color: _mint),
      ],
    ),
    Lesson(
      id: 'beach',
      title: 'At the Beach',
      subtitle: 'Sand and sea',
      coverEmoji: '🐚',
      coverColor: _sky,
      words: [
        LessonWord(emoji: '🌊', word: 'Sea', text: 'The sea is blue and salty.', color: _sky),
        LessonWord(emoji: '🏝️', word: 'Sand', text: 'The sand is warm under our feet.', color: _butter),
        LessonWord(emoji: '🐚', word: 'Shell', text: 'We find a shell on the beach.', color: _pink),
        LessonWord(emoji: '🦀', word: 'Crab', text: 'The crab walks sideways.', color: _blush),
        LessonWord(emoji: '⛱️', word: 'Umbrella', text: 'The umbrella keeps us in the shade.', color: _apricot),
        LessonWord(emoji: '🍧', word: 'Ice lolly', text: 'The ice lolly is cold and sweet.', color: _mint),
      ],
    ),

    // ── SECTION 3, UNIT 2 · Wild animals ─────────────────────────────────
    Lesson(
      id: 'jungle',
      title: 'In the Jungle',
      subtitle: 'Animals in the trees',
      coverEmoji: '🐵',
      coverColor: _sage,
      words: [
        LessonWord(emoji: '🐵', word: 'Monkey', text: 'The monkey swings from tree to tree.', color: _apricot),
        LessonWord(emoji: '🐍', word: 'Snake', text: 'The snake slides along the ground.', color: _mint),
        LessonWord(emoji: '🐯', word: 'Tiger', text: 'The tiger has orange and black stripes.', color: _butter),
        LessonWord(emoji: '🦜', word: 'Parrot', text: 'The parrot has bright colourful feathers.', color: _blush),
        LessonWord(emoji: '🦍', word: 'Gorilla', text: 'The gorilla is big and strong.', color: _slate),
        LessonWord(emoji: '🦥', word: 'Sloth', text: 'The sloth moves very, very slowly.', color: _sage),
      ],
    ),
    Lesson(
      id: 'ocean',
      title: 'Under the Sea',
      subtitle: 'Animals in the water',
      coverEmoji: '🐬',
      coverColor: _sky,
      words: [
        LessonWord(emoji: '🐬', word: 'Dolphin', text: 'The dolphin jumps out of the water.', color: _sky),
        LessonWord(emoji: '🦈', word: 'Shark', text: 'The shark has sharp teeth.', color: _slate),
        LessonWord(emoji: '🐙', word: 'Octopus', text: 'The octopus has eight arms.', color: _pink),
        LessonWord(emoji: '🐟', word: 'Fish', text: 'The fish swims in the sea.', color: _mint),
        LessonWord(emoji: '🐳', word: 'Whale', text: 'The whale is the biggest animal.', color: _sky),
        LessonWord(emoji: '🦭', word: 'Seal', text: 'The seal claps and barks.', color: _slate),
      ],
    ),
    Lesson(
      id: 'bugs_and_birds',
      title: 'Bugs and Birds',
      subtitle: 'Little wings and legs',
      coverEmoji: '🦉',
      coverColor: _lavender,
      words: [
        LessonWord(emoji: '🐜', word: 'Ant', text: 'The ant carries a big crumb.', color: _apricot),
        LessonWord(emoji: '🕷️', word: 'Spider', text: 'The spider makes a web.', color: _slate),
        LessonWord(emoji: '🐞', word: 'Ladybird', text: 'The ladybird has black spots.', color: _blush),
        LessonWord(emoji: '🦉', word: 'Owl', text: 'The owl stays awake at night.', color: _lavender),
        LessonWord(emoji: '🦅', word: 'Eagle', text: 'The eagle flies very high.', color: _butter),
        LessonWord(emoji: '🐛', word: 'Caterpillar', text: 'The caterpillar munches a leaf.', color: _mint),
      ],
    ),

    // ── SECTION 3, UNIT 3 · Seasons and days ─────────────────────────────
    Lesson(
      id: 'seasons',
      title: 'Four Seasons',
      subtitle: 'The year goes round',
      coverEmoji: '🍂',
      coverColor: _apricot,
      words: [
        LessonWord(emoji: '🌼', word: 'Spring', text: 'In spring the flowers come out.', color: _butter),
        LessonWord(emoji: '🌞', word: 'Summer', text: 'In summer the days are long and hot.', color: _butter),
        LessonWord(emoji: '🍂', word: 'Autumn', text: 'In autumn the leaves turn brown.', color: _apricot),
        LessonWord(emoji: '⛄', word: 'Winter', text: 'In winter it is cold and snowy.', color: _sky),
        LessonWord(emoji: '📅', word: 'Year', text: 'A year has four seasons.', color: _slate),
        LessonWord(emoji: '🌦️', word: 'Weather', text: 'The weather changes every day.', color: _sage),
      ],
    ),
    Lesson(
      id: 'day_and_night',
      title: 'Day and Night',
      subtitle: 'From morning to night',
      coverEmoji: '🌇',
      coverColor: _slate,
      words: [
        LessonWord(emoji: '🌅', word: 'Morning', text: 'In the morning we wake up.', color: _peach),
        LessonWord(emoji: '🏙️', word: 'Day', text: 'In the day we play outside.', color: _sky),
        LessonWord(emoji: '🌇', word: 'Evening', text: 'In the evening the sun goes down.', color: _apricot),
        LessonWord(emoji: '🌃', word: 'Night', text: 'At night the sky is dark.', color: _slate),
        LessonWord(emoji: '🕗', word: 'Clock', text: 'The clock tells us the time.', color: _butter),
        LessonWord(emoji: '🗓️', word: 'Week', text: 'A week has seven days.', color: _lavender),
      ],
    ),
    Lesson(
      id: 'party',
      title: 'Party Time',
      subtitle: 'Something to celebrate',
      coverEmoji: '🎉',
      coverColor: _pink,
      words: [
        LessonWord(emoji: '🎉', word: 'Party', text: 'Everyone comes to the party.', color: _pink),
        LessonWord(emoji: '🎂', word: 'Birthday', text: 'We sing on your birthday.', color: _blush),
        LessonWord(emoji: '🎁', word: 'Present', text: 'The present has a big bow.', color: _lavender),
        LessonWord(emoji: '🥳', word: 'Cheer', text: 'We cheer and clap together.', color: _butter),
        LessonWord(emoji: '🎊', word: 'Confetti', text: 'The confetti falls like rain.', color: _apricot),
        LessonWord(emoji: '💌', word: 'Card', text: 'We write a card for you.', color: _pink),
      ],
    ),

    // ── SECTION 3, UNIT 4 · My house ─────────────────────────────────────
    Lesson(
      id: 'rooms',
      title: 'Rooms at Home',
      subtitle: 'Every room has a name',
      coverEmoji: '🏡',
      coverColor: _peach,
      words: [
        LessonWord(emoji: '🍳', word: 'Kitchen', text: 'We cook our food in the kitchen.', color: _apricot),
        LessonWord(emoji: '🚽', word: 'Bathroom', text: 'We wash our hands in the bathroom.', color: _sky),
        LessonWord(emoji: '🛌', word: 'Bedroom', text: 'We sleep in the bedroom.', color: _lavender),
        LessonWord(emoji: '🛋️', word: 'Living room', text: 'We sit together in the living room.', color: _peach),
        LessonWord(emoji: '🪜', word: 'Stairs', text: 'We walk up the stairs.', color: _slate),
        LessonWord(emoji: '🏡', word: 'Garden', text: 'The garden is behind our house.', color: _sage),
      ],
    ),
    Lesson(
      id: 'furniture',
      title: 'Things at Home',
      subtitle: 'What is in the room',
      coverEmoji: '🪑',
      coverColor: _slate,
      words: [
        LessonWord(emoji: '🪑', word: 'Chair', text: 'We sit down on the chair.', color: _apricot),
        LessonWord(emoji: '🍽️', word: 'Table', text: 'We eat our dinner at the table.', color: _butter),
        LessonWord(emoji: '💡', word: 'Lamp', text: 'The lamp gives us light.', color: _butter),
        LessonWord(emoji: '🚪', word: 'Door', text: 'We open the door to go in.', color: _peach),
        LessonWord(emoji: '🔑', word: 'Key', text: 'The key opens the door.', color: _slate),
        LessonWord(emoji: '📦', word: 'Box', text: 'The box is full of toys.', color: _apricot),
      ],
    ),
    Lesson(
      id: 'helping_at_home',
      title: 'Helping at Home',
      subtitle: 'Jobs we can do',
      coverEmoji: '🧹',
      coverColor: _mint,
      words: [
        LessonWord(emoji: '🧹', word: 'Broom', text: 'We sweep the floor with a broom.', color: _apricot),
        LessonWord(emoji: '🧺', word: 'Washing', text: 'The washing hangs out to dry.', color: _sky),
        LessonWord(emoji: '🗑️', word: 'Bin', text: 'The rubbish goes in the bin.', color: _slate),
        LessonWord(emoji: '🪣', word: 'Bucket', text: 'The bucket is full of water.', color: _sky),
        LessonWord(emoji: '🥄', word: 'Spoon', text: 'We stir with a spoon.', color: _butter),
        LessonWord(emoji: '🥤', word: 'Cup', text: 'We fill the cup with water.', color: _mint),
      ],
    ),

    // ── SECTION 3, UNIT 5 · Let's go! ────────────────────────────────────
    Lesson(
      id: 'sports',
      title: 'Sports Day',
      subtitle: 'Games we play',
      coverEmoji: '⚽',
      coverColor: _mint,
      words: [
        LessonWord(emoji: '⚽', word: 'Football', text: 'We kick the football into the goal.', color: _mint),
        LessonWord(emoji: '🏀', word: 'Basketball', text: 'The basketball goes in the hoop.', color: _apricot),
        LessonWord(emoji: '🏊', word: 'Swimming', text: 'Swimming keeps us cool.', color: _sky),
        LessonWord(emoji: '🚴', word: 'Cycling', text: 'Cycling is fun and fast.', color: _butter),
        LessonWord(emoji: '🎾', word: 'Tennis', text: 'We hit the tennis ball over the net.', color: _sage),
        LessonWord(emoji: '⛸️', word: 'Skating', text: 'Skating on the ice is slippery.', color: _slate),
      ],
    ),
    Lesson(
      id: 'moving',
      title: 'Move Your Body',
      subtitle: 'Ways we can move',
      coverEmoji: '🤸',
      coverColor: _pink,
      words: [
        LessonWord(emoji: '🧗', word: 'Climb', text: 'We climb up high.', color: _apricot),
        LessonWord(emoji: '🐰', word: 'Hop', text: 'The rabbit likes to hop.', color: _blush),
        LessonWord(emoji: '🌀', word: 'Spin', text: 'We spin round and round.', color: _lavender),
        LessonWord(emoji: '🤸', word: 'Stretch', text: 'We stretch up to the sky.', color: _pink),
        LessonWord(emoji: '🚶', word: 'Walk', text: 'We walk to the park.', color: _sage),
        LessonWord(emoji: '👋', word: 'Wave', text: 'We wave goodbye.', color: _butter),
      ],
    ),
    Lesson(
      id: 'on_the_road',
      title: 'On the Road',
      subtitle: 'Staying safe outside',
      coverEmoji: '🚦',
      coverColor: _butter,
      words: [
        LessonWord(emoji: '🚦', word: 'Traffic light', text: 'The traffic light turns red.', color: _blush),
        LessonWord(emoji: '🛑', word: 'Stop', text: 'Stop and look both ways.', color: _blush),
        LessonWord(emoji: '🚸', word: 'Crossing', text: 'We use the crossing to go over.', color: _butter),
        LessonWord(emoji: '⛑️', word: 'Helmet', text: 'The helmet keeps our head safe.', color: _apricot),
        LessonWord(emoji: '🚧', word: 'Sign', text: 'The sign tells us to be careful.', color: _butter),
        LessonWord(emoji: '🚏', word: 'Bus stop', text: 'We wait at the bus stop.', color: _slate),
      ],
    ),
  ];

  static Lesson byId(String id) => lessons.firstWhere((l) => l.id == id);

  /// Every distinct word in the catalog, in teaching order.
  static List<LessonWord> get allWords {
    final seen = <String>{};
    return [
      for (final lesson in lessons)
        for (final word in lesson.words)
          if (seen.add(word.word)) word,
    ];
  }

  /// Looks a word up by its text. Null if it isn't in the catalog any
  /// more — a saved miss can outlive the lesson that taught it.
  static LessonWord? wordByText(String text) {
    for (final word in allWords) {
      if (word.word == text) return word;
    }
    return null;
  }

  /// A drill over [words] — the same listen-and-tap loop as a lesson,
  /// built on the fly from whatever is being practised. Null when fewer
  /// than two of them are still in the catalog, since a tap-the-match
  /// question needs something to choose between.
  static Lesson? practiceLesson(List<String> words) {
    final found = [
      for (final text in words)
        if (wordByText(text) case final word?) word,
    ];
    if (found.length < 2) return null;
    return Lesson(
      id: 'practice_tricky',
      title: 'Tricky words',
      subtitle: 'The ones worth another go',
      coverEmoji: '🎯',
      coverColor: const Color(0xFFFFDBC2),
      words: found.take(6).toList(),
    );
  }
}

/// Display-only. The real subscription price is configured in Play Console.
const String kSubscriptionPriceLabel = '€4.99 / month';
