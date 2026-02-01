# Audioplayers Local Path Setup

This guide explains how to migrate a Flutter project from using the `audioplayers` Git dependency to a local path dependency. This avoids the "File name too long" error on macOS caused by deeply nested paths in the pub-cache.

## Problem

When using a Git-based dependency for `audioplayers`:

```yaml
audioplayers:
  git:
    url: https://github.com/novas1r1/audioplayers.git
    ref: main
    path: packages/audioplayers
```

macOS may fail with:

```
error: unable to create file packages/audioplayers_android_exo/android/src/main/kotlin/xyz/luan/audioplayers/AudioContextAndroid.kt: File name too long
```

## Solution: Local Path Dependency

### Step 1: Clone the Fork

Clone your audioplayers fork to a location **outside** your Flutter project:

```bash
# Navigate to your development directory (parent of your Flutter projects)
cd ~/development/looplab

# Clone the audioplayers fork
git clone https://github.com/novas1r1/audioplayers.git ap
```

**Recommended directory structure:**

```
~/development/looplab/
├── ap/                      # audioplayers fork
│   └── packages/
│       ├── audioplayers/
│       └── audioplayers_android_exo/
├── repeatlab_app/           # Your Flutter project
└── other_project/           # Another project using audioplayers
```

### Step 2: Update pubspec.yaml

Replace the Git dependencies with local path references:

**Before (Git-based):**

```yaml
audioplayers:
  git:
    url: https://github.com/novas1r1/audioplayers.git
    ref: main
    path: packages/audioplayers

audioplayers_android_exo:
  git:
    url: https://github.com/novas1r1/audioplayers.git
    ref: main
    path: packages/audioplayers_android_exo
```

**After (Local path):**

```yaml
audioplayers:
  path: ../ap/packages/audioplayers

audioplayers_android_exo:
  path: ../ap/packages/audioplayers_android_exo
```

Adjust the relative path (`../ap/`) based on your project's location relative to the cloned repo.

### Step 3: Run pub get

```bash
fvm flutter pub get
```

## CI/CD Configuration

For CI/CD pipelines that need to use the Git dependency, add this step **before** `flutter pub get`:

```yaml
# GitHub Actions example
- name: Configure Git for long paths
  run: git config --global core.longpaths true
```

### Codemagic Configuration

For Codemagic, you have two options:

#### Option 1: Configure Git for Long Paths (Recommended)

Add a pre-build script in your `codemagic.yaml` to configure Git before dependencies are fetched:

```yaml
workflows:
  your-workflow:
    name: Your Workflow
    scripts:
      - name: Configure Git for long paths
        script: |
          git config --global core.longpaths true
      - name: Get Flutter packages
        script: |
          flutter pub get
      # ... rest of your build scripts
```

#### Option 2: Clone the Fork in CI

Clone the audioplayers fork alongside your project during the build:

```yaml
workflows:
  your-workflow:
    name: Your Workflow
    scripts:
      - name: Configure Git for long paths
        script: |
          git config --global core.longpaths true
      - name: Clone audioplayers fork
        script: |
          cd $CM_BUILD_DIR/..
          git clone https://github.com/novas1r1/audioplayers.git ap
      - name: Get Flutter packages
        script: |
          flutter pub get
      # ... rest of your build scripts
```

This approach lets you use local path dependencies in `pubspec.yaml` even in CI. The directory structure in Codemagic will be:

```
$CM_BUILD_DIR/../
├── ap/                      # Cloned audioplayers fork
│   └── packages/
│       ├── audioplayers/
│       └── audioplayers_android_exo/
└── your_project/            # $CM_BUILD_DIR
```

#### Option 3: Use Codemagic UI (No YAML)

If you're using the Codemagic UI instead of `codemagic.yaml`:

1. Go to your app settings in Codemagic
2. Navigate to **Build** > **Pre-build script**
3. Add the following script:

```bash
#!/bin/bash
git config --global core.longpaths true
```

This runs before Flutter dependencies are fetched.

### Alternative: Use pubspec_overrides.yaml

Keep Git dependencies in `pubspec.yaml` for CI/CD, and use `pubspec_overrides.yaml` (gitignored) for local development:

**pubspec.yaml (committed, used by CI):**

```yaml
audioplayers:
  git:
    url: https://github.com/novas1r1/audioplayers.git
    ref: main
    path: packages/audioplayers

audioplayers_android_exo:
  git:
    url: https://github.com/novas1r1/audioplayers.git
    ref: main
    path: packages/audioplayers_android_exo
```

**pubspec_overrides.yaml (gitignored, local only):**

```yaml
dependency_overrides:
  audioplayers:
    path: ../ap/packages/audioplayers
  audioplayers_android_exo:
    path: ../ap/packages/audioplayers_android_exo
```

Add to `.gitignore`:

```
pubspec_overrides.yaml
```

## Updating the Fork

To pull updates from the upstream audioplayers repo:

```bash
cd ~/development/looplab/ap

# Add upstream remote (one-time setup)
git remote add upstream https://github.com/bluefireteam/audioplayers.git

# Fetch and merge updates
git fetch upstream
git merge upstream/main
```

## Troubleshooting

### "File name too long" error persists

Clear the pub-cache and retry:

```bash
rm -rf ~/.pub-cache/git/cache/audioplayers-*
fvm flutter pub get
```

### Path not found

Verify the relative path is correct:

```bash
# From your project directory
ls ../ap/packages/audioplayers/pubspec.yaml
```

### Multiple projects sharing the same fork

All projects can reference the same local clone. Just adjust the relative path in each project's `pubspec.yaml` accordingly.
