import SwiftUI

struct CalendarView: View {

    @Environment(AppContainer.self) private var container

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Plans",
                systemImage: "calendar.badge.clock",
                description: Text("Your calendar will show trip schedules")
            )
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarView()
        .environment(AppContainer())
}
