# Repository Guidelines

## Project Structure & Module Organization
- `lib/main.dart` bootstraps the Flutter app and registers shared services.
- Feature code lives under `lib/features/<feature>/`, keeping screens, blocs, and widgets together.
- Shared utilities reside in `lib/core` (configuration, UI primitives, helpers) and `lib/data` (repositories, DTOs).
- `assets/` holds translations and icons; generated localization keys land in `lib/l10n`.
- Tests mirror source placement inside `test/`, with UI goldens under `test/goldens` and common mocks in `test/helpers`.

## Build, Test, and Development Commands
- `fvm flutter pub get` installs dependencies with the locked Flutter version.
- `fvm flutter run` launches the app locally.
- `fvm flutter test` runs all Dart and widget tests; append `--coverage` to refresh coverage metrics.
- `make generate` invokes `build_runner` for code generation; use `make watch` while iterating.

## Checking a change on a device / emulator
- `make devices` lists targets; `make run` (or `make run DEVICE=<id>`) starts a debug build.
- `make run-driver` starts the same app via `test_driver/app.dart` with the Flutter Driver extension enabled, so tooling can tap, scroll, type, and read the widget tree of the running instance. That entrypoint shares `bootstrap()` with `main()` but omits Sentry / Clarity / PostHog / UserOrient — development sessions must not report crashes or emit analytics.
- `make screenshot [NAME=<name>]` writes `build/screenshots/<name>.png`; `make logs` tails the Flutter log.
- `.mcp.json` registers the Dart & Flutter MCP server (`fvm dart mcp-server`) for device listing, launch, hot reload, runtime errors, widget inspection, and driver commands.
- Full walkthrough: [docs/device_testing.md](docs/device_testing.md). Automated flows belong in the Patrol suite instead — see [docs/e2e_testing_concept.md](docs/e2e_testing_concept.md).

## Coding Style & Naming Conventions
- The analyzer extends `package:lint/strict.yaml`; resolve warnings before submitting.
- Prefer single quotes, preserve trailing commas on multi-line expressions, and use 2-space indentation.
- Name files in `snake_case.dart`; classes use `PascalCase`, private members use leading underscores.
- Keep widget build methods compact; extract reusable UI into `lib/core/ui` or shared helpers when patterns repeat.

## Testing Guidelines
- Create a matching `*_test.dart` for every new class; group tests by behavior rather than method names.
- Use golden tests sparingly and tag them with `@Tags(['golden'])` to opt in to the golden pipeline.
- Mock network and persistence layers via utilities in `test/helpers` instead of embedding ad hoc mocks.
- Run `fvm flutter test` before every PR and ensure new features include widget coverage for primary flows.

## Packages
- Try to stick to the existing packages and dependencies.

## Flutter
- Use flutter_bloc for state management. Prefer cubits over blocs.
- Use dart_mappable for data modeling.

## Commit & Pull Request Guidelines
- Write concise, imperative commit subjects (e.g., `add pitch control`) and avoid generic messages like "update".
- Squash work-in-progress commits before review; keep the branch history readable.
- Every pull request should describe the change, reference relevant issues, list manual test steps, and attach screenshots for UI tweaks.
- Confirm CI success and lint cleanliness in the PR checklist; mention any deferred TODOs explicitly.

## Features
For a complete list of features, see the [FEATURES.md](FEATURES.md) file.

## Audio Features Analysis & Code Quality
- **Primary Audio Service**: `RepeatlabAudioplayersServiceHandler` in `lib/data/services/repeatlab_audioplayers_service_handler.dart`
- **Secondary Service**: `AudioplayerService` in `lib/data/services/audioplayers_service.dart`
- **Known Issues**: When the song is completed, it cant be played again, seeking via touch often ends up in timeoutexceptions
- **Performance Focus**: Loop wrapping is native on Android (`AudioPlayer.setLoopRegion` → PlayerMessage inside the ExoPlayer fork, wraps reported via `onLoopWrap`); other platforms fall back to predictive Dart scheduling plus a 200 ms poll (watchdog-only while native is active). Seek operations and stream subscriptions remain hot paths.
- **Code Quality**: Multiple audio service implementations exist - some commented out, need consolidation
- **Performance Monitoring**: Memory leaks in stream subscriptions, timer cleanup, audio session management
