import SwiftUI

struct TransactionCalendarView: View {
    
    let summaries: [DailySummary]
    let isSmall: Bool
    let size: Int = 30
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private static let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var filteredSummaries: [DailySummary] {
        Array(summaries.suffix(size))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            calendarGrid
                .padding(.horizontal, isSmall ? 0 : 24)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .treasuryCardStyle()
    }
}

private extension TransactionCalendarView {
    var header: some View {
        HStack(alignment: .top) {
            Text("Last \(size) days activity")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer(minLength: 0)
            score
        }
    }
    
    var calendarGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(Array(Self.weekdays.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(filteredSummaries) { summary in
                    RoundedRectangle(cornerRadius: isSmall ? 3 : 8)
                        .fill(color(for: summary))
                        .aspectRatio(1, contentMode: .fill)
                }
            }
        }
    }
    
    var score: some View {
        let stats = calculateStats()
        
        return VStack(alignment: .leading,
                      spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 6, height: 6)
                
                Text("\(stats.positive) positive")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 6, height: 6)
                
                Text("\(stats.negative) negative")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    func calculateStats() -> (positive: Int, negative: Int) {
        let positive = filteredSummaries.count { $0.netAmount > 0 }
        let negative = filteredSummaries.count { $0.netAmount < 0 }
        return (positive, negative)
    }
    
    func color(for summary: DailySummary) -> Color {
        if summary.netAmount == 0 && summary.transactionCount > 0 {
            return Color.orange.opacity(0.5)
        }
        
        if summary.netAmount == 0 {
            return Color.gray.opacity(0.15)
        }
        
        let amount = NSDecimalNumber(decimal: summary.netAmount).doubleValue
        
        if amount > 500 { return Color.green.opacity(0.9) }
        if amount > 100 { return Color.green.opacity(0.7) }
        if amount > 0   { return Color.green.opacity(0.4) }
        
        if amount < -500 { return Color.red.opacity(0.9) }
        if amount < -100 { return Color.red.opacity(0.7) }
        if amount < 0    { return Color.red.opacity(0.4) }
        
        return Color.gray.opacity(0.15)
    }
}

#Preview {
    TransactionCalendarView(summaries: [], isSmall: true)
}
