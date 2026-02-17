import SwiftUI

struct PersonalStakeCard: View {
    let available: Decimal
    let frozen: Decimal
    let total: Decimal
    
    var body: some View {
        VStack(spacing: 16) {
            header
            Divider().background(.white.opacity(0.1))
            balanceRow
        }
        .padding(20)
        .background(Color("SecondaryBackground"))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Stake")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.0)
                
                Text(total.formatted(.currency(code: "BRL")))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Spacer()
            Image(systemName: "wallet.pass.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
                .opacity(0.5)
        }
    }
    
    private var balanceRow: some View {
        HStack(spacing: 0) {
            balanceItem(
                label: "Available",
                amount: available,
                color: Color("AvailableGreen"),
                icon: "checkmark.circle.fill"
            )
            
            Divider()
                .frame(height: 30)
                .padding(.horizontal, 16)
            
            balanceItem(
                label: "Frozen",
                amount: frozen,
                color: Color("FrozenBlue"),
                icon: "lock.fill"
            )
        }
    }
    
    private func balanceItem(label: String, amount: Decimal, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(color)
            
            Text(amount.formatted(.currency(code: "BRL")))
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        Color("PrimaryBackground")
            .ignoresSafeArea()
        
        PersonalStakeCard(
            available: 350.00,
            frozen: 150.00,
            total: 500.00
        )
        .padding()
    }
}
