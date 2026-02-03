import SwiftUI

struct TripsView: View {

    @Environment(AppContainer.self) private var container

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Trips Yet",
                systemImage: "airplane",
                description: Text("Your upcoming trips will appear here")
            )
            .navigationTitle("Trips")
        }
    }
}

#Preview {
    TripsView()
        .environment(AppContainer())
}
