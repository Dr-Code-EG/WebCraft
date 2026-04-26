# WebCraft

تطبيق Android لبناء المواقع بصرياً عبر السحب والإفلات بأسلوب Sketchware للويب.

WebCraft is an Android app that lets you build real websites visually — drag elements onto a canvas, customize their style with focused dialogs, preview live, and export a ready-to-host website as a ZIP. Sketchware-style UX, for the web.

## ✨ Features

- 📂 **Project manager** — create, rename, delete, and reopen projects (saved locally on the device).
- 🎨 **Sketchware-style editor** — vertical element library on the right, canvas in the center, properties strip pinned to the bottom. Tap any property chip to open a focused edit dialog.
- 🧩 **17 HTML element types** — container, row, column, heading, paragraph, text, button, image, input, textarea, form, link, divider, spacer, card, list, video.
- 🌳 **Component tree** — browse and select elements hierarchically.
- 🎛️ **Property dialogs** — edit content (text, src, href, placeholder, alt, …), style (background, color, font, border, …), and layout (width, height, padding, margin, gap) one focused dialog at a time, with color swatches for color picks.
- 📱 **Live preview** in WebView with the generated HTML/CSS, page switcher.
- 📦 **Export to ZIP** — full static site (`public/index.html` + `public/assets/css/styles.css` + per-page HTML), plus a re-importable `project.webcraft.json`. Shared via the Android share sheet.
- 🌐 **Bilingual UI** — Arabic + English with RTL support, switchable from settings.
- 🌗 **Light / Dark / System theme**.
- 🤖 Min SDK: Android 10 (API 29).

## 🚧 Roadmap

- **Cloud sandbox** — optional run-button that spins up PHP+MySQL on a remote container so users can fully test their site from the device.
- **Templates marketplace + responsive design controls + plugins**.

## 🧱 Stack

- **Flutter 3.24** + **Dart 3.5** (cross-platform; primary target Android).
- **Provider** for state management.
- **WebView Flutter** for in-app preview.
- **archive** + **share_plus** for ZIP export and sharing.
- **shared_preferences** for settings, JSON files for project storage.
- **flutter_localizations** + ARB files for i18n.

## 🗂️ Project structure

```
lib/
  main.dart                       App entry + providers wiring
  l10n/
    app_en.arb / app_ar.arb       Localized strings
  models/
    project.dart                  Project root
    page_node.dart                Page within a project
    element_node.dart             Tree node + ElementType enum + defaults
  state/
    settings_provider.dart        Locale + theme persistence
    projects_provider.dart        Projects list CRUD
    editor_provider.dart          Selection, mutations, dirty tracking
  services/
    project_storage.dart          File-system JSON persistence
    export_service.dart           ZIP build + share
  codegen/
    html_generator.dart           Pure: ElementNode -> HTML
    css_generator.dart            Base stylesheet
  screens/
    projects_screen.dart          Project picker / empty state / dialogs
    editor_screen.dart            Tabs: Elements / Tree / Properties + Canvas
    preview_screen.dart           WebView + page switcher
    settings_screen.dart          Language + theme
  widgets/editor/
    element_library.dart          Draggable element palette
    canvas_view.dart              Visual canvas with drop targets
    tree_view.dart                Hierarchical element tree
    properties_panel.dart         Selected element editor
  theme/
    app_theme.dart                Light + dark Material 3 themes
```

## ▶️ Running

```bash
flutter pub get
flutter gen-l10n
flutter run        # on a connected Android device or emulator
```

## 🏗️ Build APK

```bash
flutter build apk --release
```

The output APK lands at `build/app/outputs/flutter-apk/app-release.apk`.

## 📜 License

TBD (will be added in a future PR).
