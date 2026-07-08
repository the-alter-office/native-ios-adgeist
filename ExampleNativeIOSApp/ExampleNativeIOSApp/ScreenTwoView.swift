import SwiftUI
import AdgeistKit

/// Secondary screen used to check that ads load/destroy correctly
/// as the user navigates between multiple screens in the app.
struct ScreenTwoView: View {
    private let adUnitId = "69ca2675576a0a20dd6c6cfb"

    @State private var adViewId = UUID()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Screen Two")
                    .font(.title2)
                    .bold()
                    .padding(.top)

                Text("A fresh ad loads each time this screen appears, and is destroyed when you navigate away. Use this to check ad load/destroy behavior across screen navigation.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                AdViewContainer(
                    adUnitId: adUnitId,
                    adType: .BANNER,
                    adSize: nil,
                    isResponsive: true,
                    onEvent: { _ in }
                )
                .id(adViewId)
                .frame(width: 320, height: 320)
                .cornerRadius(4)
            }
            .padding(.bottom)
        }
        .onAppear {
            adViewId = UUID()
        }
    }
}

#Preview {
    ScreenTwoView()
}
