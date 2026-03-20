# Attierly

Attierly is an iOS app that uses AI-powered vision to identify and analyze clothing items from photos. Take a picture or choose one from your library, and the app will detect each clothing item and provide detailed attributes including type, color, fabric, pattern, formality, season suitability, and more — powered by the Anthropic Claude API.

## Setup

1. Open the project in Xcode 15+ (or Xcode 26+)
2. In `Attierly/Resources/`, duplicate `Config.plist.example` and rename the copy to `Config.plist`
3. Open `Config.plist` and replace `your-api-key-here` with your [Anthropic API key](https://console.anthropic.com/)
4. Build and run on an iOS 17+ device or simulator

> **Note:** `Config.plist` is git-ignored to keep your API key out of version control.

## Camera

The camera feature requires a **physical iOS device**. On the simulator, only the photo library picker is available (the camera button will be hidden automatically).

If running on a device, the app will request camera permission on first use.

## Architecture

- **MVVM** — Models, ViewModels, Views, and Services are cleanly separated
- **No third-party dependencies** — uses only Apple frameworks and URLSession
- **SwiftUI** with `@Observable` for state management

## Project Structure

```
Attierly/
├── App/AttierlyApp.swift          # App entry point
├── Models/ClothingItem.swift      # Clothing item data model
├── Services/
│   ├── AnthropicService.swift     # Claude API integration
│   └── ConfigManager.swift        # API key configuration
├── ViewModels/ScanViewModel.swift # Scan state management
├── Views/
│   ├── HomeView.swift             # Main screen
│   ├── ResultsView.swift          # Scan results display
│   ├── ClothingItemCard.swift     # Individual item card
│   └── ImagePicker.swift          # Camera wrapper
├── Helpers/ColorMapping.swift     # Color name → SwiftUI Color
└── Resources/
    ├── Config.plist.example       # API key template
    └── Assets.xcassets            # App assets
```
