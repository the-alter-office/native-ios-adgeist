# UTM Tracking Implementation Summary

## Overview

Implemented comprehensive UTM parameter tracking for the AdgeistKit iOS SDK to track marketing attribution from first app install and deeplinks.

## Files Created

### 1. Core/UTMParameters.swift

- Defines `UTMParameters` struct to represent UTM data
- Properties: source, medium, campaign, term, content, capturedAt, captureType
- Can parse UTM params from URLs automatically
- Supports three capture types: install, deeplink, universal_link
- Converts to dictionary for analytics integration

### 2. Core/UTMTracker.swift

- Singleton manager class for UTM tracking
- **Features:**
  - Tracks first install UTM (one-time, persisted)
  - Tracks deeplink UTM (updates on each deeplink)
  - Tracks universal link UTM
  - Maintains history of up to 50 UTM captures
  - Persists data in UserDefaults
  - Thread-safe with NSLock
- **Key Methods:**
  - `trackInstallIfNeeded(url:)` - Auto-called on first launch
  - `trackDeeplink(url:)` - Track custom URL scheme deeplinks
  - `trackUniversalLink(url:)` - Track universal links
  - `getFirstInstallUTM()` - Get install attribution
  - `getLastDeeplinkUTM()` - Get most recent deeplink
  - `getAllUTMParameters()` - Get all UTM data
  - `getCurrentUTMParameters()` - Get most relevant UTM
  - `clearAllUTMData()` - Clear for testing

## Files Modified

### 1. AdgeistKit/AdgeistCore.swift

**Changes:**

- Added public `utmTracker: UTMTracker` property
- Initialized UTM tracker in init()
- Calls `trackInstallIfNeeded()` automatically on first launch
- Updated `logEvent()` to automatically include UTM data in all events
- **New Public Methods:**
  - `trackDeeplink(url:)` - Convenience method to track deeplinks
  - `trackUniversalLink(url:)` - Convenience method for universal links
  - `getUTMData()` - Get all UTM tracking data
  - `getCurrentUTM()` - Get current UTM parameters

### 2. AdgeistKit/core/TargetingOptions.swift

**Changes:**

- Updated `getTargetingInfo()` to include UTM parameters
- UTM data is automatically added to targeting info for ad requests

### 3. ExampleNativeIOSApp/ExampleNativeIOSAppApp.swift

**Changes:**

- Added `onOpenURL` handler to capture deeplinks
- Implemented `handleDeeplink(url:)` method
- Tracks UTM from deeplinks and logs event
- Demonstrates proper integration

### 4. ExampleNativeIOSApp/ContentView.swift

**Changes:**

- Added UTM tracking UI section
- New state variables for UTM display and testing
- **New UI Features:**
  - Display current UTM data (formatted JSON)
  - Test deeplink URL input field
  - "Refresh UTM Data" button
  - "Simulate Deeplink" button (for testing)
  - "Clear UTM Data" button (for testing)
- **New Helper Methods:**
  - `refreshUTMData()` - Fetch and display current UTM data
  - `simulateDeeplink()` - Test deeplink tracking without leaving app
  - `clearUTMData()` - Clear all UTM data for testing

## Documentation Created

### UTM_TRACKING_GUIDE.md

Comprehensive documentation including:

- Overview of UTM tracking feature
- Automatic first install tracking
- Manual deeplink setup instructions
- Universal links configuration
- Code examples for SwiftUI and UIKit
- Retrieving UTM data
- Automatic analytics integration
- Testing procedures
- Example URL formats
- API reference
- Troubleshooting guide

## Key Features

### ✅ Automatic First Install Tracking

- Captures UTM parameters on first app launch
- One-time capture, persisted permanently
- No manual integration required beyond SDK initialization

### ✅ Deeplink Tracking

- Simple one-line integration: `adgeistCore.trackDeeplink(url: url)`
- Supports custom URL schemes (e.g., `myapp://`)
- Supports universal links (e.g., `https://yourapp.com/`)
- Updates on each deeplink open

### ✅ Automatic Analytics Integration

- UTM data automatically included in all `logEvent()` calls
- UTM data automatically included in ad targeting info
- No manual parameter passing required

### ✅ Data Persistence

- All UTM data stored in UserDefaults
- Survives app restarts
- Maintains history of captures

### ✅ Thread Safety

- NSLock protection on all data access
- Safe for concurrent use

### ✅ Privacy Friendly

- Respects user consent status
- No PII collection
- Standard marketing attribution data

## Usage Example

```swift
// 1. Initialize SDK (automatic first install tracking)
let adgeistCore = AdgeistCore.initialize(
    customPackageOrBundleID: "com.example.app",
    customAdgeistAppID: "your-app-id"
)

// 2. Handle deeplinks (in App or AppDelegate)
.onOpenURL { url in
    adgeistCore.trackDeeplink(url: url)
}

// 3. UTM data is automatically included in events
let event = Event(eventType: "purchase", eventProperties: ["amount": 99.99])
adgeistCore.logEvent(event) // Includes UTM data automatically

// 4. Retrieve UTM data anytime
let utmData = adgeistCore.getUTMData()
// {
//   "first_install": { "utm_source": "facebook", ... },
//   "last_deeplink": { "utm_source": "google", ... }
// }
```

## Testing the Implementation

### In the Example App:

1. Launch the app and configure SDK
2. Check "UTM Tracking" section to see first install data
3. Enter a test deeplink URL (e.g., `myapp://test?utm_source=test&utm_campaign=demo`)
4. Tap "Simulate Deeplink" to test tracking
5. Tap "Refresh UTM Data" to see updated values
6. Use "Clear UTM Data" to reset for testing

### Command Line Testing:

```bash
# Open deeplink in simulator
xcrun simctl openurl booted "myapp://campaign?utm_source=facebook&utm_medium=social&utm_campaign=spring_sale"
```

## Next Steps

To complete the integration:

1. **Add UTM files to Xcode project:**
   - Open `AdgeistKit.xcodeproj` in Xcode
   - Right-click on `AdgeistKit/core` folder
   - Select "Add Files to AdgeistKit..."
   - Add `UTMParameters.swift` and `UTMTracker.swift`
   - Ensure "Copy items if needed" is unchecked (files are already in place)
   - Ensure target membership includes AdgeistKit framework

2. **Configure URL scheme in example app:**
   - Open `ExampleNativeIOSApp/Info.plist`
   - Add CFBundleURLTypes with your custom scheme
   - Or use Xcode: Target > Info > URL Types

3. **Build and test:**

   ```bash
   cd /Users/joynal/work/sdk/native-ios-adgeist
   xcodebuild -workspace native-ios-adgeist.xcworkspace -scheme AdgeistKit -configuration Debug
   ```

4. **Build framework:**
   ```bash
   ./build_framework.sh
   ```

## Notes

- All code is Swift and follows iOS best practices
- Thread-safe implementation
- Backward compatible (no breaking changes to existing API)
- Well-documented with inline comments
- Example integration provided in demo app
