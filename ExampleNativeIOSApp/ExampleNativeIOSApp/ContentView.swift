import SwiftUI
import SwiftData
import AdgeistKit

struct ContentView: View {
    @ObservedObject private var viewModel = ContentViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var adUnitId = "69412a16e0e0c0ebb29d4462"
    @State private var adType = "display"
    @State private var width = 300
    @State private var height = 270
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
        GeometryReader { geometry in
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 0) {
                            TextField("Ad Unit ID (Adspace ID)", text: $adUnitId)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                            
                            TextField("Ad Type (e.g. banner, display)", text: $adType)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            HStack {
                                TextField("Width (dp)", value: $width, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                Text("×")
                                TextField("Height (dp)", value: $height, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            Toggle("Test Mode", isOn: $isTestMode)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            Button(showingAd ? "Cancel Ad" : "Generate Ad") {
                                showingAd ? cancelAd() : generateAd()
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showingAd ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                            .foregroundColor(showingAd ? .red : .blue)
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }
                        .padding(.vertical)
                        
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

                        // Ad Container
                        if showingAd {
                            AdViewContainer(
                                adUnitId: adUnitId,
                                adType: adType,
                                adSize: AdSize(width: width, height: height),
                                isTestMode: isTestMode,
                                onEvent: handleAdEvent
                            )
                            .id(adViewId)
                            .frame(
                                width: CGFloat(width),
                                height: CGFloat(height)
                            )
                        }
                    }
                    .frame(minHeight: geometry.size.height, alignment: .top)
                    .padding(.top)
                    .background(Color.gray.opacity(0.2))
                }
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
        if width <= 0 { missing.append("Valid Width") }
        if height <= 0 { missing.append("Valid Height") }
        return missing
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
