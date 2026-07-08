import SwiftUI
import AdgeistKit

struct HomeView: View {
    @ObservedObject private var viewModel = ContentViewModel()

    // Configuration Section
    @State private var packageId = "com.leaguex.crm.beta"
    @State private var adgeistAppId = "69a6777707df2b1527e357f9"
    @State private var defaultBidRequestBackendDomain = "https://beta.v2.bg-services.adgeist.ai"

    // Load Advertisement Section
    @State private var autoLoadDefaults = true
    private let defaultBannerAdUnitId1 = "69ca2675576a0a20dd6c6cfb"
    private let defaultBannerAdUnitId2 = "6a4b7c9a50946c5aa2fda929"

    // Manual ad config (used when autoLoadDefaults is off)
    @State private var adspaceId = "69ca2675576a0a20dd6c6cfb"
    @State private var selectedAdType: AdType = .BANNER
    @State private var width = 360
    @State private var height = 360
    @State private var isResponsive = true
    @State private var containerWidth = 360
    @State private var containerHeight = 360

    @State private var adViewId = UUID()
    @State private var showingAd = false

    @State private var autoAdViewId1 = UUID()
    @State private var autoAdViewId2 = UUID()
    @State private var showingAutoAds = false

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    public init() { }

    var body: some View {
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

                    Toggle("Auto Load (default IDs)", isOn: $autoLoadDefaults)
                        .padding(.horizontal)

                    if !autoLoadDefaults {
                        Picker("Adspace Type", selection: $selectedAdType) {
                            Text("Banner").tag(AdType.BANNER)
                            Text("Display").tag(AdType.DISPLAY)
                            Text("Companion").tag(AdType.COMPANION)
                        }
                        .pickerStyle(.segmented)
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
                    }

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
                        .disabled(showingAd || showingAutoAds)
                        .opacity((showingAd || showingAutoAds) ? 0.5 : 1.0)

                        if showingAd || showingAutoAds {
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
                if showingAutoAds {
                    VStack(spacing: 12) {
                        AdViewContainer(
                            adUnitId: defaultBannerAdUnitId1,
                            adType: .BANNER,
                            adSize: AdSize(width: 360, height: 360),
                            isResponsive: false,
                            onEvent: handleAdEvent
                        )
                        .id(autoAdViewId1)
                        .frame(width: 360, height: 360)

                        AdViewContainer(
                            adUnitId: defaultBannerAdUnitId2,
                            adType: .BANNER,
                            adSize: AdSize(width: 360, height: 360),
                            isResponsive: false,
                            onEvent: handleAdEvent
                        )
                        .id(autoAdViewId2)
                        .frame(width: 360, height: 360)
                    }
                    .padding(.horizontal)
                } else if showingAd {
                    if isResponsive {
                        // Responsive Container
                        AdViewContainer(
                            adUnitId: adspaceId,
                            adType: selectedAdType,
                            adSize: nil,
                            isResponsive: true,
                            onEvent: handleAdEvent
                        )
                        .id(adViewId)
                        .frame(
                            width: CGFloat(containerWidth),
                            height: CGFloat(containerHeight)
                        )
                        .cornerRadius(4)
                        .padding(.horizontal)
                    } else {
                        // Fixed Container
                        AdViewContainer(
                            adUnitId: adspaceId,
                            adType: selectedAdType,
                            adSize: AdSize(width: width, height: height),
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
            .padding(.top)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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
        if autoLoadDefaults {
            print("Loading default ads: \(defaultBannerAdUnitId1), \(defaultBannerAdUnitId2)")
            autoAdViewId1 = UUID()
            autoAdViewId2 = UUID()
            showingAutoAds = true
            return
        }

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
        showingAutoAds = false
        clearInputFields()
    }

    private func validateFields() -> [String] {
        var missing: [String] = []

        if adspaceId.isEmpty { missing.append("Adspace ID") }
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

#Preview {
    HomeView()
}
