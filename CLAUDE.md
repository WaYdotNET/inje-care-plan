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

# Run all tests (642 tests, 100% coverage on non-generated files)
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
│   ├── theme/        # Rosé Pine design system (light=Dawn, dark=default)
│   ├── utils/        # Helper functions
│   └── widgets/      # Shared UI components (ShimmerLoading, StatCard, etc.)
├── features/         # Self-contained feature modules (screen + widgets + providers)
├── models/           # Shared data models (BodyZone, RotationPattern, etc.)
└── l10n/             # ARB localization files (IT default, EN, DE, FR, ES)
```

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

When bumping the version and releasing, **always** update all of these:

1. `pubspec.yaml` — bump `version` (e.g. `4.3.1+2`)
2. `CHANGELOG.md` — move Unreleased items under the new version heading
3. `pages/index.html` — update the changelog section (both IT and EN) and the version in the footer
4. Commit, push, and verify GitHub Actions pipelines (Deploy Pages + Build APK)
