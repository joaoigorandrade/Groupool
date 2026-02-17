import SwiftUI

struct PIXKey: Identifiable, Hashable {
    let id: UUID
    let type: PIXKeyType
    let value: String
    
    enum PIXKeyType: String, CaseIterable, Identifiable {
        case cpf = "CPF"
        case email = "Email"
        case phone = "Phone"
        case random = "Random Key"
        
        var id: String { self.rawValue }
    }
}

struct PIXKeysView: View {
    @State private var keys: [PIXKey] = [
        PIXKey(id: UUID(), type: .email, value: "joao.silva@email.com"),
        PIXKey(id: UUID(), type: .cpf, value: "***.456.789-**")
    ]
    
    @State private var showingAddKeySheet = false
    
    var body: some View {
        List {
            Section {
                if keys.isEmpty {
                    ContentUnavailableView(
                        "No PIX Keys",
                        systemImage: "qrcode",
                        description: Text("Add a PIX key to receive payments.")
                    )
                } else {
                    ForEach(keys) { key in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(key.type.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(key.value)
                                    .font(.body)
                            }
                            Spacer()
                            Button {
                                // Copy action placeholder
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete(perform: deleteKey)
                }
            } header: {
                Text("Your Keys")
            } footer: {
                Text("These keys will be used for withdrawals.")
            }
        }
        .navigationTitle("PIX Keys")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddKeySheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddKeySheet) {
            AddPIXKeyView(keys: $keys)
        }
    }
    
    private func deleteKey(at offsets: IndexSet) {
        keys.remove(atOffsets: offsets)
    }
}

struct AddPIXKeyView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var keys: [PIXKey]
    
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
                        // In a real app, keyboard type would change based on key type
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("Add PIX Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newKey = PIXKey(id: UUID(), type: selectedType, value: keyValue)
                        keys.append(newKey)
                        
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        dismiss()
                    }
                    .disabled(keyValue.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PIXKeysView()
    }
}
