import SwiftUI

struct PIXKeysView: View {
    @Bindable var viewModel: ProfileViewModel
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.pixKeys) { key in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(key.type.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        
                        Text(key.value)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: viewModel.deletePIXKey)
            } footer: {
                Text("Swipe left to delete a key.")
            }
        }
        .navigationTitle("PIX Keys")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.showingAddKeySheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddKeySheet) {
            AddPIXKeySheet(viewModel: viewModel)
        }
    }
}

struct AddPIXKeySheet: View {
    @Bindable var viewModel: ProfileViewModel
    @State private var selectedType: PIXKey.PIXKeyType = .email
    @State private var value: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $selectedType) {
                    ForEach(PIXKey.PIXKeyType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                
                TextField("Value", text: $value)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .navigationTitle("Add PIX Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addPIXKey(type: selectedType, value: value)
                        dismiss()
                    }
                    .disabled(value.isEmpty)
                }
            }
        }
    }
}
