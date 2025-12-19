import SwiftUI
import SwiftData
import AdgeistKit

struct ContentView: View {
    @ObservedObject private var viewModel = ContentViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var adUnitId = "6932a4c022f6786424ce3b84"
    @State private var adType = "display"
    @State private var width = "320"
    @State private var height = "480"
    @State private var isTestMode = false
    
    public init() { }
    
//   @State private var adUnitId = ""
//   @State private var adType = ""
//   @State private var width = ""
//   @State private var height = ""
//   @State private var isTestMode = false
    
    @State private var adViewId = UUID()
    @State private var showingAd = false
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        Form {
                            Section {
                                TextField("Ad Unit ID (Adspace ID)", text: $adUnitId)
                                    .textContentType(.username)
                                
                                TextField("Ad Type (e.g. banner, display)", text: $adType)
                                    .textInputAutocapitalization(.never)
                                
                                HStack {
                                    TextField("Width (dp)", text: $width)
                                        .keyboardType(.numberPad)
                                        .frame(width: 100)
                                    Text("×")
                                    TextField("Height (dp)", text: $height)
                                        .keyboardType(.numberPad)
                                        .frame(width: 100)
                                }
                                
                                Toggle("Test Mode", isOn: $isTestMode)
                            }
                            
                            Section {
                                Button(showingAd ? "Cancel Ad" : "Generate Ad") {
                                    showingAd ? cancelAd() : generateAd()
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(showingAd ? .red : .blue)
                            }
                        }
                        .frame(height: 400)
                        
                        // Extra scrollable content for testing viewability
                        // ForEach(0..<20) { index in
                        //     VStack(alignment: .leading, spacing: 8) {
                        //         Text("Sample Content \(index + 1)")
                        //             .font(.headline)
                        //         Text("Scroll down to see the ad at the bottom of the screen. This content helps test viewable impressions.")
                        //             .font(.subheadline)
                        //             .foregroundColor(.secondary)
                        //     }
                        //     .padding()
                        //     .frame(maxWidth: .infinity, alignment: .leading)
                        //     .background(Color(.systemGray6))
                        //     .cornerRadius(8)
                        //     .padding(.horizontal)
                        //     .padding(.vertical, 4)
                        // }
                        
                        if showingAd {
                            AdViewContainer(
                                adUnitId: adUnitId,
                                adType: adType,
                                adSize: AdSize(width: Int(width) ?? 320, height: Int(height) ?? 480),
                                isTestMode: isTestMode,
                                onEvent: handleAdEvent
                            )
                            .id(adViewId)
                            .frame(
                                width: CGFloat(Int(width) ?? 320),
                                height: CGFloat(Int(height) ?? 480)
                            )
                        }
                    }
                }
            }
            .navigationTitle("Adgeist Demo")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
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
        adViewId = UUID()
        showingAd = true
    }
    
    private func cancelAd() {
        showingAd = false
    }
    
    private func validateFields() -> [String] {
        var missing: [String] = []
        if Int(width) ?? 0 <= 0 { missing.append("Valid Width") }
        if Int(height) ?? 0 <= 0 { missing.append("Valid Height") }
        return missing
    }
    
    private func handleAdEvent(_ event: String) {
        switch event {
        case "loaded":
            print("Ad loaded successfully")
            
        case let error where error.hasPrefix("failed:"):
            let msg = String(error.dropFirst("failed:".count))
            showAlert(title: "Ad Load Failed", message: msg)
            cancelAd()
            
        case "clicked":
            print("Ad clicked")
            
        case "impression":
            print("Impression recorded")
            
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
    let adSize: AdSize
    let isTestMode: Bool
    let onEvent: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }
    
    func makeUIView(context: Context) -> AdView {
        print("AdViewContainer: Creating AdView for unit ID: \(adUnitId)")
        let adView = AdView()
        adView.adUnitId = adUnitId
        adView.adType = adType
        adView.setAdDimension(adSize)
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
            onEvent("loaded")
        }
        
        override func onAdFailedToLoad(_ errorMessage: String) {
            onEvent("failed:\(errorMessage)")
        }
        
        override func onAdClicked() {
            onEvent("clicked")
        }
        
        override func onAdImpression() {
            onEvent("impression")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
