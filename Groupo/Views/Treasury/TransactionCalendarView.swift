import SwiftUI

struct TransactionCalendarView: View {
    enum CalendarSize: Int {
        case half = 30
        case full = 60
    }
    
    let summaries: [DailySummary]
    let size: CalendarSize
    
    private let columns = Array(repeating: GridItem(.fixed(14), spacing: 4), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var filteredSummaries: [DailySummary] {
        Array(summaries.suffix(size.rawValue))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            calendarGrid
            footer
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private extension TransactionCalendarView {
    var header: some View {
        Text("Last \(size.rawValue) days activity")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    var calendarGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.5))
                        .frame(width: 14)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(filteredSummaries) { summary in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color(for: summary))
                        .frame(width: 14, height: 14)
                }
            }
        }
    }
    
    var footer: some View {
        let stats = calculateStats()
        
        return HStack {
            HStack(spacing: 4) {
                Circle().fill(Color.green.opacity(0.8)).frame(width: 6, height: 6)
                Text("\(stats.positive) positive days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle().fill(Color.red.opacity(0.8)).frame(width: 6, height: 6)
                Text("\(stats.negative) negative days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    func calculateStats() -> (positive: Int, negative: Int) {
        let positive = filteredSummaries.filter { $0.netAmount > 0 }.count
        let negative = filteredSummaries.filter { $0.netAmount < 0 }.count
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
