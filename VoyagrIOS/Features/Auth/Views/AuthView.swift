import SwiftUI

struct AuthView: View {

    @State private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Voyagr")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your journey begins here")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                viewModel.signIn()
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .onDisappear {
            viewModel.cancelSignIn()
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel(authService: MockAuthService()))
}
