import SwiftUI

struct PIXKeysView: View {
    @State private var viewModel = PIXKeysViewModel()
    
    var body: some View {
        List {
            keysSection
        }
        .navigationTitle("PIX Keys")
        .toolbar { toolbarContent }
        .sheet(isPresented: $viewModel.showingAddKeySheet) {
            AddPIXKeyView(viewModel: viewModel)
        }
    }
}

// MARK: - Subviews/Sections
private extension PIXKeysView {
    @ViewBuilder
    var keysSection: some View {
        Section {
            if viewModel.keys.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.keys) { key in
                    PIXKeyRow(key: key)
                }
                .onDelete(perform: viewModel.deleteKey)
            }
        } header: {
            Text("Your Keys")
        } footer: {
            Text("These keys will be used for withdrawals.")
        }
    }
    
    @ViewBuilder
    var emptyStateView: some View {
        ContentUnavailableView(
            "No PIX Keys",
            systemImage: "qrcode",
            description: Text("Add a PIX key to receive payments.")
        )
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.showingAddKeySheet = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

// MARK: - Row View
private extension PIXKeysView {
    struct PIXKeyRow: View {
        let key: PIXKey
        
        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(key.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(key.value)
                        .font(.body)
                }
                
                Spacer()
                
                copyButton
            }
        }
        
        private var copyButton: some View {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                // TODO: Implement actual clipboard copy
            } label: {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Add Key Sheet
private extension PIXKeysView {
    struct AddPIXKeyView: View {
        @Environment(\.dismiss) var dismiss
        var viewModel: PIXKeysViewModel
        
        @State private var selectedType: PIXKey.PIXKeyType = .email
        @State private var keyValue: String = ""
        
        var body: some View {
            NavigationStack {
                Form {
                    Section("Key Details") {
                        Picker("Type", selection: $selectedType) {
                            ForEach(PIXKey.PIXKeyType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        
                        TextField("Key Value", text: $keyValue)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }
                .navigationTitle("Add PIX Key")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            viewModel.addKey(type: selectedType, value: keyValue)
                            dismiss()
                        }
                        .disabled(keyValue.isEmpty)
                    }
                }
            }
        }
    }
}

#Preview("Standard") {
    NavigationStack {
        PIXKeysView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        PIXKeysView()
            .preferredColorScheme(.dark)
    }
}
