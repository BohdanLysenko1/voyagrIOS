import SwiftUI

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    List {
        DetailRow(label: "Name", value: "John Doe")
        DetailRow(label: "Status", value: "Active")
    }
}
