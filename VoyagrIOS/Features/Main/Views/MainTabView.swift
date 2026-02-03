import SwiftUI

struct MainTabView: View {

    var body: some View {
        TabView {
            TripsView()
                .tabItem {
                    Label("Trips", systemImage: "airplane")
                }

            EventsView()
                .tabItem {
                    Label("Events", systemImage: "star")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "doc.on.doc")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppContainer())
}
