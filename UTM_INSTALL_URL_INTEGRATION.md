# UTM Install URL Integration Guide

This guide explains how to capture install URLs for UTM tracking in your iOS app using AdgeistKit.

## Overview

iOS doesn't have a direct Install Referrer API like Android. To capture UTM parameters on first launch, your app must be opened via a Universal Link or Custom URL Scheme that contains UTM parameters.

## Integration Methods

### 1. AppDelegate Integration (UIKit)

Add the following to your `AppDelegate.swift`:

```swift
import UIKit
import AdgeistKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Initialize AdgeistCore first
        AdgeistCore.initialize(publisherId: "your-publisher-id")

        // Check if app was opened via URL on first launch
        if let url = launchOptions?[.url] as? URL {
            // This captures install attribution with UTM parameters
            UTMTracker.shared.initializeInstallReferrer(url: url)
        } else {
            // No URL provided (organic install)
            UTMTracker.shared.initializeInstallReferrer()
        }

        return true
    }

    // Handle URLs when app is already running (deeplinks)
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        UTMTracker.shared.trackFromDeeplink(url: url)
        return true
    }

    // Handle Universal Links
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        UTMTracker.shared.trackFromDeeplink(url: url)
        return true
    }
}
```

### 2. SceneDelegate Integration (UIKit with Scenes)

Add the following to your `SceneDelegate.swift`:

```swift
import UIKit
import AdgeistKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let _ = (scene as? UIWindowScene) else { return }

        // Initialize AdgeistCore
        AdgeistCore.initialize(publisherId: "your-publisher-id")

        // Check for URL context on first launch
        if let urlContext = connectionOptions.urlContexts.first {
            UTMTracker.shared.initializeInstallReferrer(url: urlContext.url)
        } else {
            UTMTracker.shared.initializeInstallReferrer()
        }

        // Handle Universal Links
        if let userActivity = connectionOptions.userActivities.first,
           userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            UTMTracker.shared.initializeInstallReferrer(url: url)
        }
    }

    // Handle URLs when app is already running
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            UTMTracker.shared.trackFromDeeplink(url: url)
        }
    }

    // Handle Universal Links when app is running
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return
        }

        UTMTracker.shared.trackFromDeeplink(url: url)
    }
}
```

### 3. SwiftUI App Integration (iOS 14+)

For SwiftUI apps, use `@UIApplicationDelegateAdaptor` or handle URLs directly:

```swift
import SwiftUI
import AdgeistKit

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle deeplinks when app is running
                    UTMTracker.shared.trackFromDeeplink(url: url)
                }
        }
    }
}

// AppDelegate for first launch handling
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Initialize AdgeistCore
        AdgeistCore.initialize(publisherId: "your-publisher-id")

        // Check for URL on first launch
        if let url = launchOptions?[.url] as? URL {
            UTMTracker.shared.initializeInstallReferrer(url: url)
        } else {
            UTMTracker.shared.initializeInstallReferrer()
        }

        return true
    }
}
```

## URL Scheme Configuration

### Step 1: Add Custom URL Scheme

Add this to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourappscheme</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
    </dict>
</array>
```

**Example URLs:**

- `yourappscheme://open?utm_source=facebook&utm_campaign=spring2024&utm_data=promo`
- `yourappscheme://install?utm_source=google&utm_campaign=winter2024`

### Step 2: Configure Universal Links (Recommended)

Universal Links provide a better user experience and are required for App Store attribution.

#### In Xcode:

1. Select your target → **Signing & Capabilities**
2. Add **Associated Domains** capability
3. Add domain: `applinks:yourdomain.com`

#### On Your Server:

Host an `apple-app-site-association` file at:

- `https://yourdomain.com/.well-known/apple-app-site-association`
- `https://yourdomain.com/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.yourcompany.yourapp",
        "paths": ["*"]
      }
    ]
  }
}
```

Replace `TEAMID` with your Apple Team ID and update the bundle identifier.

**Example URLs:**

- `https://yourdomain.com/install?utm_source=twitter&utm_campaign=launch`
- `https://yourdomain.com/promo?utm_source=email&utm_campaign=newsletter`

## Marketing Campaign Setup

### Install Attribution Flow

1. **User clicks marketing link** containing UTM parameters
2. **User installs app** from App Store
3. **User opens app** for the first time
4. **App receives URL** (if user clicked link within 24 hours)
5. **UTM parameters captured** and sent to backend

### URL Format

```
https://yourdomain.com/install?utm_source=SOURCE&utm_campaign=CAMPAIGN&utm_data=DATA
```

**Parameters:**

- `utm_source`: Traffic source (e.g., facebook, google, twitter)
- `utm_campaign`: Campaign name (e.g., spring2024, flash-sale)
- `utm_data`: Additional custom data (optional)

### Example Marketing URLs

```
https://yourdomain.com/install?utm_source=facebook&utm_campaign=spring2024
https://yourdomain.com/install?utm_source=google&utm_campaign=app-launch
https://yourdomain.com/install?utm_source=email&utm_campaign=newsletter&utm_data=subscriber123
yourappscheme://install?utm_source=twitter&utm_campaign=promotion
```

## Testing

### Test Custom URL Scheme

```bash
# On Simulator or Device
xcrun simctl openurl booted "yourappscheme://install?utm_source=test&utm_campaign=debug"
```

### Test Universal Links

```bash
# On Device (requires real device, not simulator)
xcrun simctl openurl booted "https://yourdomain.com/install?utm_source=test&utm_campaign=debug"
```

### Verify in Code

Add logging to see captured parameters:

```swift
// After initialization, check stored parameters
if let params = UTMTracker.shared.getUtmParameters() {
    print("Captured UTM Parameters:")
    print("Source: \(params.source ?? "none")")
    print("Campaign: \(params.campaign ?? "none")")
    print("Data: \(params.data ?? "none")")
    print("Session ID: \(params.sessionId ?? "none")")
} else {
    print("No UTM parameters captured")
}
```

## Important Notes

### iOS Limitations

1. **No Native Install Referrer API**: Unlike Android, iOS doesn't provide install referrer data directly
2. **24-Hour Window**: Universal Links typically work if the user installs and opens the app within 24 hours of clicking the link
3. **App Store Redirect**: Users must go through the App Store, which may break attribution
4. **First Launch Only**: Install attribution only works on genuine first launch

### Best Practices

1. **Use Universal Links**: Preferred over custom URL schemes for attribution
2. **Track Organic Installs**: Call `initializeInstallReferrer()` even without URL
3. **Handle Both Scenarios**: Support both install attribution and deeplinks
4. **Test Thoroughly**: Verify both UIKit and SwiftUI implementations
5. **Consider Third-Party SDKs**: For advanced attribution (Branch, AppsFlyer, Adjust)

### Third-Party Attribution Solutions

For more reliable install attribution, consider integrating:

- **Branch**: https://branch.io
- **AppsFlyer**: https://www.appsflyer.com
- **Adjust**: https://www.adjust.com
- **Firebase Dynamic Links**: https://firebase.google.com/products/dynamic-links

These services provide server-side attribution matching and work around iOS limitations.

## Troubleshooting

### URL not captured on first launch

- Ensure Universal Links are properly configured
- Verify the user clicked the link before installing
- Check that Associated Domains are correctly set up
- Test with a real device (Universal Links don't work reliably on simulator)

### Parameters not saved

- Verify `AdgeistCore.initialize()` is called first
- Check that URL contains valid UTM parameters
- Review console logs for error messages

### Deeplinks not working

- Confirm URL scheme is registered in Info.plist
- Verify delegate methods are implemented
- Test with correct URL format
