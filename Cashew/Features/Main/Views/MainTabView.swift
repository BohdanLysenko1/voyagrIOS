import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Tab = .dashboard

    private enum Tab: Int, CaseIterable {
        case dashboard = 0
        case events
        case calendar
        case trips
        case settings

        var next: Tab? {
            Tab(rawValue: rawValue + 1)
        }

        var previous: Tab? {
            Tab(rawValue: rawValue - 1)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("My Day", systemImage: "sun.max")
                }
                .tag(Tab.dashboard)

            EventsView()
                .tabItem {
                    Label("Events", systemImage: "star")
                }
                .tag(Tab.events)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)

            TripsView()
                .tabItem {
                    Label("Trips", systemImage: "airplane")
                }
                .tag(Tab.trips)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .onChange(of: selectedTab) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .global)
                .onEnded { gesture in
                    let horizontalDistance = gesture.translation.width
                    let verticalDistance = abs(gesture.translation.height)

                    // Only handle horizontal swipes (ignore diagonal/vertical)
                    guard abs(horizontalDistance) > verticalDistance else { return }

                    withAnimation(.easeInOut(duration: 0.25)) {
                        if horizontalDistance < 0, let next = selectedTab.next {
                            // Swipe left -> next tab
                            selectedTab = next
                        } else if horizontalDistance > 0, let previous = selectedTab.previous {
                            // Swipe right -> previous tab
                            selectedTab = previous
                        }
                    }
                }
        )
    }
}

#Preview {
    MainTabView()
        .environment(AppContainer())
}
