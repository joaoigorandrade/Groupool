//
//  PhoneEntryView.swift
//  Groupo
//
//  Created by Antigravity on 2026-02-18.
//

import SwiftUI

struct PhoneEntryView: View {
    @StateObject private var viewModel = PhoneEntryViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Header
                Text("Enter your phone number")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("We will send you a verification code.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                
                // Input Field
                HStack(spacing: 12) {
                    // Country Code
                    HStack {
                        Text("🇧🇷")
                        Text("+55")
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Phone Number
                    TextField("11 99999-9999", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: viewModel.phoneNumber) { newValue in
                             // Optional: Format as user types (not strictly required yet)
                             // Limit to 11 digits (2 area + 9 number)
                             let filtered = newValue.filter { $0.isNumber }
                             if filtered.count > 11 {
                                 viewModel.phoneNumber = String(filtered.prefix(11))
                             }
                        }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Send Code Button
                Button(action: {
                    viewModel.sendCode(sessionManager: sessionManager)
                }) {
                    Text("Send Code")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isValid ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.isValid)
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Navigation to OTP
                .navigationDestination(isPresented: $viewModel.navigateToOTP) {
                    OTPEntryView(phoneNumber: viewModel.phoneNumber)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    PhoneEntryView()
}
