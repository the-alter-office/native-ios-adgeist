import SwiftUI
import SwiftData
import AdgeistKit

struct ContentView: View {
    @ObservedObject private var viewModel = ContentViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    // Configuration Section
    @State private var packageId = "com.camerasideas.InstaShot"
    @State private var adgeistAppId = "695e797d6fcfb14c38cfd1d6"
    @State private var defaultBidRequestBackendDomain = "https://qa.v2.bg-services.adgeist.ai"

    // Ad Loading Section
    @State private var adspaceId = "695e828d6fcfb14c38cfd3b1"
    @State private var adspaceType = "banner"
    @State private var width = 250
    @State private var height = 250
    @State private var isTestMode = false
    @State private var isResponsive = false
    @State private var containerWidth = 300
    @State private var containerHeight = 250
    
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
