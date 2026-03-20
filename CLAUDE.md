# Attierly — Project Guide

## What is Attierly?
A wardrobe management iOS app. Users scan clothing via camera/photo library, the app identifies items using Claude's vision API, and builds a persistent digital wardrobe. Users can generate outfits manually or with AI assistance.

## Tech Stack
- **Language:** Swift (strict concurrency enabled)
- **UI:** SwiftUI
- **Min Target:** iOS 26.2
- **Storage:** SwiftData (planned — currently in-memory only)
- **AI:** Anthropic Claude API (vision + outfit generation)
- **Architecture:** MVVM
- **Dependencies:** None. Apple frameworks + URLSession only. Do NOT add SPM packages, CocoaPods, or any third-party dependencies without explicit approval.

## Build & Run
1. Copy `Attierly/Resources/Config.plist.example` → `Config.plist`, add Anthropic API key
2. Open in Xcode 26+, build and run (Cmd+R)
3. Camera requires physical device; simulator supports photo library only

## Project Structure
```
Attierly/
├── App/AttierlyApp.swift
├── Models/ClothingItem.swift
├── Services/
│   ├── AnthropicService.swift      # Claude API calls
│   └── ConfigManager.swift         # Reads API key from Config.plist
├── ViewModels/ScanViewModel.swift
├── Views/
│   ├── HomeView.swift
│   ├── ResultsView.swift
│   ├── ClothingItemCard.swift
│   └── ImagePicker.swift           # UIImagePickerController wrapper
├── Helpers/ColorMapping.swift      # Color name → SwiftUI Color
└── Resources/
    ├── Config.plist.example
    └── Assets.xcassets
```

## Xcode Project Conventions
- `PBXFileSystemSynchronizedRootGroup` is enabled — new source files added to `Attierly/` are auto-detected. Do NOT manually edit `.pbxproj` to add source files.
- `GENERATE_INFOPLIST_FILE = YES` — add Info.plist keys via `INFOPLIST_KEY_*` build settings, not a standalone Info.plist file.
- `Config.plist` is git-ignored (contains API key). Never commit it.

## Architecture Rules (MVVM)

### Models (`Models/`)
- Plain data types. Currently `Codable` structs, will migrate to SwiftData `@Model` classes in v0.2.
- No business logic, no API calls, no UI code.
- Models own their `CodingKeys` for JSON mapping (snake_case API ↔ camelCase Swift).

### Services (`Services/`)
- Handle all external I/O: API calls, file system, config reading.
- `AnthropicService` is the only type that talks to the network. All API logic stays here.
- Return Swift types, not raw JSON. Throw typed errors, not generic ones.
- Services should be stateless where possible. The view model owns state.

### ViewModels (`ViewModels/`)
- Owns the mutable state that views observe (`@Published` / `@Observable`).
- Calls into services, maps results to view-ready state.
- Contains presentation logic (e.g., "should the retry button be visible?") but NOT layout/styling.
- One view model can serve multiple related views (e.g., `ScanViewModel` serves both `HomeView` and `ResultsView`).

### Views (`Views/`)
- Purely declarative SwiftUI. No `URLSession`, no file I/O, no business logic.
- Read state from view models. Trigger actions by calling view model methods.
- Extract reusable components into their own files (e.g., `ClothingItemCard`).

### Helpers (`Helpers/`)
- Pure utility functions with no side effects. No state, no I/O.
- Example: `ColorMapping` translates color name strings to SwiftUI `Color` values.

## Swift & Concurrency Conventions

### Actor Isolation
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set project-wide. All types default to `@MainActor`.
- For types that must run off the main actor, explicitly annotate with `nonisolated` or a custom actor.
- Service methods performing network I/O should be `async` and are fine on `@MainActor` since URLSession.data is already non-blocking.

### Async/Await
- Use structured concurrency (`async/await`) everywhere. No completion handlers, no Combine publishers for new code.
- Call async service methods from view models inside `Task { }` blocks.
- Always handle `Task` cancellation gracefully — check `Task.isCancelled` in long operations.

### Error Handling
- Define domain-specific error enums (e.g., `AnthropicError`, `ConfigError`), not raw strings.
- Services throw errors. ViewModels catch them and map to user-facing state (error message strings, retry flags).
- Views never see raw errors — they see view model properties like `errorMessage: String?` and `canRetry: Bool`.
- Never force-unwrap (`!`) network responses or JSON parsing results. Always use `guard let` / `if let` or `try/catch`.

## API Integration Details

### Anthropic API
- Endpoint: `POST https://api.anthropic.com/v1/messages`
- Auth header: `x-api-key` read from `Config.plist` via `ConfigManager`
- Model: `claude-sonnet-4-20250514`
- API version header: `anthropic-version: 2023-06-01`
- Images sent as base64-encoded JPEG at 0.6 compression quality
- Response parsing: extract `content[0].text`, decode as JSON array of `ClothingItem`

### Prompt Location
The clothing detection prompt lives as a string constant inside `AnthropicService`. If prompts grow more complex in later versions, extract to a `Prompts/` directory with one file per prompt.

### API Key
- Read once from `Config.plist` at launch via `ConfigManager`.
- If missing or empty, surface a clear error to the user — do not crash.
- Never hardcode the key. Never log it. Never include it in error messages.

## Naming Conventions
- **Types:** PascalCase (`ClothingItem`, `ScanViewModel`, `AnthropicService`)
- **Properties/methods:** camelCase (`primaryColor`, `analyzeImage()`)
- **Files:** match the primary type they contain (`ClothingItem.swift`, `ScanViewModel.swift`)
- **Constants:** camelCase, not SCREAMING_SNAKE (`maxImageSize`, not `MAX_IMAGE_SIZE`)
- **Booleans:** prefix with `is`, `has`, `can`, `should` (`isLoading`, `hasResults`, `canRetry`)
- **JSON keys from API:** snake_case in JSON, mapped to camelCase via `CodingKeys`

## Common Anti-Patterns — Do NOT Do These
- **No force unwraps** (`!`) on optionals from external data (API responses, plist values, user input).
- **No `print()` for error logging** in production paths. Use structured error handling. `print()` is acceptable only for temporary debugging.
- **No god view models.** If a view model grows beyond ~200 lines, it probably needs to be split.
- **No business logic in views.** If a view has an `if` statement that isn't purely about layout, it belongs in the view model.
- **No raw strings for state.** Use enums for finite states (e.g., `enum ScanState { case idle, loading, success([ClothingItem]), error(String) }`).
- **No nested closures for async work.** Use `async/await`.
- **No editing `.pbxproj` by hand.** File sync handles source files. Build settings go through Xcode's UI or `xcconfig` files.

## Current State (v0.1) ✅
- Camera and photo library input
- Claude vision API integration for clothing detection
- Results displayed as cards with all attributes
- In-memory session history on home screen
- Error handling (missing key, network, API, empty results)
- **No persistence** — everything is lost on app restart

## Roadmap

### v0.2 — Persistence & Wardrobe (next)
- Migrate `ClothingItem` from `Codable` struct → SwiftData `@Model` class
  - Keep `Codable` conformance for API response parsing; use a factory method or init to create `@Model` instances from decoded API data
  - Add `createdAt`, `updatedAt`, `brand`, `notes`, `imagePath`, `sourceImagePath` fields
- Store images on disk (`Documents/` directory), save file paths in model
- Add `Wardrobe` view — browsable, filterable collection of all saved items
- Add feature for user to save an item, a saved item will be
added to the wardrobe
- Add `ScanSession` as a persisted model (date, source image, linked items)
- Duplicate detection: when scanning, pre-filter by category + primary color, then use Claude to confirm if an item already exists in the wardrobe
- User-editable fields: brand, material override, personal notes

### v0.3 — Outfit Generation
- `Outfit` model: ordered collection of `ClothingItem`s
- Manual outfit creation: user picks items from wardrobe
- AI outfit generation: send wardrobe items to Claude, get outfit suggestions based on occasion/weather/style
- Outfit history and favorites

### v0.4 — Image Extraction
- Crop/extract individual items from group photos
- Per-item image stored separately from source scan image
- Potentially use Vision framework for object detection bounding boxes before sending to Claude

### Future Ideas
- iCloud sync via SwiftData + CloudKit
- Outfit calendar (what you wore when)
- Style analytics (most worn items, color distribution, etc.)
- Share outfits
- Seasonal wardrobe rotation suggestions
- Weather API integration for context-aware outfit suggestions

## Data Model Design (planned for v0.2+)

```
ClothingItem (SwiftData @Model)
├── id: UUID
├── type, category, primaryColor, secondaryColor, pattern
├── fabricEstimate, weight, formality, season, fit, statementLevel
├── description: String           # AI-generated one-sentence summary
├── brand: String?                # user-editable
├── notes: String?                # user-editable
├── imagePath: String?            # path to cropped item image on disk
├── sourceImagePath: String?      # path to original scan image
├── createdAt: Date
├── updatedAt: Date
└── outfits: [Outfit]             # inverse relationship

Outfit (SwiftData @Model)
├── id: UUID
├── name: String?
├── occasion: String?
├── items: [ClothingItem]
├── isAIGenerated: Bool
├── createdAt: Date
└── isFavorite: Bool

ScanSession (SwiftData @Model)
├── id: UUID
├── imagePath: String             # original photo
├── date: Date
└── items: [ClothingItem]         # items detected in this scan
```

## Duplicate Detection Strategy
When new items are scanned, compare against existing wardrobe:
1. Pre-filter existing items by `category` + `primaryColor` to find candidates (cheap, local)
2. If candidates exist, send the new item image + candidate descriptions to Claude
3. Claude classifies each pair: "same item" (skip), "similar but different" (add with note), "no match" (add)
4. Present results to user for final confirmation — never auto-skip without user approval