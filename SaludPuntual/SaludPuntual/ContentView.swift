
import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $viewModel.userInput)
                    .frame(height: 150)
                    .border(Color.gray.opacity(0.25))

                Button {
                    Task { await viewModel.runModel() }
                } label: {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView()
                        }
                        Text("Run Model")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isProcessing)

                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red)
                }

                ScrollView {
                    Text(viewModel.output)
                        .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Demo")
        }
    }
}

#Preview {
    ContentView()
}
