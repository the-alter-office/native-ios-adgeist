[![CocoaPods](https://img.shields.io/cocoapods/v/AdgeistKit.svg)](https://cocoapods.org/pods/AdgeistKit)

---

# Adgeist Mobile Ads SDK for iOS

This guide is for publishers who want to monetize an iOS app with Adgeist.

Integrating the Adgeist Mobile Ads SDK into an app is the first step toward displaying ads and earning revenue. Once you've integrated the SDK, you can proceed to implement one or more of the supported ad formats.

## Prerequisites

- Use Xcode 16.0 or higher
- Target iOS 12.0 or higher
- **Recommended:** Create an Adgeist publisher account and whitelist your bundle ID

## Import Adgeist Mobile Ads SDK

### CocoaPods

Before you continue, review [Using CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html) for information on creating and using Podfiles.

#### Method 1: Import in your app's Podfile

1. Open your project's `Podfile` and add this line to your app's target build configuration:

```ruby
pod 'AdgeistKit'
```

2. In a terminal, run:

```bash
pod install --repo-update
```

#### Method 2: Import in your .podspec file

1. Open your project's `.podspec` and add this line to your app's target build configuration:

```ruby
s.dependency "AdgeistKit", '= {{VERSION_NUMBER}}'
```

2. In a terminal, run:

```bash
pod install --repo-update
```

## Update your Info.plist

Update your app's `Info.plist` file to add three keys:

1. **`ADGEIST_APP_ID`** - A string value of your Adgeist publisher ID found in the Adgeist UI.

### Complete snippet

```xml
<key>ADGEIST_APP_ID</key>
<string>{{APP_ID}}</string>
```

**Note:** Replace `{{APP_ID}}` with your actual Adgeist publisher ID.

## Initialize Adgeist Mobile Ads SDK

Before loading ads, call the `initialize()` method on `AdgeistCore`. Call this as early as possible in your app's lifecycle.

```swift
// Initialize the Adgeist Mobile Ads SDK
AdgeistCore.initialize()
```

## Banner and Display Ads

Banner ads are rectangular ads that occupy a portion of an app's layout. They stay on screen while users are interacting with the app, either anchored at the top or bottom of the screen or inline with content as the user scrolls.

Anchored adaptive banner ads are fixed aspect ratio ads. The aspect ratio is similar to the 320x50 industry standard.

### Create a View

Banner and display ads are displayed in `BaseAdView` objects, so the first step toward integrating ads is to include a `BaseAdView` in your view hierarchy. This is typically done programmatically.

A `BaseAdView` can also be instantiated directly. The following example creates a `BaseAdView`:

```swift
adView = AdView()
view.addSubview(adView)
```

### Set the Ad Size

Set the `AdSize` struct to an anchored type with a specified width and height:

```swift
adView.setAdDimension(AdSize(width: 360, height: 360))
```

### Set the Ad Unit ID

```swift
adView.adUnitID = ADUNIT_ID
```

Replace `ADUNIT_ID` with the ad unit ID you created in the Adgeist dashboard.

### Set the Ad Type

```swift
adView.adType = .BANNER // or .DISPLAY, .COMPANION
```

Use one of the supported `AdType` enum values:

- `.BANNER` - Small rectangular banner ads
- `.DISPLAY` - Standard display ads
- `.COMPANION` - Companion ads (requires minimum 320x320 dimensions)

### Create an Ad Request

Once the `BaseAdView` is in place and its properties such as `adUnitID`, `adType`, and `adSize` are configured, it's time to load an ad. But before that, we have to create the request builder using the builder pattern below:

```swift
let request = AdRequest.AdRequestBuilder()
    .setTestMode(isTestMode)
    .build()
```

### Always Test with Test Ads

When building and testing your apps, make sure you use test ads rather than live, production ads. Failure to do so can lead to suspension of your account.

The easiest way to load test ads is to use `isTestMode: true` when building your ad request, as shown below:

```swift
let request = AdRequest.AdRequestBuilder()
    .setTestMode(true)
    .build()
```

It's been specially configured to return test ads for every request, and you're free to use it in your own apps while coding, testing, and debugging. Just make sure you replace it with `isTestMode: false` before publishing your app.

### Load an Ad

Now it's time to load an ad. This is done by calling `loadAd:` on a `BaseAdView` object:

```swift
adView.loadAd(request)
```

### Ad Events

Through the use of `BaseAdViewDelegate`, you can listen for lifecycle events, such as when an ad is closed or the user leaves the app.

#### Register for Events

To register for banner ad events, create a class that implements the `AdListener` protocol, and set an instance of that class as the listener property of your `BaseAdView` object:

```swift
adView.setAdListener(listeners)
```

Each of the methods is marked as optional, so you only need to implement the methods you want. This example implements each method and logs a message to the console:

```swift
override func onAdClicked() {
    print(#function)
}

override func onAdClosed() {
    print(#function)
}

override func onAdFailedToLoad(_ error: String) {
    print(#function)
}

override func onAdImpression() {
    print(#function)
}

override func onAdLoaded() {
    print(#function)
}

override func onAdOpened() {
    print(#function)
}
```

## Advertiser UTM Tracker

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

## Next Steps

Once the SDK is initialized, you can proceed to implement ad formats supported by Adgeist Mobile Ads SDK.
