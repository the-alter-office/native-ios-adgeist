# UTM Tracking - Quick Start Guide

## 📱 Basic Setup (5 minutes)

### Step 1: SDK Initialization

The SDK automatically tracks first install UTM parameters. Just initialize as normal:

```swift
import AdgeistKit

let adgeistCore = AdgeistCore.initialize(
    customPackageOrBundleID: "com.yourapp.bundle",
    customAdgeistAppID: "your-app-id"
)
```

### Step 2: Add Deeplink Handling

Add this to your main app file:

**SwiftUI:**

```swift
import AdgeistKit

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    AdgeistCore.getInstance().trackDeeplink(url: url)
                }
        }
    }
}
```

**UIKit AppDelegate:**

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    AdgeistCore.getInstance().trackDeeplink(url: url)
    return true
}
```

### Step 3: Configure URL Scheme

Add to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

**Done!** 🎉 UTM tracking is now active.

---

## 🧪 Testing

### Test in iOS Simulator

```bash
xcrun simctl openurl booted "yourapp://test?utm_source=facebook&utm_medium=social&utm_campaign=spring_sale"
```

### View Captured Data

```swift
let utmData = AdgeistCore.getInstance().getUTMData()
print(utmData)
```

### Clear for Testing

```swift
UTMTracker.shared.clearAllUTMData()
```

---

## 📊 Common Use Cases

### 1. Track Marketing Campaign Performance

```
yourapp://promo?utm_source=facebook&utm_medium=cpc&utm_campaign=holiday_sale
```

### 2. Track Email Campaigns

```
yourapp://offer?utm_source=mailchimp&utm_medium=email&utm_campaign=newsletter_01
```

### 3. Track Social Media Posts

```
yourapp://share?utm_source=instagram&utm_medium=social&utm_campaign=influencer_partnership&utm_content=story
```

### 4. Track QR Codes

```
yourapp://scan?utm_source=poster&utm_medium=qr&utm_campaign=in_store_promo
```

### 5. Track App Store Campaigns

```
https://apps.apple.com/app/yourapp?utm_source=google&utm_medium=search&utm_campaign=brand_keywords
```

---

## 🔍 Retrieving UTM Data

### Get Current UTM (Most Recent)

```swift
if let utm = AdgeistCore.getInstance().getCurrentUTM() {
    print("Source: \(utm.source ?? "none")")
    print("Campaign: \(utm.campaign ?? "none")")
}
```

### Get All UTM Data

```swift
let allUTM = AdgeistCore.getInstance().getUTMData()
// Returns both first_install and last_deeplink
```

### Get First Install Attribution

```swift
if let firstInstall = UTMTracker.shared.getFirstInstallUTM() {
    print("Acquired from: \(firstInstall.source ?? "organic")")
}
```

### Get Last Deeplink

```swift
if let lastDeeplink = UTMTracker.shared.getLastDeeplinkUTM() {
    print("Last campaign: \(lastDeeplink.campaign ?? "none")")
}
```

---

## 🎯 Automatic Integration

UTM data is **automatically included** in:

✅ All events via `logEvent()`  
✅ Ad request targeting info  
✅ User analytics

**No extra code needed!**

---

## 📝 Standard UTM Parameters

| Parameter      | Purpose          | Example                      |
| -------------- | ---------------- | ---------------------------- |
| `utm_source`   | Traffic source   | facebook, google, newsletter |
| `utm_medium`   | Marketing medium | cpc, social, email, qr       |
| `utm_campaign` | Campaign name    | spring_sale, launch_2024     |
| `utm_content`  | Ad variant       | banner_a, link_red           |
| `utm_term`     | Search keywords  | running shoes, fitness       |

---

## 🚀 Example Deeplink URLs

### Facebook Ad Campaign

```
yourapp://campaign?utm_source=facebook&utm_medium=cpc&utm_campaign=spring_sale&utm_content=carousel_ad
```

### Instagram Story

```
yourapp://story?utm_source=instagram&utm_medium=social&utm_campaign=influencer&utm_content=swipe_up
```

### Email Newsletter

```
yourapp://promo?utm_source=mailchimp&utm_medium=email&utm_campaign=weekly_deals&utm_content=header_cta
```

### Google Ads

```
yourapp://landing?utm_source=google&utm_medium=cpc&utm_campaign=brand&utm_term=shoe+store
```

### QR Code on Poster

```
yourapp://scan?utm_source=poster&utm_medium=qr&utm_campaign=store_opening&utm_content=entrance_poster
```

---

## ⚠️ Troubleshooting

### Deeplinks not working?

1. Check URL scheme is in Info.plist
2. Verify `onOpenURL` handler is set up
3. Test with simulator command

### No UTM data?

1. Ensure URL contains `utm_*` parameters
2. Check that AdgeistCore is initialized
3. Look for console logs starting with "AdgeistKit:"

### First install not tracking?

1. First install only happens once
2. Clear data with `clearAllUTMData()` to test
3. Or reinstall the app

---

## 📱 Full Integration Example

```swift
import SwiftUI
import AdgeistKit

@main
struct MyApp: App {
    init() {
        // Initialize SDK - automatically tracks first install
        _ = AdgeistCore.initialize(
            customPackageOrBundleID: "com.example.app",
            customAdgeistAppID: "your-app-id"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeeplink(url)
                }
        }
    }

    func handleDeeplink(_ url: URL) {
        // Track UTM parameters
        AdgeistCore.getInstance().trackDeeplink(url: url)

        // Log event with auto-included UTM data
        let event = Event(
            eventType: "deeplink_opened",
            eventProperties: ["url": url.absoluteString]
        )
        AdgeistCore.getInstance().logEvent(event)

        // Navigate based on deeplink path
        // ... your navigation logic
    }
}
```

---

## 🎓 Best Practices

1. **Always include utm_source and utm_medium** - These are the most important
2. **Use consistent naming** - stick to lowercase with underscores
3. **Keep it short** - URLs get long quickly
4. **Test before launching** - Always test your deeplinks
5. **Document your campaigns** - Keep a spreadsheet of UTM values

---

## 📚 More Information

- Full documentation: [UTM_TRACKING_GUIDE.md](./UTM_TRACKING_GUIDE.md)
- Implementation details: [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)
- Example app code: `ExampleNativeIOSApp/`

---

**Need help?** Check the troubleshooting section in the full guide or contact support.
