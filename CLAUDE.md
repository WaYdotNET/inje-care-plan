# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

InjeCare Plan is a Flutter app for managing subcutaneous Interferon beta-1a injection therapy. It is **offline-first** (no cloud, no analytics) with all data stored locally via Drift (SQLite). The codebase is in Italian (comments, docs, ARB strings) with English code identifiers.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Generate code (Drift database + Riverpod providers) — required after modifying tables or @riverpod annotations
dart run build_runner build --delete-conflicting-outputs

# Same, but watch & regenerate on save (preferred while editing tables/providers)
dart run build_runner watch --delete-conflicting-outputs

# Run the full test suite
flutter test

# Run a single test file
flutter test test/unit/models/body_zone_test.dart

# Run tests with coverage
flutter test --coverage

# Run the app
flutter run

# Analyze code (strict-casts, strict-inference, strict-raw-types enabled)
flutter analyze

# Build release APK
flutter build apk --release

# Build for web
flutter build web --base-href /inje-care-plan/app/
```

## Architecture

**Feature-first organization** with shared code in `core/`:

```
lib/
├── app/              # GoRouter config, app entry point
├── core/
│   ├── database/     # Drift tables, AppDatabase, migrations (generates .g.dart)
│   ├── ml/           # Rule-based recommendation algorithms (not real ML)
│   ├── services/     # Notifications, PDF/CSV export, crypto, smart reminders
│   ├── theme/        # "Pop Gradient" design system (AppTokens + AppTheme, light+dark)
│   ├── utils/        # Helper functions
│   └── widgets/      # Shared UI components (ShimmerLoading, StatCard, etc.)
├── features/         # Self-contained feature modules (screen + widgets + providers)
├── models/           # Shared data models (BodyZone, RotationPattern, etc.)
└── l10n/             # ARB localization files (IT default, EN, DE, FR, ES)
```

Other top-level dirs you may see in `git status`:
- `pages/` — static GitHub Pages landing site (HTML/CSS/JS, IT+EN); has its own changelog kept in sync via the release checklist
- `store_listing/` — Google Play Store assets (feature graphic, IT listing copy)

**Data flow pattern**: Feature Screen → Provider (Riverpod) → Repository → Database (Drift)

### Key Architectural Decisions

- **Riverpod 3.x** for state management. Uses `riverpod_generator` (@riverpod annotations) — generated files are `*.g.dart`.
- **Drift (SQLite)** for persistence. Tables defined in `core/database/tables.dart`, database in `app_database.dart`. Supports Web via WASM/IndexedDB.
- **GoRouter** for declarative routing with auth-based redirects. Routes defined in `app/router.dart` via `AppRoutes` sealed class.
- **Rule-based ML** in `core/ml/` (ZonePredictionModel, TimeOptimizer, AdherenceScorer, RotationPatternEngine) — statistical algorithms, no TensorFlow.
- **7 rotation patterns** for injection zone cycling, configurable per-user (model in `models/rotation_pattern.dart`).

### Database Tables

BodyZones, Injections, TherapyPlans, BlacklistedPoints, PointConfigs, UserProfiles, AppSettings (key-value).

## Code Style

- Strict analyzer: `strict-casts`, `strict-inference`, `strict-raw-types` all enabled
- Linter rules enforced: `prefer_const_constructors`, `require_trailing_commas`, `prefer_final_locals`, `prefer_single_quotes`, `sort_child_properties_last`, `use_super_parameters`, `avoid_print`
- `riverpod_lint` via `custom_lint`

## Localization

ARB-based with template file `lib/l10n/app_it.arb` (Italian). Generated class: `AppLocalizations` in `lib/l10n/generated/`. Config in `l10n.yaml`. Supports 5 languages: IT, EN, DE, FR, ES.

## Testing

Tests in `test/` organized as `unit/`, `widget/`, `integration/`. Uses `mocktail` for mocking, `fake_async` for time-dependent tests. Provider overrides used for isolation. Database tests use in-memory instances.

## Release Checklist

When bumping the version and releasing, **always** update **all** of these (changelog, version bump, web version, READMEs):

1. `pubspec.yaml` — bump `version` (e.g. `4.8.3+12`). **IMPORTANT**: the version code (number after `+`) must be strictly greater than any previously uploaded to Google Play Store. Current highest: **23**.
2. `CHANGELOG.md` — add a new `## <version> - <YYYY-MM-DD>` heading at the top with the changes (`### Corretto` / `### Aggiunto`).
3. `pages/index.html` (web version) — add the changelog block in **both** IT (`<h3>Versione X (..)</h3>`) and EN (`<h3>Version X (..)</h3>`) sections, **and** bump the footer version `InjeCare Plan vX` (two lines: IT + EN, currently ~398 and ~408).
4. `README.md` (and any other README) — keep in sync: it has **no** version number/changelog today (feature docs only), so usually no change is needed — but verify and update the relevant section if a feature/behavior described there changed.
5. `.github/workflows/build-apk.yml` and `pages.yml` — if Flutter SDK was upgraded, update `flutter-version` to match (currently `3.41.6`).
6. Commit, tag (`v<version>`), push with `--tags` to trigger GitHub Actions release.
7. Verify the pipelines: both **Deploy Pages** and **Build APK & App Bundle** run **only on tags** `v*` (and via manual `workflow_dispatch`). Pushing the release tag triggers both; plain pushes/merges to `main` trigger **nothing** (no web build, no APK build) to avoid wasting CI time.

### Two BodyZone types

The codebase has two distinct `BodyZone` types — be careful which one you're working with:
- **`lib/models/body_zone.dart`** — app model with `displayName` getter (prefers `customName`)
- **`lib/core/database/app_database.g.dart`** — Drift-generated DataClass, no `displayName`. Use `zone.customName?.isNotEmpty == true ? zone.customName! : zone.name` instead.
