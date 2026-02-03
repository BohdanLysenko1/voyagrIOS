import SwiftUI

struct EventsView: View {

    @Environment(AppContainer.self) private var container

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Events",
                systemImage: "calendar",
                description: Text("Your scheduled events will appear here")
            )
            .navigationTitle("Events")
        }
    }
}

#Preview {
    EventsView()
        .environment(AppContainer())
}
