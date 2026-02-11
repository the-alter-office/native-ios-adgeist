import SwiftUI
import SwiftData
import AdgeistKit

struct ContentView: View {
    @ObservedObject private var viewModel = ContentViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    // Configuration Section
    @State private var packageId = "com.example"
    @State private var adgeistAppId = "6954e6859ab54390db01e3d7"
    @State private var defaultBidRequestBackendDomain = "https://beta.v2.bg-services.adgeist.ai"

    // Ad Loading Section
    @State private var adspaceId = "695bae6f6c59cd9c0bd24388"
    @State private var adspaceType = "display"
    @State private var width = 320
    @State private var height = 450
    @State private var isTestMode = true
    @State private var isResponsive = false
    @State private var containerWidth = 300
    @State private var containerHeight = 250
    
    // UTM Tracking Section
    @State private var utmDataString = "No UTM data yet"
    @State private var testDeeplinkURL = "myapp://campaign?utm_source=facebook&utm_medium=social&utm_campaign=spring_sale&utm_content=ad1"
    
    @State private var adViewId = UUID()
    @State private var showingAd = false
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    public init() { }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // SDK Configuration Section
                        VStack(spacing: 12) {
                            Text("SDK Configuration")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            TextField("Package ID", text: $packageId)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal)
                            
                            TextField("Adgeist App ID", text: $adgeistAppId)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal)
                            
                            Button("Configure SDK") {
                                configureSDK()
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        
                        // Divider
                        Divider()
                            .padding(.horizontal)
                        
                        // UTM Tracking Section
                        VStack(spacing: 12) {
                            Text("UTM Tracking")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            // Display current UTM data
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current UTM Data:")
                                    .font(.subheadline)
                                    .bold()
                                    .padding(.horizontal)
                                
                                Text(utmDataString)
                                    .font(.caption)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            }
                            
                            // Test deeplink input
                            TextField("Test Deeplink URL", text: $testDeeplinkURL)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                Button("Refresh UTM Data") {
                                    refreshUTMData()
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                
                                Button("Simulate Deeplink") {
                                    simulateDeeplink()
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            
                            Button("Clear UTM Data") {
                                clearUTMData()
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        
                        // Divider
                        Divider()
                            .padding(.horizontal)
                        
                        // Ad Loading Section
                        VStack(spacing: 12) {
                            Text("Load Advertisement")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            TextField("Adspace Type (e.g., display)", text: $adspaceType)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal)
                            
                            TextField("Adspace ID", text: $adspaceId)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal)
                            
                            HStack {
                                TextField("Width (dp)", value: $width, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                    .disabled(isResponsive)
                                    .opacity(isResponsive ? 0.5 : 1.0)
                                Text("×")
                                TextField("Height (dp)", value: $height, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                    .disabled(isResponsive)
                                    .opacity(isResponsive ? 0.5 : 1.0)
                            }
                            .padding(.horizontal)
                            
                            // Responsive Ad Toggle
                            Toggle("Responsive Ad", isOn: $isResponsive)
                                .padding(.horizontal)
                            
                            // Container dimensions for responsive ads
                            if isResponsive {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Container Dimensions (for responsive ad)")
                                        .font(.subheadline)
                                        .italic()
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                    
                                    HStack {
                                        TextField("Container Width (dp)", value: $containerWidth, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                        Text("×")
                                        TextField("Container Height (dp)", value: $containerHeight, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            Toggle("Test Mode", isOn: $isTestMode)
                                .padding(.horizontal)
                            
                            HStack(spacing: 16) {
                                Button("Get Ad") {
                                    generateAd()
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .disabled(showingAd)
                                .opacity(showingAd ? 0.5 : 1.0)
                                
                                if showingAd {
                                    Button("Cancel") {
                                        cancelAd()
                                    }
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)

                        // Ad Container
                        if showingAd {
                            if isResponsive {
                                // Responsive Container
                                AdViewContainer(
                                    adUnitId: adspaceId,
                                    adType: adspaceType,
                                    adSize: nil,
                                    isTestMode: isTestMode,
                                    isResponsive: true,
                                    onEvent: handleAdEvent
                                )
                                .id(adViewId)
                                .frame(
                                    width: CGFloat(containerWidth),
                                    height: CGFloat(containerHeight)
                                )
                                .background(Color.pink.opacity(0.1))
                                .cornerRadius(4)
                                .padding(.horizontal)
                            } else {
                                // Fixed Container
                                AdViewContainer(
                                    adUnitId: adspaceId,
                                    adType: adspaceType,
                                    adSize: AdSize(width: width, height: height),
                                    isTestMode: isTestMode,
                                    isResponsive: false,
                                    onEvent: handleAdEvent
                                )
                                .id(adViewId)
                                .frame(
                                    width: CGFloat(width),
                                    height: CGFloat(height)
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .frame(minHeight: geometry.size.height, alignment: .top)
                    .padding(.top)
                }
                .alert(alertTitle, isPresented: $showingAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(alertMessage)
                }
            }
        }
    }
    
    private func configureSDK() {
        if packageId.isEmpty || adgeistAppId.isEmpty {
            showAlert(
                title: "Invalid Configuration",
                message: "Please enter valid Package ID and Adgeist App ID"
            )
            return
        }
        
        AdgeistCore.destroy()
        let _ = AdgeistCore.initialize(
            customBidRequestBackendDomain: defaultBidRequestBackendDomain,
            customPackageOrBundleID: packageId,
            customAdgeistAppID: adgeistAppId
        )
        
        showAlert(
            title: "Success",
            message: "SDK configured with:\nPackage ID: \(packageId)\nApp ID: \(adgeistAppId)"
        )
        print("SDK reinitialized with Package ID: \(packageId), App ID: \(adgeistAppId)")
    }
    
    private func generateAd() {
        let missing = validateFields()
        if !missing.isEmpty {
            showAlert(
                title: "Invalid Fields",
                message: "Please enter valid values for: \(missing.joined(separator: ", "))"
            )
            return
        }
        
        print(isResponsive 
            ? "Loading RESPONSIVE ad in container: \(containerWidth)dp x \(containerHeight)dp"
            : "Loading FIXED ad: \(width)dp x \(height)dp"
        )
        
        adViewId = UUID()
        showingAd = true
    }
    
    private func cancelAd() {
        showingAd = false
        clearInputFields()
    }
    
    private func validateFields() -> [String] {
        var missing: [String] = []
        
        if adspaceId.isEmpty { missing.append("Adspace ID") }
        if adspaceType.isEmpty { missing.append("Adspace Type") }
        
        if !isResponsive {
            if width <= 0 { missing.append("Width") }
            if height <= 0 { missing.append("Height") }
        } else {
            if containerWidth <= 0 { missing.append("Container Width") }
            if containerHeight <= 0 { missing.append("Container Height") }
        }
        
        return missing
    }
    
    private func clearInputFields() {
        adspaceId = ""
        adspaceType = ""
        width = 0
        height = 0
    }
    
    private func handleAdEvent(_ event: String) {
        switch event {
        case "loaded":
            return
            
        case let error where error.hasPrefix("failed:"):
            let msg = String(error.dropFirst("failed:".count))
            showAlert(title: "Ad Load Failed", message: msg)
            cancelAd()
            
        case "clicked":
            return
            
        case "impression":
            return
            
        default:
            break
        }
    }
    
    // Helper to show alerts cleanly
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    // UTM Tracking Helper Methods
    private func refreshUTMData() {
        do {
            let adgeistCore = try AdgeistCore.getInstance()
            let utmData = adgeistCore.getUTMData()
            
            if utmData.isEmpty {
                utmDataString = "No UTM data captured yet"
            } else {
                // Format UTM data for display
                if let jsonData = try? JSONSerialization.data(withJSONObject: utmData, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    utmDataString = jsonString
                } else {
                    utmDataString = "UTM data: \(utmData.description)"
                }
            }
            
            showAlert(title: "UTM Data Refreshed", message: "Check the display above")
        } catch {
            utmDataString = "AdgeistCore not initialized"
            showAlert(title: "Error", message: "Please configure SDK first")
        }
    }
    
    private func simulateDeeplink() {
        guard let url = URL(string: testDeeplinkURL) else {
            showAlert(title: "Invalid URL", message: "Please enter a valid deeplink URL")
            return
        }
        
        do {
            let adgeistCore = try AdgeistCore.getInstance()
            adgeistCore.trackDeeplink(url: url)
            
            // Log an event
            let event = Event(
                eventType: "deeplink_simulated",
                eventProperties: ["url": url.absoluteString]
            )
            adgeistCore.logEvent(event)
            
            refreshUTMData()
            showAlert(title: "Deeplink Tracked", message: "UTM parameters captured from: \(url.absoluteString)")
        } catch {
            showAlert(title: "Error", message: "Please configure SDK first")
        }
    }
    
    private func clearUTMData() {
        UTMTracker.shared.clearUtmParameters()
        utmDataString = "No UTM data yet"
        showAlert(title: "Cleared", message: "All UTM data has been cleared")
    }
}

// MARK: - UIViewRepresentable Wrapper
struct AdViewContainer: UIViewRepresentable {
    let adUnitId: String
    let adType: String
    let adSize: AdSize?
    let isTestMode: Bool
    let isResponsive: Bool
    let onEvent: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }
    
    func makeUIView(context: Context) -> AdView {
        print("AdViewContainer: Creating AdView for unit ID: \(adUnitId)")
        let adView = AdView()
        adView.adUnitId = adUnitId
        adView.adType = adType
        adView.adIsResposive = isResponsive
        
        if let adSize = adSize, !isResponsive {
            adView.setAdDimension(adSize)
        }
        
        adView.setAdListener(context.coordinator)

        let request = AdRequest.AdRequestBuilder()
            .setTestMode(isTestMode)
            .build()

        adView.loadAd(request)

        return adView
    }
    
    func updateUIView(_ uiView: AdView, context: Context) {}
    
    static func dismantleUIView(_ uiView: AdView, coordinator: Coordinator) {
        uiView.destroy()
    }
    
    class Coordinator: AdListener {
        let onEvent: (String) -> Void
        
        init(onEvent: @escaping (String) -> Void) {
            self.onEvent = onEvent
        }
        
        override func onAdLoaded() {
            print("AdView: Ad Loaded Successfully!")
            onEvent("loaded")
        }
        
        override func onAdFailedToLoad(_ errorMessage: String) {
            print("AdView: Ad Failed to Load: \(errorMessage)")
            onEvent("failed:\(errorMessage)")
        }
        
        override func onAdClicked() {
            print("AdView: Ad Clicked")
            onEvent("clicked")
        }
        
        override func onAdImpression() {
            print("AdView: Ad Impression")
            onEvent("impression")
        }
        
        override func onAdOpened() {
            print("AdView: Ad Opened")
        }
        
        override func onAdClosed() {
            print("AdView: Ad Closed")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
