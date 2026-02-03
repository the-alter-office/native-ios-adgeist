# UTM Parameter Tracking for AdgeistKit iOS SDK

This document explains how to use the UTM parameter tracking feature in the AdgeistKit iOS SDK.

## Overview

The UTM tracking feature allows you to capture marketing attribution data from:

1. **First app install/launch** - Captures UTM parameters when the app is first installed
2. **Deeplinks** - Captures UTM parameters from custom URL schemes (e.g., `myapp://`)
3. **Universal Links** - Captures UTM parameters from universal links (e.g., `https://yourdomain.com/...`)

UTM parameters captured include:

- `utm_source` - Identifies which site sent the traffic (e.g., facebook, google, newsletter)
- `utm_medium` - Identifies what type of link was used (e.g., cpc, social, email)
- `utm_campaign` - Identifies a specific product promotion or strategic campaign
- `utm_term` - Identifies search keywords
- `utm_content` - Identifies what specifically was clicked to bring the user (e.g., ad_variant_a)

## Automatic Tracking

### First Install Tracking

UTM tracking for first install is **automatically initialized** when you call `AdgeistCore.initialize()`:

```swift
import AdgeistKit

// In your AppDelegate or App struct
let adgeistCore = AdgeistCore.initialize(
    customBidRequestBackendDomain: "https://your-domain.com",
    customPackageOrBundleID: "com.yourapp.bundle",
    customAdgeistAppID: "your-app-id"
)

// First install UTM parameters are automatically tracked
```

The first install tracking happens only once, on the very first launch of the app.

## Manual Deeplink Tracking

### 1. Handle Deeplinks in Your App

Add deeplink handling to your app's main struct or AppDelegate:

#### SwiftUI App

```swift
import SwiftUI
import AdgeistKit

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeeplink(url: url)
                }
        }
    }

    private func handleDeeplink(url: URL) {
        print("Deeplink received: \(url)")

        // Get AdgeistCore instance
        if let adgeistCore = try? AdgeistCore.getInstance() {
            // Track the deeplink with UTM parameters
            adgeistCore.trackDeeplink(url: url)

            // Optionally log an event
            let event = Event(
                eventType: "deeplink_opened",
                eventProperties: ["url": url.absoluteString]
            )
            adgeistCore.logEvent(event)
        }
    }
}
```

#### UIKit AppDelegate

```swift
import UIKit
import AdgeistKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        handleDeeplink(url: url)
        return true
    }

    private func handleDeeplink(url: URL) {
        if let adgeistCore = try? AdgeistCore.getInstance() {
            adgeistCore.trackDeeplink(url: url)
        }
    }
}
```

### 2. Configure URL Scheme

Add your custom URL scheme to your app's `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
    </dict>
</array>
```

Now your app can handle URLs like:

```
myapp://campaign?utm_source=facebook&utm_medium=social&utm_campaign=spring_sale
```

## Universal Links

For universal links, add handling in your AppDelegate or SceneDelegate:

```swift
func application(_ application: UIApplication,
                continue userActivity: NSUserActivity,
                restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else {
        return false
    }

    if let adgeistCore = try? AdgeistCore.getInstance() {
        adgeistCore.trackUniversalLink(url: url)
    }

    return true
}
```

## Retrieving UTM Data

### Get All UTM Data

```swift
let adgeistCore = AdgeistCore.getInstance()
let utmData = adgeistCore.getUTMData()

// Returns dictionary with structure:
// {
//     "first_install": {
//         "utm_source": "facebook",
//         "utm_medium": "social",
//         "utm_campaign": "launch_campaign",
//         "captured_at": "2024-02-03T10:30:00Z",
//         "capture_type": "install"
//     },
//     "last_deeplink": {
//         "utm_source": "google",
//         "utm_medium": "cpc",
//         "utm_campaign": "retargeting",
//         "captured_at": "2024-02-03T12:45:00Z",
//         "capture_type": "deeplink"
//     }
// }
```

### Get Current UTM Parameters

This returns the most relevant UTM parameters (prefers deeplink over install):

```swift
let adgeistCore = AdgeistCore.getInstance()
if let currentUTM = adgeistCore.getCurrentUTM() {
    print("Source: \(currentUTM.source ?? "none")")
    print("Medium: \(currentUTM.medium ?? "none")")
    print("Campaign: \(currentUTM.campaign ?? "none")")
}
```

### Access UTM Tracker Directly

```swift
let utmTracker = UTMTracker.shared

// Get first install UTM
if let firstInstall = utmTracker.getFirstInstallUTM() {
    print("First install source: \(firstInstall.source ?? "none")")
}

// Get last deeplink UTM
if let lastDeeplink = utmTracker.getLastDeeplinkUTM() {
    print("Last deeplink campaign: \(lastDeeplink.campaign ?? "none")")
}

// Get UTM history (up to 50 most recent)
let history = utmTracker.getUTMHistory()
for utm in history {
    print("Campaign: \(utm.campaign ?? "none") at \(utm.capturedAt)")
}
```

## Automatic Analytics Integration

UTM parameters are **automatically included** in all events logged through `AdgeistCore.logEvent()`:

```swift
let event = Event(
    eventType: "purchase_completed",
    eventProperties: [
        "item_id": "12345",
        "price": 29.99
    ]
)
adgeistCore.logEvent(event)

// The event will automatically include utm_data:
// {
//     "event_type": "purchase_completed",
//     "event_properties": {
//         "item_id": "12345",
//         "price": 29.99,
//         "utm_data": {
//             "first_install": { ... },
//             "last_deeplink": { ... }
//         }
//     }
// }
```

UTM data is also automatically included in the `targetingInfo` used for ad requests.

## Testing UTM Tracking

### Test Deeplinks in Simulator

```bash
# Open a deeplink in iOS Simulator
xcrun simctl openurl booted "myapp://campaign?utm_source=test&utm_medium=manual&utm_campaign=testing"
```

### Test Deeplinks on Device

1. Send yourself an email or message with the deeplink
2. Tap the link on your device
3. The app should open and capture the UTM parameters

### Clear UTM Data for Testing

```swift
// Clear all stored UTM data (useful during development)
UTMTracker.shared.clearAllUTMData()
```

## Example URL Formats

### Custom URL Scheme (Deeplink)

```
myapp://home?utm_source=facebook&utm_medium=social&utm_campaign=spring_sale&utm_content=banner_ad
```

### Universal Link

```
https://yourapp.com/promo?utm_source=google&utm_medium=cpc&utm_campaign=retargeting&utm_term=shoes
```

### Install Attribution URL (handled by install tracking)

```
https://install-attribution-provider.com/click?
  redirect=itunes.apple.com/app/yourapp&
  utm_source=newsletter&
  utm_medium=email&
  utm_campaign=launch
```

## Data Persistence

- UTM data is stored in `UserDefaults` and persists across app launches
- First install UTM is captured only once and never changes
- Deeplink UTM is updated each time a deeplink is opened
- History of up to 50 UTM captures is maintained

## Privacy Considerations

UTM parameters are marketing attribution data. Ensure you:

1. Have user consent where required by regulations (GDPR, CCPA, etc.)
2. Include UTM tracking in your privacy policy
3. Respect the consent status set via `AdgeistCore.updateConsentStatus()`

## API Reference

### AdgeistCore

```swift
// Track a deeplink
func trackDeeplink(url: URL)

// Track a universal link
func trackUniversalLink(url: URL)

// Get all UTM data
func getUTMData() -> [String: Any]

// Get current (most relevant) UTM parameters
func getCurrentUTM() -> UTMParameters?
```

### UTMTracker

```swift
// Singleton instance
static let shared: UTMTracker

// Track first install (called automatically)
func trackInstallIfNeeded(url: URL?)

// Track deeplink
func trackDeeplink(url: URL)

// Track universal link
func trackUniversalLink(url: URL)

// Get first install UTM
func getFirstInstallUTM() -> UTMParameters?

// Get last deeplink UTM
func getLastDeeplinkUTM() -> UTMParameters?

// Get all UTM data
func getAllUTMParameters() -> [String: Any]

// Get current UTM
func getCurrentUTMParameters() -> UTMParameters?

// Get UTM history
func getUTMHistory() -> [UTMParameters]

// Clear all data (for testing)
func clearAllUTMData()
```

### UTMParameters

```swift
struct UTMParameters {
    let source: String?
    let medium: String?
    let campaign: String?
    let term: String?
    let content: String?
    let capturedAt: Date
    let captureType: CaptureType

    enum CaptureType {
        case install
        case deeplink
        case universal
    }

    // Parse from URL
    init?(url: URL, captureType: CaptureType = .deeplink)

    // Convert to dictionary
    func toDictionary() -> [String: Any]
}
```

## Troubleshooting

### UTM parameters not captured

1. Verify the URL contains UTM parameters: `utm_source`, `utm_medium`, etc.
2. Check that `trackDeeplink()` is being called in your URL handler
3. Verify AdgeistCore is initialized before tracking
4. Check console logs for debug output

### First install UTM not working

1. First install tracking happens only on the very first app launch
2. Uninstall and reinstall the app to test
3. Or call `UTMTracker.shared.clearAllUTMData()` during testing

### Deeplinks not opening app

1. Verify URL scheme is correctly configured in `Info.plist`
2. Check that your `onOpenURL` handler is set up
3. Test with `xcrun simctl openurl` in simulator

## Support

For issues or questions about UTM tracking, please refer to the main AdgeistKit documentation or contact support.
