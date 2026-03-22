# Typer Kids

A fun, kid-friendly typing tutor app built with Flutter. Targets children learning to type with colorful lessons, arcade-style games, free practice, and timed tests.

## Quick Reference

- **Version:** 1.1.2+3
- **Dart SDK:** ^3.11.0
- **State management:** Provider (ChangeNotifier)
- **Routing:** go_router
- **Storage:** SharedPreferences (local, per-profile)
- **Fonts:** Google Fonts (Fredoka for headings, Nunito for body, Source Code Pro for typing)
- **Platforms:** Windows, macOS, Linux, Web

## Project Structure

```
lib/
  core/
    router/app_router.dart        # go_router setup, route definitions
    theme/app_colors.dart         # Color palette (jungle green, warm orange, cream bg)
    theme/app_theme.dart          # Material 3 theme with custom typography
    sound_manager.dart            # Audio pooling singleton (8 WAV sound effects)
  data/
    keyboard_data.dart            # QWERTY layout, finger-to-key color zones
    lesson_curriculum.dart        # Classic 34-lesson curriculum
    lesson_curriculum_comprehensive.dart  # Expanded curriculum (160+ lessons)
    lesson_curriculum_selector.dart       # Facade to switch curricula (default: comprehensive)
    story_content.dart            # Story passages by difficulty (easy/medium/hard)
    word_lists.dart               # Word pools by difficulty for games
  models/
    lesson.dart                   # Lesson model with Category & Difficulty enums
    profile.dart                  # User profile (name, emoji avatar)
    lesson_progress.dart          # Per-lesson progress tracking with history
    typing_stats.dart             # Session stats (accuracy, WPM, stars)
  providers/
    profile_provider.dart         # Multi-profile CRUD, active profile tracking
    progress_provider.dart        # Lesson progress + game high scores per profile
    typing_provider.dart          # Real-time typing state (char states, cursor, timer)
  screens/
    home_screen.dart              # Main menu with progress summary
    lesson_list_screen.dart       # Browse lessons by category
    typing_screen.dart            # Lesson typing interface with keyboard widget
    results_screen.dart           # Post-lesson celebration with confetti
    profile_screen.dart           # Profile picker/manager
    settings_screen.dart          # Stats display, reset progress
    games/
      game_menu_screen.dart       # Game selection grid
      defend_temple_screen.dart   # Defend temple from demons (trishul projectile)
      falling_words_screen.dart   # Type falling words before they hit bottom
      word_bubbles_screen.dart    # Pop bubbles by typing before fade
      speed_chase_screen.dart     # Race ghost car by typing words
    sandbox/
      sandbox_screen.dart         # Free practice with story passages
    test/
      typing_test_screen.dart     # Timed tests (30s/1m/2m/5m)
  widgets/
    keyboard_widget.dart          # On-screen QWERTY with finger color zones
    finger_guide.dart             # Hand diagram showing active finger
    typing_display.dart           # Character-by-character feedback display
    star_rating.dart              # Animated 1-5 star display
    animal_mascot.dart            # Bouncing monkey with mood states
```

## Architecture Patterns

- **Provider pattern** for state management with ChangeNotifier
- **Facade pattern** for curriculum selection (LessonCurriculumSelector)
- **Singleton** for SoundManager with audio pooling (6 players)
- **Phase-based screens** in games: setup -> playing -> gameOver
- **Adaptive difficulty** in all games: speed scales based on player performance
- **Per-profile data isolation** via prefixed SharedPreferences keys

## Content Structure

### Curriculum (Comprehensive - default)
The comprehensive curriculum has 160+ lessons organized in sections:
1. **Individual letters** (52 lessons) - Each letter intro + type & mix
2. **Group mix/play/quest** (27 lessons) - 9 alphabet groups x 3 drill styles
3. **Alphabet range practice** (20 lessons) - A-F, A-L, A-R, A-Z ranges
4. **Word patterns** (16 lessons) - Rhyming families (_ad, _at, _ed, etc.)
5. **Sight words** (24 lessons) - High-frequency word pairs
6. **Phrases** (12 lessons) - Theme-based short phrases
7. **Sentence sets** (12 lessons) - Full sentence fluency
8. **Overall reviews** (12 lessons) - Mixed review topics
9. **Punctuation & numbers** (12 lessons) - Period, comma, digits, data entry
10. **Digraphs** (10 lessons) - sh, ch, th, wh, ph, ck, ng, qu, wr, kn
11. **Consonant blends** (12 lessons) - bl, br, cl, cr, dr, fl, fr, gr, pl, sl, sp, st
12. **Compound words** (8 lessons) - Themed compound word groups
13. **Themed sentences** (5 lessons) - Space theme (planets, stars, rockets)

### Word Lists
- **Easy:** 300+ three-letter words (the, cat, dog, hat...)
- **Medium:** 310+ five-letter words (apple, happy, smile, house...)
- **Hard:** 280+ seven-to-nine-letter words (amazing, believe, captain...)

### Story Passages
- **Easy (16):** Classic folk tales (Three Bears, Little Red Hen, Tortoise and Hare...)
- **Medium (16):** Children's literature (Alice in Wonderland, Peter Pan, Narnia...)
- **Hard (16):** Classic novels (Christmas Carol, Moby Dick, The Hobbit...)

## Games

All games have Easy/Medium/Hard modes with adaptive difficulty that adjusts speed based on player performance (speeds up on correct answers, slows down on mistakes).

1. **Defend the Temple** - Demons carry words downward; type correctly to launch trishul projectile. Temple health meter.
2. **Falling Words** - Type words before they hit bottom. Lives system (5 lives). Height-adaptive scaling.
3. **Word Bubbles** - Pop floating bubbles by typing before fade. Timed (60/75/90s).
4. **Speed Chase** - Race ghost car by typing words. Ghost progress bar.

## Key Design Decisions

- **Punctuation:** Only period (.) and comma (,) are used. No question marks, exclamation points, or other punctuation.
- **Target audience:** Kids learning to type. Games should be fun but not frustratingly hard.
- **Adaptive difficulty:** All games dynamically adjust speed/difficulty based on real-time performance.
- **Responsive layout:** Grid layout on wide screens (>860px), single column on narrow screens.
- **Sound effects:** CC0 synthesized WAVs, graceful degradation if audio unavailable.

## Build & Release

CI/CD via GitHub Actions (`.github/workflows/release.yml`):
- Triggered by git tag push or manual workflow_dispatch
- Builds: Windows (zip + Inno Setup exe), macOS (zip + DMG), Linux (tar.gz + AppImage)
- macOS app bundle name is "Typer Kids" (with space) - the workflow must reference "Typer Kids.app"

## Commands

```bash
# Run the app
flutter run

# Build for release
flutter build windows --release
flutter build macos --release
flutter build linux --release
flutter build web --release

# Analyze
flutter analyze

# Run tests
flutter test
```

## Conventions

- Use `GoogleFonts.fredoka` for headings/titles/buttons
- Use `GoogleFonts.nunito` for body text
- Use `GoogleFonts.sourceCodePro` for typing/monospace displays
- Colors come from `AppColors` - jungle green primary, warm orange secondary, fun pink accent, warm cream background
- Rounded corners (16px default), Material Design 3
- Keyboard shortcuts on every screen (Enter, Esc, letter shortcuts)
- All game data persisted per-profile: `profile_{profileId}_highscore_{gameId}`
