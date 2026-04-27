# Contributing to WebCraft

Thanks for taking the time to look at WebCraft. This guide covers the few
things you need to know before opening a PR.

## Local setup

```bash
git clone https://github.com/Dr-Code-EG/WebCraft.git
cd WebCraft
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

A device or emulator running Android 10+ (API 29) is required to run the
app. Build a release APK with:

```bash
flutter build apk --release
```

## Commit style

We use Conventional Commits prefixes — pick the one that fits:

- `feat:` — new user-facing feature
- `fix:` — bug fix
- `refactor:` — internal cleanup with no behavior change
- `test:` — test-only changes
- `docs:` — documentation only
- `chore:` — repo plumbing (CI, deps, scripts)

A short imperative summary in the title; multi-paragraph body for any
non-trivial change explaining *why*, not *what*.

## Required checks before opening a PR

1. `flutter analyze` — must report 0 issues.
2. `flutter test` — every test must pass.
3. If you touched `lib/l10n/*.arb`, run `flutter gen-l10n` and commit the
   generated `lib/l10n/*.dart`.
4. Follow the existing layering — see [ARCHITECTURE.md](ARCHITECTURE.md).

The `.github/workflows/ci.yml` workflow runs the same checks on every PR.

## Code style

- Idiomatic Dart, no `dynamic` or `Any` shortcuts.
- Imports at the top of every file, sorted (Dart SDK, package imports,
  relative imports).
- Prefer minimal, targeted edits over big refactors.
- New strings always go in *both* `app_en.arb` and `app_ar.arb`.
- Don't use emoji in source code or comments.

## Testing

- New behaviour belongs in a test file under `test/` mirroring the source
  layout.
- Tests should be small and deterministic. Avoid sleeping, network calls
  or filesystem writes outside `getTemporaryDirectory()`.
- Block-codegen tests live in `test/codegen_test.dart`. Add a case for
  every new block spec — `input → expected JS`.
