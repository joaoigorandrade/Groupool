import SwiftUI

struct InputField: View {
    let title: String
    let placeholder: String
    let errorMessage: String?
    
    private let text: Binding<String>?
    private let doubleValue: Binding<Double>?
    private let isCurrency: Bool
    
    init(title: String, placeholder: String, text: Binding<String>, errorMessage: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self.text = text
        self.doubleValue = nil
        self.isCurrency = false
        self.errorMessage = errorMessage
    }
    
    init(title: String, placeholder: String, value: Binding<Double>, errorMessage: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self.text = nil
        self.doubleValue = value
        self.isCurrency = true
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.captionText)
                .foregroundColor(.textSecondary)
            
            textField
                .padding()
                .background(Color.primaryBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(errorMessage != nil ? Color.dangerRed : Color.textSecondary.opacity(0.3), lineWidth: 1)
                )
            
            if let error = errorMessage {
                Text(error)
                    .font(.captionText)
                    .foregroundColor(.dangerRed)
            }
        }
    }
    
    @ViewBuilder
    private var textField: some View {
        if isCurrency, let doubleValue = doubleValue {
            TextField(placeholder, value: doubleValue, format: .currency(code: "BRL"))
                .keyboardType(.decimalPad)
        } else if let text = text {
            TextField(placeholder, text: text)
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
    .background(Color.secondaryBackground)
}
