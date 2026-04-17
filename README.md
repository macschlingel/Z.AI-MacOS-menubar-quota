<div align="center">
  <img src="icon.png" alt="Z.AI Subscription Widget" width="128" height="128">
  
  # Z.AI Subscription Widget
  
  A native macOS menu bar app to monitor your Z.AI Coding Plan subscription usage across multiple accounts.
</div>

---

![Screenshot](screenshots/screenshot.png)

## Features

- **Multi-Account Support**: Manage and switch between multiple Z.AI accounts easily.
- **Enhanced Menu Bar Display**: 
  - Dynamic menu bar icon showing mini progress bars for current quotas.
  - Real-time GLM-5 cost multiplier display (e.g., `1x` or `3x`) directly in the menu bar.
- **Redesigned Quota Section**:
  - Visual vertical progress bars for 5-hour, weekly, and monthly (MCP/Time) limits.
  - **Quota Reset Countdown**: View exactly when your limits will reset if they've been reached.
- **GLM-5 Usage Window**: Monitor peak and off-peak hours with the corresponding usage multiplier.
- **Auto-refresh**: Configurable automatic data refresh (1-30 min).
- **Hide Dock Icon**: Runs as a true menu bar extra without cluttering your Dock.
- **Secure Storage**: API keys are securely stored in the macOS Keychain.

## Requirements

- macOS 13.0 (Ventura) or later
- One or more Z.AI API keys

## Installation

1. Download the latest `ZaiSubscriptionWidget-*.dmg` from [Releases](https://github.com/anomalyco/zai-subscripton-info/releases)
2. Open the DMG file
3. Drag `ZaiSubscriptionWidget.app` to the `Applications` folder
4. **First launch**: Right-click the app in Applications and select "Open" → "Open" (required for unsigned apps)

> **Note**: This app is not signed with an Apple Developer certificate. On first launch, macOS may show a warning. Use the Right-click → Open method to bypass Gatekeeper.

## Building from Source

### Requirements

- Xcode 15.0 or later

### Option 1: Xcode

1. Open `ZaiSubscriptionWidget.xcodeproj` in Xcode
2. Select "ZaiSubscriptionWidget" scheme
3. Build and run (⌘R)

### Option 2: Command Line

```bash
xcodebuild -project ZaiSubscriptionWidget.xcodeproj \
  -scheme ZaiSubscriptionWidget \
  -configuration Release \
  build
```

The app will be at `build/Build/Products/Release/ZaiSubscriptionWidget.app`

## Setup

1. Launch the app
2. Click the menu bar icon
3. Click the gear icon to open Settings
4. Add one or more accounts by entering a name and your Z.AI API key
5. Switch between accounts using the picker in the menu bar dropdown

Get your API key from: https://z.ai/manage-apikey/apikey-list

## API Endpoints Used

| Endpoint | Description |
|----------|-------------|
| `/api/monitor/usage/model-usage` | Model token statistics |
| `/api/monitor/usage/tool-usage` | Tool call statistics |
| `/api/monitor/usage/quota/limit` | Quota percentages and reset times |

## Project Structure

```
ZaiSubscriptionWidget/
├── ZaiSubscriptionWidgetApp.swift  # App entry point
├── Models/
│   ├── Account.swift               # Multi-account data model
│   ├── ModelUsage.swift            # Model usage data model
│   ├── ToolUsage.swift             # Tool usage data model
│   └── QuotaLimit.swift            # Quota limit & reset time model
├── Services/
│   ├── ZaiAPIService.swift         # API client
│   └── KeychainService.swift       # Secure multi-account key storage
├── ViewModels/
│   └── UsageViewModel.swift        # Business logic & cost window management
├── Views/
│   ├── MenuBarView.swift           # Main dropdown UI
│   ├── MenuBarLabelView.swift      # Dynamic menu bar icon UI
│   └── SettingsView.swift          # Account management & preferences UI
└── Assets.xcassets/                # App icons and assets
```

## License

MIT License
