//
//  TransactionDenseRow.swift
//  Groupo
//
//  Created by Groupo on 2026-02-19.
//

import SwiftUI

struct TransactionDenseRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.type.iconColor().opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: transaction.type.iconName())
                    .foregroundColor(transaction.type.iconColor())
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(transaction.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.formattedAmount())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.type.amountColor())
                
                Text(transaction.type.rawValue.capitalized)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(transaction.type.iconColor())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(transaction.type.iconColor().opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack {
        TransactionDenseRow(transaction: .preview())
        TransactionDenseRow(transaction: .preview(type: .expense))
    }
    .padding()
    .background(Color.appPrimaryBackground)
}
