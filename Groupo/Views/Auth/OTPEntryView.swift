//
//  OTPEntryView.swift
//  Groupo
//
//  Created by Antigravity on 2026-02-18.
//

import SwiftUI
import Combine

struct OTPEntryView: View {
    @StateObject private var viewModel: OTPEntryViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @FocusState var focus: Bool
    
    init(phoneNumber: String) {
        _viewModel = StateObject(wrappedValue: OTPEntryViewModel(phoneNumber: phoneNumber))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Enter Verification Code")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Sent to \(viewModel.maskedPhoneNumber)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            ZStack {
                TextField("", text: $viewModel.otpCode)
                    .keyboardType(.numberPad)
                    .focused($focus)
                    .textContentType(.oneTimeCode)
                    .accentColor(.clear)
                    .foregroundColor(.clear)
                    .onChange(of: viewModel.otpCode) { _, newValue in
                        if newValue.count > 6 {
                            viewModel.otpCode = String(newValue.prefix(6))
                        }
                    }
                
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPDigitBox(index: index, code: viewModel.otpCode)
                            .onTapGesture {
                                guard !focus else { return }
                                focus = true
                            }
                    }
                }
            }
            .padding(.horizontal)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.verifyCode(using: sessionManager)
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Verify")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.otpCode.count == 6 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.otpCode.count != 6 || viewModel.isLoading)
            .padding(.horizontal)
            
            // Resend Button / Timer
            Button(action: {
                viewModel.resendCode()
            }) {
                if viewModel.canResend {
                    Text("Resend Code")
                        .foregroundColor(.blue)
                } else {
                    Text("Resend code in \(viewModel.timeRemaining)s")
                        .foregroundColor(.secondary)
                }
            }
            .disabled(!viewModel.canResend)
            .padding(.bottom, 20)
        }
        .padding()
        .navigationBarHidden(false)
    }
}

struct OTPDigitBox: View {
    let index: Int
    let code: String
    
    var body: some View {
        let digit = (index < code.count) ? String(code[code.index(code.startIndex, offsetBy: index)]) : ""
        
        Text(digit)
            .font(.title)
            .fontWeight(.bold)
            .frame(width: 45, height: 55)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(digit.isEmpty ? Color.clear : Color.blue, lineWidth: 1)
            )
    }
}

#Preview {
    OTPEntryView(phoneNumber: "+5511912345678")
        .environmentObject(SessionManager(userDefaults: .standard))
}
