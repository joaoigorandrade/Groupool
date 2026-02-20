//
//  TreasuryStatCard.swift
//  Groupo
//
//  Created by Groupo on 2026-02-19.
//

import SwiftUI

struct TreasuryStatCard: View {
    let title: String
    let value: Decimal
    var format: StatFormat = .currency
    
    enum StatFormat { case currency, number }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
             Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
             
            if format == .currency {
                Text(value, format: .currency(code: "BRL"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            } else {
                Text("\(NSDecimalNumber(decimal: value).intValue)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    HStack {
        TreasuryStatCard(title: "Total Balance", value: 1250.50)
        TreasuryStatCard(title: "Transactions", value: 42, format: .number)
    }
    .padding()
    .background(Color.appPrimaryBackground)
}
