# Clipboard Browser Design

## Goal

Build a more Alfred-like clipboard browser for Maccy: a larger two-pane popup with a scannable history list on the left, persistent rich preview on the right, type filters for text/images/files, and direct actions for copying a selected text fragment or inspecting visual/file content.

## Product Decisions

- The new experience is the default popup experience in this fork. It should feel like a compact productivity tool, not a settings-heavy menu.
- The popup opens wider by default and keeps preview visible when a history item is selected or hovered.
- The footer commands remain available by keyboard shortcuts and settings, but the visible footer defaults to hidden so the popup is cleaner.
- The core Maccy behavior remains intact: selecting a list item copies or pastes the whole clipboard item according to the existing `pasteByDefault` and modifier behavior.
- Rich preview actions are additive. They should not steal the normal list selection flow.

## User Experience

### Layout

The popup is a two-pane browser:

- Header: title/search field plus a segmented type filter.
- Left pane: history list, including pins and paste stack behavior from existing Maccy.
- Right pane: preview of the selected or hovered item, with actions relevant to the item type.
- Footer: hidden by default. Existing commands still work through shortcuts and preferences.

The default size changes from a narrow menu to a browser-sized panel:

- Content/list width: 520 points.
- Preview width: 520 points.
- Window height: 760 points.

The panel remains resizable and continues to save user width/height preferences through the existing `windowSize` and `previewWidth` defaults.

### Type Filters

The popup adds type filtering in the header:

- All: show every history item.
- Text: show items with string, RTF, or HTML content.
- Images: show image items, including PNG, TIFF, JPEG, HEIC, and universal clipboard image records.
- Files: show file URL items.

Search and type filters combine: search is applied first through existing search modes, then type filtering narrows the visible result set. An empty result should leave no item selected and show a lightweight empty state in the preview.

Images can therefore be filtered even when their OCR title is empty. Existing OCR text recognition remains useful for searching image text.

### Text Preview And Fragment Copy

Text-like items show a selectable, scrollable text preview on the right. Users can select any substring inside the preview and copy it without copying the whole history item.

Actions:

- Copy selection: enabled only when preview text has an active selection.
- Copy all: copies the preview text as plain text.
- Copy item: copies the original clipboard item with all retained pasteboard types.

Implementation choice: use an AppKit-backed `NSTextView` wrapper for selection support. SwiftUI `Text` is not sufficient for selecting arbitrary fragments.

### Image Preview

Image items show a larger fit-to-pane preview. Actions:

- Copy item: copy original image pasteboard data.
- Open image preview: show a transient Quick Look style floating preview if practical; otherwise use a larger in-pane preview with fit-to-pane behavior.
- Metadata: display pixel dimensions and data size when available.

### File Preview

File URL items show a compact file summary:

- File name.
- Path.
- Size, if the file exists and size can be read.
- Kind from `NSWorkspace`.
- Modified date, if available.
- Quick Look thumbnail/icon where available.

Actions:

- Copy item: copy original file URL pasteboard item.
- Reveal in Finder: opens Finder at the selected file.
- Open file: asks macOS to open the file with its default application.

Missing or inaccessible files should show a clear unavailable state rather than failing silently.

### Footer Simplification

Visible footer defaults to hidden in this fork. Existing actions remain:

- Clear: Command-Option-Delete.
- Clear all: Command-Option-Shift-Delete.
- Preferences: Command-Comma.
- About and Quit remain in the app menu/status item behavior where applicable.

The Appearance setting for showing the footer stays available for users who want the original menu command list.

## Architecture

### Models And Filtering

Add a small `ClipboardItemKind` enum that classifies a `HistoryItem` or `HistoryItemDecorator` as `.text`, `.image`, `.file`, or `.mixed`.

Add `ClipboardFilter` for the selected filter state. It should be independent from storage settings: storage controls what Maccy saves; filter controls what the popup displays.

`History` owns the active filter because it already owns `searchQuery`, `all`, and `items`. When either `searchQuery` or `activeFilter` changes, `History` recomputes visible `items`.

### Preview Data

Add focused preview helper types rather than bloating views:

- `TextSelectionStore`: observable state for selected preview text.
- `FilePreviewInfo`: value type that derives readable metadata from file URLs.
- Image metadata helpers on `HistoryItemDecorator` or a focused helper.

### Views

Update existing SwiftUI views instead of replacing the app shell:

- `ContentView`: keep `SlideoutView` but configure preview as open by default.
- `HeaderView` / `ListHeaderView`: include type filter controls beside search.
- `HistoryListView`: continues to render pins, paste stack, and items.
- `PreviewItemView`: becomes a router for text/image/file preview subviews.
- New views:
  - `ClipboardFilterPickerView`
  - `SelectableTextPreviewView`
  - `ImagePreviewDetailView`
  - `FilePreviewDetailView`
  - `PreviewActionBar`

### Defaults

Change default values in `Defaults.Keys+Names.swift`:

- `showFooter`: `false`
- `windowSize`: `NSSize(width: 520, height: 760)`
- `previewWidth`: `520`
- `previewDelay`: `200`

Add:

- `activeClipboardFilter`: default `.all`
- `keepPreviewOpen`: default `true`

`keepPreviewOpen` allows future escape hatches and makes the behavior explicit.

### Testing

Unit tests should cover:

- Type classification for text, image, file, and mixed items.
- Filter behavior combined with search.
- File metadata formatting for existing and missing files.
- Text selection state behavior where possible without UI automation.

Build/test command:

```bash
xcodebuild test -project Maccy.xcodeproj -scheme Maccy -destination 'platform=macOS' -testPlan Maccy -only-testing:MaccyTests CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Current local baseline:

- Normal test command fails before build because the official team signing certificate `MN3X4648SC` is not installed.
- With signing disabled, unit tests compile and run, but local baseline has existing failures in `ClipboardTests.testIgnoreAllApplicationsExcept` and `ClipboardTests.testIgnoreApplication`, caused by frontmost application / asynchronous pasteboard hook behavior in this environment.
- New work should verify affected tests directly and run broad build/test where feasible.

## Out Of Scope

- Rewriting Maccy as a different app architecture.
- Replacing SwiftData storage.
- Full Quick Look document viewer for every file format.
- Editing clipboard history contents in place.
- Syncing filters or preview state across devices.

## Acceptance Criteria

- Popup opens as a larger two-pane browser by default.
- Hovering or keyboard-navigating history items updates the right preview.
- Users can filter history by All/Text/Images/Files.
- Images are visible through the Images filter even if OCR did not produce a title.
- Text preview supports selecting and copying a substring.
- File preview displays useful metadata and supports reveal/open actions.
- Default visible footer commands are removed from the popup, while shortcut actions still work.
- Existing copy/paste/select behavior remains compatible.
- New and affected unit tests pass under signing-disabled local commands, with any pre-existing environmental failures documented.
