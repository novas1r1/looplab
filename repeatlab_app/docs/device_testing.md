# Running RepeatLab on a device / emulator

How to get a change in front of a real running app — by hand, or driven by an
agent — instead of only proving it in `fvm flutter test`. Host tests cover
cubits, repositories and goldens; this is the layer that catches "it compiles,
it's green, and it still looks/behaves wrong on the phone".

This is the *interactive* loop. It is **not** the automated E2E suite — that's
Patrol, specified in [`e2e_testing_concept.md`](e2e_testing_concept.md) and run
with `make e2e [DEVICE=<id>] [TARGET=<flow file>]`. Both run the same
`bootstrap()` entry, so the seams described there apply here too.

## 1. Pick a target

```bash
make devices          # fvm flutter devices
adb devices           # Android only, shows emulators + attached phones
make doctor           # fvm flutter doctor -v, when a device won't show up
```

Every make target below accepts `DEVICE=<id>` (the id printed by
`make devices`, e.g. `emulator-5554`). Omit it when only one device is
connected.

## 2. Run the app

```bash
make run                      # debug build on the only/default device
make run DEVICE=emulator-5554
```

Hot reload with `r`, hot restart with `R`, quit with `q` — as usual. Nothing
special is needed for a normal look-at-it pass.

## 3. Run it so tooling can drive it

```bash
make run-driver               # fvm flutter run -t test_driver/app.dart
```

`test_driver/app.dart` is the production app — the same `bootstrap()` call as
`main()`, the same real Sembast DB, SoLoud, media_kit and preferences — with the
Flutter Driver extension registered, so anything speaking to the VM service can
tap, scroll, enter text and read the widget tree of the running instance.

Deliberately **absent** from that entrypoint, exactly as in the E2E harness:
Sentry, Clarity, PostHog, UserOrient. Development sessions must not report
crashes, record sessions, or emit analytics.

Use `make run-driver` when an agent should interact with the app; use
`make run` when you are driving it yourself.

## 4. Look at the result

```bash
make screenshot                    # → build/screenshots/screen.png
make screenshot NAME=loop_empty    # → build/screenshots/loop_empty.png
make logs                          # adb logcat -s flutter:V
```

`make screenshot` goes through `adb shell screencap` + `adb pull` rather than
`adb exec-out … > file.png`, because PowerShell's `>` corrupts binary output.
The pulled PNG can be read directly by an agent.

## 5. The Dart MCP server

`.mcp.json` registers the Dart & Flutter MCP server (`fvm dart mcp-server`), so
an agent gets first-class tools for this loop instead of shelling out: list
devices, launch the app, hot reload / hot restart, read runtime errors and app
logs, inspect the widget tree, send Flutter Driver commands to an app started
via `make run-driver`, and stop it again.

It runs through `fvm`, so it always uses the SDK pinned in `.fvmrc` (3.44.4) —
neither `flutter` nor `dart` is on `PATH` on this machine.

Claude Code asks for approval the first time a project MCP server is used;
`claude mcp list` shows whether `dart` is connected. If it isn't, check that
`fvm dart --version` works from the project root.

## 6. What this does not cover

- **iOS.** Everything above works for an iOS simulator via `make run` /
  `make run-driver`; the `adb`-based targets (`make screenshot`, `make logs`,
  `make fontsize`) are Android-only. Use `xcrun simctl io booted screenshot`
  on macOS.
- **Automated flows.** Repeatable, asserted user journeys belong in the Patrol
  suite (`integration_test/`), not here.
- **Release behaviour.** These are debug builds: `kDebugMode` gates analytics
  (`AppAnalytics`), Clarity and PostHog, and shader/jank characteristics differ.
  Use `fvm flutter run --profile` to judge performance.
