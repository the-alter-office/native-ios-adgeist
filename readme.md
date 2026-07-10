[![CocoaPods](https://img.shields.io/cocoapods/v/AdgeistKit.svg)](https://cocoapods.org/pods/AdgeistKit)

---

# Adgeist Mobile Ads SDK for iOS

This guide is for publishers who want to monetize an iOS app with Adgeist.

Integrating the Adgeist Mobile Ads SDK into an app is the first step toward displaying ads and earning revenue. Once you've integrated the SDK, you can proceed to implement one or more of the supported ad formats.

## Prerequisites

- Use Xcode 16.0 or higher
- Target iOS 12.0 or higher
- **Recommended:** Create an Adgeist publisher account and whitelist your bundle ID

## Configure your app

### STEP 1: Add the dependency

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

_Replace `{{VERSION_NUMBER}}` with the latest version from [CocoaPods](https://cocoapods.org/pods/AdgeistKit)._

2. In a terminal, run:

```bash
pod install --repo-update
```

### STEP 2: Initialize the Adgeist Mobile Ads SDK

Before loading ads, initialize the Adgeist Mobile Ads SDK by calling `AdgeistCore.initialize()`. Call this as early as possible in your app's lifecycle, e.g. in `AppDelegate` or your root `View`:

```swift
import AdgeistKit

// Initialize the Adgeist Mobile Ads SDK
let adgeistCore = AdgeistCore.initialize()
```

You're now ready to implement ads in your app!

## Implement Ad Formats

Once the SDK is integrated and initialized, you can implement one or more of the supported ad formats below.

### Banner and Display Ads

Banner ads are rectangular ads that occupy a portion of an app's layout. They stay on screen while users are interacting with the app, either anchored at the top or bottom of the screen or inline with content as the user scrolls.

Anchored adaptive banner ads are fixed aspect ratio ads. The aspect ratio is similar to the 320x50 industry standard.

#### Define the Ad View

Banner and display ads are displayed in `AdView` objects, so the first step toward integrating ads is to include an `AdView` in your view hierarchy. Create an `AdView` and add it to your view hierarchy programmatically:

```swift
let adView = AdView()
view.addSubview(adView)
```

#### Set the Ad Size

For a fixed-size ad, set the `AdSize` struct to an anchored type with a specified width and height:

```swift
adView.setAdDimension(AdSize(width: 360, height: 360))
```

For a **responsive ad** that sizes itself to fit its parent view, skip `setAdDimension()` entirely and set `adIsResponsive` instead:

```swift
adView.adIsResponsive = true
```

#### Set Required Properties

Configure the following properties on your `AdView`:

**Ad Unit ID:**

```swift
adView.adUnitId = "YOUR_AD_UNIT_ID"
```

Replace `YOUR_AD_UNIT_ID` with the ad unit ID you created in the Adgeist dashboard.

**Ad Type:**

```swift
adView.adType = .BANNER // or .DISPLAY, .COMPANION
```

Replace with the ad type you created in the Adgeist dashboard:

- `.BANNER` - Small rectangular banner ads
- `.DISPLAY` - Standard display ads
- `.COMPANION` - Companion ads (requires minimum 320x320 dimensions)

#### Create an Ad Request

Once the `AdView` is configured with its properties (`adUnitId`, `adType`, etc.), create an ad request using the builder pattern:

```swift
let request = AdRequest.AdRequestBuilder()
    .build()
```

#### Load an Ad

Now it's time to load an ad. This is done by calling `loadAd()` on the `AdView` object:

```swift
adView.loadAd(request)
```

#### Destroy the Ad

When you're done with an `AdView`, call `destroy()` to permanently tear the ad down and release its resources. Call it when the view is going away, e.g. from `viewDidDisappear` or `deinit`:

```swift
deinit {
    adView?.destroy()
}
```

Calling `destroy()` stops any in-progress ad load, releases the underlying web view, and triggers the `onAdClosed()` callback on your listener. A destroyed `AdView` should not be reused — create a new instance to show another ad.

`AdView` also calls `destroy()` automatically from its own `deinit`, so cleanup happens even if you forget — but calling it explicitly is recommended so teardown happens deterministically.

#### Complete Example

Here's a complete example of loading a banner ad programmatically:

```swift
import UIKit
import AdgeistKit

class ViewController: UIViewController {
    private var adView: AdView?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize SDK
        AdgeistCore.initialize()

        // Create AdView
        let newAdView = AdView()
        newAdView.adUnitId = "YOUR_AD_UNIT_ID"
        newAdView.adType = .BANNER
        newAdView.setAdDimension(AdSize(width: 320, height: 50))
        adView = newAdView

        // Create ad request
        let request = AdRequest.AdRequestBuilder()
            .build()

        // Load ad
        newAdView.loadAd(request)

        // Add to view hierarchy
        view.addSubview(newAdView)
    }

    deinit {
        adView?.destroy()
    }
}
```

#### Responsive Ad Example

For an ad that fills its parent view instead of a fixed size, skip `setAdDimension()` and set `adIsResponsive = true`:

```swift
let adView = AdView()
adView.adUnitId = "YOUR_AD_UNIT_ID"
adView.adType = .BANNER
adView.adIsResponsive = true

view.addSubview(adView)
adView.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    adView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    adView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    adView.topAnchor.constraint(equalTo: view.topAnchor)
])

adView.loadAd(AdRequest.AdRequestBuilder().build())
```

#### Ad Events

You can listen for a number of events in the ad's lifecycle, including loading, impression, click, as well as open and close events. It is recommended to set the listener before loading the ad.

`AdListener` is an open class with no-op default implementations, so subclass it and override only the methods you need:

```swift
class MyAdListener: AdListener {
    override func onAdClicked() {
        // Code to be executed when the user clicks on an ad.
    }

    override func onAdClosed() {
        // Code to be executed when the ad is completely removed
        // from the screen.
    }

    override func onAdFailedToLoad(_ error: String) {
        // Code to be executed when an ad request fails.
        print("Ad Failed to Load: \(error)")
    }

    override func onAdImpression() {
        // Code to be executed when an impression is recorded
        // for an ad.
    }

    override func onAdLoaded() {
        // Code to be executed when an ad finishes loading.
        print("Ad Loaded Successfully!")
    }

    override func onAdOpened() {
        // Code to be executed when an ad opens an overlay that
        // covers the screen.
    }
}

adView.setAdListener(MyAdListener())
```

---

## Support

If you run into any difficulties while integrating or using the Adgeist Mobile Ads SDK, reach out to beast@thealteroffice.com and we'll help you get it sorted out.
