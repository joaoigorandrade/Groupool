## 2026-02-19 - Unstable Identifiers in LedgerViewModel
**Learning:** `TransactionSection` and `DailySummary` were using `let id = UUID()`, causing full list re-renders on every data refresh, even if data was identical. This is a significant performance anti-pattern in SwiftUI lists.
**Action:** Always verify `Identifiable` structs have stable IDs based on content (e.g., date, unique key) rather than random UUIDs, especially for view models that refresh frequently.
