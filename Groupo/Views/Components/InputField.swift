import SwiftUI

struct InputField: View {
    let title: String
    let placeholder: String
    let errorMessage: String?
    let axis: Axis
    let characterLimit: Int?
    let showCharacterCount: Bool
    let keyboardType: UIKeyboardType
    
    private let text: Binding<String>?
    private let doubleValue: Binding<Double>?
    private let isCurrency: Bool
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        errorMessage: String? = nil,
        axis: Axis = .horizontal,
        characterLimit: Int? = nil,
        showCharacterCount: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self.placeholder = placeholder
        self.text = text
        self.doubleValue = nil
        self.isCurrency = false
        self.errorMessage = errorMessage
        self.axis = axis
        self.characterLimit = characterLimit
        self.showCharacterCount = showCharacterCount
        self.keyboardType = keyboardType
    }
    
    init(
        title: String,
        placeholder: String,
        value: Binding<Double>,
        errorMessage: String? = nil,
        keyboardType: UIKeyboardType = .decimalPad
    ) {
        self.title = title
        self.placeholder = placeholder
        self.text = nil
        self.doubleValue = value
        self.isCurrency = true
        self.errorMessage = errorMessage
        self.axis = .horizontal
        self.characterLimit = nil
        self.showCharacterCount = false
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerView
            inputContainer
            errorFooter
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            Text(title)
                .font(.captionText)
                .foregroundColor(.appTextSecondary)
            
            Spacer()
            
            if showCharacterCount, let limit = characterLimit, let text = text {
                Text("\(text.wrappedValue.count)/\(limit)")
                    .font(.caption)
                    .foregroundColor(text.wrappedValue.count > limit ? .appDangerRed : .appTextSecondary)
            }
        }
    }
    
    @ViewBuilder
    private var inputContainer: some View {
        textField
            .padding()
            .background(Color.appPrimaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
    
    @ViewBuilder
    private var errorFooter: some View {
        if let error = errorMessage {
            Text(error)
                .font(.captionText)
                .foregroundColor(.appDangerRed)
        }
    }
    
    private var borderColor: Color {
        errorMessage != nil ? .appDangerRed : .appTextSecondary.opacity(0.3)
    }
    
    @ViewBuilder
    private var textField: some View {
        if isCurrency, let doubleValue = doubleValue {
            TextField(placeholder, value: doubleValue, format: .currency(code: "BRL"))
                .keyboardType(keyboardType)
        } else if let text = text {
            TextField(placeholder, text: text, axis: axis)
                .keyboardType(keyboardType)
                .onChange(of: text.wrappedValue) { _, newValue in
                    limitText(newValue)
                }
        }
    }
    
    private func limitText(_ newValue: String) {
        if let limit = characterLimit, newValue.count > limit {
            text?.wrappedValue = String(newValue.prefix(limit))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        InputField(title: "Name", placeholder: "Enter name", text: .constant(""))
        
        InputField(title: "Amount", placeholder: "0,00", value: .constant(123.45))
        
        InputField(title: "Email", placeholder: "Email", text: .constant("invalid"), errorMessage: "Invalid email")
    }
    .padding()
    .background(Color.appSecondaryBackground)
}
