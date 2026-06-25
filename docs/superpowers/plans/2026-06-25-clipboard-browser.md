# Clipboard Browser Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Alfred-like two-pane clipboard browser with type filters, richer previews, text fragment copy, and a cleaner default popup.

**Architecture:** Extend Maccy's current SwiftUI/AppKit popup architecture instead of replacing it. `History` owns filter/search state, focused helper models classify/format preview data, and `PreviewItemView` routes to dedicated text/image/file preview views.

**Tech Stack:** Swift, SwiftUI, AppKit, SwiftData, Defaults, XCTest, Xcode build system.

---

## Files

- Modify: `Maccy/Extensions/Defaults.Keys+Names.swift`
- Modify: `Maccy/Models/HistoryItem.swift`
- Modify: `Maccy/Observables/History.swift`
- Modify: `Maccy/Observables/HistoryItemDecorator.swift`
- Modify: `Maccy/Observables/SlideoutController.swift`
- Modify: `Maccy/Views/ContentView.swift`
- Modify: `Maccy/Views/HeaderView.swift`
- Modify: `Maccy/Views/ListHeaderView.swift`
- Modify: `Maccy/Views/PreviewItemView.swift`
- Modify: `Maccy/Views/SlideoutContentView.swift`
- Modify: `Maccy/Views/ToolbarView.swift`
- Create: `Maccy/ClipboardFilter.swift`
- Create: `Maccy/FilePreviewInfo.swift`
- Create: `Maccy/PreviewTextSelection.swift`
- Create: `Maccy/Views/ClipboardFilterPickerView.swift`
- Create: `Maccy/Views/SelectableTextPreviewView.swift`
- Create: `Maccy/Views/ImagePreviewDetailView.swift`
- Create: `Maccy/Views/FilePreviewDetailView.swift`
- Create: `MaccyTests/ClipboardFilterTests.swift`
- Create: `MaccyTests/FilePreviewInfoTests.swift`
- Create: `MaccyTests/PreviewTextSelectionTests.swift`

## Baseline Verification Notes

- `xcodebuild test ...` without signing overrides fails locally because no `Mac Development` signing certificate for team `MN3X4648SC` is installed.
- `xcodebuild test ... CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO` builds and runs unit tests, but this local environment already fails `ClipboardTests.testIgnoreAllApplicationsExcept` and `ClipboardTests.testIgnoreApplication`.
- For task-level verification, run focused tests for files touched. For final verification, run a signing-disabled build plus focused new tests and document pre-existing environmental failures.

---

### Task 1: Classification And Filtering

**Files:**
- Create: `Maccy/ClipboardFilter.swift`
- Modify: `Maccy/Models/HistoryItem.swift`
- Modify: `Maccy/Observables/HistoryItemDecorator.swift`
- Modify: `Maccy/Observables/History.swift`
- Modify: `Maccy/Extensions/Defaults.Keys+Names.swift`
- Create: `MaccyTests/ClipboardFilterTests.swift`

- [ ] **Step 1: Write failing tests**

Add tests that construct text, image, file, and mixed `HistoryItem` values and assert classification plus filter matching. Include a search + image-filter case where the image has no title and still appears under Images when query is empty.

- [ ] **Step 2: Run tests and confirm failure**

Run:

```bash
xcodebuild test -project Maccy.xcodeproj -scheme Maccy -destination 'platform=macOS' -testPlan Maccy -only-testing:MaccyTests/ClipboardFilterTests CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Expected: build fails because `ClipboardFilter`, `ClipboardItemKind`, or related APIs do not exist yet.

- [ ] **Step 3: Implement classification and filter state**

Create `ClipboardItemKind` and `ClipboardFilter`, add item classification helpers, add `History.activeFilter`, and refactor `History.searchQuery` recomputation so search and type filtering are applied together.

- [ ] **Step 4: Run focused tests**

Run the same `ClipboardFilterTests` command. Expected: tests pass.

- [ ] **Step 5: Commit**

```bash
git add Maccy/ClipboardFilter.swift Maccy/Models/HistoryItem.swift Maccy/Observables/HistoryItemDecorator.swift Maccy/Observables/History.swift Maccy/Extensions/Defaults.Keys+Names.swift MaccyTests/ClipboardFilterTests.swift
git commit -m "feat: add clipboard type filters"
```

### Task 2: Header Filter UI And Default Browser Sizing

**Files:**
- Modify: `Maccy/Extensions/Defaults.Keys+Names.swift`
- Modify: `Maccy/Observables/SlideoutController.swift`
- Modify: `Maccy/Views/ContentView.swift`
- Modify: `Maccy/Views/HeaderView.swift`
- Modify: `Maccy/Views/ListHeaderView.swift`
- Create: `Maccy/Views/ClipboardFilterPickerView.swift`

- [ ] **Step 1: Write focused view/build test**

Add or extend compile-time preview-safe code through `ClipboardFilterPickerView` and ensure the app target compiles with the new view. If adding a unit test is practical, assert `ClipboardFilter.description` strings and stable IDs.

- [ ] **Step 2: Run build and confirm current failure**

Run:

```bash
xcodebuild build -project Maccy.xcodeproj -scheme Maccy -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Expected before implementation: compile fails if the view references missing APIs.

- [ ] **Step 3: Implement header controls and defaults**

Add a compact segmented picker for All/Text/Images/Files beside or below search. Set fork defaults to `showFooter = false`, `windowSize = 520x760`, `previewWidth = 520`, `previewDelay = 200`, and keep preview open by default via `keepPreviewOpen`.

- [ ] **Step 4: Run build**

Run the same signing-disabled build. Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Maccy/Extensions/Defaults.Keys+Names.swift Maccy/Observables/SlideoutController.swift Maccy/Views/ContentView.swift Maccy/Views/HeaderView.swift Maccy/Views/ListHeaderView.swift Maccy/Views/ClipboardFilterPickerView.swift
git commit -m "feat: add browser header filters"
```

### Task 3: Selectable Text Preview And Fragment Copy

**Files:**
- Create: `Maccy/PreviewTextSelection.swift`
- Create: `Maccy/Views/SelectableTextPreviewView.swift`
- Modify: `Maccy/Views/PreviewItemView.swift`
- Modify: `Maccy/Views/ToolbarView.swift`
- Modify: `Maccy/Clipboard.swift`
- Create: `MaccyTests/PreviewTextSelectionTests.swift`

- [ ] **Step 1: Write failing tests**

Test `PreviewTextSelection` enables copy-selection only when selection text is non-empty and trims no user content. If adding a pure Clipboard helper, test that copying a plain string routes through `Clipboard.copy(_:)`.

- [ ] **Step 2: Run tests and confirm failure**

Run:

```bash
xcodebuild test -project Maccy.xcodeproj -scheme Maccy -destination 'platform=macOS' -testPlan Maccy -only-testing:MaccyTests/PreviewTextSelectionTests CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Expected: missing `PreviewTextSelection`.

- [ ] **Step 3: Implement selectable text preview**

Create an `NSViewRepresentable` wrapping `NSTextView` in an `NSScrollView`. Bind selected text into `PreviewTextSelection`. Add Copy selection, Copy all, and Copy item actions in the preview/toolbar area.

- [ ] **Step 4: Run tests and build**

Run focused tests and signing-disabled app build. Expected: focused tests pass and build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Maccy/PreviewTextSelection.swift Maccy/Views/SelectableTextPreviewView.swift Maccy/Views/PreviewItemView.swift Maccy/Views/ToolbarView.swift Maccy/Clipboard.swift MaccyTests/PreviewTextSelectionTests.swift
git commit -m "feat: support copying text preview selections"
```

### Task 4: Image And File Preview Details

**Files:**
- Create: `Maccy/FilePreviewInfo.swift`
- Create: `Maccy/Views/ImagePreviewDetailView.swift`
- Create: `Maccy/Views/FilePreviewDetailView.swift`
- Modify: `Maccy/Views/PreviewItemView.swift`
- Modify: `Maccy/Observables/HistoryItemDecorator.swift`
- Create: `MaccyTests/FilePreviewInfoTests.swift`

- [ ] **Step 1: Write failing tests**

Test `FilePreviewInfo` for an existing temporary file and for a missing file. Assert name, path, existence, byte count formatting inputs, and that missing files do not crash.

- [ ] **Step 2: Run tests and confirm failure**

Run:

```bash
xcodebuild test -project Maccy.xcodeproj -scheme Maccy -destination 'platform=macOS' -testPlan Maccy -only-testing:MaccyTests/FilePreviewInfoTests CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Expected: missing `FilePreviewInfo`.

- [ ] **Step 3: Implement image/file previews**

Add image preview metadata for pixel dimensions and data size. Add file preview metadata, icon/thumbnail display, Reveal in Finder, Open file, and Copy item actions.

- [ ] **Step 4: Run tests and build**

Run focused tests and signing-disabled app build. Expected: focused tests pass and build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Maccy/FilePreviewInfo.swift Maccy/Views/ImagePreviewDetailView.swift Maccy/Views/FilePreviewDetailView.swift Maccy/Views/PreviewItemView.swift Maccy/Observables/HistoryItemDecorator.swift MaccyTests/FilePreviewInfoTests.swift
git commit -m "feat: enrich image and file previews"
```

### Task 5: Integration, Polish, And Regression Pass

**Files:**
- Inspect and update: `Maccy/Views/ContentView.swift`
- Inspect and update: `Maccy/Views/SlideoutContentView.swift`
- Inspect and update: `Maccy/Views/HistoryListView.swift`
- Inspect and update: `Maccy/Views/ListItemView.swift`
- Inspect and update: `Maccy/Views/PreviewItemView.swift`
- Inspect and update: `Maccy/en.lproj/Localizable.strings`
- Inspect and update: `Maccy/Views/en.lproj/PreviewItemView.strings`

- [ ] **Step 1: Verify behavior against spec**

Review the design acceptance criteria and inspect current code paths for each item.

- [ ] **Step 2: Run focused test suite**

Run:

```bash
xcodebuild test -project Maccy.xcodeproj -scheme Maccy -destination 'platform=macOS' -testPlan Maccy -only-testing:MaccyTests/ClipboardFilterTests -only-testing:MaccyTests/FilePreviewInfoTests -only-testing:MaccyTests/PreviewTextSelectionTests CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Expected: new focused tests pass.

- [ ] **Step 3: Run broad build**

Run:

```bash
xcodebuild build -project Maccy.xcodeproj -scheme Maccy -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Expected: build succeeds.

- [ ] **Step 4: Run broad unit tests and document baseline exceptions**

Run:

```bash
xcodebuild test -project Maccy.xcodeproj -scheme Maccy -destination 'platform=macOS' -testPlan Maccy -only-testing:MaccyTests CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Expected: either all tests pass or only the known baseline `ClipboardTests` environment failures remain. If new failures appear, fix them.

- [ ] **Step 5: Commit**

```bash
git add Maccy MaccyTests docs/superpowers
git commit -m "chore: polish clipboard browser"
```
