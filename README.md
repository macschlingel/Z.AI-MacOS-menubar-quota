# Z.AI Subscription Widget

A native macOS menu bar app to monitor your Z.AI Coding Plan subscription usage.

![Screenshot](screenshots/screenshot.png)

## Features

- **Quota Display**: View 5-hour token and monthly MCP usage percentages
- **Model Usage**: Per-model token breakdown (input/output)
- **Tool Usage**: MCP tool call statistics
- **Auto-refresh**: Configurable automatic data refresh (1-30 min)
- **Manual Refresh**: On-demand data update
- **Secure Storage**: API key stored in macOS Keychain

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Z.AI API key

## Building

### Option 1: Xcode

1. Open `ZaiSubscriptionWidget.xcodeproj` in Xcode
2. Select "ZaiSubscriptionWidget" scheme
3. Build and run (⌘R)

### Option 2: Swift Package Manager

```bash
swift build -c release
```

The executable will be at `.build/release/ZaiSubscriptionWidget`

### Option 3: Generate Xcode Project

```bash
swift package generate-xcodeproj
open ZaiSubscriptionWidget.xcodeproj
```

## Setup

1. Launch the app
2. Click the menu bar icon
3. Click the gear icon to open Settings
4. Enter your Z.AI API key
5. Click Save

Get your API key from: https://z.ai/manage-apikey/apikey-list

## Menu Bar Icon

The menu bar icon should be placed at:
```
ZaiSubscriptionWidget/Assets.xcassets/MenuBarIcon.imageset/
├── MenuBarIcon@1x.png  (16x16 pixels)
└── MenuBarIcon@2x.png  (32x32 pixels)
```

For now, the app uses a placeholder. You can:
1. Create a simple Z.AI logo at 16x16 and 32x32
2. Or modify `ZaiSubscriptionWidgetApp.swift` to use a system icon:
   ```swift
   MenuBarExtra("Z.AI", systemImage: "gauge") { ... }
   ```

## API Endpoints Used

| Endpoint | Description |
|----------|-------------|
| `/api/monitor/usage/model-usage` | Model token statistics |
| `/api/monitor/usage/tool-usage` | Tool call statistics |
| `/api/monitor/usage/quota/limit` | Quota percentages |

## Project Structure

```
ZaiSubscriptionWidget/
├── ZaiSubscriptionWidgetApp.swift  # App entry point
├── Models/
│   ├── ModelUsage.swift            # Model usage data model
│   ├── ToolUsage.swift             # Tool usage data model
│   └── QuotaLimit.swift            # Quota limit data model
├── Services/
│   ├── ZaiAPIService.swift         # API client
│   └── KeychainService.swift       # Secure key storage
├── ViewModels/
│   └── UsageViewModel.swift        # Business logic
├── Views/
│   ├── MenuBarView.swift           # Menu bar UI
│   └── SettingsView.swift          # Preferences UI
└── Assets.xcassets/                # App icons and assets
```

## License

MIT License
