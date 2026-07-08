import SwiftUI

enum AppScreen: String, CaseIterable, Identifiable, Hashable {
    case home
    case screenTwo
    case screenThree

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home (Ads)"
        case .screenTwo: return "Screen Two"
        case .screenThree: return "Screen Three"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house"
        case .screenTwo: return "doc.text"
        case .screenThree: return "doc.text"
        }
    }
}

struct DrawerView: View {
    let selectedScreen: AppScreen
    let onSelect: (AppScreen) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Adgeist Example")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom)

            Divider()

            ForEach(AppScreen.allCases) { screen in
                Button {
                    onSelect(screen)
                } label: {
                    HStack {
                        Image(systemName: screen.iconName)
                        Text(screen.title)
                        Spacer()
                    }
                    .padding()
                    .background(screen == selectedScreen ? Color.accentColor.opacity(0.15) : Color.clear)
                }
                .foregroundColor(.primary)
            }

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct AppShellView: View {
    @State private var path: [AppScreen] = []
    @State private var isDrawerOpen = false

    private var selectedScreen: AppScreen {
        path.last ?? .home
    }

    var body: some View {
        ZStack(alignment: .leading) {
            NavigationStack(path: $path) {
                HomeView()
                    .navigationTitle(AppScreen.home.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { hamburgerToolbar }
                    .navigationDestination(for: AppScreen.self) { screen in
                        destinationView(for: screen)
                            .navigationTitle(screen.title)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar { hamburgerToolbar }
                    }
            }

            if isDrawerOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isDrawerOpen = false
                        }
                    }

                DrawerView(selectedScreen: selectedScreen, onSelect: selectScreen)
                    .frame(width: 260)
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.move(edge: .leading))
            }
        }
    }

    @ViewBuilder
    private func destinationView(for screen: AppScreen) -> some View {
        switch screen {
        case .home:
            EmptyView()
        case .screenTwo:
            ScreenTwoView()
        case .screenThree:
            ScreenThreeView()
        }
    }

    @ToolbarContentBuilder
    private var hamburgerToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                withAnimation {
                    isDrawerOpen.toggle()
                }
            } label: {
                Image(systemName: "line.3.horizontal")
            }
        }
    }

    private func selectScreen(_ screen: AppScreen) {
        if screen == .home {
            path = []
        } else {
            path.append(screen)
        }
        withAnimation {
            isDrawerOpen = false
        }
    }
}

#Preview {
    AppShellView()
}
