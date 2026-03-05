import SwiftUI

struct TemplatesView: View {

    @Environment(AppContainer.self) private var container

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Templates",
                systemImage: "doc.on.doc",
                description: Text("Create templates to quickly plan new trips")
            )
            .navigationTitle("Templates")
        }
    }
}

#Preview {
    TemplatesView()
        .environment(AppContainer())
}
