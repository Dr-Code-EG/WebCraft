# WebCraft architecture

This is a high-level map of the codebase so you can find your way around
quickly. Layers are ordered top-to-bottom from UI to storage; each layer
depends only on the layers below it.

```
┌──────────────────────────── Screens & Widgets ────────────────────────────┐
│  lib/screens/    visual editor, preview, projects list, settings          │
│  lib/widgets/    canvas, element library, properties panel, dialogs       │
│  lib/blocks/     block workshop UI (toolbox, snap, field dialogs)         │
└───────────────────────────────────────────────────────────────────────────┘
                                   │
┌──────────────────────────── State (Provider) ─────────────────────────────┐
│  lib/state/editor_provider.dart   selection, undo/redo, mutations         │
│  lib/state/projects_provider.dart projects list, save/load                │
└───────────────────────────────────────────────────────────────────────────┘
                                   │
┌──────────────────────────── Services ─────────────────────────────────────┐
│  lib/services/storage_service.dart    JSON files in app docs dir          │
│  lib/services/export_service.dart     ZIP build (generic / GitHub Pages)  │
│  lib/services/import_service.dart     ZIP / .webcraft / .json import      │
│  lib/services/template_library.dart   curated starter templates           │
└───────────────────────────────────────────────────────────────────────────┘
                                   │
┌──────────────────────────── Codegen ──────────────────────────────────────┐
│  lib/codegen/html_generator.dart      ElementNode → HTML                  │
│  lib/codegen/css_generator.dart       theme + base reset + custom CSS     │
│  lib/codegen/js_generator.dart        wires data-wc-id handlers           │
│  lib/codegen/blocks_js_generator.dart block tree → JavaScript             │
└───────────────────────────────────────────────────────────────────────────┘
                                   │
┌──────────────────────────── Models (pure Dart) ───────────────────────────┐
│  lib/models/project.dart       Project + themeVars + customCss + comps    │
│  lib/models/page_node.dart     PageNode (one HTML page)                   │
│  lib/models/element_node.dart  ElementNode (one HTML element)             │
│  lib/models/component_spec.dart reusable element subtree                  │
│  lib/blocks/model/*.dart        block specs, nodes, workspace, types      │
└───────────────────────────────────────────────────────────────────────────┘
```

## Data flow

1. The user drags an element from `ElementLibrary` onto the `CanvasView`.
2. `EditorProvider.addElement()` records a JSON snapshot for undo, mutates
   the active page's tree, and notifies listeners.
3. The canvas rebuilds; the properties panel rebuilds; the tree sheet
   rebuilds.
4. On save (auto, every 700 ms after a change), `StorageService` writes
   `project.json` to the app's documents directory.
5. On preview, `HtmlGenerator + CssGenerator + JsGenerator + BlocksJsGenerator`
   produce a self-contained HTML string fed into a `WebView`.
6. On export, the same generators emit the same files into an in-memory
   archive and write it to `share_plus`.

## Block model

The visual editor tracks a `BlockWorkspace` per *(element id, event name)*
pair on `Project.blockWorkspaces`. Each workspace is a list of stacks; a
stack is a chain of `BlockNode` joined via `next`. Slots and mouths are
modeled as separate child arrays so a `c-block` like `if … then …` can
nest a stack inside its mouth and an expression inside its condition slot.

The **JS generator** walks each stack and emits the corresponding handler
(e.g. `document.querySelector('[data-wc-id="…"]').addEventListener('click', …)`).
The HTML generator stamps `data-wc-id="<element id>"` on every element that
has at least one event handler so the runtime can find it.

## Theme + custom CSS

`Project.themeVars` is a `Map<String, String>` with sane defaults
(`kDefaultThemeVars`). The CSS generator emits them at the very top of
the stylesheet inside `:root { ... }`. Element styles can reference them
with `var(--name)`.

`Project.customCss` is appended *after* the base reset so the user can
override anything.

## Components

`Project.components` is a list of `ComponentSpec`s — reusable element
subtrees saved by the user. Inserting a component performs a deep
`copyWithNewIds()` clone so multiple instances don't share ids.
