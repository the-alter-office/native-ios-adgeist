import SwiftUI
import AdgeistKit

/// Secondary screen used to check that ads survive navigation correctly:
/// the ad pauses when this screen is covered by another push and resumes
/// instantly (no reload) when you navigate back to it.
struct ScreenTwoView: View {
    private let adUnitId = "69ca2675576a0a20dd6c6cfb"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Screen Two")
                    .font(.title2)
                    .bold()
                    .padding(.top)

                Text("This ad pauses when you navigate away and resumes instantly when you come back, without reloading. Use this to check ad session persistence across screen navigation.")
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
                .frame(width: 320, height: 320)
                .cornerRadius(4)
            }
            .padding(.bottom)
        }
    }
}

#Preview {
    ScreenTwoView()
}
