# Attirely — Project Guide

## Documentation Rules
After completing any code changes, **always update both `CLAUDE.md` and `README.md`** to reflect the current state of the project. This includes:
- New or removed files → update **Project Structure** in both files
- New features or changed behavior → update **Current State** in CLAUDE.md and **Features** in README.md
- New or changed models → update **Data Model Design** in CLAUDE.md
- New API methods or prompt changes → update **API Integration Details** in CLAUDE.md
- Roadmap items that are now implemented → move from **Roadmap** to **Current State**

## What is Attirely?
A wardrobe management iOS app. Users scan clothing via camera/photo library, the app identifies items using Claude's vision API, and builds a persistent digital wardrobe. Users can generate outfits manually or with AI assistance.

## Tech Stack
- **Language:** Swift (strict concurrency enabled)
- **UI:** SwiftUI
- **Min Target:** iOS 26.2
- **Storage:** SwiftData
- **AI:** Anthropic Claude API (vision + outfit generation)
- **Architecture:** MVVM
- **Dependencies:** None. Apple frameworks + URLSession only. Do NOT add SPM packages, CocoaPods, or any third-party dependencies without explicit approval.

## Build & Run
1. Copy `Attirely/Resources/Config.plist.example` → `Config.plist`, add Anthropic API key
2. Open in Xcode 26+, build and run (Cmd+R)
3. Camera requires physical device; simulator supports photo library only

## Project Structure
```
Attirely/
├── App/AttirelyApp.swift
├── Models/
│   ├── ClothingItem.swift          # SwiftData @Model (persistent)
│   ├── ClothingItemDTO.swift       # Codable struct (API parsing)
│   ├── ScanSession.swift           # SwiftData @Model
│   ├── Outfit.swift                # SwiftData @Model (outfit collection + weather snapshot)
│   ├── OutfitSuggestionDTO.swift   # Codable struct (AI outfit parsing)
│   ├── WeatherData.swift           # Ephemeral structs (current + hourly weather)
│   ├── UserProfile.swift           # SwiftData @Model (user prefs, profile, style questionnaire)
│   └── StyleSummary.swift          # SwiftData @Model (template/AI style summary)
├── Services/
│   ├── AnthropicService.swift      # Claude API calls (scan, duplicates, outfits)
│   ├── ConfigManager.swift         # Reads API key from Config.plist
│   ├── ImageStorageService.swift   # Save/load images on disk
│   ├── LocationService.swift       # CoreLocation wrapper for user location
│   └── WeatherService.swift        # WeatherKit + Open-Meteo fallback
├── ViewModels/
│   ├── ScanViewModel.swift
│   ├── WardrobeViewModel.swift
│   ├── OutfitViewModel.swift       # Outfit creation, generation, favorites
│   ├── WeatherViewModel.swift      # Weather state, location, fetch coordination
│   └── ProfileViewModel.swift      # Profile state, analytics, geocoding
├── Views/
│   ├── MainTabView.swift           # TabView (Scan + Outfits + Wardrobe + Profile)
│   ├── HomeView.swift
│   ├── ResultsView.swift
│   ├── ClothingItemCard.swift
│   ├── ImagePicker.swift           # UIImagePickerController wrapper
│   ├── WardrobeView.swift          # Browsable wardrobe (grid/list)
│   ├── ItemDetailView.swift        # View/edit item details
│   ├── DuplicateWarningBanner.swift
│   ├── DuplicateReviewSheet.swift
│   ├── OutfitsView.swift           # Outfit list with favorites filter
│   ├── OutfitDetailView.swift      # Layer-ordered card stack view
│   ├── OutfitRowCard.swift         # Compact outfit card for list
│   ├── OutfitGenerationContextSheet.swift  # AI generation context picker
│   ├── ItemPickerSheet.swift       # Manual outfit item selection
│   ├── AddItemView.swift           # Manual wardrobe item entry form
│   ├── WeatherWidgetView.swift     # Compact toolbar weather indicator
│   ├── WeatherDetailSheet.swift    # Full weather modal with hourly forecast
│   ├── ProfileView.swift           # Profile tab (details, prefs, analytics)
│   └── WardrobeAnalyticsView.swift # Swift Charts wardrobe analytics
├── Helpers/
│   ├── Theme.swift                 # Brand design system: color tokens, ViewModifiers, ButtonStyles
│   ├── ColorMapping.swift          # Color name → SwiftUI Color
│   ├── ClothingItemDisplayable.swift  # Protocol for DTO + Model
│   ├── OutfitLayerOrder.swift      # Category → layer sort order
│   ├── SeasonHelper.swift          # Season detection from date/weather
│   ├── TemperatureFormatter.swift  # °C/°F formatting helper
│   └── StyleSummaryTemplate.swift  # Deterministic style summary from questionnaire
└── Resources/
    ├── Config.plist.example
    └── Assets.xcassets
```

## Xcode Project Conventions
- `PBXFileSystemSynchronizedRootGroup` is enabled — new source files added to `Attirely/` are auto-detected. Do NOT manually edit `.pbxproj` to add source files.
- `GENERATE_INFOPLIST_FILE = YES` — add Info.plist keys via `INFOPLIST_KEY_*` build settings, not a standalone Info.plist file.
- `Config.plist` is git-ignored (contains API key). Never commit it.

## Architecture Rules (MVVM)

### Models (`Models/`)
- `ClothingItem` is a SwiftData `@Model` class for persistence. `ClothingItemDTO` is a `Codable` struct for API parsing. `ScanSession`, `Outfit`, and `UserProfile` are SwiftData `@Model`s. `OutfitSuggestionDTO` is a `Codable` struct for AI outfit response parsing.
- No business logic, no API calls, no UI code.
- DTOs own their `CodingKeys` for JSON mapping (snake_case API ↔ camelCase Swift).
- `ClothingItem` uses `itemDescription` (not `description`) to avoid NSObject conflict.
- `Outfit` has a `displayName` computed property that falls back from `name` → `occasion` → formatted date.

### Services (`Services/`)
- Handle all external I/O: API calls, file system, config reading.
- `AnthropicService` handles all Claude API calls. `WeatherService` handles weather API calls (WeatherKit + Open-Meteo fallback). `LocationService` handles CoreLocation.
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
- `Theme` — brand design system with **adaptive light/dark mode** support. Color tokens (`Theme.obsidian`, `.ivory`, `.stone`, `.champagne`, `.blush`, `.border`) use `Color(UIColor { traitCollection in ... })` to auto-adapt. Champagne accent is fixed across modes. Semantic aliases (`Theme.primaryText`, `.secondaryText`, `.screenBackground`, `.cardFill`, `.cardBorder`) all adapt. ViewModifiers (`ThemeCardModifier`, `ThemePillModifier`, `ThemeTagModifier`) and ButtonStyles (`ThemePrimaryButtonStyle`, `ThemeSecondaryButtonStyle`). All views use these tokens instead of hardcoded colors.
- `ColorMapping` translates color name strings to SwiftUI `Color` values (for clothing item display, not UI theme).

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
- Response parsing: extract `content[0].text`, decode as JSON array of `ClothingItemDTO`

### Outfit Generation API
- Text-only request (no image) — sends wardrobe item attributes with UUIDs
- Returns JSON array of `OutfitSuggestionDTO` with `name`, `occasion`, `item_ids`, `reasoning`
- Prompt enforces: 3-6 items per outfit, exactly one footwear, max 3-4 colors, max 2 patterns, consistent formality
- Weather-adaptive rules: temperature-based layering/fabric guidance, precipitation awareness, UV consideration
- Optional `weatherContext` parameter appended to prompt with current conditions
- **Comfort preferences** injected as hard constraints (override style preferences when conflicting)
- **Style summary** optionally appended to prompt for aesthetic alignment
- Uses 2048 max tokens (vs 4096 for vision analysis)
- **Planned improvement**: generate 1 outfit per request (not 3), and include existing outfit item-ID sets in the prompt to prevent duplicate suggestions

### Style Analysis API
- Text-only request — sends wardrobe item attributes, outfit compositions (grouped by favorited → manual → AI-generated), and previous style summary (for incremental analysis)
- Returns structured JSON with: `overallIdentity`, `styleModes` (array of detected modes with name/description/colorPalette/formality), `temporalNotes` (observed trends/phase momentum), `gapObservations`
- **Initial analysis** prompt: full wardrobe data + outfit data, no prior summary
- **Incremental analysis** prompt: includes previous summary as stable baseline, only new items/outfits since last analysis. Prompt explicitly instructs: "The existing profile is the baseline. Only adjust conclusions where the new evidence is clearly compelling. Style identity is stable — do not overreact to a single new purchase."
- **Favorited outfits** are the highest-weight signal — separated and emphasized in the prompt above manual outfits and AI-generated outfits
- **Weather-relative behavior**: outfit weather snapshots (temperature + month) are included so the AI can detect seasonal-relative dressing patterns (e.g., "dresses warmer than temperature suggests in early spring")
- If user has edited the style summary (`isUserEdited` flag), the edited version is used as the baseline for incremental analysis, with a note in the prompt that the user has personally refined it
- Uses 2048 max tokens

### Weather API
- **Primary**: Apple WeatherKit via `WeatherKit.WeatherService.shared.weather(for:)` — requires WeatherKit entitlement
- **Fallback**: Open-Meteo free API — `GET https://api.open-meteo.com/v1/forecast` with lat/lon, no API key
- Returns `WeatherSnapshot` (ephemeral struct, not persisted) with current conditions + 12-hour forecast
- WMO weather codes mapped to SF Symbol names and condition descriptions
- Location via CoreLocation `CLLocationManager` with "when in use" permission

### Prompt Location
All prompts (clothing analysis, duplicate detection, outfit generation, style analysis) live as string constants inside `AnthropicService`. If prompts grow more complex in later versions, extract to a `Prompts/` directory with one file per prompt.

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

## Current State (v0.5a) ✅
- Camera and photo library input
- Claude vision API integration for clothing detection
- Results displayed as cards with all attributes
- SwiftData persistence for clothing items, scan sessions, outfits, and user profile
- Images stored on disk (Documents/clothing-images/, Documents/scan-images/, Documents/profile-images/)
- Wardrobe view with grid/list toggle and category filtering
- Item detail/edit view with all fields editable, AI originals shown as reference
- Save individual items or save all from scan results
- Duplicate detection: pre-filter by category+color, Claude-based comparison, user confirmation
- Tab-based navigation (Scan + Outfits + Wardrobe + Profile)
- **Outfit generation**: manual creation via item picker, AI-powered generation with occasion/season/weather context
- **Outfit display**: card-based layout with items ordered by layer (Outerwear → Full Body → Top → Bottom → Footwear → Accessory)
- **Outfit management**: favorites, deletion, AI reasoning display
- Layer ordering via `OutfitLayerOrder` helper — deterministic sort by category, designed to be reusable by v0.5 visual compositor
- **Manual item entry**: add wardrobe items manually via form with Pickers for all attributes, optional photo attachment
- **Weather-aware outfits**: real-time weather via WeatherKit (+ Open-Meteo fallback), compact toolbar indicator on Outfits and Wardrobe pages, weather detail sheet with hourly forecast, weather context passed to AI outfit generation prompt, temperature-based layering/fabric rules, season auto-populated from weather
- **Location**: CoreLocation "when in use" permission for weather data, reverse geocoding for city name display
- **Weather override**: user can toggle "Ignore weather" to use manual season/occasion only
- **Profile page**: 4th tab with user name, profile photo (via PhotosPicker), and item/outfit count summary
- **User preferences**: temperature unit (°C/°F) applied across all weather displays, theme preference (System/Light/Dark) with full dark mode support, custom location override with city geocoding
- **Dark mode**: adaptive color system in `Theme.swift` using `UIColor { traitCollection in ... }`. Warm espresso/charcoal dark palette. Champagne accent fixed across modes. `ThemeWrapper` in `AttirelyApp` applies `.preferredColorScheme()` based on user's stored `ThemePreference`
- **Wardrobe analytics dashboard**: Swift Charts — category composition (horizontal bar), formality breakdown (donut/sector chart), color distribution (swatch grid with counts). Empty state for < 3 items.
- **Temperature formatting**: centralized `TemperatureFormatter` helper, all weather views respect user's unit preference. AI prompt always uses Celsius internally.
- **Location override**: user can set a custom city; forward geocoding converts to coordinates; weather fetches use override location when enabled
- Error handling (missing key, network, API, empty results, insufficient wardrobe)
- **Brand design system**: centralized `Theme.swift` with adaptive color tokens (Obsidian, Ivory, Stone, Champagne, Blush, Border), reusable ViewModifiers (`.themeCard()`, `.themePill()`, `.themeTag()`), and ButtonStyles (`.themePrimary`, `.themeSecondary`). CHAMPAGNE set as AccentColor globally. Light mode: IVORY backgrounds, glass-tinted cards. Dark mode: warm espresso backgrounds, dark glass cards. Consistent typography across all views.
- **Style & Comfort questionnaire**: "Style & Comfort" section on Profile page with cold/heat sensitivity pickers, body temp notes, layering preference, style identity multi-select (tag grid), comfort vs appearance, and weather dressing approach. All stored as raw strings on `UserProfile` with enum bridges.
- **Template-based style summary**: `StyleSummaryTemplate` helper generates a readable style summary from questionnaire answers via deterministic string interpolation (no LLM). Auto-generated on questionnaire save, displayed below questionnaire with manual edit support. `StyleSummary` SwiftData model tracks summary state (`isUserEdited`, `isAIEnriched`).
- **Weather snapshot on outfits**: `Outfit` captures current temperature, feels-like, season, and month at creation (manual and AI-generated). Backfills weather on favorite if not captured at creation.
- **Comfort-aware outfit generation**: AI outfit generation prompt injects user's comfort preferences (cold/heat sensitivity, layering, weather dressing approach) as hard constraints above style guidance. Style summary appended as context when available.

## Roadmap

### Outfit Generation Improvements (near-term)
- Generate only **one** outfit at a time instead of up to 3 — focused single recommendation per request
- **Deduplicate** against existing outfits — before generating, pass existing outfit item-ID sets to the prompt so the AI avoids suggesting an outfit combination that already exists in the user's collection
- Requires changes to: `AnthropicService.generateOutfits()` prompt (request 1 outfit, add dedup context), `OutfitViewModel.generateOutfits()` (pass existing outfit item-IDs)

### v0.5 — Style Intelligence

#### v0.5a — Data Model & Style Questionnaire ✅ (IMPLEMENTED)
- `StyleSummary` SwiftData @Model, `UserProfile` questionnaire fields, `Outfit` weather snapshot fields
- Style & Comfort questionnaire UI on Profile page (7 fields with tag grid for style identity)
- Template-based summary generation via `StyleSummaryTemplate` helper
- Weather snapshot capture on outfit creation/favoriting
- Comfort preferences injected as hard constraints in outfit generation prompt

#### v0.5b — AI Style Analysis
- **`AnthropicService.analyzeStyle()`**: new API method for style analysis
- **Initial analysis**: triggered when wardrobe crosses a threshold (~8–10 items). Sends all wardrobe item attributes + all outfit compositions (favorited outfits emphasized as highest-weight signal, then manual outfits, then AI-generated). Questionnaire-generated summary included as "user-declared ground truth — do not contradict."
- **Incremental analysis**: triggered by debounced wardrobe changes (see trigger rules below). Sends previous summary as stable baseline + only delta (new items, new outfits since last analysis). Prompt instructs AI to treat existing summary as baseline and only adjust where new evidence is compelling.
- **Style modes**: the AI detects distinct style modes organically from the data (especially from favorited outfit clusters). Not forced to a fixed count — some users have one cohesive style, others have 3–4 modes. Each mode has its own name, description, color palette, and formality level.
- **Temporal trends / phases**: AI notes any directional shifts in recent additions or recent favorites vs. older ones. Framed as observations, not identity rewrites (e.g., "Recent additions lean toward relaxed tailoring compared to earlier casual streetwear pieces").
- **Weather-relative behavior**: outfit weather snapshots (temperature + month) included in analysis. AI detects seasonal-relative dressing patterns (e.g., "Dresses warmer than temperature suggests in early spring after winter. Acclimates fully by mid-season."). This behavioral pattern is stored in the summary and fed into outfit generation.
- **Gap observations**: AI identifies wardrobe gaps and opportunities (e.g., "Many casual tops but few smart-casual options").

#### Style Analysis Trigger Rules
Auto-trigger re-analysis when:
- **First analysis**: wardrobe crosses 8–10 items (minimum signal threshold)
- **Manual outfit creation**: strong style intent signal — but debounced (see below)
- **Outfit favorited**: strongest signal of style identity — triggers analysis consideration
- **Batch additions**: 5+ items added in a single session

Debounce strategy: track `itemCountAtLastAnalysis` and `favoritedOutfitCountAtLastAnalysis` on `StyleSummary`. Only auto-trigger when delta since last analysis crosses a threshold (3–5 new items, or 2+ new favorited outfits). Always allow manual "Re-analyze" button.

Do NOT auto-trigger on:
- Single item scans (accumulate dirty flag instead)
- Item deletion (rarely changes style profile)
- Item field edits (housekeeping, not style shift)

#### Signal Hierarchy for Style Analysis
**Tier 1 — highest signal:**
- Favorited outfits (explicit "this is me" declaration)
- Manual outfit compositions (intentional taste signal)
- Category distribution (wardrobe shape)
- Color clustering (dominant palette, not just presence)

**Tier 2 — supporting signal:**
- Formality distribution
- Pattern preferences
- Brand presence (if data exists)
- Weather-relative outfit choices (temperature + month at creation)

**Tier 3 — context, not core:**
- Seasonal coverage
- Fabric tendencies (lower confidence from photo-based estimates)
- Statement level distribution

#### Style Summary → Outfit Generation Integration
Outfit generation prompt receives three layers (in priority order):
1. **Comfort constraints** (from UserProfile questionnaire fields) — hard constraints, never overridden by style
2. **Weather appropriateness** (live weather + seasonal-relative behavioral patterns from style summary)
3. **Style alignment** (overall identity + relevant style mode from style summary)

The style summary is always included once it exists. No user toggle — it enhances generation silently.

#### User Editability
- Style summary displayed on Profile page as editable text
- If user edits the summary, `isUserEdited` flag is set
- Edited version becomes the baseline for next incremental analysis, with prompt note: "The user has personally refined this description — weight it heavily"
- Questionnaire answers remain separately editable; changing them re-templates the summary only if no AI enrichment has occurred yet (`isAIEnriched == false`). If AI-enriched, questionnaire changes trigger a new incremental analysis that merges updated answers with existing wardrobe observations.

### v0.6 — Image Extraction & Confidence
- Crop/extract individual items from group photos into per-item images stored separately from the source scan image
- Use Apple Vision framework (`VNGenerateForegroundInstanceMaskRequest`) for background removal to produce clean cutouts on transparent backgrounds
- Potentially use Vision framework for object detection bounding boxes before sending to Claude
- **Attribute confidence system:** modify the scan prompt to have Claude return a confidence level per attribute — `observed` (clearly visible in the image), `inferred` (reasonable guess based on visible cues), `assumed` (generic default, low certainty). Store as a JSON map in `attributeConfidence` field on `ClothingItem`.
- Surface confidence to the user: inferred/assumed attributes shown with a subtle indicator so the user knows what the AI is guessing vs. seeing
- Items with mostly low-confidence attributes get a badge in the wardrobe prompting the user to "add a better photo"
- **Re-scan merge workflow:** user adds a dedicated close-up or flat-lay photo of an item. System re-runs extraction on the new photo and merges: user edits are always preserved, AI-generated fields are updated with the new (presumably better) values, confidence levels are upgraded

### v0.7 — Visual Outfit Compositor
Replace the card-based outfit layout from v0.3 with a **layered visual composition** where items appear stacked as they would on a body. The goal is an almost-3D effect: a t-shirt visible through an open jacket, jeans below the shirt hem, shoes at the bottom. Items have realistic spatial relationships and overlapping, not just a flat list.

#### Two sub-problems
1. **Isolation** — every item needs to exist as a clean cutout with transparent background. Groundwork laid in v0.4 (Vision framework background removal). Items scanned from outfit photos will have partial visibility; items scanned individually will be more complete.
2. **Normalization** — items photographed from different angles, distances, and lighting must be transformed into a consistent visual system so they compose together. A shirt from a selfie, a jacket from a flat-lay, and jeans from a product page cannot simply be stacked — they need matching perspective, scale, and lighting.

#### Planned approach: generative flat-lay standardization
Use a generative AI model to transform whatever source photo the user provided into a **standardized flat-lay product image**: front-facing, studio-lit, transparent background, proportional scale. This becomes the "compositing asset" for each item.

The compositor then stacks flat-lay images in z-order using category-based anchor points:
- Tops anchor at the shoulder line
- Bottoms anchor at the waist line
- Outerwear wraps around the top layer
- Footwear sits at the bottom
- Accessories placed contextually (scarves at neck, hats above, bags to the side)

Scaling is relative to a standard body proportion so items look right together regardless of original photo zoom level.

#### Key considerations and open questions
- **Fidelity trade-off:** generated flat-lays are approximations, not exact replicas. Colors may shift slightly, logos or graphics may not reproduce accurately, fabric texture is estimated. This is acceptable for outfit visualization ("does this combination work?") but the user should understand these are AI-rendered representations, not photographs. Consider a subtle label or visual treatment that distinguishes generated composites from real photos.
- **Flat-lay photo option:** when a user adds a real flat-lay photo of an item (shot on a clean surface, full item visible), prefer that over the AI-generated version. This gives power users a path to higher fidelity without requiring it from everyone.
- **Image generation provider:** evaluate options at the time of implementation — cloud APIs (Stability AI, DALL-E, etc.), on-device diffusion models (Core ML converted), or Apple generative frameworks if available. Key criteria: transparent background support, consistency across items, latency, and cost per generation.
- **Template system:** define silhouette geometry per garment sub-type (crew neck vs. v-neck vs. henley, slim jeans vs. wide leg vs. shorts, blazer vs. puffer vs. trench) for consistent anchor points and layering. This is significant design work — scope it before committing.
- **Caching:** generated flat-lays should be stored on disk (`flatLayImagePath` on `ClothingItem`) and only regenerated if the source image changes or the user requests it.

### Future Ideas
- iCloud sync via SwiftData + CloudKit
- Outfit calendar (what you wore when)
- Style analytics (most worn items, color distribution, etc.)
- Share outfits
- Seasonal wardrobe rotation suggestions
- Virtual try-on: user photo + generated outfit overlay (significant technical leap, requires pose estimation)

## Data Model Design

```
ClothingItem (SwiftData @Model) — IMPLEMENTED
├── id: UUID
├── type, category, primaryColor, secondaryColor, pattern
├── fabricEstimate, weight, formality, season, fit, statementLevel
├── itemDescription: String       # renamed from description (NSObject conflict)
├── brand: String?                # user-editable
├── notes: String?                # user-editable
├── imagePath: String?            # path to cropped item image on disk
├── sourceImagePath: String?      # path to original scan image
├── aiOriginalValues: String?     # JSON blob of original AI-detected values
├── createdAt: Date
├── updatedAt: Date
├── scanSession: ScanSession?     # inverse relationship
└── outfits: [Outfit]             # inverse relationship

ClothingItemDTO (Codable struct) — IMPLEMENTED
├── Same fields as API response (uses "description" not "itemDescription")
├── CodingKeys for snake_case mapping
└── Used only for API response parsing, then converted to ClothingItem

ScanSession (SwiftData @Model) — IMPLEMENTED
├── id: UUID
├── imagePath: String
├── date: Date
└── items: [ClothingItem]

Outfit (SwiftData @Model) — IMPLEMENTED (weather snapshots: v0.5a)
├── id: UUID
├── name: String?
├── occasion: String?
├── reasoning: String?            # AI explanation of why the outfit works
├── isAIGenerated: Bool
├── isFavorite: Bool
├── createdAt: Date
├── items: [ClothingItem]         # @Relationship(deleteRule: .nullify)
├── displayName: String           # computed: name → occasion → formatted date
├── weatherTempAtCreation: Double? #  v0.5a — actual temp (Celsius) when outfit was created/favorited
├── weatherFeelsLikeAtCreation: Double? # v0.5a — feels-like temp at creation
├── seasonAtCreation: String?     # v0.5a — "spring"/"summer"/"fall"/"winter"
└── monthAtCreation: Int?         # v0.5a — 1-12, more granular than season for early/late distinction

OutfitSuggestionDTO (Codable struct) — IMPLEMENTED
├── name: String
├── occasion: String
├── itemIDs: [String]             # CodingKey: "item_ids"
├── reasoning: String
└── Used only for AI response parsing, then converted to Outfit

CurrentWeather (struct, ephemeral) — IMPLEMENTED
├── temperature, feelsLike: Double (Celsius)
├── conditionDescription, conditionSymbol: String
├── humidity, precipitationChance: Double (0.0–1.0)
├── windSpeed: Double (km/h)
└── uvIndex: Int

HourlyForecast (struct, Identifiable, ephemeral) — IMPLEMENTED
├── hour: Date
├── temperature: Double
├── conditionDescription, conditionSymbol: String
└── precipitationChance: Double

WeatherSnapshot (struct, ephemeral) — IMPLEMENTED
├── current: CurrentWeather
├── hourlyForecast: [HourlyForecast]
├── fetchedAt: Date
└── locationName: String?

UserProfile (SwiftData @Model) — IMPLEMENTED (questionnaire fields: v0.5a)
├── id: UUID
├── name: String
├── profileImagePath: String?     # relative path to profile photo on disk
├── temperatureUnitRaw: String    # "°C" or "°F" (TemperatureUnit enum)
├── themePreferenceRaw: String    # "System"/"Light"/"Dark" (ThemePreference enum)
├── isLocationOverrideEnabled: Bool
├── locationOverrideName: String? # display city name
├── locationOverrideLat: Double?  # geocoded latitude
├── locationOverrideLon: Double?  # geocoded longitude
├── createdAt: Date
├── updatedAt: Date
│   # v0.5a — Style Questionnaire fields (structured, user-declared)
├── coldSensitivity: String?      # "low"/"moderate"/"high"
├── heatSensitivity: String?      # "low"/"moderate"/"high"
├── bodyTempNotes: String?        # free text (e.g., "legs run hot, torso runs cold")
├── layeringPreference: String?   # "minimal"/"moderate"/"heavy"
├── selectedStyles: String?       # JSON array of style labels (e.g., ["preppy","streetwear"])
├── comfortVsAppearance: String?  # "comfort"/"balanced"/"appearance"
└── weatherDressingApproach: String? # "light"/"exact"/"overdress"

StyleSummary (SwiftData @Model) — v0.5a (NEW)
├── id: UUID
├── overallIdentity: String       # throughlines that span all style modes
├── styleModes: String?           # JSON array of mode objects [{name, description, colorPalette, formality}]
├── temporalNotes: String?        # observed trends / phase momentum
├── gapObservations: String?      # "you have lots of X but no Y"
├── weatherBehavior: String?      # seasonal-relative dressing patterns
├── lastAnalyzedAt: Date
├── itemCountAtLastAnalysis: Int
├── outfitCountAtLastAnalysis: Int
├── favoritedOutfitCountAtLastAnalysis: Int
├── analysisVersion: Int          # increments each re-analysis
├── isUserEdited: Bool            # true if user has manually tweaked the text
├── isAIEnriched: Bool            # true once AI analysis has run (vs questionnaire-only)
└── createdAt: Date
```

### Planned Model Extensions

```
ClothingItem — v0.6 additions
├── cutoutImagePath: String?      # path to background-removed cutout (transparent PNG)
└── attributeConfidence: String?  # JSON map of field name → "observed"/"inferred"/"assumed"

ClothingItem — v0.7 additions
└── flatLayImagePath: String?     # path to AI-generated or user-provided flat-lay image
```

## Style Summary Template Generation (v0.5a)

Questionnaire answers are converted to a readable style summary via deterministic string interpolation — no LLM call required. Template logic lives in a helper (e.g., `StyleSummaryTemplate.swift`). Example output:

> "Very sensitive to cold, especially upper body. Prefers heavy layering even in mild weather. Low heat sensitivity. Drawn to preppy and streetwear aesthetics. Prioritizes comfort over formality. Tends to overdress for warmth in transitional weather."

This summary is immediately useful for outfit generation even before any AI analysis enriches it.

## Duplicate Detection Strategy
When new items are scanned, compare against existing wardrobe:
1. Pre-filter existing items by `category` + `primaryColor` to find candidates (cheap, local)
2. If candidates exist, send the new item image + candidate descriptions to Claude
3. Claude classifies each pair: "same item" (skip), "similar but different" (add with note), "no match" (add)
4. Present results to user for final confirmation — never auto-skip without user approval