# Z.AI Subscription Widget - Development Plan

## Status: ✅ IMPLEMENTED

## Overview
Native macOS menu bar app built with SwiftUI that displays your Z.AI Coding Plan subscription usage.

## Tech Stack
- **Language:** Swift 5.9
- **Framework:** SwiftUI (MenuBarExtra)
- **Minimum macOS:** 13.0 (Ventura)
- **Storage:** Keychain (API key), UserDefaults (preferences)
- **Networking:** URLSession with async/await

## Features
| Feature | Description |
|---------|-------------|
| Menu Bar Icon | Custom Z.AI logo |
| Quota Display | 5-hour token %, weekly token %, monthly MCP % |
| Auto-refresh | Configurable interval (default 5 min) |
| Manual Refresh | Button in dropdown menu |
| Settings | API key input, refresh interval |
| Model Usage | Per-model token breakdown |
| Tool Usage | MCP tool call statistics |

## Directory Structure
```
ZaiSubscriptionWidget/
├── ZaiSubscriptionWidgetApp.swift      # App entry point
├── Models/
│   ├── ModelUsage.swift                # Model usage data
│   ├── ToolUsage.swift                 # Tool usage data
│   └── QuotaLimit.swift                # Quota limits
├── Services/
│   ├── ZaiAPIService.swift             # API client
│   └── KeychainService.swift           # Secure storage
├── ViewModels/
│   └── UsageViewModel.swift            # Business logic
├── Views/
│   ├── MenuBarView.swift               # Menu bar content
│   ├── UsageStatsView.swift            # Stats display
│   └── SettingsView.swift              # Preferences
├── Assets.xcassets/
│   ├── AppIcon.appiconset/
│   └── MenuBarIcon.imageset/
├── Info.plist
└── Entitlements.entitlements
```

## Implementation Steps

### Step 1: Xcode Project Setup
- Create new macOS App project (SwiftUI, SwiftUI App lifecycle)
- Configure Info.plist: `LSUIElement = true` (hide from Dock)
- Add App Sandbox with Outgoing Network Connections
- Set deployment target to macOS 13.0

### Step 2: Data Models
- Create Codable structs matching API response shape
- `ModelUsageItem`: model name, input tokens, output tokens
- `ToolUsageItem`: tool name, call count
- `QuotaLimit`: type (TOKENS_LIMIT/TIME_LIMIT), percentage, current/total

### Step 3: Keychain Service
- Secure API key storage/retrieval
- `KeychainService.save(key:value:)`
- `KeychainService.load(key:) -> String?`

### Step 4: API Service
- Base URL: `https://api.z.ai/api/monitor/usage/`
- Async functions: `fetchModelUsage()`, `fetchToolUsage()`, `fetchQuotaLimit()`
- Time window: 24h rolling (yesterday HH:00 to today HH:59)
- Error handling with typed throws

### Step 5: ViewModel
- `@Published` properties: modelUsage, toolUsage, quotaLimit
- `@Published` states: isLoading, error, lastRefresh
- Timer-based auto-refresh
- `refresh()` async function

### Step 6: Menu Bar View
- `MenuBarExtra("Z.AI", image:)` with custom asset
- VStack with quota progress bars
- Model/Tool usage lists
- Footer: last refresh time, refresh button, settings link

### Step 7: Settings View
- `Settings` scene with `TabView`
- API Key: `SecureField` bound to Keychain
- Preferences: auto-refresh toggle, interval picker
- Save button with validation

### Step 8: Custom Icon Asset
- Create Z.AI logo as template images (16x16, 32x32)
- Add to Assets.xcassets

### Step 9: Testing & Polish
- Test API calls with real API key
- Verify auto-refresh timer
- Test Keychain persistence
- Add loading spinners and error alerts
- Accessibility: VoiceOver labels

## API Reference

| Endpoint | Method | Auth | Query Params |
|----------|--------|------|--------------|
| `/api/monitor/usage/model-usage` | GET | Bearer token | startTime, endTime |
| `/api/monitor/usage/tool-usage` | GET | Bearer token | startTime, endTime |
| `/api/monitor/usage/quota/limit` | GET | Bearer token | None |

**Base URL:** `https://api.z.ai/api/monitor/usage/`

**Time Format:** `yyyy-MM-dd HH:mm:ss` (URL encoded)

**Headers:**
```
Authorization: Bearer YOUR_API_KEY
Accept-Language: en-US,en
Content-Type: application/json
```

## Response Examples

### Model Usage Response
```json
{
  "data": [
    {
      "model": "glm-4.7",
      "inputTokens": 12345,
      "outputTokens": 6789
    }
  ]
}
```

### Quota Limit Response
```json
{
  "data": {
    "limits": [
      {
        "type": "TOKENS_LIMIT",
        "percentage": 45.5
      },
      {
        "type": "TIME_LIMIT",
        "percentage": 23.1,
        "currentValue": 1234,
        "usage": 5000
      }
    ]
  }
}
```
